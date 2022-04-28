#!/usr/bin/env bash
#  shellcheck disable=SC2034
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2012-06-25 15:20:39 +0100
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# ============================================================================ #
#                        Terminal ANSI Escape Color Codes
# ============================================================================ #

# Show color codes - adapted from http://codesnippets.joyent.com/posts/show/1517 example 1
#
# see also colors.pl from DevOps-Perl-tools repo which is slightly better
colors(){
    local text="hari"

    echo -e '\n                  40m      41m      42m      43m      44m      45m      46m      47m';

    for FGs in '    m' '   1m' '  30m' '1;30m' '  31m' '1;31m' '  32m' \
               '1;32m' '  33m' '1;33m' '  34m' '1;34m' '  35m' '1;35m' \
               '  36m' '1;36m' '  37m' '1;37m'; do
        FG=${FGs// /}
        # shellcheck disable=SC1117
        echo -en " $FGs \033[$FG  $text  "
        for BG in 40m 41m 42m 43m 44m 45m 46m 47m; do
            # shellcheck disable=SC1117
            echo -en "$EINS \033[$FG\033[$BG  $text  \033[0m";
        done
        echo
    done
    echo
}

# ============================================================================ #

# For Gentoo stylish prompts
#
# Find or write a full colour output table like seen here:
# Daniel Robbins prompt magic tip on ibm developerworks
#
# from http://wiki.archlinux.org/index.php/Color_Bash_Prompt
#
# would set 'readonly' but causes reloads to output readonly variable errors
# replaced \e with \033 as it is more portable on Mac script includes for lib/utils.sh tick_msg()
txtblk='\033[0;30m'  # Black - Regular
txtred='\033[0;31m'  # Red
txtgrn='\033[0;32m'  # Green
txtylw='\033[0;33m'  # Yellow
txtblu='\033[0;34m'  # Blue
txtpur='\033[0;35m'  # Purple
txtcyn='\033[0;36m'  # Cyan
txtwht='\033[0;37m'  # White
bldblk='\033[1;30m'  # Black - Bold
bldred='\033[1;31m'  # Red
bldgrn='\033[1;32m'  # Green
bldylw='\033[1;33m'  # Yellow
bldblu='\033[1;34m'  # Blue
bldpur='\033[1;35m'  # Purple
bldcyn='\033[1;36m'  # Cyan
bldwht='\033[1;37m'  # White
unkblk='\033[4;30m'  # Black - Underline
undred='\033[4;31m'  # Red
undgrn='\033[4;32m'  # Green
undylw='\033[4;33m'  # Yellow
undblu='\033[4;34m'  # Blue
undpur='\033[4;35m'  # Purple
undcyn='\033[4;36m'  # Cyan
undwht='\033[4;37m'  # White
bakblk='\033[40m'    # Black - Background
bakred='\033[41m'    # Red
bakgrn='\033[42m'    # Green
bakylw='\033[43m'    # Yellow
bakblu='\033[44m'    # Blue
bakpur='\033[45m'    # Purple
bakcyn='\033[46m'    # Cyan
bakwht='\033[47m'    # White
txtrst='\033[0m'     # Text Reset
