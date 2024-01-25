#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-02-13 15:36:35 +0000 (Thu, 13 Feb 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
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

cd "$srcdir"

filelist="
setup/bootstrap.sh
setup/ci_bootstrap.sh
setup/ci_git_set_dir_safe.sh
"

if [ -n "$*" ]; then
    echo "$@"
else
    sed 's/#.*//; s/:/ /' "$srcdir/../setup/repos.txt"
fi |
grep -v -e bash-tools -e '^[[:space:]]*$' |
while read -r repo dir; do
    if [ -z "$dir" ]; then
        dir="$(tr '[:upper:]' '[:lower:]' <<< "$repo")"
    fi
    # filtered above
    #if ls -lLdi "$dir" "$srcdir" | awk '{print $1}' | uniq -d | grep -q .; then
    #    echo "skipping $dir as it's our directory"
    #    continue
    #fi
    if ! [ -d "../$dir" ]; then
        echo "WARNING: repo dir $dir not found, skipping..."
        continue
    fi
    for filename in $filelist; do
        target="../$dir/$filename"
        mkdir -pv "${target%/*}"
        echo "syncing $filename -> $target"
        perl -pe "
            s/directory=\"(devops-)*bash-tools/directory=\"$dir/;
            s/(devops-)*bash-tools/$repo/i;
            s/make install/make/;" \
            "$filename" > "$target"
        if [ "$repo" = "nagios-plugins" ]; then
            perl -pi -e 's/^(\s*make)$/$1 build zookeeper/' "$target"
        fi
    done
done
