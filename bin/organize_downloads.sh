#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-07-18 16:21:32 +0200 (Thu, 18 Jul 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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
Moves files of well-known extensions in the \$HOME/Downloads directory older than 1 week
to capitalized subdirectories of their type to keep the \$HOME/Downloads/ directory tidy

Designed to be run either interactively or scheduled via local user 'crontab -e'

Can optionally specify a file extension, otherwise operates on a default list of common files,
aggregating several files of similar types eg. jpeg / png / webp into directories of names like PICS/
or .tar.* into TARBALLS/

To change the number of days for which files older than should be moved:

    export DOWNLOADS_ORGANIZE_OLD_DAYS_THRESHOLD=7
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<file_extension>]"

help_usage "$@"

max_args 1 "$@"

cd ~/Downloads

file_extension="${1:-}"

# Common file extensions cluttering my ~/Downloads directory
file_extensions=(
cer
cert
crt
csv
dmg
doc
docx
img
iso
jpeg
jpg
json
key
log
odp
p12
pdf
pem
png
ppt
pptx
rtf
svg
tar
tar.bz2
tar.gz
tbz2
tgz
txt
webp
xls
xlsx
xml
zip
)

# for the case match below
shopt -s nocasematch

move_files_of_extension(){
    local file_extension="$1"
    timestamp "Processing files or extension '$file_extension'"
    echo >&2
    local subdir
    case "$file_extension" in
           doc|docx|odp|rtf)    subdir="DOC"
                                ;;
                   ppt|pptx)    subdir="POWERPOINT"
                                ;;
                   xls|xlsx)    subdir="EXCEL"
                                ;;
                    img|iso)    subdir="ISO"
                                ;;
                        log)    subdir="LOGS"
                                ;;
       crt|cert|key|p12|pem)    subdir="SSL_CERTS"
                                ;;
      jpg|jpeg|png|webp|svg)    subdir="PICS"
                                ;;
tar|tar.gz|tar.bz2|tgz|tbz2)    subdir="TARBALLS"
                                ;;
                          *)    subdir="$(tr '[:lower:]' '[:upper:]' <<< "$file_extension")"

    esac

    mkdir -p -v "$subdir"

    #yes no |
    find . -maxdepth 1 \
           -type f \
           -iname "*.$file_extension" \
           -mtime +"${DOWNLOADS_ORGANIZE_OLD_DAYS_THRESHOLD:-7}" \
           -exec mv -iv "{}" "$subdir/" \;  # trailing slash is important to enforce directory move and not accidental rename behaviour
    echo >&2
}

if [ -n "$file_extension" ]; then
    move_files_of_extension "$file_extension"
else
    for file_extension in "${file_extensions[@]}"; do
        move_files_of_extension "$file_extension"
    done
fi
