#!/bin/sh
# Copy next to Vim's top-level Makefile to build that source checkout.
set -eu
dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
if [ -f "$dir/src/Makefile" ]; then
    VIM_SOURCE_DIR=$dir
    export VIM_SOURCE_DIR
fi
case $(uname -s) in
    Darwin) script=build-macos.sh ;;
    Linux)
        if [ ! -f /etc/gentoo-release ]; then
            echo 'The Linux source build script currently targets Gentoo.' >&2
            exit 1
        fi
        script=build-gentoo.sh
        ;;
    *) echo 'Use official Vim binaries on this platform.' >&2; exit 1 ;;
esac
config=$HOME/.vim/config
if [ -e "$config/.git" ]; then
    config=$config/config
fi
exec "$config/maintenance/$script" "$@"
