#!/usr/bin/env bash
# shellcheck disable=SC2015
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: Fri Nov 1 19:04:26 2019 +0000
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#
#  https://www.linkedin.com/in/harisekhon
#

# Various Git log author commit checks against Name / Email / Domain inconsistencies to catch committing with the wrong or default user.name / user.email

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090
. "$srcdir/.bash.d/functions.sh"

# shellcheck disable=SC1090
. "$srcdir/.bash.d/git.sh"

section "Git Author Name + Email Checks"

start_time="$(start_timer)"

#author_name="${GIT_AUTHOR_NAME:-${USER:-`whoami`}}"
#author_email="${GIT_AUTHOR_EMAIL:-${EMAIL:-$(whoami)@$(hostname -f | sed 's/.*@//')}}"
#user_name="$(git config -l | awk -F= '/user.name/{print $2}')"
#user_email="$(git config -l | awk -F= '/user.email/{print $2}')"

# used to check the last N commits (default: last 100 commits, override with $GIT_COMMIT_HISTORY_DEPTH)
# but figured this is fast enough even on my biggest repo with 10,000 commmits it still returns in a second
#commit_count="${GIT_COMMIT_HISTORY_DEPTH:-100}"

exitcode=0

git_log(){
    #local opts=""
    #if [[ "$commit_count" =~ ^[0-9]+$ ]] &&
    #   [ "$commit_count" -gt 1 ]; then
    #    opts="-n $commit_count"
    #fi
    # need to split opts
    # shellcheck disable=SC2086
    #git log --all $opts "$@"
    git log --all "$@"
}

git_log_names(){
    git_log --pretty=format:"%an" | trim | sort -u
}

git_log_emails(){
    git_log --pretty=format:"%ae" | trim | sort -u
}

git_log_names_emails(){
    git_log --pretty=format:"%an %ae" | trim | sort -u
}

names="$(git_log_names)"
emails="$(git_log_emails)"
names_emails="$(git_log_names_emails)"

check_multiple_names_per_email(){
    local err=0
    emails="${emails:-$(git_log_emails)}"
    names_emails="${names_emails:-(git_log_names_emails)}"
    for email in $emails; do
        #names_for_same_email="$(grep "[[:space:]]$email$" <<< "$names_emails" | perl -p -e 's/\s\S*?$//')"
        names_for_same_email="$(grep -i "[[:space:]]$email$" <<< "$names_emails" | normalize_spaces | remove_last_column | sort | uniq -d || :)"
        check_error "$names_for_same_email" "different names found for same email address '$email'! (misconfigured git config user.name?)" || err=1
    done
    if [ $err -eq 0 ]; then
        echo "OK: no differing names for each committed email address"
    fi
}

check_multiple_emails_per_name(){
    local err=0
    names="${names:-$(git_log_names)}"
    names_emails="${names_emails:-(git_log_names_emails)}"
    for name in $names; do
        name_regex="${name//[[:space:]]/[[:space:].]*}"
        emails_for_same_name="$(grep -i "^${name_regex}[[:space:]]" <<< "$names_emails" | awk '{print $NF}' | sort | uniq -d || :)"
        check_error "$emails_for_same_name" "different email addresses committed for the same user name '$name'! (misconfigured git config user.email?)" || err=1
    done
    if [ $err -eq 0 ]; then
        echo "OK: no differing email addresses committed for each committed user name"
    fi
}

check_duplicate_email_prefixes(){
    emails="${emails:-$(git_log_emails)}"
    # need to use sed not built-in variable replacement in order to handle multi-line emails
    # shellcheck disable=SC2001
    duplicate_email_prefixes="$(sed 's/@.*$//' <<< "$emails" | sort | uniq -d || :)"
    check_error "$duplicate_email_prefixes" "duplicate email prefixes detected (misconfigured domain name in git user.email?)" &&
    echo "OK: no duplicate email prefixes detected" || :
}

check_root_committed(){
    names_emails="${names_emails:-$(git_log_names_emails)}"
    root_detected="$(grep -i '\<root\>' <<< "$names_emails" || :)"
    check_error "$root_detected" "root commits detected" &&
    echo "OK: no root commits detected" || :
}

check_emails_without_domains(){
    emails="${emails:-$(git_local_emails)}"
    # need to use sed not built-in variable replacement in order to handle multi-line emails
    # shellcheck disable=SC2001
    domains="$(sed 's/.*@//' <<< "$emails" | sort -u)"
    non_domain_suffixes="$(grep -Ev '^(([A-Za-z](-?[A-Za-z0-9])*)\.)+[A-Za-z]{2,}$' <<< "$domains" || :)"
    check_error "$non_domain_suffixes" "non-domain email suffixes detected (misconfigured git user.email defaulting to hostname?)" &&
    echo "OK: no non-domain email suffixes detected" || :
}

check_single_word_author_names(){
    names="${names:-$(git_log_names)}"
    single_word_author_names="$(awk '{if(NF == 1) print $0}' <<< "$names" | sort -u)"
    check_error "$single_word_author_names" "single word author names detected (misconfigured git user.name?)" &&
    echo "OK: no single word author names detected" || :
}

check_error(){
    if [ -n "$1" ]; then
        echo "WARNING: $2"
        echo
        echo "$1"
        echo
        exitcode=1
        return 1
    fi
}

if isGit; then
    check_multiple_names_per_email
    check_multiple_emails_per_name
    check_duplicate_email_prefixes
    check_root_committed
    check_emails_without_domains
    # lots of my contrib authors have single word author names
    # and so do 3rd party services like pyup-bot and ReadmeCritic
    #check_single_word_author_names
else
    echo "Not a git repo, skipping..."
fi

time_taken "$start_time"
section2 "All Git author name / email checks passed"
echo
exit $exitcode
