#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-02-27 02:08:34 +0700 (Thu, 27 Feb 2025)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

export ANDROID_HOME="$HOME/Android/Sdk"

# Doesn't work
#export ANDROID_SDK_ROOT="$ANDROID_HOME"

add_PATH "$ANDROID_HOME/platform-tools"

add_PATH "$ANDROID_HOME/cmdline-tools/latest/bin"
add_PATH "$ANDROID_HOME/cmdline-tools/bin"
