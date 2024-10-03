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

# shellcheck disable=SC2034,SC2154
usage_description="
Graphs the GitHub commit times from all public GitHub repos for a given user

Fetches the commit data via the GitHub API and generates a bar chart using GNUplot

A Golang version of this program can be found here:

    https://github.com/HariSekhon/GitHub-Graph-Commit-Times

Fetching GitHub commits via the API is slow so if \$CACHE_GITHUB_COMMITS is set will cache the data locally and not
re-fetch it on subsequent runs (useful for tweaking the graph and just re-running quickly)

Requires GitHub CLI and GNUplot to be installed and GH_TOKEN to be present
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<username>"

help_usage "$@"

min_args 1 "$@"

username="$1"

image="github_commit_times.png"
gnuplot_data="github_commit_times.dat"

trap_cmd "rm -f '$gnuplot_data'"

if ! [ -f "$gnuplot_data" ]; then
    timestamp "Fetching list of GitHub repos"
    repos="$(get_github_repos "$username")"
    timestamp "Found repos: $(wc -l <<< "$repos" | sed 's/[[:space:]]/g')"
    echo

    while read -r repo; do
        timestamp "Fetching commit times for repo: $repo"
        gh api -H "Accept: application/vnd.github.v3+json" "/repos/$username/$repo/commits" --paginate |
        jq -r '.[].commit.author.date[11:13]'
    done <<< "$repos" |
    sort |
    uniq -c |
    awk '{print $2" "$1}' > "$gnuplot_data"
    echo
fi

timestamp "Generating GNUplot bar chart of times"
gnuplot <<EOF
set terminal pngcairo size 1280,720 enhanced font "Arial,14"
set ylabel "Number of Commits"
set grid
set xtics rotate by -45
set boxwidth 0.8 relative
set style fill solid
set datafile separator " "
set title "Git Commits by Hour"
set xlabel "Hour of Day"
# results in X axis labels every 2 years
#set xdata time
#set timefmt "%H"
#set format x "%H"
# trick to get X axis labels for every year
stats "$gnuplot_data" using 1 nooutput
set xrange [STATS_min:STATS_max]
set xtics 1
set output "$image"
plot "$gnuplot_data" using 1:2 with boxes title 'Commits'
EOF

timestamp "Generated bar chart image: $image"
echo

if [ -n "${CACHE_GITHUB_COMMITS:-}" ]; then
    rm "$gnuplot_data"
fi
untrap

if is_CI; then
    exit 0
fi

timestamp "Opening generated bar chart"
"$srcdir/../bin/imageopen.sh" "$image"
