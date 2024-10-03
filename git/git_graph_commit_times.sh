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
. "$srcdir/lib/git.sh"

repolist="$(readlink -f "$srcdir/../setup/repos.txt")"

# shellcheck disable=SC2034,SC2154
usage_description="
Graphs the Git commit times from all adjacent Git repos listed in:

    $repolist

The adjacent script ../github/github_graph_commit_times.sh does a similar function but using GitHub API commit data

A Golang version of this program which uses the GitHub API can be found here:

    https://github.com/HariSekhon/GitHub-Graph-Commit-Times

Requires GNUplot to be installed to generate the graph
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

image="git_commit_times.png"
gnuplot_data="git_commit_times.dat"

trap_cmd "rm -f '$gnuplot_data'"

if ! [ -f "$gnuplot_data" ]; then
    timestamp "Fetting list of Git repo checkout directories from: $repolist"
    repo_dirs="$(sed 's/#.*//; s/.*://; /^[[:space:]]*$/d' "$repolist")"

    timestamp "Found repos: $(wc -l <<< "$repo_dirs" | sed 's/[[:space:]]/g')"
    echo

    while read -r repo_dir; do
        repo_dir="$(readlink -f "$srcdir/../../$repo_dir")"
        timestamp "Entering repo dir: $repo_dir"
        pushd "$repo_dir" &>/dev/null || die "Failed to pushd to: $repo_dir"
        timestamp "Fetching Hour of all commits from Git log"
        git log --date=format:'%H' --pretty=format:'%ad'
        popd &>/dev/null || die "Failed to popd from: $repo_dir"
        echo
    done <<< "$repo_dirs" |
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

rm "$gnuplot_data"
untrap

if is_CI; then
    exit 0
fi

timestamp "Opening generated bar chart"
"$srcdir/../bin/imageopen.sh" "$image"
