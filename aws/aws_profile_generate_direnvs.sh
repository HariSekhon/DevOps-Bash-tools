#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-11-24 04:21:37 +0400 (Sun, 24 Nov 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Generates subdirectories containing the config.ini and .envrc for every AWS profile found
in the given file or \$AWS_CONFIG_FILE or ~/.aws/config

Useful to take a large generated AWS config.ini from script:

    aws_sso_configs.sh

and then split it into subdirectories for direnvs
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<aws_config>]"

help_usage "$@"

max_args 1 "$@"

config="${1:-${AWS_CONFIG_FILE:-$HOME/.aws/config}}"

if ! [ -f "$config" ]; then
    die "ERROR: file does not exist: $config"
fi

grep -Eo "^[[:space:]]*\[profile .+\]" "$config" |
sed 's/.*\[profile//; s/\].*$//' |
while read -r profile; do
    if is_blank "$profile"; then
        continue
    fi
    if ! [[ "$profile" =~ ^[[:alnum:]_-]+$ ]]; then
        warn "profile '$profile' failed regex validation, skipping for safety..."
        continue
    fi
    mkdir -p "$profile"
    subconfig="$profile/config.ini"
    if ! [ -f "$subconfig" ]; then
        timestamp "Generating $subconfig"
        cat > "$subconfig" <<EOF
#!/usr/bin/env bash
#
# Generated using ${0##*/} from:
#
#   https://github.com/HariSekhon/DevOps-Bash-tools

EOF
        "$srcdir/../data/ini_grep_section.sh" "profile $profile" "$config" >> "$subconfig"
        sed -i '' -e '${/^$/d}' "$subconfig"
        if ! [ -s "$subconfig" ]; then
            die "Failed to generate $subconfig"
        fi
    fi
    envrc="$profile/.envrc"
    if ! [ -f "$envrc" ]; then
        # AWS_ACCOUNT_ID is automatically inferred by envrc code from AWS_PROFILE which is all we need
        #account_id="$(grep -Eo '^[[:space:]]*[[:alnum:]_]*account_id[[:space:]]*=[[:space:]][[:digit:]]+' "$subconfig" || :)"
        #if [ -z "$account_id" ]; then
        #    die "Failed to determine AWS Account ID from $subconfig"
        #fi
        #echo "export AWS_ACCOUNT_ID=$aws_account_id" >> "$envrc"
        timestamp "Generating $envrc" # with AWS_PROFILE=$profile"
        cat >> "$envrc" <<EOF
# Generated using ${0##*/} from:
#
#   https://github.com/HariSekhon/DevOps-Bash-tools

export AWS_PROFILE=$profile

#export EKS_CLUSTER=
#export EKS_NAMESPACE=

# if copying this .envrc to terraform / terragrunt directories in a different part of the repo:
#
#git_root="$(git rev-parse --show-toplevel)"
#
# shellcheck disable=SC1091
#. "\$git_root/aws/.envrc"

. ../.envrc
EOF
    fi
done
