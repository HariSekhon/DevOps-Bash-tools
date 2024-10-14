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

code="git_commit_times.mmd"
data="data/git_commit_times.dat"
image="images/git_commit_times.svg"

# shellcheck disable=SC2034,SC2154
usage_description="
Generates a MermaidJS graph of Git commit times from the current Git repo checkout's git log

Generates the MermaidJS code and then uses MermaidJS CLI to generate the image

    $code - Code

    $data - Data

    $image - Image

A GNUplot version of this script is adjacent at:

    git_graph_commit_times_gnuplot.sh

Requires Git and MermaidJS CLI (mmdc) to be installed to generate the graphs
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

check_bin mmdc

if ! is_in_git_repo; then
    die "ERROR: must be run from a git repo checkout as it relies on the 'git log' command"
fi

git_repo="$(git_repo)"

timestamp "Running inside checkout of Git repo: $git_repo"
timestamp "Fetching Hour of all commits from Git log"
git log --date=format:'%H' --pretty=format:'%ad' |
sort |
uniq -c |
awk '{print $2" "$1}' > "$data"
echo

export -f parse_file_col_to_csv

timestamp "Generating MermaidJS code for bar chart of commit times"
cat > "$code" <<EOF
xychart-beta
    title "$git_repo - Git Commits by Hour"
    x-axis [ $(parse_file_col_to_csv "$data" 1) ]
    y-axis "Number of Commits"
    bar    [ $(parse_file_col_to_csv "$data" 2) ]
    %%line [ $(parse_file_col_to_csv "$data" 2) ]
EOF
timestamp "Generated MermaidJS code"
echo

timestamp "Generating MermaidJS bar chart image: $image"
mmdc -i "$code" -o "$image" -t dark --quiet # -b transparent
timestamp "Generated MermaidJS image: $image"

if is_CI; then
    exit 0
fi

timestamp "Opening generated bar chart"
"$srcdir/../media/imageopen.sh" "$image"
