#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-09-18 23:21:50 +0100 (Wed, 18 Sep 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Checks if .bashrc and .bash_profile are sourced, otherwise injects source lines in to the $HOME directory equivalents

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash_tools="$srcdir/.."

conf_files="$(sed 's/#.*//; /^[[:space:]]*$/d' "$bash_tools/setup/files.txt")"

# unreliable that HOME is set, ensure shell evaluates to the right thing before we use it
#[ -n "${HOME:-}" ] || HOME=~
HOME="${HOME:-$(cd && pwd)}"

setup_file(){
    local filename="$1"
    if grep -Eq "^[[:space:]]*(source|\\.)[[:space:]]+$bash_tools/$filename" "$HOME/$filename" 2>/dev/null; then
        echo "$filename already sourced in $HOME/$filename"
    else
        echo "injecting into ~/$filename: source $bash_tools/$filename"
        echo "source $bash_tools/$filename" >> "$HOME/$filename"
    fi
}

setup_file .bashrc
setup_file .bash_profile
setup_file .bash_logout

setup_file .zshrc
setup_file .zprofile
setup_file .zshenv
setup_file .zlogin
setup_file .zlogout

echo
echo "Symlinking dot files to \$HOME directory: $HOME"
echo

opts=""
if [ -n "${FORCE:-}" ]; then
    opts="-f"
fi

fix_link(){
    local path="$1"
    local target="$2"

    if [ -L "$path" ]; then
        local current
        current="$(readlink "$path")"

        if [ ! -e "$path" ] || [ "$current" != "$target" ]; then
            echo "WARNING: Removing stale symlink: $path"
            rm -f -- "$path"
        fi
    fi
}

#find_file(){
#    local filename="$1"
#    if [ -e "$filename" ]; then
#        echo "$filename"
#    else
#        root_filename="$bash_tools/$filename"
#        if [ -e "$root_filename" ]; then
#            echo "$root_filename"
#        else
#            echo "ERROR: cannot find source for $filename" >&2
#            exit 1
#        fi
#    fi
#}

symlink(){
    local path="$1"
    if [[ "$path" =~ / ]]; then
        filename="${path##*/}"
        srcdir="${path%/*}"
        destdir="${srcdir#configs}"
        destdir="${destdir##/}"
        destdir="${destdir%%/}"
        sourcepath="$bash_tools${srcdir+/$srcdir}/$filename"  # if dirname, insert /dirname in middle
        destpath="$HOME${destdir+/"$destdir"/}"               # if dirname, append /dirname to dest
        # remove double slashes to clean the path
        sourcepath="${sourcepath/\/\//\/}"
        destpath="${destpath/\/\//\/}"
        mkdir -pv "$destpath"
        fix_link "$destpath/$filename" "$sourcepath"
        # want opt expansion
        # shellcheck disable=SC2086
        ln -sv $opts -- "$sourcepath" "$destpath" || :
    else
        fix_link "$HOME/$filename" "$PWD/$filename"
        # want opt expansion
        # shellcheck disable=SC2086
        ln -sv $opts -- "$PWD/$filename" "$HOME/" || return
        # if we link .vimrc then run the vundle install and get plugins to prevent vim errors every startup
        if [ "$filename" = .vimrc ]; then
            "$srcdir/../install/install_vundle.sh" || :
        fi
    fi
}

for filename in $conf_files; do
    symlink "$filename"
done

fix_link "$HOME/.gitignore_global" "$HOME/.gitignore"
# want opt expansion
# shellcheck disable=SC2086
ln -sv $opts -- "$HOME/.gitignore" "$HOME/.gitignore_global" || :

# drop my personal Git username and email local file in this repo into home dir
if [[ "${USER:-}" =~ ^hari$|harisekhon|hsekhon ]]; then
    fix_link "$HOME/.gitconfig.local" "$PWD/.gitconfig.local"
    ln -sv -- "$PWD/.gitconfig.local" "$HOME/" || :
fi
