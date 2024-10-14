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

repolist="$(readlink -f "$srcdir/../setup/repos.txt")"

code="git_commit_times_all_repos.mmd"
data="data/git_commit_times_all_repos.dat"
image="images/git_commit_times_all_repos.svg"

# shellcheck disable=SC2034,SC2154
usage_description="
Generates a MermaidJS graph of Git commit times from all adjacent Git repos listed in:

    $repolist

Generates the MermaidJS code and then uses MermaidJS CLI to generate the image

    $code - Code

    $data - Data

    $image - Image

A GNUplot version of this script is adjacent at:

    git_graph_commit_times_gnuplot_all_repos.sh

These adjacent scripts perform a similar function but using GitHub API commit data:

    ../github/github_graph_commit_times_gnuplot.sh

    ../github/github_graph_commit_times_mermaidjs.sh

A Golang version of this program which uses the GitHub API can be found here:

    https://github.com/HariSekhon/GitHub-Graph-Commit-Times

Requires Git and MermaidJS CLI (mmdc) to be installed to generate the graphs
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

check_bin mmdc

for x in $code \
         $data \
         $image; do
    mkdir -p -v "$(dirname "$x")"
done

older_than(){
    local file="$1"
    local days="$2"
    if ! [ -f "$file" ]; then
        return 0
    fi
    if find "$file" -mtime +"$days" -print -quit | grep -q . ; then
        return 0
    fi
    return 1
}

if ! older_than "$data" 7; then
    timestamp "Using cached data since it is less than 7 days old: $data"
else
    timestamp "Getting list of Git repo checkout directories from: $repolist"
    repo_dirs="$(sed 's/#.*//; s/.*://; /^[[:space:]]*$/d' "$repolist")"

    timestamp "Found repos: $(wc -l <<< "$repo_dirs" | sed 's/[[:space:]]//g')"
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
    awk '{print $2" "$1}' > "$data"
fi
echo

export -f parse_file_col_to_csv

timestamp "Generating MermaidJS code for bar chart of commit times"
cat > "$code" <<EOF
xychart-beta
    title "Git Commits by Hour"
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
