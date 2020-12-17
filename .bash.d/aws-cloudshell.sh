#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-12-17 18:54:23 +0000 (Thu, 17 Dec 2020)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# This is designed to mimick the standard GCP CloudShell behaviour
# of re-customizing a new CloudShell

if ! [ "${AWS_EXECUTION_ENV:-}" = "CloudShell" ]; then
    return
fi

customize_script=~/.aws_customize_environment

completion_semaphore="/.aws_customize_environment_completed"

if ! [ -f "$customize_script" ]; then
    return
fi

if [ -f "$completion_semaphore" ]; then
    return
fi

# used as a mutex lock
mkdir /tmp/aws_customize_environment.lock || return

{

    bash ~/.aws_customize_environment &&

    sudo UMASK=0044 touch "$completion_semaphore" &

} > /var/log/customize_environment 2>&1
