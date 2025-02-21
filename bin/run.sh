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

# shellcheck disable=SC1090,SC1091
 . "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090,SC1091
 . "$srcdir/.bash.d/aliases.sh"

# shellcheck disable=SC1090,SC1091
 . "$srcdir/.bash.d/functions.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Runs one or more files

Auto-determines the file types, any run or arg headers and executes each file using the appropriate script or CLI tool

Useful to call from vim or IDEs via hotkeys to portably standardize quick build testing while editing
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
shift || :

# examples:
#
# #  run: kubectl apply -f file.yaml
# // run: go run file.go
# -- run: psql -f file.sql
run_cmd="$(parse_run_args "$filename")"

filename="$(readlink -f "$filename")"
dirname="$(dirname "$filename")"
basename="${filename##*/}"

cd "$dirname"

docker_compose_up(){
    local dc_args=()
    local env_file="${filename%.*}.env"
    if [ -f "$env_file" ]; then
        dc_args+=(--env-file "$env_file")
    fi
    docker-compose -f "$filename" ${dc_args:+"${dc_args[@]}"} up
}

if [ -n "$run_cmd" ]; then
    eval "$run_cmd"
# fails to do the open for d2 diagrams
#elif test -x "$basename"; then
#    ./"$basename"
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
                    Fastfile) if [[ "$(readlink -f "$basename")" =~ /fastlane/Fastfile ]]; then
                            cd ".."
                            fastlane "$@"
                        fi
                        ;;
     cloudbuild*.y*ml)  gcloud builds submit --config "$basename" .
                        ;;
   kustomization.yaml)  kustomize build --enable-helm
                        ;;
               .envrc)  direnv allow .
                        ;;
                 *.d2)  if test -x "$basename"; then
                            # use its shebang line to get the settings like --theme or --layout elk eg. for github_actions_cicd.d2 in https://github.com/HariSekhon/Diagrams-as-Code
                            ./"$basename"
                            # shellcheck disable=SC2012
                            latest_image="$(ls -t "${basename%.d2}".{png,svg} 2>/dev/null | head -n1 || :)"
                        else
                            image="${basename%.d2}.svg"
                            d2 --dark-theme 200 "$basename" "$image"
                            latest_image="$image"
                        fi
                        open "$latest_image"
                        ;;
                 *.go)  eval go run "'$basename'" "$("$srcdir/lib/args_extract.sh" "$basename")"
                        ;;
                 *.tf)  #terraform plan
                        terraform apply
                        ;;
       terragrunt.hcl)  terragrunt apply
                        ;;
 *.pkr.hcl|*.pkr.json)  packer init "$basename" &&
                        packer build "$basename"
                        ;;
                 *.md)  bash -ic "cd '$dirname'; gitbrowse"
                        ;;
                 *.gv)  file_png="${basename%.gv}.png"
                        dot -T png "$basename" -o "$file_png" >/dev/null && open "$file_png"
                        ;;
            .pylintrc)  pylint ./*.py
                        ;;
                    *)  if [[ "$basename" =~ /docker-compose/.+\.ya?ml$ ]]; then
                            docker_compose_up
                        elif [[ "$basename" =~ \.ya?ml$ ]] &&
                           grep -q '^apiVersion:' "$basename" &&
                           grep -q '^kind:'       "$basename"; then
                            # a yaml with these apiVersion and kind fields is almost certainly a kubernetes manifest
                            kubectl apply -f "$basename"
                            exit 0
                        fi
                        if ! [ -x "$basename" ]; then
                            echo "ERROR: file '$filename' is not set executable!" >&2
                            exit 1
                        fi
                        args="$("$srcdir/lib/args_extract.sh" "$basename")"
                        echo "'$basename'" "$args" >&2
                        eval "'$basename'" "$args"
                        ;;
    esac
fi
