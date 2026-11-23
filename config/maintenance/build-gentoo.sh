#!/bin/bash
# Build and install the committed Gentoo Vim source. Use --build to stop
# at the checked stage, and --install to install the last successful build.
#
# Update first with git pull --ff-only. If Gentoo cannot reach GitHub:
#   On a machine with the official Vim checkout and current master:
#     git bundle create vim-update.bundle master ^<gentoo-master-sha>
#   Transfer the bundle over SSH, then run on Gentoo:
#     git bundle verify /path/to/vim-update.bundle
#     git pull --ff-only /path/to/vim-update.bundle master
set -euo pipefail
export LC_ALL=C
prefix="$HOME/.local/opt/vim"
py=/usr/bin/python3.13
cache="${XDG_CACHE_HOME:-$HOME/.cache}/vim-gentoo-build"
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
    local tree=$1 bin version
    local runtime=("$tree"/share/vim/vim[0-9]*)
    [[ ${#runtime[@]} == 1 && -d ${runtime[0]} ]]
    for bin in vim vim-terminal; do
        detail "Checking $tree/bin/$bin (Python 3.13 and terminal support)"
        version=$("$tree/bin/$bin" --version)
        case "$bin:$version" in
            vim:*'with GTK3 GUI'*|vim-terminal:*'without GUI'*) ;;
            *) echo "Unexpected build for $bin" >&2; return 1 ;;
        esac
        VIMRUNTIME="${runtime[0]}" "$tree/bin/$bin" -v -Nu NONE -i NONE -n -es \
            -c 'if !has("terminal") || !has("python3") | cquit | endif' \
            -c 'py3 import sys; assert sys.version_info[:2] == (3, 13)' -c 'qa!'
    done
    test -x "$tree/bin/gvim"
}

install_build() {
    local work revision stage
    work=$(realpath -e "$1") || return 1
    revision=$(cat "$work/commit")
    stage="$work/stage$prefix"
    mkdir -p "$cache"
    # Serialize changes to the installation and command links.
    exec 9>"$cache/install.lock"
    flock -x 9
    check_stage "$stage"
    entry_dir="$HOME/.local/bin"
    mkdir -p "$entry_dir" "$HOME/.local/opt"
    names=(vim gvim xxd vimtutor gvimtutor)
    targets=(../opt/vim/bin/vim-terminal ../opt/vim/bin/gvim ../opt/vim/bin/xxd
             ../opt/vim/bin/vimtutor ../opt/vim/bin/gvimtutor)
    for i in "${!names[@]}"; do
        entry="$entry_dir/${names[i]}"
        if [[ -e $entry || -L $entry ]]; then
            if [[ ! -L $entry || $(readlink "$entry") != "${targets[i]}" ]]; then
                echo "Review the existing entry: $entry" >&2
                exit 1
            fi
        fi
    done

    incoming=$(mktemp -d "$HOME/.local/opt/.vim-install-XXXXXXXX")
    detail "Copying $stage to $incoming"
    cp -a "$stage"/. "$incoming"/
    check_stage "$incoming"
    backup=""
    if [[ -e $prefix || -L $prefix ]]; then
        backup=$(mktemp -d "$HOME/.local/opt/.vim-backup-XXXXXXXX")
        detail "Backing up $prefix to $backup/install"
        mv "$prefix" "$backup/install"
    fi
    detail "Installing to $prefix"
    if ! mv "$incoming" "$prefix"; then
        if [[ -n $backup ]]; then mv "$backup/install" "$prefix"; fi
        exit 1
    fi

    created=()
    for i in "${!names[@]}"; do
        entry="$entry_dir/${names[i]}"
        if [[ ! -L $entry ]]; then
            detail "Linking $entry to ${targets[i]}"
            if ! ln -s "${targets[i]}" "$entry"; then
                for link in "${created[@]}"; do unlink "$link"; done
                mv "$prefix" "$incoming"
                if [[ -n $backup ]]; then mv "$backup/install" "$prefix"; fi
                exit 1
            fi
            created+=("$entry")
        fi
    done
    printf 'Installed at: %s\nSource commit: %s\nPrefix: %s\nPrevious installation: %s\n' \
        "$(date -u +%FT%TZ)" "$revision" "$prefix" "${backup:-none}" | tee "$work/install-record.txt"
}

usage() {
    printf '%s\n' \
        'bash c.sh                       Build, verify, and install both Vim variants.' \
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
set -- "${args[@]}"

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
for variant in gtk3 terminal; do
    mkdir "$work/$variant"
    tar -xf "$work/source.tar" -C "$work/$variant"
    if [[ $variant == gtk3 ]]; then
        gui=(--enable-gui=gtk3 --with-x --enable-xim --enable-fontset --enable-autoservername)
    else
        gui=(--disable-gui --without-x)
    fi
    printf 'Building %s\n' "$variant"
    build_variant() (
        cd "$work/$variant" || exit 1
        ./configure --prefix="$prefix" --with-features=huge --enable-python3interp=dynamic \
            --with-python3-command="$py" --enable-terminal --enable-cscope \
            --enable-fail-if-missing "${gui[@]}" &&
        make -j"${JOBS:-8}"
    )
    run_logged "$work/$variant.log" build_variant
done
run_logged "$work/install.log" make -C "$work/gtk3" install DESTDIR="$work/stage"
install -m755 "$work/terminal/src/vim" "$work/stage$prefix/bin/vim-terminal"
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
