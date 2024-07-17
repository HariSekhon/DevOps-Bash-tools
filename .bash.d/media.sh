#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-07-21 11:36:49 +0100 (Tue, 21 Jul 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

webp_to_png(){
    local filename="$1"
    shopt -s nocasematch
    if ! [[ "$filename" =~ .+\.webp$ ]]; then
        echo "usage: webp_to_png filename.webp"
        return 1
    fi
    #basename="${filename%.webp}"
    # catches case insensitive and we already validated the filename is a case insentive .webp above
    basename="${filename%.*}"
    newname="$basename.png"
    # dwebp overwrites the -o outfile so add extra protection here
    if [ -f "$newname" ]; then
        echo "File '$filename' already exists, not overwriting for safety"
        return 1
    fi
    echo "Converting '$filename' to '$newname'"
    dwebp "$filename" -o "$basename.png"
}
