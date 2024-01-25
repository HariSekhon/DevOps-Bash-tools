#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-10-08 18:20:47 +0100 (Tue, 08 Oct 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Uses App::Fatpacker to package all perl scripts given as args in to self-contained scripts with dependencies contained
#
# fatpack doesn't bundle compiled XS code, but is smart enough to replace those references eg. 'use JSON::XS;' becomes 'use JSON;' in the outputted self-contained script

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

# shellcheck source=lib/docker.sh
. "$srcdir/lib/docker.sh"

output_dir="fatpacks"

# unreliable that HOME is set, ensure shell evaluates to the right thing before we use it
[ -n "${HOME:-}" ] || HOME=~

export PERL5LIB="${PERL5LIB:-}:$HOME/perl5/lib/perl5"
export PATH="${PATH:-}:$HOME/perl5/bin"
# for Mac
for x in /usr/local/Cellar/perl/*/bin; do
    if [ -d "$x" ]; then
        export PATH="$PATH:$x"
    fi
done

usage(){
    echo "Generates self-contained versions of Perl scripts using App::FatPacker"
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

section "FatPacking Perl Scripts"

if is_inside_docker; then
    echo "Detected running inside Docker, skipping building fatpacks..."
    exit 0
fi

check_bin fatpack

# want expansion
# shellcheck disable=SC2086
trap 'echo ERROR' $TRAP_SIGNALS

mkdir -pv "$output_dir"

echo "Generating App::FatPacker self-contained perl scripts with all dependencies:"
echo
i=0
for perl_script in $perl_scripts; do
    [ -f "$perl_script" ] || continue
    ((i+=1))
    dest="$output_dir/${perl_script%.pl}.fatpack.pl"
    echo "$perl_script -> $dest"
    # re-run without error messages suppressed if it fails
    fatpack pack "$perl_script" 2>/dev/null > "$dest" ||
    fatpack pack "$perl_script" > "$dest"
    chmod +x "$dest"
done
echo
echo "Generated $i fatpacked scripts under fatpacks/ directory"
#echo
#echo "Generating tarball of fatpacked scripts"
#echo
#tar czf fatpacks.tar.gz fatpacks/
#echo
#echo "Done! Generated fatpacks.tar.gz containing $i fatpacked scripts with all dependencies included"
untrap
