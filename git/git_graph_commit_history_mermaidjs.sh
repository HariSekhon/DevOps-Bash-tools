#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-10-04 03:03:56 +0300 (Fri, 04 Oct 2024)
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

code_month="git_commits_per_month.mmd"
code_year="git_commits_per_year.mmd"

data_month="data/git_commits_per_month.dat"
data_year="data/git_commits_per_year.dat"

image_month="images/git_commits_per_month.svg"
image_year="images/git_commits_per_year.svg"

# shellcheck disable=SC2034,SC2154
usage_description="
Generates MermaidJS graphs of Git commits per year and per month for the entire history of the local Git repo checkout

Generates the MermaidJS code and then uses MermaidJS CLI to generate the images

    $code_month - Code
    $code_year  - Code

    $data_month - Data
    $data_year  - Data

    $image_month - Image
    $image_year  - Image

A GNUplot version of this script is adjacent at:

    git_graph_commit_history_gnuplot.sh

Requires Git and MermaidJS CLI (mmdc) to be installed to generate the graphs
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<git_log_paths_to_check_only>]"

help_usage "$@"

check_bin mmdc

if ! is_in_git_repo; then
    die "Error: Not inside a git repository!"
fi

for x in $code_month  \
         $code_year   \
         $data_month  \
         $data_year   \
         $image_month \
         $image_year; do
    mkdir -p -v "$(dirname "$x")"
done

# output git commits as simple YYYY-MM and then just sort and count them by month
timestamp "Calculating commit counts per month from the Git log"
git log --date=format:'%Y-%m' --pretty=format:'%ad' "$@" |
sort |
uniq -c |
awk '{print $2" "$1}' > "$data_month"
timestamp "Wrote data: $data_month"
echo

timestamp "Calculating commit counts per year from the Git log"
git log --date=format:'%Y' --pretty=format:'%ad' "$@" |
sort |
uniq -c |
awk '{print $2" "$1}' > "$data_year"
timestamp "Wrote data: $data_year"
echo

export -f parse_file_col_to_csv

timestamp "Generating MermaidJS code for Commits per Month"
cat > "$code_month" <<EOF
xychart-beta
    title "Git Commits per Month"
    x-axis [ $(parse_file_col_to_csv "$data_month" 1) ]
    y-axis "Number of Commits"
    bar    [ $(parse_file_col_to_csv "$data_month" 2) ]
    %%line [ $(parse_file_col_to_csv "$data_month" 2) ]
EOF
timestamp "Generated MermaidJS code: $code_month"
echo

timestamp "Generating MermaidJS code for Commits per Year"
cat > "$code_year" <<EOF
xychart-beta
    title "Git Commits per Year"
    x-axis [ $(parse_file_col_to_csv "$data_year" 1) ]
    y-axis "Number of Commits"
    bar    [ $(parse_file_col_to_csv "$data_year" 2) ]
    %%line [ $(parse_file_col_to_csv "$data_year" 2) ]
EOF
timestamp "Generated MermaidJS code: $code_year"
echo

timestamp "Generating bar chart for Commits per Month"
mmdc -i "$code_month" -o "$image_month" -t dark --quiet # -b transparent
timestamp "Generated bar chart image: $image_month"
echo

timestamp "Generating bar chart for Commits per Year"
mmdc -i "$code_year" -o "$image_year" -t dark --quiet # -b transparent
timestamp "Generated bar chart image: $image_year"
echo

if is_CI; then
    exit 0
fi

timestamp "Opening: $image_month"
"$srcdir/../media/imageopen.sh" "$image_month"

timestamp "Opening: $image_month"
"$srcdir/../media/imageopen.sh" "$image_year"
