#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-15 13:48:29 +0000 (Fri, 15 Feb 2019)
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

perl="${PERL:-perl}"

usage(){
    echo "Installs Perl CPAN modules not already installed using Cpanm"
    echo
    echo "Leverages adjacent perl_cpanm_install.sh which takes in to account library paths, perlbrew envs etc"
    echo
    echo "Takes a list of perl module names as arguments or .txt files containing lists of modules (one per line)"
    echo
    echo "usage: ${0##*} <list_of_modules>"
    echo
    exit 3
}

for arg; do
    case "$arg" in
        -*) usage
            ;;
    esac
done

cpan_modules=""

process_args(){
    for arg; do
        if [ -f "$arg" ]; then
            echo "adding cpan modules from file:  $arg"
            cpan_modules="$cpan_modules $(sed 's/#.*//;/^[[:space:]]*$$/d' "$arg")"
            echo
        else
            cpan_modules="$cpan_modules $arg"
        fi
    done
}

if [ $# -gt 0 ]; then
    process_args "$@"
else
    # shellcheck disable=SC2046
    process_args $(cat)
fi

if [ -z "${cpan_modules// }" ]; then
    usage
fi

cpan_modules="$(tr ' ' ' \n' <<< "$cpan_modules" | sort -u | tr '\n' ' ')"

echo "Installing CPAN Modules that are not already installed"
echo

for cpan_module in $cpan_modules; do
    perl_module="${cpan_module%%@*}"
    if "$perl" -e "use $perl_module;" &>/dev/null; then
        echo "perl cpan module '$perl_module' already installed, skipping..."
    else
        echo "installing perl cpan module '$perl_module'"
        echo
        "$srcdir/perl_cpanm_install.sh" "$cpan_module"
    fi
done
