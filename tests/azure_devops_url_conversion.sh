#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-12-04 23:05:31 +0000 (Fri, 04 Dec 2020)
#
#  https://devops.azure.com/HariSekhon/bash-tools
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

# shellcheck disable=SC1090
. "$srcdir/../lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Tests the git_to_azure_url function from lib/git.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

src[0]='git@devops.azure.com:/HariSekhon/pylib'
dest[0]='git@devops.azure.com:v3/harisekhon/GitHub/pylib'

src[1]='git@devops.azure.com:/harisekhon/nagios-plugin-kafka'
dest[1]='git@devops.azure.com:v3/harisekhon/GitHub/nagios-plugin-kafka'

src[2]='git@devops.azure.com:HariSekhon/DevOps-Bash-tools'
dest[2]='git@devops.azure.com:v3/harisekhon/GitHub/DevOps-Bash-tools'

src[3]='git@devops.azure.com:HariSekhon/DevOps-Golang-tools'
dest[3]='git@devops.azure.com:v3/harisekhon/GitHub/DevOps-Golang-tools'

src[4]='git@devops.azure.com:HariSekhon/Dockerfiles.git'
dest[4]='git@devops.azure.com:v3/harisekhon/GitHub/Dockerfiles'

src[5]='git@devops.azure.com:HariSekhon/HAProxy-configs'
dest[5]='git@devops.azure.com:v3/harisekhon/GitHub/HAProxy-configs'

src[6]='git@devops.azure.com:HariSekhon/Nagios-Plugins'
dest[6]='git@devops.azure.com:v3/harisekhon/GitHub/Nagios-Plugins'

src[7]='git@devops.azure.com:HariSekhon/SQL-scripts'
dest[7]='git@devops.azure.com:v3/harisekhon/GitHub/SQL-scripts'

src[8]='git@devops.azure.com:HariSekhon/Spotify-Playlists.git'
dest[8]='git@devops.azure.com:v3/harisekhon/GitHub/Spotify-Playlists'

src[9]='git@devops.azure.com:HariSekhon/Templates'
dest[9]='git@devops.azure.com:v3/harisekhon/GitHub/Templates'

src[10]='git@devops.azure.com:harisekhon/kubernetes-templates'
dest[10]='git@devops.azure.com:v3/harisekhon/GitHub/kubernetes-templates'

src[11]='git@devops.azure.com:harisekhon/spotify-tools.git'
dest[11]='git@devops.azure.com:v3/harisekhon/GitHub/spotify-tools'

src[12]='git@devops.azure.com:harisekhon/sql-keywords'
dest[12]='git@devops.azure.com:v3/harisekhon/GitHub/sql-keywords'

src[13]='git@devops.azure.com:/HariSekhon/Nagios-Plugin-Kafka'
dest[13]='git@devops.azure.com:v3/harisekhon/GitHub/Nagios-Plugin-Kafka'

src[14]='git@devops.azure.com:/HariSekhon/pylib'
dest[14]='git@devops.azure.com:v3/harisekhon/GitHub/pylib'

src[15]='git@devops.azure.com:HariSekhon/DevOps-Bash-tools'
dest[15]='git@devops.azure.com:v3/harisekhon/GitHub/DevOps-Bash-tools'

src[16]='git@devops.azure.com:HariSekhon/DevOps-Golang-tools'
dest[16]='git@devops.azure.com:v3/harisekhon/GitHub/DevOps-Golang-tools'

src[17]='git@devops.azure.com:HariSekhon/Dockerfiles.git'
dest[17]='git@devops.azure.com:v3/harisekhon/GitHub/Dockerfiles'

src[18]='git@devops.azure.com:HariSekhon/HAProxy-configs'
dest[18]='git@devops.azure.com:v3/harisekhon/GitHub/HAProxy-configs'

src[19]='git@devops.azure.com:HariSekhon/Nagios-Plugins'
dest[19]='git@devops.azure.com:v3/harisekhon/GitHub/Nagios-Plugins'

src[20]='git@devops.azure.com:HariSekhon/SQL-scripts'
dest[20]='git@devops.azure.com:v3/harisekhon/GitHub/SQL-scripts'

src[21]='git@devops.azure.com:HariSekhon/Spotify-Playlists.git'
dest[21]='git@devops.azure.com:v3/harisekhon/GitHub/Spotify-Playlists'

src[22]='git@devops.azure.com:HariSekhon/Spotify-tools.git'
dest[22]='git@devops.azure.com:v3/harisekhon/GitHub/Spotify-tools'

src[23]='git@devops.azure.com:HariSekhon/Templates'
dest[23]='git@devops.azure.com:v3/harisekhon/GitHub/Templates'

src[24]='git@devops.azure.com:harisekhon/kubernetes-templates'
dest[24]='git@devops.azure.com:v3/harisekhon/GitHub/kubernetes-templates'

src[25]='git@devops.azure.com:harisekhon/sql-keywords'
dest[25]='git@devops.azure.com:v3/harisekhon/GitHub/sql-keywords'

src[26]='git@devops.azure.com:HariSekhon/Spotify-Playlists.git'
dest[26]='git@devops.azure.com:v3/harisekhon/GitHub/Spotify-Playlists'

src[27]='ssh://git@devops.azure.com/HariSekhon/DevOps-Perl-tools'
dest[27]='ssh://git@devops.azure.com/v3/harisekhon/GitHub/DevOps-Perl-tools'

src[28]='ssh://git@devops.azure.com/HariSekhon/lib-java'
dest[28]='ssh://git@devops.azure.com/v3/harisekhon/GitHub/lib-java'

src[29]='ssh://git@devops.azure.com/harisekhon/lib'
dest[29]='ssh://git@devops.azure.com/v3/harisekhon/GitHub/lib'

src[30]='ssh://git@devops.azure.com:/HariSekhon/DevOps-Python-tools'
dest[30]='ssh://git@devops.azure.com:/v3/harisekhon/GitHub/DevOps-Python-tools'

src[31]='ssh://git@devops.azure.com/HariSekhon/lib-java'
dest[31]='ssh://git@devops.azure.com/v3/harisekhon/GitHub/lib-java'

src[32]='ssh://git@devops.azure.com:/HariSekhon/DevOps-Python-tools'
dest[32]='ssh://git@devops.azure.com:/v3/harisekhon/GitHub/DevOps-Python-tools'

src[33]='ssh://git@ssh.devops.azure.com/HariSekhon/DevOps-Perl-tools'
dest[33]='ssh://git@ssh.devops.azure.com/v3/harisekhon/GitHub/DevOps-Perl-tools'

src[34]='ssh://git@ssh.devops.azure.com/HariSekhon/lib'
dest[34]='ssh://git@ssh.devops.azure.com/v3/harisekhon/GitHub/lib'

# expands to the list of indicies in the array, starting at zero - this is easier to work with that ${#src} which is a total
# that is off by one for index usage and doesn't support sparse arrays for any  missing/disabled test indicies
test_numbers="${!src[*]}"

for i in $test_numbers; do
    [ -n "${src[$i]:-}" ]  || { echo "code error: src[$i] not defined";  exit 1; }
    [ -n "${dest[$i]:-}" ] || { echo "code error: dest[$i] not defined"; exit 1; }
    echo "git_to_azure_url ${src[$i]}"
    converted_repo_url="$(git_to_azure_url "${src[$i]}")"
    if [ "$converted_repo_url" != "${dest[$i]}" ]; then
        echo "ERROR: unit test failed"
        echo
        echo "Expected: ${dest[$i]}"
        echo "Got:      $converted_repo_url"
        exit 2
    fi
    #echo "checking URL result '$converted_repo_url' is valid"
    #if ! git ls-remote "$converted_repo_url"; then
    #    echo "ERROR: unit test failed - URL failed git ls-remote test"
    #    exit 3
    #fi
    echo
done

echo
echo "SUCCESS: git_to_azure_url URL conversion tests passed"
