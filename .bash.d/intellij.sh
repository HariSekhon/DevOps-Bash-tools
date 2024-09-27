#
#  Author: Hari Sekhon
#  Date: 2023-07-26 00:10:06 +0100
#
#  vim:ts=4:sts=4:sw=4:et
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# ============================================================================ #
#                                I n t e l l i J
# ============================================================================ #

# so that you can open files in IntelliJ from the command line on Mac like so:
#
#   idea <filename>
#
if [ -d "/Applications/IntelliJ IDEA CE.app/Contents/MacOS" ]; then
    add_PATH "/Applications/IntelliJ IDEA CE.app/Contents/MacOS"
fi

# so that you can quickly open files without them holding your terminal open and spewing Java logs all over your screen
idea(){
    nohup command idea "$@" &
    # disowns the first backgrounded command instead of the latest command,
    # so use $! to specify the pid of the latest command in this shell
    disown $!
}

# if a file does not already exist then IntelliJ opens it in a new light IDE instead of in the current project
touch_idea(){
    touch "$@"
    idea "$@"
}
alias tidea="touch_idea"
