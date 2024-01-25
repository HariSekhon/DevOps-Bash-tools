#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-08-02 12:21:34 +0100 (Tue, 02 Aug 2022)
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
#                                C i r c l e C I
# ============================================================================ #

bash_tools="${bash_tools:-$(dirname "${BASH_SOURCE[0]}")/..}"

if ! type github_owner_repo &>/dev/null; then
    # shellcheck disable=SC1090,SC1091
    . "$bash_tools/.bash.d/git.sh"
fi

circleci_debug(){
    circleci_project_set_env_vars.sh github/$(github_owner_repo) DEBUG=1
}

circleci_undebug(){
    circleci_project_delete_env_vars.sh github/$(github_owner_repo) DEBUG
}
