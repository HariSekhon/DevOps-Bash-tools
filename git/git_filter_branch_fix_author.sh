#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-12-04 17:46:52 +0000 (Fri, 04 Dec 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Rewrites the current Git branch using git filter-branch to change the Author/Committer name and/or email address

For each commit in the current branch history, if both:

    - the Author or Committer Name matches the <old_name>
    - the Author or Committer Email matches the <old_email>

then both the Author and Committer names and emails are set to <new_name> and <new_email>

<git_options> - passed literally to git filter-branch after -- can use this to only rewrite a revision range, eg. <starting_hashref>..<ending_hashref>

Must be called from the top level directory of the repository

You may still see the old name/email in the local repo's git log, test by cloning to a new repo and if happy then park the old checkout and checkout clean


DANGER: this rewrites Git history.
        Do not use this carelessly as it rewrites Git history.
        Always have a backup.
        Do not do this on pushed branches unless you are an Expert and intend to

If there is already a git filter-branch rewrite backup in .git/refs/original, git filter-branch will refuse to proceed - specify \$FORCE_GIT_REWRITE=1 in the environment to force the rewrite
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<old_email> <new_email> [<new_name>] [<git_options>]"

help_usage "$@"

min_args 2 "$@"

old_email="$1"
new_email="$2"
new_name="${3:-}"
shift || :
shift || :
if [ -n "$new_name" ]; then
    shift || :
fi

opts=()
if [ -n "${FORCE_GIT_REWRITE:-}" ]; then
    opts+=(-f)
fi

for x in "$old_email" "$new_email"; do
    # email_regex is defined in lib/utils.sh
    # shellcheck disable=SC2154
    # <Hari Sekhon@TeamCity> doesn't match - technically this may not match real emails so be a bit more lax
    #if ! [[ "$x" =~ $email_regex ]]; then
    if ! [[ "$x" =~ @ ]]; then
        die "Invalid email '$x' given"
    fi
done

echo
echo "DANGER!!!"
echo
echo -n "You are about to replace all Author and Committer references from '$old_email' to '$new_email'"
if [ -n "$new_name" ]; then
    echo " and change the name field to '$new_name'"
fi
echo
read -r -p "DANGER: are you absolutely sure? (y/N)  " answer
echo

is_yes "$answer" || die "Aborting"

timestamp "Starting git filter-branch replacement"
echo

git filter-branch "${opts[@]}" --tag-name-filter cat --env-filter \
    "
    if [ \"\$GIT_AUTHOR_EMAIL\"    = '$old_email' ] ||
       [ \"\$GIT_COMMITTER_EMAIL\" = '$old_email' ]; then
        if [ -n '$new_name' ]; then
            export GIT_AUTHOR_NAME='$new_name'
            export GIT_COMMITTER_NAME='$new_name'
        fi
        export GIT_AUTHOR_EMAIL='$new_email'
        export GIT_COMMITTER_EMAIL='$new_email'
    fi
    " \
    -- --all "$@"
