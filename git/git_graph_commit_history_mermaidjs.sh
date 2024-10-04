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

image_file_per_month="git_commits_per_month.svg"
image_file_per_year="git_commits_per_year.svg"

mermaid_code_per_month="git_commits_per_month.mmd"
mermaid_code_per_year="git_commits_per_year.mmd"

# shellcheck disable=SC2034,SC2154
usage_description="
Generates MermaidJS graphs of Git commits per year and per month for the entire history of the local Git repo checkout

Generates the MermaidJS code and then uses MermaidJS CLI to generate the images

    $mermaid_code_per_month - Code
    $mermaid_code_per_year  - Code

    $image_file_per_month - Image
    $image_file_per_year  - Image

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

# output git commits as simple YYYY-MM and then just sort and count them by month
timestamp "Calculating commit counts per month from the Git log"
month_counts="$(git log --date=format:'%Y-%m' --pretty=format:'%ad' "$@" | sort | uniq -c | awk '{print $2" "$1}')"

timestamp "Calculating commit counts per year from the Git log"
year_counts="$(git log --date=format:'%Y' --pretty=format:'%ad' "$@" | sort | uniq -c | awk '{print $2" "$1}')"
echo

timestamp "Generating MermaidJS code for bar chart per month"
cat > "$mermaid_code_per_month" <<EOF
xychart-beta
    title "Number of Commits"
    x-axis [ $(awk '{print $1}' <<< "$month_counts" | tr '\n' ',' | sed 's/,/, /g; s/, $//') ]
    y-axis "Commits"
    bar    [ $(awk '{print $2}' <<< "$month_counts" | tr '\n' ',' | sed 's/,/, /g; s/, $//') ]
    %%line [ $(awk '{print $2}' <<< "$month_counts" | tr '\n' ',' | sed 's/,/, /g; s/, $//') ]
EOF
timestamp "Generated MermaidJS code for bar chart per month"
echo

timestamp "Generating MermaidJS code for bar chart per year"
cat > "$mermaid_code_per_year" <<EOF
xychart-beta
    title "Number of Commits"
    x-axis [ $(awk '{print $1}' <<< "$year_counts" | tr '\n' ',' | sed 's/,/, /g; s/, $//') ]
    y-axis "Commits"
    bar    [ $(awk '{print $2}' <<< "$year_counts" | tr '\n' ',' | sed 's/,/, /g; s/, $//') ]
    %%line [ $(awk '{print $2}' <<< "$year_counts" | tr '\n' ',' | sed 's/,/, /g; s/, $//') ]
EOF
timestamp "Generated MermaidJS code for bar chart per year"
echo

timestamp "Generating MermaidJS bar chart image: $image_file_per_month"
mmdc -i "$mermaid_code_per_month" -o "$image_file_per_month" -t dark --quiet # -b transparent
timestamp "Generated MermaidJS bar chart image: $image_file_per_month"

timestamp "Generating MermaidJS bar chart image: $image_file_per_year"
mmdc -i "$mermaid_code_per_year" -o "$image_file_per_year" -t dark --quiet # -b transparent
timestamp "Generated MermaidJS bar chart image: $image_file_per_year"

if is_CI; then
    exit 0
fi

timestamp "Opening: $image_file_per_month"
"$srcdir/../bin/imageopen.sh" "$image_file_per_month"

timestamp "Opening: $image_file_per_month"
"$srcdir/../bin/imageopen.sh" "$image_file_per_year"
