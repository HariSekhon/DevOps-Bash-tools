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
Generates graphs of Git commits per year and per month for the entire history of the local Git repo checkout

Requires Git and GNUplot to be installed to generate the graph
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<git_log_paths_to_check_only>]"

help_usage "$@"

image_file_per_year="git_commits_per_year.png"
image_file_per_month="git_commits_per_month.png"

# Check if we're inside a Git repository
if ! is_in_git_repo; then
    die "Error: Not inside a git repository!"
fi

# output git commits as simple YYYY-MM and then just sort and count them by month
timestamp "Calculating commit counts per month from the Git log"
month_counts="$(git log --date=format:'%Y-%m' --pretty=format:'%ad' "$@" | sort | uniq -c)"

timestamp "Calculating commit counts per year from the Git log"
year_counts="$(git log --date=format:'%Y' --pretty=format:'%ad' "$@" | sort | uniq -c)"
echo

timestamp "Preparing GNUplot data file per month"
gnuplot_data_file_per_month="${image_file_per_month%.png}.dat"
awk '{print $2, $1}' <<< "$month_counts" > "$gnuplot_data_file_per_month"

timestamp "Preparing GNUplot data file per year"
gnuplot_data_file_per_year="${image_file_per_year%.png}.dat"
awk '{print $2, $1}' <<< "$year_counts" > "$gnuplot_data_file_per_year"
echo

gnuplot_common_settings='
set terminal pngcairo size 1280,720 enhanced font "Arial,14"
set ylabel "Number of Commits"
set grid
set xtics rotate by -45
set boxwidth 0.5 relative
set style fill solid
set datafile separator " "
'
#set xtics auto  # cannot find a way to make this show every year

timestamp "Generating GNUplot bar chart per month"
gnuplot <<EOF
$gnuplot_common_settings
set title "Git Commits per Month"
set xlabel "Year-Month"
set format x "%b %Y"
set xdata time
set timefmt "%Y-%m"
set output "$image_file_per_month"
plot "$gnuplot_data_file_per_month" using 1:2 with boxes title 'Commits'
EOF

timestamp "Generated bar chart image: $image_file_per_month"
echo

timestamp "Generating GNUplot bar chart per year"
gnuplot <<EOF
$gnuplot_common_settings
set title "Git Commits per Year"
set xlabel "Year"
# results in X axis labels every 2 years
#set xdata time
#set timefmt "%Y"
#set format x "%Y"
# trick to get X axis labels for every year
stats "$gnuplot_data_file_per_year" using 1 nooutput
set xrange [STATS_min:STATS_max]
set xtics 1
set output "$image_file_per_year"
plot "$gnuplot_data_file_per_year" using 1:2 with boxes title 'Commits'
EOF

timestamp "Generated bar chart image: $image_file_per_year"
echo

rm "$gnuplot_data_file_per_month"
rm "$gnuplot_data_file_per_year"

if is_CI; then
    exit 0
fi

timestamp "Opening generated bar chart image file containing Git commits per month"
"$srcdir/../bin/imageopen.sh" "$image_file_per_month"

timestamp "Opening generated bar chart image file containing Git commits per year"
"$srcdir/../bin/imageopen.sh" "$image_file_per_year"
