"""Create an isolated LaOS source copy for the deliberate quickfix failure test."""
import argparse
import shutil
import tempfile
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("repository", type=Path)
args = parser.parse_args()
source = args.repository.resolve()
if not (source / "kernel/arch/aarch64/main.c").is_file():
    parser.error("repository does not contain the LaOS ARM64 entry point")


def ignore(_directory, names):
    return [name for name in names
            if name in {".git", ".cache", "build", "compile_commands.json"}
            or name.startswith(("obj-", "bin-"))]


target = Path(tempfile.mkdtemp(prefix="laos-clang22-quickfix-"))
shutil.copytree(source, target, dirs_exist_ok=True, ignore=ignore)
(target / "kernel/arch/aarch64/quickfix_probe.c").write_text(
    '#warning "LAOS_QF_WARNING_PROBE"\n'
    '#error "LAOS_QF_ERROR_PROBE"\n'
    'int laos_quickfix_probe(void) {\n    return 0;\n}\n'
)
Path("/tmp/laos-quickfix-root").write_text(str(target))
print(target)
