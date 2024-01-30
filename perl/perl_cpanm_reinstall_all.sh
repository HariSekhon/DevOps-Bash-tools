#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-01-30 21:00:19 +0000 (Tue, 30 Jan 2024)
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

CPANM="${CPANM:-cpanm}"

# shellcheck disable=SC2034,SC2154
usage_description="
Re-Installs all currently installed Perl CPAN modules using Cpanm, taking in to account library paths, perlbrew envs etc

Useful for trying to recompile XS modules on Macs after migration assistant from an Intel Mac to an ARM Silicon Mac leaves your home XS libraries broken as they're built for the wrong architecture

export PERL_USER_INSTALL=1

to prevent it installing to the system but just overriding the home dir modules in this case
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

echo "Re-Installing ALL CPAN Modules"
echo

export CPANM_OPTS="--reinstall"

cpan -l |
sed $'s/\t/@/; s/@undef$//' |
xargs "$srcdir/perl_cpanm_install.sh"
