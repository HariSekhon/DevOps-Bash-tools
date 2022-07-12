#!/usr/bin/env bash
# shellcheck disable=SC2230
#
#  Author: Hari Sekhon
#  Date: 2019-09-17
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/HariSekhon
#

# Installs Parquet Tools to local ~/bin
#
# add ~/bin/parquet-tools-* to $PATH (automatically detected and done via advanced bashrc in this repo)

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

PARQUET_VERSION="${PARQUET_VERSION:-1.5.0}"

zipfile="parquet-tools-$PARQUET_VERSION-bin.zip"
zipdir="${zipfile%-bin.zip}"

URL="${URL:-http://search.maven.org/remotecontent?filepath=com/twitter/parquet-tools/$PARQUET_VERSION/$zipfile}"

# unreliable that HOME is set, ensure shell evaluates to the right thing before we use it
[ -n "${HOME:-}" ] || HOME=~

bin="${BIN:-$HOME/bin}"

mkdir -pv "$bin"

cd "$bin"

if type -P parquet-cat &>/dev/null; then
    echo "parquet-tools already found in \$PATH:"
    echo
    dirname "$(which parquet-cat)"
elif [ -f "$zipdir/parquet-cat" ]; then
    echo "parquet-tools already installed in local dir ($PWD/$zipdir)"
else
    echo "parquet-tools not found in \$PATH, nor in the local ${zipfile%.zip} directory"
    echo
    echo "downloading parquet-tools to $bin"
    wget -t 100 --retry-connrefused -c -O "$zipfile" "$URL"
    echo
    echo "unzipping parquet-tools"
    unzip -- "$zipfile"
    echo
    echo "chmod'ing 0755 parquet-tools-*"
    chmod 0755 parquet-tools-*
    echo
    echo "removing zipfile"
    rm -f -- "$zipfile"
    echo
    echo "Done"
fi

echo
echo "Ensure $bin/${zipfile%.zip} is in the \$PATH (it's auto-detected in new shells if sourcing this repo's .bashrc)"
echo
