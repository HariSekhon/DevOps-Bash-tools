#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-02-16 15:24:45 +0000 (Sun, 16 Feb 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Uses PAR::Packer to compile all perl scripts given as args in to binaries

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

# shellcheck source=lib/docker.sh
. "$srcdir/lib/docker.sh"

output_dir="bin"

usage(){
    echo "Generates binaries from Perl scripts using PAR::Packer"
    echo
    echo "Takes a list of perl scripts as arguments or .txt files containing lists of scripts (one per line)"
    echo
    echo "usage: ${0##*} <list_of_scripts>"
    echo
    exit 3
}

perl_scripts=""
for x in "$@"; do
    if [[ "$x" =~ .*\.txt ]]; then
        echo "adding perl scripts from file:  $x"
        perl_scripts="$perl_scripts $(sed 's/#.*//;/^[[:space:]]*$$/d' "$x")"
        echo
    else
        perl_scripts="$perl_scripts $x"
    fi
    perl_scripts="$(tr ' ' ' \n' <<< "$perl_scripts" | sort -u | tr '\n' ' ')"
done

for x in "$@"; do
    # shellcheck disable=SC2119
    case "$1" in
        -*) usage
            ;;
    esac
done

if [ -z "$perl_scripts" ]; then
    # shellcheck disable=SC2119
    usage
fi

section "Generating PAR binaries from Perl Scripts"

if is_inside_docker; then
    echo "Detected running inside Docker, skipping building par binaries..."
    exit 0
fi

check_bin pp

# want expansion
# shellcheck disable=SC2086
trap 'echo ERROR' $TRAP_SIGNALS

mkdir -pv "$output_dir"

echo "Generating App::FatPacker self-contained perl scripts with all dependencies:"
echo
i=0
for perl_script in $perl_scripts; do
    ((i+=1))
    dest="$output_dir/${perl_script%.pl}"
    echo "$perl_script -> $dest"
    # -c runs it but breaks on taint mode enable scripts with the usual: "-T" is on the #! line, it must also be used on the command line at
    # re-run without error messages suppressed if it fails
    pp -o "$dest" "$perl_script" 2>/dev/null ||
    pp -o "$dest" "$perl_script"
    #chmod +x "$dest"
done
echo
echo "Generated $i PAR binaries under bin/ directory"
untrap
