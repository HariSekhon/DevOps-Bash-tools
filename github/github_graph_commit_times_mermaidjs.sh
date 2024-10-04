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

code="git_commit_times.mmd"
data="data/git_commit_times.dat"
image="images/git_commit_times.svg"

# shellcheck disable=SC2034,SC2154
usage_description="
Graphs the GitHub commit times from all public GitHub repos for a given user

Fetches the commit data via the GitHub API and generates a bar chart using MermaidJS

Generates the MermaidJS code and then uses MermaidJS CLI to generate the image

    $code - Code

    $data - Data

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

check_bin mmdc

username="$1"

for x in $code \
         $data \
         $image; do
    mkdir -p -v "$(dirname "$x")"
done

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

export -f parse_file_col_to_csv

timestamp "Generating MermaidJS code for Commits per Hour"
cat > "$code" <<EOF
xychart-beta
    title "Git Commits by Hour"
    x-axis [ $(parse_file_col_to_csv "$data" 1) ]
    y-axis "Number of Commits"
    bar    [ $(parse_file_col_to_csv "$data" 2) ]
    %%line [ $(parse_file_col_to_csv "$data" 2) ]
EOF
timestamp "Generated MermaidJS code: $code"
echo

timestamp "Generating MermaidJS bar chart for Commits per Hour"
mmdc -i "$code" -o "$image" -t dark --quiet # -b transparent
timestamp "Generated MermaidJS image: $image"

if is_CI; then
    exit 0
fi

timestamp "Opening: $image"
"$srcdir/../bin/imageopen.sh" "$image"
