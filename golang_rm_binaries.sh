#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-05-15 17:27:41 +0100 (Fri, 15 May 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Finds binaries adjacent to Golang .go source files in given directories and removes them
#
# Doesn't remove $GOPATH/bin stuff, only adjacent .go compiles
# because $GOPATH/bin stuff is often 'go get' downloaded programs that we want to keep

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
#srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
#. "$srcdir/lib/utils.sh"

basedir="${1:-$PWD}"

echo
echo "Removing Golang binaries adjacent to .go files under $basedir:"
echo

#directories="$(
#    find "$basedir" -type f -name '*.go' |
#    sed 's/[^/].*.go$//' |
#    sort -u
#)"

#while read -r directory; do
#done <<< "$directories"

rm_if_binary(){
    set +o pipefail
    file --mime "$1" |
    # can't use -l because it gives (standard input) instead of filename,
    # must get the filename from the file --mime output instead
    grep 'charset=binary' |
    grep -v '[[:space:]]inode/directory;[[:space:]]' |
    sed 's/:.*//' |
    xargs rm -fv
}

# Finds and removes 'foo' binary for 'foo.go' adjacent compiled programs
find "$basedir" -type f -name '*.go' |
grep -Eve '/src/github\.com/' -e '/src/golang\.org/' |
while read -r filename; do
    filename="${filename%.go}"
    rm_if_binary "$filename"
done

check_src_dir(){
    for x in "$1"/*; do
        if ! [ -d "$x" ]; then
            continue
        fi
        binfile="$x/${x##*/}"
        if [ -f "$binfile" ]; then
            rm_if_binary "$binfile"
        fi
    done
}

find "$basedir" -type d -name 'src' |
while read -r src_dir; do
    check_src_dir "$src_dir"
done

if [ "src" = "$(basename "$(cd "$basedir" && pwd)")" ]; then
    check_src_dir "$basedir"
fi
