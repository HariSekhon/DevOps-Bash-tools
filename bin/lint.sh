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
Lints one or more files

Auto-determines the file types, parses any lint headers and calls appropriate scripts and tools
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="file1 [file2 file3 ...]"

help_usage "$@"

min_args 1 "$@"

# defer expansion
# shellcheck disable=SC2016
trap_cmd 'exitcode=$?; echo; echo "Error - Exit Code: $exitcode"'

filename="$1"

if ! [ -f "$filename" ]; then
    echo "File not found: $filename"
    exit 1
fi

# examples:
#
# #  lint: k8s
lint_hint="$(parse_lint_hint "$filename")"

dirname="$(dirname "$filename")"
basename="${filename##*/}"

cd "$dirname"

if [ -n "$lint_hint" ]; then
    if [[ "$lint_hint" =~ k8s|kubernetes ]]; then
        #check_yaml.sh "$basename"
        #datree test "$basename"
        check_kubernetes_yaml.sh "$basename"
    else
        # assume it's a commmand
        eval "$lint_hint" "$filename"
    fi
else
    case "$basename" in
             Makefile)  check_makefiles.sh "$basename"
                        ;;
           Dockerfile)  #hadolint "$basename"
                        check_yaml.sh "$basename"
                        check_dockerfiles.sh "$basename"
                        ;;
*docker-compose*.y*ml)  #yamllint "$basename"
                        #docker-compose -f "$basename" config
                        check_yaml.sh "$basename"
                        check_docker_compose.sh "$basename"
                        ;;
                        # TODO: add linting for CloudBuild and Kustomize
  #  cloudbuild*.y*ml)  yamllint "$basename"
  #                     ;;
  #kustomization.yaml)  yamllint "$basename"
  #                     ;;
*.y*ml|autoinstall-user-data)
                        #yamllint "$filename"
                        check_yaml.sh "$basename"
                        ;;
              #.envrc)  cd "$dirname" && direnv allow .
              #         ;;
                 *.d2)  d2 fmt "$basename"
                        ;;
                 *.go)  go fmt -w "$basename"
                        ;;
                 *.tf)  terraform fmt -diff
                        terraform validate
                        ;;
 *.pkr.hcl|*.pkr.json)  packer init "$filename" &&
                        packer validate "$filename" &&
                        packer fmt -diff "$filename"
                        ;;
                 *.md)  mdl "$basename"
                        ;;
               # this command doesn't exit 1 if the file isn't found
               #.vimrc)  if ! vim -c "source $filename" -c "q"; then
               .vimrc)  if vim -c "
                            if !filereadable('$filename') |
                                echoerr 'Error: File not found'
                                cquit 1
                            else
                                source $filename
                            endif
                            " -c "q"; then
                            echo "ViM basic lint validation passed"
                        else
                            die "ViM basic lint validation failed"
                        fi
                        if type -P vint &>/dev/null; then
                            if vint "$filename"; then
                                echo "Vint vim script linting passed"
                            else
                                die "Vint vim script linting failed"
                            fi
                        fi
                        ;;
                    *)  die "Cannot lint unrecognized file type for file: $filename"
                        ;;
    esac
fi
