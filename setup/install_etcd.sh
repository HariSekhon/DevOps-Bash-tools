#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2023-05-26 01:32:46 +0100 (Fri, 26 May 2023)
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

# shellcheck disable=SC1090,SC1091
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Installs Etcd
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

export PATH="$PATH:$HOME/bin"

help_usage "$@"

#version="${1:-v3.5.9}"
version="${1:-latest}"

owner_repo="etcd-io/etcd"

os="$(get_os)"
arch="$(get_arch)"
ext="tar.gz"
if [ "$os" = "darwin" ]; then
    ext="zip"
fi

if [ "$version" = latest ]; then
    timestamp "determining latest version of '$owner_repo' via GitHub API"
    version="$("$srcdir/../github/github_repo_latest_release.sh" "$owner_repo")"
    timestamp "latest version is '$version'"
else
    is_semver "$version" || die "non-semver version argument given: '$version' - should be in format: N.N.N"
fi

url="https://github.com/$owner_repo/releases/download/$version/etcd-$version-$os-$arch.$ext"

package="/tmp/etcd.$$.$ext"

curl -sSLf "$url"  -o "$package"

if [ "$ext" = "tar.gz" ]; then
    sudo tar -zxv --strip-components=1 -C /usr/local/bin/
else
    tmpdir="/tmp/etcd.$$"
    mkdir -p -v "$tmpdir"
    echo
    unzip -o -d "$tmpdir" "$package"
    unalias rm 2>/dev/null || :
    rm -fv "$package"
    echo
    unalias mv 2>/dev/null || :
    sudo mv -fv "$tmpdir/etcd-$version-$os-$arch/"{etcd,etcdctl,etcdutl} /usr/local/bin/
    rm -fr "$tmpdir"
fi

echo
/usr/local/bin/etcd --version
echo
/usr/local/bin/etcdctl version
echo
/usr/local/bin/etcdutl version
