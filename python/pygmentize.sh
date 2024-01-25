#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-11-02 21:50:00 +0000 (Sat, 02 Nov 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

#set -euo pipefail
#[ -n "${DEBUG:-}" ] && set -x

# idea from https://superuser.com/questions/117841/when-reading-a-file-with-less-or-more-how-can-i-get-the-content-in-colors

if [ $# -gt 0 ]; then
    case "$1" in
        *.ad[asb]|\
        *.asm|\
        *.awk|\
        *.axp|\
        *.diff|\
        *.ebuild|\
        *.eclass|\
        *.groff|\
        *.hh|\
        *.inc|\
        *.java|\
        *.js|\
        *.lsp|\
        *.l|\
        *.m4|\
        *.pas|\
        *.patch|\
        *.php|\
        *.pl|\
        *.pm|\
        *.pod|\
        *.pov|\
        *.ppd|\
        *.py|\
        *.p|\
        *.rb|\
        *.sh|\
        *.sql|\
        *.xml|\
        *.xps|\
        *.xsl|\
        *.[ch]pp|\
        *.[ch]xx|\
        *.[ch]\
            )   pygmentize -f 256 "$1"
                ;;

        .bash*) pygmentize -f 256 -l sh "$1"
                ;;

        *)
            if grep -q '#!.*bash' "$1" 2> /dev/null; then
                pygmentize -f 256 -l sh "$1"
            else
                exit 1
            fi
    esac
else
    pygmentize -f 256 -g
fi

exit 0
