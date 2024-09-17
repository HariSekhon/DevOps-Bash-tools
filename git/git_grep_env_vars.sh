#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-06-13 11:15:06 +0100 (Mon, 13 Jun 2022)
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Git Grep's tokens that look like environment variables (UPPER_UPPER) out of the current code base underneath the given dir or \$PWD

Useful to find out environment variables supported in a code base when they're not well documented

Won't find short one-piece environment variables like DEBUG because otherwise we'd also return HTTPS and all sorts of other irrelevant tokens and noise.

Originally written to document ArgoCD's environment variables for better administration

    https://github.com/argoproj/argo-cd/pull/8680

Files or extensions to exclude can optionally be specified as args, and must be valid ERE regex that match the file path suffix, filenames and file extension literals will usually be fine


Examples:

You may want to exclude other files like Dockerfiles, Makefiles to just focus on environment variables supported in the actual code.
You can mix and match any of the following argument examples.

Exclude Dockerfiles and Makefiles:

    ${0##*/} Dockerfile Makefile


To exclude all Dockerfiles like Dockerfile and Dockerfile.dev, Dockerfile.prod etc. this ERE regex must be quoted to not expand in the shell before being passed to this script:

    ${0##*/} 'Dockerfile[[:alnum:].-]*'


To exclude all GitHub Actions workflows:

    ${0##*/} '.github/workflows/[[:alnum:].-]+'
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<dir> <files_or_extensions_to_ignore>]"

help_usage "$@"

#min_args 1 "$@"

dir="${1:-}"

if [ -n "$dir" ] && [ -d "$dir" ]; then
    shift || :
    cd "$dir"
fi

files_or_extensions_to_ignore=(
"$@"
md
asc
crt
key
http
css
go.sum
svg
tsx
LICENSE
)

# XXX: tune this if needed, currently the trade off is will find things like ARGOCD_<blah> but won't find something without an underscore like DEBUG=1
# looser, finds more, but also a lot more noise
#environment_variable_bre_regex='[[:upper:]_]\{4,\}[^[:alnum:]_]'
environment_variable_bre_regex='[[:upper:]]\{2,\}_[[:upper:]_]\{3,\}'

dockerfile_keywords="$(sed 's/#.*//; /^[[:space:]]*$/d' "$srcdir/lib/dockerfile_keywords.txt")"

# shellcheck disable=SC2207
file_content_prefixes_to_ignore=(
Makefile:.PHONY
    $(
        for keyword in $dockerfile_keywords; do
            echo "Dockerfile:$keyword"
        done
    )

)

# generate large single regex because too many -e switches don't work on grep on Mac (bug?)
files_or_extensions_regex="$(printf "%s|" "${files_or_extensions_to_ignore[@]}" | sed 's/|$//')"
file_content_prefixes_regex="$(printf "%s|" "${file_content_prefixes_to_ignore[@]}" | sed 's/|$//')"

# XXX: must disable git grep color or will break filter processing due to escape codes not matching exclusion filters
# want arg splitting
# shellcheck disable=SC2046
git grep -I --color=never "$environment_variable_bre_regex" |
# don't put quote inside the echo, it'll put literal quotes that will then fail to match to filter out
grep -Ev -e "(^|/|\\.)($files_or_extensions_regex):" -e "$file_content_prefixes_regex" |
sort -ui |
if is_piped; then
    grep "$environment_variable_bre_regex"
else
    # restore colour to make it easier to see the important bits of the lines
    grep "$environment_variable_bre_regex" --color=yes |
    less -RFX
fi
