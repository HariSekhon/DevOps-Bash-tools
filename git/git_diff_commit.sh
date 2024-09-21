#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-08-05 15:49:27 +0100
#  (migrated out of .bash.d/git.sh for use in IntelliJ)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Runs git diff and commit with a generic \"updated \$filename\" commit message

Lazy but awesome for lots of daily quick intermediate commit saves

Originally used in .bash.d/git.sh as a function git() and vimrc hotkey

Ported to external script be callable from IntelliJ as an External Tool because it's less keystrokes
and no mouse movement compared to IntelliJ's own hot key git commit tooling

If no args are given, then git diffs and commits against the current working directory
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<files_or_directories>]"

help_usage "$@"

#min_args 1 "$@"

resolve_symlinks(){
    local readlink=readlink
    if is_mac; then
        readlink=greadlink
        if ! type -P greadlink >&/dev/null; then
            "$srcdir/../packages/brew_install_package.sh" coreutils  # for greadlink
        fi
    fi
    for x in "$@"; do
        "$readlink" -m "$x"
    done
}

git_diff_commit(){
    local basedir
    for filename in "${@:-.}"; do
        if [ "$filename" != . ]; then
            # TODO: detect link changes and commit them too
            filename="$(resolve_symlinks "$filename")"
        fi
        basedir="$(dirname "$filename")"
        pushd "$basedir" > /dev/null
        changed_files="$(
            git status --porcelain -s "${filename##*/}" |
            grep -e '^M' -e '^.M' |
            sed 's/^...//' || :
        )"
        for changed_filename in $changed_files; do
            basename="${changed_filename##*/}"
            diff="$(git diff --color=always -- "$changed_filename"
                    git diff --cached --color=always -- "$changed_filename")"
            if [ -z "$diff" ]; then
                continue
            fi
            echo "$diff" | more -FR
            echo
            # discard the save variable, call it _ to signify this
            read -r -p "Hit enter to commit '$changed_filename' or Control-C to cancel" _
            echo
            git add -- "$changed_filename"
            echo "committing $changed_filename"
            git commit -m "updated $basename" -- "$changed_filename"
        done
        popd >&/dev/null || :
    done
}

for target in "${@:-.}"; do
    git_diff_commit "$target"
done

timestamp "Git Diff Commit completed"
