#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-02-24 17:31:03 +0700 (Mon, 24 Feb 2025)
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
For a given list of domains, deduplicate and print dev / staging subdomains as well as root domain for prod

Set environment variable SUBDOMAIN to alter the subdomain prefix:

    export SUBDOMAIN='ads'

Set environment variable ENVIRONMENTS to alter the subdomain suffixes:

    export ENVIRONMENTS='dev staging'

Output:

    ads-dev.<domain>     ads-staging.<domain>     ads.<domain>
    ads-dev.<domain2>    ads-staging.<domain2>    ads.<domain2>
    ads-dev.<domain3>    ads-staging.<domain3>    ads.<domain3>
    ads-dev.<domain4>    ads-staging.<domain4>    ads.<domain4>

Used to generate a whole bunch of Ad Tech domains and pixel tracker subdomains for a project
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<domains_or_files_containing_domains>"

help_usage "$@"

min_args 1 "$@"

subdomain="${SUBDOMAIN:-ads}"

environments="${ENVIRONMENTS:-
dev
staging
}"

if [ $# -eq 0 ]; then
    timestamp "Reading from stdin"
    cat
else
    for arg; do
        if [ -f "$arg" ]; then
            timestamp "Reading from file: $arg"
            cat "$arg"
        else
            echo "$arg"
        fi
    done
fi |
sort -u |
while read -r domain; do
    if ! [[ "$domain" =~ ^$domain_regex$ ]]; then
        die "Failed domain regex validation: $domain"
    fi
    for environment in $environments; do
        echo -n "$subdomain-$environment.$domain "
    done
    echo "$subdomain.$domain"
done |
column -t
