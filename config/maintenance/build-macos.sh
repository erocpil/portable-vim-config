#!/bin/bash
# The GTK3/terminal Gentoo builds use build-gentoo.sh. MacVim is separate.
set -euo pipefail
prefix="$HOME/.local/opt/vim"
py=/Library/Frameworks/Python.framework/Versions/3.13/bin/python3
cache="${XDG_CACHE_HOME:-$HOME/.cache}/vim-macos-build"
latest="$cache/latest"
verbose=0

detail() {
    if (( verbose )); then printf '%s\n' "$*"; fi
}

run_logged() {
    local log=$1
    shift
    if (( verbose )); then
        printf 'Log: %s\n' "$log"
        "$@" 2>&1 | tee "$log"
    elif "$@" > "$log" 2>&1; then
        return 0
    else
        local status=$?
        tail -40 "$log" >&2
        return "$status"
    fi
}

check_stage() {
    local tree=$1
    local runtime=("$tree"/share/vim/vim[0-9]*)
    [[ ${#runtime[@]} == 1 && -d ${runtime[0]} ]]
    detail "Checking $tree/bin/vim (Python 3.13 and terminal support)"
    VIMRUNTIME="${runtime[0]}" "$tree/bin/vim" -Nu NONE -i NONE -n -es \
        -c 'if !has("terminal") || !has("python3") | cquit | endif' \
        -c 'py3 import sys; assert sys.version_info[:2] == (3, 13)' -c 'qa!'
}

usage() {
    printf '%s\n' \
        'bash c.sh                       Build, verify, and install terminal Vim.' \
        'bash c.sh --build               Build, verify, and stage without installing.' \
        'bash c.sh --install [BUILD_DIR] Install a staged build (default: last successful build).' \
        'bash c.sh --help                Show this help.' \
        'Add --verbose to show live build output and installation details.'
}

args=()
for arg in "$@"; do
    if [[ $arg == --verbose ]]; then
        verbose=1
    else
        args+=("$arg")
    fi
done
# macOS Bash 3.2 treats an empty array as unset under nounset.
if [[ ${args[0]+present} ]]; then
    set -- "${args[@]}"
else
    set --
fi
install_build() {
    local work revision stage
    work=$(cd "$1" && pwd -P)
    revision=$(cat "$work/commit")
    stage="$work/stage$prefix"
    check_stage "$stage"
    mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
    entry="$HOME/.local/bin/vim"
    if [[ -e $entry || -L $entry ]]; then
        [[ -L $entry && $(readlink "$entry") == ../opt/vim/bin/vim ]] || {
            echo "Review the existing entry: $entry" >&2; exit 1;
        }
    fi
    incoming=$(mktemp -d "$HOME/.local/opt/.vim-install-XXXXXXXX")
    detail "Copying $stage to $incoming"
    cp -a "$stage"/. "$incoming"/
    check_stage "$incoming"
    backup="$prefix.backup-$(date +%Y%m%d-%H%M%S)"
    if [[ -e $prefix ]]; then
        [[ ! -e $backup ]]
        detail "Backing up $prefix to $backup"
        mv "$prefix" "$backup"
    fi
    detail "Installing to $prefix"
    if ! mv "$incoming" "$prefix"; then
        if [[ -e $backup ]]; then mv "$backup" "$prefix"; fi
        exit 1
    fi
    if [[ ! -L $entry ]]; then ln -s ../opt/vim/bin/vim "$entry"; fi
    {
        printf 'Installed at: %s\nSource commit: %s\nPrefix: %s\n' "$(date -u +%FT%TZ)" "$revision" "$prefix"
        if [[ -e $backup ]]; then printf 'Previous installation: %s\n' "$backup"; fi
    } | tee "$work/install-record.txt"
}

case "$#:${1:-}" in
    0:) mode=both ;;
    1:--build) mode=build ;;
    1:--install)
        if [[ ! -s $latest ]]; then
            echo 'No staged build recorded. Run c.sh --build first.' >&2
            exit 1
        fi
        IFS= read -r work < "$latest"
        if [[ ! -d $work/stage$prefix ]]; then
            echo "Staged build is missing: $work. Run c.sh --build again." >&2
            exit 1
        fi
        install_build "$work"
        exit
        ;;
    2:--install) install_build "$2"; exit ;;
    1:--help|1:-h) usage; exit ;;
    *) usage >&2; exit 2 ;;
esac

cd "${VIM_SOURCE_DIR:-$HOME/src/vim}"
test -x "$py"
mkdir -p "$cache"
work=$(mktemp -d "$cache/build-XXXXXXXX")
printf 'Build directory: %s\n' "$work"
git rev-parse HEAD > "$work/commit"
git archive HEAD > "$work/source.tar"
mkdir "$work/source"
tar -xf "$work/source.tar" -C "$work/source"
cd "$work/source"
run_logged "$work/configure.log" ./configure --prefix="$prefix" --with-features=huge --enable-python3interp=yes \
    --with-python3-command="$py" --enable-terminal --disable-gui --without-x
run_logged "$work/make.log" make -j"${JOBS:-8}"
run_logged "$work/install.log" make install DESTDIR="$work/stage"
check_stage "$work/stage$prefix"
record=$(mktemp "$cache/.latest-XXXXXXXX")
printf '%s\n' "$work" > "$record"
mv -f "$record" "$latest"
printf 'Checked stage: %s\n' "$work/stage$prefix"
if [[ $mode == both ]]; then
    install_build "$work"
else
    printf 'Install the most recent successful build with: bash c.sh --install\n'
fi
