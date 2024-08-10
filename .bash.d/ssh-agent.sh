#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2006 (forked from .bashrc)
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
#                               S S H   A g e n t
# ============================================================================ #

# keychain id_rsa
# . .keychain/$HOSTNAME-sh

ssh_agent(){
    #if [ $UID != 0 ]; then
        local SSH_ENV_FILE=~/.ssh-agent.env
        if [ -f "${SSH_ENV_FILE:-}" ]; then
            # shellcheck source=~/.agent.env
            # shellcheck disable=SC1090,SC1091
            . "$SSH_ENV_FILE" > /dev/null

            if ! kill -0 "$SSH_AGENT_PID" >/dev/null 2>&1; then
                echo "Stale ssh-agent found. Spawning new agent..."
                killall -9 ssh-agent
                eval "$(ssh-agent | tee "$SSH_ENV_FILE")" #| grep -v "^Agent pid [[:digit:]]\+$"
                # lazy evaluated ssh func now so it's not prompted until used
                #ssh-add
            elif [ "$(ps -p "$SSH_AGENT_PID" -o comm=)" != "ssh-agent" ]; then
                echo "ssh-agent PID does not belong to ssh-agent, spawning new agent..."
                eval "$(ssh-agent | tee "$SSH_ENV_FILE")" #| grep -v "^Agent pid [[:digit:]]\+$"
                # lazy evaluated ssh func now so it's not prompted until used
                #ssh-add
            fi
        else
            echo "Starting ssh-agent..."
            killall -9 ssh-agent
            eval "$(ssh-agent | tee "$SSH_ENV_FILE")"
            # lazy evaluated ssh func now so it's not prompted until used
            #ssh-add
        fi
        #clear
    #fi
}

[ -n "${GOOGLE_CLOUD_SHELL:-}" ] && return

# do not launch SSH Agent if we are inheriting an SSH_AUTH_SOCK from an 'ssh -A' agent forwarding connection
[ -n "${SSH_AUTH_SOCK:-}" ] && return

ssh_agent
