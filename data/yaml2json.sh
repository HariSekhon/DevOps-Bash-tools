#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: .gitlab-ci.yml
#
#  Author: Hari Sekhon
#  Date: 2020-08-16 19:21:27 +0100 (Sun, 16 Aug 2020)
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
Converts YAML to JSON using either Perl, Ruby or Python (whichever is available in that order)

YAML can be specified as a filename argument to piped to standard input
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<filename>]"

help_usage "$@"

yaml2json(){
    # needs 3rd party modules installed (YAML::XS, JSON::XS), so check we have both modules first
    if type -P perl &>/dev/null &&
         perl -MYAML::XS=Load -MJSON::XS=encode_json -e '' &>/dev/null; then
        #perl -MYAML::XS=LoadFile -MJSON::XS=encode_json -e 'for (@ARGV) { for (LoadFile($_)) { print encode_json($_),"\n" } }'
        perl -MYAML::XS=Load -MJSON::XS=encode_json -e '$/ = undef; print encode_json(Load(<STDIN>)) . "\n"'
    elif type -P ruby &>/dev/null &&
         ruby -r yaml -r json -e '' &>/dev/null; then
        # don't want variable expansion
        # shellcheck disable=SC2016
        ruby -r yaml -r json -e 'puts YAML.load($stdin.read).to_json'
    # moved to last as typical Python version change problems, breaks across environments with AttributeError: 'module' object has no attribute 'FullLoader'
    # yaml is a 3rd party library, and in old 2.x versions so was json - only run the Python conversion if we have both libraries installed
    elif type -P python &>/dev/null &&
       python -c 'import yaml, json' &>/dev/null; then
        python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin, Loader=yaml.FullLoader), sys.stdout, indent=4)'
    # don't use yq - there are 2 completely different 'yq' which could appear in \$PATH, so this is unreliable
    #elif type -P yq &>/dev/null; then
    else
        die "ERROR: unable to convert yaml to json since not one of the following tools were found:  Perl (YAML::XS + JSON::XS), Ruby (json + yaml) or Python (PyYaml)"
    fi
}

if [ $# -gt 0 ]; then
    for arg; do
        yaml2json < "$arg"
        echo
    done
else
    yaml2json
    echo
fi
