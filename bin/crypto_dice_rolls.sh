#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-06-12 14:02:26 +0200 (Thu, 12 Jun 2025)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback to help steer this or other code I publish
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
Generates random dice rolls to be used for TESTING ONLY of a hardware wallet's fidelity using a site like:

    https://bitcoiner.guide/seed/

Defaults to 100 dice rolls as this is how much entropy you need to test a 24 word BIP-39 seed phrase
as used by Ledger and similar hardware wallets

DO NOT USE THIS FOR YOUR REAL CRYPTO HOLDINGS - if you machine is compromised with malware
YOU CAN HAVE YOUR CRYPTO STOLEN
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<num_rolls>]"

help_usage "$@"

max_args 1 "$@"

num="${1:-100}"

# solves this error on macOS:
#
#   tr: Illegal byte sequence
#
export LC_ALL=C

tr -dc 1-6 < /dev/urandom |
head -c "$num" |
fold -w5 || :
#paste -sd ' ' -

echo
