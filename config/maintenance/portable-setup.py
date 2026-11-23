#!/usr/bin/env python3
"""Deploy shared Vim configuration and install pinned plugin sources."""

import argparse
from collections import defaultdict
from datetime import datetime
from io import BytesIO
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import subprocess
import sys
import tempfile
from zipfile import ZipFile

HERE = Path(__file__).resolve().parent
WINDOWS = os.name == "nt"


def run(*argv, capture=False, **kwargs):
    return subprocess.run(argv, check=True, capture_output=capture, **kwargs)


def git(directory, *args):
    return run("git", "-C", directory, *args, capture=True, text=True).stdout.strip()


def paths(home):
    return home / ("vimfiles" if WINDOWS else ".vim"), home / ("_vimrc" if WINDOWS else ".vimrc")


def resolve_vim(supplied=None):
    command = supplied or ("mvim" if sys.platform == "darwin" else "vim")
    editor = shutil.which(command)
    if not editor:
        raise RuntimeError(f"Cannot find {command}; provide --vim with the executable path.")
    return editor


def smoke(home, editor, checks):
    runtime, entry = paths(home)
    env = os.environ.copy()
    env.update(HOME=str(home), VIM_SETUP_CHECKS=checks)
    env["VIM_SETUP_CONFIG"] = (runtime / "config/dotvimrc").as_posix()
    with tempfile.TemporaryDirectory(prefix="vim-smoke-") as name:
        scratch = Path(name)
        result, log = scratch / "result", scratch / "vim.log"
        env["VIM_SETUP_RESULT"] = str(result)
        job = subprocess.run(
            [editor, "-v", "-Nu", entry, "-n", "-i", "NONE", "-es",
             "-V1" + str(log), "-S", HERE / "smoke.vim"],
            env=env, stdin=subprocess.DEVNULL, capture_output=True, timeout=75,
        )
        report = result.read_text(encoding="utf-8") if result.is_file() else ""
        if job.returncode or not report.startswith("PASS:"):
            diagnostics = job.stderr.decode(errors="replace")
            if log.is_file():
                diagnostics += "\n" + log.read_text(errors="replace")[-4000:]
            raise RuntimeError(f"Vim smoke check failed:\n{report}{diagnostics}")
        print(report.strip())


def deploy(args):
    runtime, entry = paths(args.home)
    repo = git(HERE, "rev-parse", "--show-toplevel")
    revision = git(repo, "rev-parse", "--verify", args.revision + "^{commit}")
    data = run("git", "-C", repo, "archive", "--format=zip", revision, "config",
               capture=True).stdout
    with ZipFile(BytesIO(data)) as archive:
        files = {}
        for item in archive.infolist():
            path = PurePosixPath(item.filename)
            if item.is_dir():
                continue
            if path.is_absolute() or path.parts[0] != "config" or ".." in path.parts:
                raise RuntimeError(f"Unsafe archive path: {path}")
            if stat.S_ISLNK(item.external_attr >> 16):
                raise RuntimeError(f"Unsupported configuration symlink: {path}")
            target = runtime.joinpath(*path.parts)
            if not target.resolve().is_relative_to(runtime.resolve()):
                raise RuntimeError(f"Configuration path escapes Vim runtime: {target}")
            files[target] = (archive.read(item), (item.external_attr >> 16) & 0o777)
    template = "vimrc.windows" if WINDOWS else "vimrc.entry"
    files[entry] = files[runtime / "config/maintenance" / template]
    files[runtime / "config/.deployed-revision"] = ((revision + "\n").encode(), 0)
    changes = {p: record for p, record in files.items()
               if not p.is_file() or p.read_bytes() != record[0]}
    print(f"Shared configuration {revision}")
    for path in changes:
        print(f"{'update' if path.exists() else 'add'} {path}")
    if not args.apply:
        return

    editor = resolve_vim(args.vim)
    backup_root = runtime / "backups"
    backup_root.mkdir(parents=True, exist_ok=True)
    backup = Path(tempfile.mkdtemp(prefix="deploy-", dir=backup_root))
    saved = {}
    for number, path in enumerate(changes):
        if path.exists():
            old = backup / str(number) / path.name
            old.parent.mkdir()
            shutil.copy2(path, old)
            saved[path] = old
    (backup / "files.txt").write_text(
        "".join(f"{p}\t{saved.get(p, 'new file')}\n" for p in changes),
        encoding="utf-8",
    )
    applied = []
    try:
        for path, (contents, mode) in changes.items():
            path.parent.mkdir(parents=True, exist_ok=True)
            with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as stream:
                temporary = Path(stream.name)
                stream.write(contents)
            try:
                if mode and not WINDOWS:
                    temporary.chmod(mode)
                os.replace(temporary, path)
                applied.append(path)
            finally:
                temporary.unlink(missing_ok=True)
        smoke(args.home, editor, "")
        if any(path.read_bytes() != record[0] for path, record in files.items()):
            raise RuntimeError("Installed files differ from the selected Git commit.")
    except BaseException:
        for path in reversed(applied):
            if path in saved:
                shutil.copy2(saved[path], path)
            else:
                path.unlink()
        print(f"Deployment rolled back. Backup: {backup}", file=sys.stderr)
        raise
    print(f"Applied and checked. Backup: {backup}")


def load_pins(lock):
    pins = {}
    nested = defaultdict(dict)
    for line in lock.read_text(encoding="utf-8").splitlines():
        fields = line.split()
        if not fields or fields[0].startswith("#"):
            continue
        path, revision, *urls = fields
        relative = PurePosixPath(path)
        if (relative.is_absolute() or ".." in relative.parts or
                relative.parts[0] not in {"bundle", "config"} or
                not re.fullmatch(r"[0-9a-f]{40}", revision)):
            raise RuntimeError(f"Invalid plugin pin: {line}")
        if urls:
            if len(urls) != 1 or not urls[0].startswith("https://"):
                raise RuntimeError(f"Expected an HTTPS plugin URL: {line}")
            pins[path] = (revision, urls[0])
            continue
        parents = [root for root in pins if path.startswith(root + "/")]
        if not parents:
            raise RuntimeError(f"No parent repository for submodule: {line}")
        root = max(parents, key=len)
        nested[root][path[len(root) + 1:]] = revision
    return pins, nested


def check_plugin(target, revision, nested):
    # Check the checkout itself, not an enclosing Vim configuration repository.
    if not (target / ".git").exists():
        raise RuntimeError(f"Unmanaged plugin directory: {target}")
    actual = git(target, "rev-parse", "HEAD")
    if actual != revision:
        raise RuntimeError(f"{target}: at {actual}, expected {revision}")
    for child, expected in nested.items():
        checkout = target / child
        if not (checkout / ".git").exists() or git(checkout, "rev-parse", "HEAD") != expected:
            raise RuntimeError(f"{checkout}: expected submodule {expected}")


def plugins(args):
    runtime, _ = paths(args.home)
    pins, nested = load_pins(HERE.parent / "plugins.lock")
    for path, (revision, url) in pins.items():
        if args.skip_ycm and path == "bundle/YouCompleteMe":
            continue
        target = runtime / path
        if target.exists() or target.is_symlink():
            check_plugin(target, revision, nested[path])
            print(f"Pinned: {path} {revision}")
            continue
        if args.check:
            raise RuntimeError(f"Plugin is missing: {target}")
        target.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix=".plugin-", dir=target.parent) as directory:
            candidate = Path(directory) / "checkout"
            run("git", "init", candidate)
            run("git", "-C", candidate, "remote", "add", "origin", url)
            run("git", "-C", candidate, "fetch", "--depth=1", "origin", revision)
            run("git", "-C", candidate, "checkout", "--detach", "FETCH_HEAD")
            if nested[path]:
                run("git", "-C", candidate, "submodule", "update", "--init", "--recursive",
                    "--depth=1", "--jobs=4")
            check_plugin(candidate, revision, nested[path])
            candidate.rename(target)
        print(f"Installed plugin source: {path} {revision}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    for name in ("deploy", "plugins", "smoke"):
        cmd = commands.add_parser(name)
        cmd.add_argument("--home", type=Path, default=Path.home())
        if name in {"deploy", "smoke"}:
            cmd.add_argument("--vim")
        if name == "deploy":
            cmd.add_argument("--revision", default="HEAD")
            cmd.add_argument("--apply", action="store_true")
        if name == "plugins":
            cmd.add_argument("--check", action="store_true")
            cmd.add_argument("--skip-ycm", action="store_true")
        if name == "smoke":
            cmd.add_argument("--practice", action="store_true")
            cmd.add_argument("--ycm", action="store_true")
    args = parser.parse_args()
    args.home = args.home.expanduser().resolve()
    try:
        if args.command == "smoke":
            checks = ",".join(name for name in ("practice", "ycm") if getattr(args, name))
            smoke(args.home, resolve_vim(args.vim), checks)
        elif args.command == "deploy":
            deploy(args)
        else:
            plugins(args)
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print(error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
