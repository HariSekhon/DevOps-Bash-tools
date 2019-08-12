#!/usr/bin/env bash
#  shellcheck disable=SC2139
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

# ============================================================================ #
#                                   $ P A T H
# ============================================================================ #

# general path additions not tied to bigger <technology>.sh

if [ -d /usr/local/parquet-tools ]; then
    add_PATH "/usr/local/parquet-tools"
fi
