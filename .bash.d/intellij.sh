#!/usr/bin/env bash
# shellcheck disable=SC2230
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

# requires git.sh for git_root() function

# so that you can open files in IntelliJ from the command line on Mac like so:
#
#   idea <filename>
#
if [ -d "/Applications/IntelliJ IDEA CE.app/Contents/MacOS" ]; then
    add_PATH "/Applications/IntelliJ IDEA CE.app/Contents/MacOS"
fi

alias i='idea'

# wrote find_lock.sh to try to find if IntelliJ uses a lock file in the git project
# whether it's open or not but it found not file existence changes at all
#
# after various experimentation, cannot find a reliable indicator via either process or lockfile
# or any .idea/ file change if IntelliJ has a project dir open or not, surprising
#
#is_intellij_project_open(){
#    local path="$1"
#    if [ -f "$path" ]; then
#        path="$(dirname "$path")"
#    fi
#    local git_root
#    git_root="$(git_root "$path")"
#    if [ -z "$git_root" ]; then
#        echo "Given path is not in a git checkout!!" >&2
#        return 1
#    fi
#    local pid
#    pid="$(lsof -n -c java | awk "/${git_root//\//\\/}/ {print \$2}" | sort -u)"
#    if [ -z "$pid" ]; then
#        return 1
#    fi
#    if ps -ef | awk "\$2 == $pid { print }" | grep -q IntelliJ; then
#        return 0
#    fi
#    return 1
#}
#
#open_intellij_project_if_not_already(){
#    local path="$1"
#    local dir
#    if [ -e "$path" ]; then
#        if ! is_intellij_project_open "$path"; then
#            if [ -f "$path" ]; then
#                dir="$(dirname "$path")"
#            else
#                dir="$path"
#            fi
#            idea_bg_disown "$dir"
#            sleep 1
#        fi
#    fi
#}

idea_bg_disown(){
    nohup command idea "$@" &
    # disowns the first backgrounded command instead of the latest command,
    # so use $! to specify the pid of the latest command in this shell
    disown $!
}

# so that you can quickly open files without them holding your terminal open and spewing Java logs all over your screen
idea(){
    local dir
    for arg in "$@"; do
        # because otherwise README Markdown Preview will not render images with relative paths to images inside project:
        #
        #   https://github.com/HariSekhon/Knowledge-Base/blob/69bb8d4220596e90e6c0e61c48dd8e1b9ffdf720/intellij.md#markdown-images-with-relative-paths-not-displaying-in-preview
        #
        # can't find any reliable method for this function, see comment just above function itself for more details
        #open_intellij_project_if_not_already "$arg"
        # XXX: caveat here - in order to not eat CLI args, we open all args after this loop,
        #      which means multiple markdown files in one command will open in the last project
        #      This will still result in broken markdown preview for any markdown files that are outside
        #      the last project directory which will be ithe foreground window
        if [[ "$arg" =~ \.md$ ]]; then
            dir="$(git_root "$arg" || :)"
            if [ -n "$dir" ]; then
                idea_bg_disown "$dir"
                # give time to settle otherwise race condition of immediate idea_bg_own() call will open the file in the other existing project
                sleep 1
            fi
        fi
    done
    idea_bg_disown "$@"
}

# if a file does not already exist then IntelliJ opens it in a new light IDE instead of in the current project
touch_idea(){
    touch "$@"
    idea "$@"
}
alias tidea="touch_idea"
