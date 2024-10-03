#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-10-03 04:55:02 +0300 (Thu, 03 Oct 2024)
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

# shellcheck disable=SC2034,SC2154
usage_description="
Generates a graph of Git commits per month for the entire history of the local Git repo checkout using the git log

Requires Git and GNUPlot to be installed to generate the graph
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<filename.png> <git_log_paths_to_check_only>]"

help_usage "$@"

image_file="${1:-git_commits_per_month.png}"
shift || :
# shif to leave remaining args as git log paths

if ! [[ "$image_file" =~ \.png$ ]]; then
	die "Error: Image filename must end in .png, given instead: $image_file"
fi

# Check if we're inside a Git repository
if ! is_in_git_repo; then
    die "Error: Not inside a git repository!"
fi

timestamp "Calculating commit counts per month from the Git log"
# output git commits as simple YYYY-MM-01 and then just sort and count them by month
# added the -01 day suffix to make GNUplot human readable date conversion possible
month_counts="$(git log --date=format:'%Y-%m-01' --pretty=format:'%ad' "$@" | sort | uniq -c)"

timestamp "Preparing GNUplot data file"
gnuplot_data_file="${image_file%.png}.dat"
awk '{print $2, $1}' <<< "$month_counts" > "$gnuplot_data_file"

timestamp "Generating GNUplot bar chart"
gnuplot <<EOF
set terminal pngcairo size 1280,720 enhanced font 'Arial,14'
set output "$image_file"
set title "Git Commits per Month"
set xlabel "Year-Month"
set ylabel "Number of Commits"
set grid
set xtics rotate by -45
set boxwidth 0.5 relative
set style fill solid
set datafile separator " "
set xdata time
set timefmt "%Y-%m-%d"
set format x "%b %Y"
plot "$gnuplot_data_file" using 1:2 with boxes title 'Commits'
EOF

rm "$gnuplot_data_file"

timestamp "Generated bar chart image file: $image_file"

if is_mac; then
	timestamp "Opening generated image"
	open "$image_file"
fi
