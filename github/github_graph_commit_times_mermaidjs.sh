#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-10-03 10:41:23 +0300 (Thu, 03 Oct 2024)
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
. "$srcdir/lib/github.sh"

image="github_commit_times.svg"
data="github_commit_times.dat"
code="github_commit_times.mmd"

# shellcheck disable=SC2034,SC2154
usage_description="
Graphs the GitHub commit times from all public GitHub repos for a given user

Fetches the commit data via the GitHub API and generates a bar chart using MermaidJS

Generates the MermaidJS code and then uses MermaidJS CLI to generate the image

    $code - Code

    $image - Image

A GNUplot version of this program is adjacent in:

    github_graph_commit_times_gnuplot.sh

A Golang version of this program can be found here:

    https://github.com/HariSekhon/GitHub-Graph-Commit-Times

Fetching GitHub commits via the API is slow so if \$CACHE_GITHUB_COMMITS is set will cache the data locally and not
re-fetch it on subsequent runs (useful for tweaking the graph and just re-running quickly)

Requires GitHub CLI and MermaidJS CLI to be installed and GH_TOKEN to be present
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<username>"

help_usage "$@"

min_args 1 "$@"

username="$1"

check_bin mmdc

trap_cmd "rm -f '$data'"

if ! [ -f "$data" ]; then
    timestamp "Fetching list of GitHub repos"
    repos="$(get_github_repos "$username")"
    timestamp "Found repos: $(wc -l <<< "$repos" | sed 's/[[:space:]]//g')"
    echo

    while read -r repo; do
        timestamp "Fetching commit times for repo: $repo"
        gh api -H "Accept: application/vnd.github.v3+json" "/repos/$username/$repo/commits" --paginate |
        jq -r '.[].commit.author.date[11:13]'
    done <<< "$repos" |
    sort |
    uniq -c |
    awk '{print $2" "$1}' > "$data"
    echo
fi

timestamp "Generating MermaidJS code for bar chart of commit times"
cat > "$code" <<EOF
xychart-beta
    title "Git Commits by Hour"
    x-axis [ $(awk '{print $1}' "$data" | tr '\n' ',' | sed 's/,/, /g; s/, $//') ]
    y-axis "Commits"
    bar    [ $(awk '{print $2}' "$data" | tr '\n' ',' | sed 's/,/, /g; s/, $//') ]
    %%line [ $(awk '{print $2}' "$data" | tr '\n' ',' | sed 's/,/, /g; s/, $//') ]
EOF
timestamp "Generated MermaidJS code"
echo

timestamp "Generating MermaidJS bar chart image: $image"
mmdc -i "$code" -o "$image" -t dark --quiet # -b transparent
timestamp "Generated MermaidJS image: $image"

if [ -n "${CACHE_GITHUB_COMMITS:-}" ]; then
    rm "$data"
fi
untrap

if is_CI; then
    exit 0
fi

timestamp "Opening generated bar chart"
"$srcdir/../bin/imageopen.sh" "$image"
