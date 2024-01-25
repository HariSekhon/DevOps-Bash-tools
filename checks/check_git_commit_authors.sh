#!/usr/bin/env bash
# shellcheck disable=SC2015,SC1090,SC1091
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: Fri Nov 1 19:04:26 2019 +0000
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#
#  https://www.linkedin.com/in/HariSekhon
#

# Various Git log author commit checks against Name / Email / Domain inconsistencies to catch committing with the wrong or default user.name / user.email

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "$srcdir/lib/utils.sh"

. "$srcdir/.bash.d/functions.sh"

. "$srcdir/.bash.d/git.sh"

section "Git Author Name + Email Checks"

# XXX: some 3rd party services have changed their names - exclude them from tripping this check here
ignored_names="
snyk bot
"

ignored_emails="
@pyup.io$
@snyk.io$
"

if ! isGit .; then
    echo "Running from a non-git directory '$PWD' - skipping author + email checks as git log is not available"
    echo
    exit 0
fi

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
    # shellcheck disable=SC2119
    git_log --pretty=format:"%an" | toLower | trim | perl -p -e 's/[\h-]+/ /g' | sort -u
}

git_log_emails(){
    # shellcheck disable=SC2119
    git_log --pretty=format:"%ae" | toLower | trim | sort -u
}

git_log_names_emails(){
    # shellcheck disable=SC2119
    git_log --pretty=format:"%an %ae" | toLower | trim | perl -p -e 's/\h+/ /g' | sort -u
}

#names="$(git_log_names)"
emails="$(git_log_emails)"
names_emails="$(git_log_names_emails)"

filter_ignored_names(){
    local regex
    for name in $ignored_names; do
        regex+="|$name"
    done
    regex="${regex#|}"
    grep -Ev "$ignored_names" || :
}

filter_ignored_emails(){
    local regex
    for email in $ignored_emails; do
        regex+="|$email"
    done
    regex="${regex#|}"
    grep -Ev "$ignored_emails" || :
}

check_multiple_names_per_email(){
    local err=0
    emails="${emails:-$(git_log_emails)}"
    names_emails="${names_emails:-(git_log_names_emails)}"
    for email in $emails; do
        #names_for_same_email="$(grep "[[:space:]]$email$" <<< "$names_emails" | perl -p -e 's/\s\S*?$//')"
        names_for_same_email="$(grep -Ei "[[:space:]]$email$" <<< "$names_emails" |
                                filter_ignored_emails |
                                normalize_spaces |
                                remove_last_column |
                                sort -u || :)"
        # don't quote otherwise have to trim wc output for comparison
        # shellcheck disable=SC2046
        if [ $(wc -l <<< "$names_for_same_email") -eq 1 ]; then
            names_for_same_email=""
        fi
        check_error "$names_for_same_email" "different names found for same email address '$email'! (misconfigured git config user.name?)" || err=1
    done
    if [ $err -eq 0 ]; then
        echo "OK: no differing names for each committed email address"
    fi
}

check_multiple_emails_per_name(){
    local err=0
    names="$(git_log_names | filter_ignored_names)"
    # generalize the spaces/dots/dashes to an ERE format regex in case the same name has changed slightly
    names="$(perl -p -e 's/[\s.-]+/[[:space:].-]*/' <<< "$names" | sort -u)"
    names_emails="${names_emails:-(git_log_names_emails)}"
    while read -r name_regex; do
        # $email_regex defined in lib
        # shellcheck disable=SC2154
        emails_for_same_name="$(grep -Ei "^${name_regex}[[:space:]]+$email_regex" <<< "$names_emails" | awk '{print $NF}' | sort -u || :)"
        # don't quote otherwise have to trim wc output for comparison
        # shellcheck disable=SC2046
        if [ $(wc -l <<< "$emails_for_same_name") -eq 1 ]; then
            emails_for_same_name=""
        fi
        check_error "$emails_for_same_name" "different email addresses committed for the same user name '$name_regex'! (misconfigured git config user.email?)" || err=1
    done <<< "$names"
    if [ $err -eq 0 ]; then
        echo "OK: no differing email addresses committed for each committed user name"
    fi
}

check_duplicate_email_prefixes(){
    emails="${emails:-$(git_log_emails)}"
    # need to use sed not built-in variable replacement in order to handle multi-line emails
    # shellcheck disable=SC2001
    duplicate_email_prefixes="$(sed 's/@.*$//;s/\.//g' <<< "$emails" | sort | uniq -d || :)"
    # email prefixes normalize hari.sekhon => harisekhon since email accounts like gmail treat them the same, so remember duplicates for harisekhon may include hari.sekhon
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
    emails="${emails:-$(git_log_emails)}"
    # need to use sed not built-in variable replacement in order to handle multi-line emails
    # shellcheck disable=SC2001
    domains="$(sed 's/.*@//' <<< "$emails" | sort -u)"
    # $domain_regex defined in lib
    # shellcheck disable=SC2154
    non_domain_suffixes="$(grep -Ev "^$domain_regex$" <<< "$domains" || :)"
    check_error "$non_domain_suffixes" "non-domain email suffixes detected (misconfigured git user.email defaulting to hostname?)" &&
    echo "OK: no non-domain email suffixes detected" || :
}

check_single_word_author_names(){
    names="$(git_log_names)"
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
if [ $exitcode -eq 0 ]; then
    section2 "All Git author name / email checks passed"
else
    section2 "ERROR: some Git author name / email checks failed"
fi
echo
exit $exitcode
