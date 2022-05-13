#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-12-20 16:01:28 +0000 (Fri, 20 Dec 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#
#  https://www.linkedin.com/in/HariSekhon
#

# Helper script for calling from vim function to run programs or execute with args extraction
#
# Runs the value of the 'run:' header from the given file

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
 . "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090
 . "$srcdir/.bash.d/aliases.sh"

# shellcheck disable=SC1090
 . "$srcdir/.bash.d/functions.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Runs one or more files

Auto-determines the file types, any run or arg headers and executes each file using the appropriate script or CLI tool
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="file1 [file2 file3 ...]"

help_usage "$@"

min_args 1 "$@"

# defer expansion
# shellcheck disable=SC2016
trap_cmd 'exitcode=$?; echo; echo "Exit Code: $exitcode"'

filename="$1"

# examples:
#
# #  run: kubectl apply -f file.yaml
# // run: go run file.go
# -- run: psql -f file.sql
run_cmd="$(parse_run_args "$filename")"

dirname="$(dirname "$filename")"
basename="${filename##*/}"

cd "$dirname"

docker_compose_up(){
    docker-compose -f "$filename" up
}

if [ -n "$run_cmd" ]; then
    eval "$run_cmd"
else
    case "$basename" in
             Makefile)  make
                        ;;
           Dockerfile)  if [ -f Makefile ]; then
                            make
                        else
                            docker build .
                        fi
                        ;;
*docker-compose*.y*ml)  docker_compose_up
                        ;;
              Gemfile)  bundle install
                        ;;
     cloudbuild*.y*ml)  gcloud builds submit --config "$basename" .
                        ;;
   kustomization.yaml)  kustomize build --enable-helm
                        ;;
               .envrc)  cd "$dirname" && direnv allow .
                        ;;
                 *.go)  eval go run "'$filename'" "$("$srcdir/lib/args_extract.sh" "$filename")"
                        ;;
                 *.tf)  #terraform plan
                        terraform apply
                        ;;
                 *.md)  bash -ic "cd '$dirname'; gitbrowse"
                        ;;
                    *)  if [[ "$filename" =~ /docker-compose/.+\.ya?ml$ ]]; then
                            docker_compose_up
                        elif [[ "$filename" =~ \.ya?ml$ ]] &&
                           grep -q '^apiVersion:' "$filename" &&
                           grep -q '^kind:'       "$filename"; then
                            # a yaml with these apiVersion and kind fields is almost certainly a kubernetes manifest
                            kubectl apply -f "$filename"
                            exit 0
                        fi
                        if ! [ -x "$filename" ]; then
                            echo "ERROR: file '$filename' is not set executable!" >&2
                            exit 1
                        fi
                        args="$("$srcdir/lib/args_extract.sh" "$filename")"
                        echo "'$filename'" "$args" >&2
                        eval "'$filename'" "$args"
                        ;;
    esac
fi
