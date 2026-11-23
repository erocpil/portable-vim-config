#!/bin/bash
set -euo pipefail

if [[ ${1:-} == --receive ]]; then
    payload=$2
    mode=$3
    config="$HOME/.vim/config"
    vimrc="$HOME/.vimrc"
    if [[ -e $config/.git ]]; then
        echo "Configuration is a Git checkout. Update it with git pull --ff-only." >&2
        exit 2
    fi
    printf 'Shared configuration %s\n' "$(cat "$payload/config/.deployed-revision")"
    rsync -rcpli --dry-run "$payload/config/" "$config/"
    rsync -rcpli --dry-run "$payload/vimrc" "$vimrc"
    if [[ $mode != apply ]]; then exit 0; fi

    mkdir -p "$HOME/.vim/backups"
    backup=$(mktemp -d "$HOME/.vim/backups/deploy-$(date +%Y%m%d-%H%M%S)-XXXXXXXX")
    if [[ -e $config ]]; then cp -a "$config" "$backup/config"; fi
    if [[ -e $vimrc ]]; then cp -a "$vimrc" "$backup/vimrc"; fi
    rollback() {
        echo "Deployment failed; restoring $backup" >&2
        if [[ -e $config ]]; then mv "$config" "$backup/failed-config"; fi
        if [[ -e $backup/config ]]; then cp -a "$backup/config" "$config"; fi
        if [[ -e $vimrc ]]; then mv "$vimrc" "$backup/failed-vimrc"; fi
        if [[ -e $backup/vimrc ]]; then cp -a "$backup/vimrc" "$vimrc"; fi
    }
    trap rollback ERR
    mkdir -p "$config"
    rsync -rcpl "$payload/config/" "$config/"
    rsync -rcpl "$payload/vimrc" "$vimrc"
    if [[ $(uname -s) == Darwin ]]; then editors=(mvim)
    else editors=(vim); if command -v gvim >/dev/null; then editors+=(gvim); fi
    fi
    for editor in "${editors[@]}"; do
        "$editor" -v -Nu "$vimrc" -n -i NONE -es -V1"$backup/$editor.log" \
            -c 'if exists(":PracticeRun") != 2 || !exists("*PortableVimBalloon") | cquit | endif' \
            -c 'qa!' < /dev/null > "$backup/$editor.out" 2>&1
    done
    test -z "$(rsync -rcpli --dry-run "$payload/config/" "$config/")"
    cmp "$payload/vimrc" "$vimrc"
    trap - ERR
    printf 'Applied and checked. Backup: %s\n' "$backup"
    exit
fi

mode=preview
host=
revision=HEAD
while [[ $# -gt 0 ]]; do
    case $1 in
        --apply) mode=apply; shift ;;
        --host) host=${2:?Missing SSH destination}; shift 2 ;;
        --revision) revision=${2:?Missing Git commit}; shift 2 ;;
        *) echo "Usage: $0 [--apply] [--host USER@HOST] [--revision COMMIT]" >&2; exit 2 ;;
    esac
done
repo=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
revision=$(git -C "$repo" rev-parse --verify "$revision^{commit}")
work=$(mktemp -d "${TMPDIR:-/tmp}/vim-deploy-XXXXXXXX")
trap 'rm -rf -- "$work"' EXIT
git -C "$repo" archive --format=tar "$revision" config > "$work/source.tar"
mkdir "$work/payload"
tar -xf "$work/source.tar" -C "$work/payload"
printf '%s\n' "$revision" > "$work/payload/config/.deployed-revision"
cp "$work/payload/config/maintenance/vimrc.entry" "$work/payload/vimrc"
if [[ -z $host ]]; then
    bash "$work/payload/config/maintenance/deploy.sh" --receive "$work/payload" "$mode"
else
    COPYFILE_DISABLE=1 tar -cf "$work/payload.tar" -C "$work/payload" .
    receiver='set -eu; stage=$(mktemp -d /tmp/vim-deploy-XXXXXXXX); trap '\''rm -rf -- "$stage"'\'' EXIT; tar -xf - -C "$stage"; bash "$stage/config/maintenance/deploy.sh" --receive "$stage"'
    ssh -o BatchMode=yes -- "$host" "bash -c $(printf '%q' "$receiver $mode")" < "$work/payload.tar"
fi
