#!/usr/bin/env python3
"""Deploy Vim configuration, install pinned plugins, and build YouCompleteMe."""

import argparse
from collections import defaultdict
from datetime import datetime
from io import BytesIO
from itertools import chain
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
YCM = "bundle/YouCompleteMe"


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


def smoke(home, editor, checks, test_runtime=None):
    runtime, entry = paths(home)
    env = os.environ.copy()
    env.update(HOME=str(home), VIM_SETUP_CHECKS=checks)
    config = runtime / "config"
    if (config / ".git").exists():
        config /= "config"
    env["VIM_SETUP_CONFIG"] = (config / "dotvimrc").as_posix()
    pre_startup = []
    if test_runtime is not None:
        env["VIM_SETUP_RUNTIME"] = str(test_runtime)
        pre_startup = ["--cmd", "let g:portable_vim_home = $VIM_SETUP_RUNTIME"]
    if "ycm" in checks.split(","):
        env["VIM_SETUP_YCM"] = str((test_runtime or runtime) / YCM / "python/ycm/__init__.py")
    with tempfile.TemporaryDirectory(prefix="vim-smoke-") as name:
        scratch = Path(name)
        result, log = scratch / "result", scratch / "vim.log"
        env["VIM_SETUP_RESULT"] = str(result)
        job = subprocess.run(
            [editor, "-v", *pre_startup, "-Nu", entry, "-n", "-i", "NONE", "-es",
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
    if (runtime / "config/.git").exists():
        raise RuntimeError("Configuration is a Git checkout. Update it with git pull --ff-only.")
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
    if nested:
        status = run("git", "-C", target, "submodule", "status", "--recursive",
                     capture=True, text=True).stdout.splitlines()
        if not status or any(not line.startswith(" ") for line in status):
            raise RuntimeError(f"{target}: some recursive submodules are uninitialized or at the wrong revision")


def fetch_checkout(target, revision, url, source=None):
    run("git", "init", "--quiet", target)
    if url:
        run("git", "-C", target, "remote", "add", "origin", url)
    upstream = source.as_uri() if source is not None else "origin"
    run("git", "-C", target, "fetch", "--depth=1", "--no-tags", "--", upstream, revision,
        timeout=300)
    run("git", "-C", target, "checkout", "--quiet", "--detach", "FETCH_HEAD")


def fetch_local_submodules(target, source):
    # Gitlinks come from the fixed checkout. Only Git objects travel between
    # hosts, so ignored binaries and local edits from the source are excluded.
    run("git", "-C", target, "submodule", "init")
    records = run("git", "-C", target, "ls-tree", "-rz", "HEAD",
                  capture=True, text=True).stdout.split("\0")
    for record in filter(None, records):
        metadata, path = record.split("\t", 1)
        mode, _, revision = metadata.split()
        if mode != "160000":
            continue
        child, seed = target / path, source / path
        if not (seed / ".git").exists():
            raise RuntimeError(f"Local YCM source is missing an initialized submodule: {seed}")
        fetch_checkout(child, revision, git(seed, "remote", "get-url", "origin"), seed)
        fetch_local_submodules(child, seed)


def fetch_plugin(target, revision, url, nested, source=None):
    fetch_checkout(target, revision, url, source)
    if source is not None:
        fetch_local_submodules(target, source)
        run("git", "-C", target, "submodule", "absorbgitdirs")
    elif nested:
        run("git", "-C", target, "submodule", "update", "--init", "--recursive",
            "--depth=1", "--jobs=4", timeout=600)
    check_plugin(target, revision, nested)


def plugins(args):
    runtime, _ = paths(args.home)
    pins, nested = load_pins(HERE.parent / "plugins.lock")
    for path, (revision, url) in pins.items():
        if args.skip_ycm and path == YCM:
            continue
        target = runtime / path
        if path.startswith("config/.vim-pack/"):
            if (runtime / ".vim-pack").is_dir() or (runtime / "config/.git").exists():
                target = runtime / Path(path).relative_to("config")
        if target.exists() or target.is_symlink():
            check_plugin(target, revision, nested[path])
            print(f"Pinned: {path} {revision}")
            continue
        if args.check:
            raise RuntimeError(f"Plugin is missing: {target}")
        target.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix=".plugin-", dir=target.parent) as directory:
            candidate = Path(directory) / "checkout"
            fetch_plugin(candidate, revision, url, nested[path])
            candidate.rename(target)
        print(f"Installed plugin source: {path} {revision}")


def ycm_builder(name):
    if os.geteuid() != 0:
        if name:
            raise RuntimeError("--build-user is only for installations run as root.")
        return None
    if not name or not shutil.which("runuser"):
        raise RuntimeError("Build as a regular user, or use --build-user USER with runuser.")
    import pwd
    try:
        user = pwd.getpwnam(name)
    except KeyError:
        raise RuntimeError(f"Build user does not exist: {name}") from None
    if not user.pw_uid:
        raise RuntimeError("YCM must be built by an unprivileged user.")
    return user


def build_ycm(candidate, python, builder, args):
    command = [python, "install.py"]
    if args.clangd_completer:
        command.append("--clangd-completer")
    if args.verbose:
        command.append("--verbose")
    if builder:
        # The build path is outside the root home and cannot access the live
        # installation. Its outputs are copied back by the installing user.
        candidate.parent.chmod(0o755)
        home = candidate.parent / "build-home"
        home.mkdir(mode=0o700)
        for path in chain((home, candidate), candidate.rglob("*")):
            os.lchown(path, builder.pw_uid, builder.pw_gid)
        command = ["runuser", "-u", builder.pw_name, "--", "env",
                   f"HOME={home}", f"TMPDIR={home}", *command]
    run(*command, cwd=candidate, stdin=subprocess.DEVNULL)


def publish_ycm(candidate, target, runtime, home, editor):
    backup = None
    if target.exists() or target.is_symlink():
        backups = runtime / "backups"
        backups.mkdir(parents=True, exist_ok=True)
        backup = Path(tempfile.mkdtemp(prefix="ycm-", dir=backups)) / target.name
        target.rename(backup)
    activated = False
    try:
        candidate.rename(target)
        activated = True
        smoke(home, editor, "ycm")
    except BaseException:
        if activated:
            target.rename(candidate)
        if backup is not None:
            backup.rename(target)
            print(f"YCM update rolled back: {target}", file=sys.stderr)
        raise
    if backup is not None:
        print(f"Previous YCM preserved at {backup}")


def install_ycm(args):
    if sys.platform not in {"darwin", "linux"}:
        raise RuntimeError("Automated YCM builds target macOS and Linux. See the Windows instructions.")
    import fcntl

    runtime, entry = paths(args.home)
    target = runtime / YCM
    vundle = target.parent / "Vundle.vim"
    if not entry.is_file() or not (vundle / "autoload/vundle.vim").is_file():
        raise RuntimeError("Install the Vim startup entry and run plugins --skip-ycm before building YCM.")
    editor = resolve_vim(args.vim)
    python = shutil.which(os.path.expanduser(args.python))
    if not python:
        raise RuntimeError(f"Python interpreter not found: {args.python}")
    python = os.path.abspath(python)
    builder = ycm_builder(args.build_user)
    source = args.source.expanduser().resolve() if args.source else None
    if source is not None and not (source / ".git").exists():
        raise RuntimeError(f"--source requires an initialized YCM Git checkout: {source}")
    pins, nested = load_pins(HERE.parent / "plugins.lock")
    revision, url = pins[YCM]
    with (target.parent / ".portable-ycm.lock").open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise RuntimeError("Another YCM installation is already running.") from None
        with tempfile.TemporaryDirectory(prefix="portable-ycm-build-",
                                         dir="/var/tmp" if builder else None) as work:
            build = Path(work) / "YouCompleteMe"
            print(f"Preparing YCM {revision} from {source or url}", flush=True)
            fetch_plugin(build, revision, url, nested[YCM], source)
            print(f"Building with {python}", flush=True)
            build_ycm(build, python, builder, args)
            # Stage next to the live installation so the final rename is local.
            with tempfile.TemporaryDirectory(prefix=".portable-ycm-", dir=target.parent) as work:
                stage = Path(work)
                validation = stage / "runtime"
                bundle = validation / "bundle"
                bundle.mkdir(parents=True)
                candidate = bundle / target.name
                shutil.copytree(build, candidate, symlinks=True)
                (bundle / vundle.name).symlink_to(vundle, target_is_directory=True)
                local = runtime / "vimrc.local"
                if local.is_file():
                    (validation / local.name).symlink_to(local)
                check_plugin(candidate, revision, nested[YCM])
                print("Verifying the staged YCM with the local Vim configuration", flush=True)
                smoke(args.home, editor, "ycm", test_runtime=validation)
                print("Verifying the installed YCM", flush=True)
                publish_ycm(candidate, target, runtime, args.home, editor)
    print(f"Installed YCM {revision}: {target}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    for name in ("deploy", "plugins", "smoke", "ycm"):
        cmd = commands.add_parser(name)
        cmd.add_argument("--home", type=Path, default=Path.home())
        if name in {"deploy", "smoke", "ycm"}:
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
        if name == "ycm":
            cmd.add_argument("--python", default=sys.executable, help="Python used to build ycmd")
            cmd.add_argument("--source", type=Path, help="Local YCM checkout with initialized submodules")
            cmd.add_argument("--build-user", help="Unprivileged build account for a root installation")
            cmd.add_argument("--clangd-completer", action="store_true", help="Download YCM's bundled clangd")
            cmd.add_argument("--verbose", action="store_true", help="Show upstream build output")
    args = parser.parse_args()
    args.home = args.home.expanduser().resolve()
    try:
        if args.command == "smoke":
            checks = ",".join(name for name in ("practice", "ycm") if getattr(args, name))
            smoke(args.home, resolve_vim(args.vim), checks)
        elif args.command == "deploy":
            deploy(args)
        elif args.command == "ycm":
            install_ycm(args)
        else:
            plugins(args)
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        if isinstance(error, subprocess.CalledProcessError) and error.stderr:
            diagnostic = error.stderr.decode(errors="replace") if isinstance(error.stderr, bytes) else error.stderr
            print(diagnostic.rstrip(), file=sys.stderr)
        print(error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
