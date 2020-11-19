#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-12-20 16:01:28 +0000 (Fri, 20 Dec 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#
#  https://www.linkedin.com/in/harisekhon
#

# Helper script for calling from vim function to run programs or execute with args extraction
#
# Runs the value of the 'run:' header from the given file

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
 . "$srcdir/../lib/utils.sh"

# shellcheck disable=SC1090
 . "$srcdir/../.bash.d/aliases.sh"

# shellcheck disable=SC1090
 . "$srcdir/../.bash.d/functions.sh"

trap_cmd 'exitcode=$?; echo; echo "Exit Code: $exitcode"'

if [ $# -eq 0 ]; then
    echo "usage: ${0##*/} <filename>"
    exit 3
fi

filename="$1"

# examples:
#
# #  run: kubectl apply -f file.yaml
# // run: go run file.go
# -- run: psql -f file.sql
run_cmd="$("$srcdir/parse_run_args.sh" "$filename")"

dirname="$(dirname "$filename")"
basename="${filename##*/}"

cd "$dirname"

if [ -n "$run_cmd" ]; then
    eval "$run_cmd"
else
    case "$basename" in
        Makefile)   make
                    ;;
      Dockerfile)   if [ -f Makefile ]; then
                        make
                    else
                        docker build .
                    fi
                    ;;
  cloudbuild*.y*ml) gcloud builds submit --config "$basename" .
                    ;;
kustomization.yaml) kustomize build
                    ;;
            *.go)   eval go run "'$filename'" "$("$srcdir/args_extract.sh" "$filename")"
                    ;;
            *.tf)   terraform plan
                    ;;
               *)   if ! [ -x "$filename" ]; then
                        echo "ERROR: file '$filename' is not set executable!" >&2
                        exit 1
                    fi
                    args="$("$srcdir/args_extract.sh" "$filename")"
                    echo "'$filename'" "$args" >&2
                    eval "'$filename'" "$args"
                    ;;
    esac
fi
