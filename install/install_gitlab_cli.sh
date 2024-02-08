#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-01-11 10:07:36 +0000 (Tue, 11 Jan 2022)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Installs GitLab CLI

Once installed, configure authentication by creating a Personal Access Token (PAT) here:

    https://gitlab.com/-/user_settings/personal_access_tokens

and then exporting that as an environment variable:

    export GITLAB_TOKEN=...
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

export PATH="$PATH:$HOME/bin"

help_usage "$@"

version="${1:-latest}"

ext="tar.gz"

export ARCH_X86_64=amd64
export OS_DARWIN=macOS

export RUN_VERSION_ARG=1

# https://gitlab.com/gitlab-org/cli/-/releases/v1.36.0/downloads/glab_1.36.0_macOS_x86_64.tar.gz

"$srcdir/../gitlab/gitlab_install_binary.sh" gitlab-org/cli "glab_{version}_{os}_{arch}.$ext" "$version" "bin/glab"
