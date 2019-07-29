#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2006 (forked from .bashrc)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Pinentry is important, gpg-agent won't work without it.
# pinentry intercepts and stores passphrase.

gpg_agent(){
    if [ $UID != 0 ]; then
        if command -v gpg-agent &>/dev/null; then
            GPG_ENV_FILE=~/.gpg-agent.env
            if [ -f "$GPG_ENV_FILE" ]; then
                # shellcheck disable=SC1090
                . "$GPG_ENV_FILE" > /dev/null
                
                GPG_AGENT_PID="${GPG_AGENT_INFO#*:}"
                GPG_AGENT_PID="${GPG_AGENT_PID%:*}"
                if ! kill -0 "$GPG_AGENT_PID" > /dev/null 2>&1; then
                    echo "Stale gpg-agent found. Spawning new agent..."
                    killall -9 gpg-agent
                    eval "$(gpg-agent --daemon | tee "$GPG_ENV_FILE")"
                elif [ "$(ps -p "$GPG_AGENT_PID" -c comm=")" != "gpg-agent")" ]; then
                    echo "gpg-agent PID does not belong to gpg-agent, spawning new agent..."
                    eval "$(gpg-agent --daemon | tee "$GPG_ENV_FILE")"
                fi
            else
                echo "Starting gpg-agent..."
                killall -9 gpg-agent
                eval "$(gpg-agent --daemon | tee "$GPG_ENV_FILE")"
            fi
            #clear
        fi
    fi
}
gpg_agent
