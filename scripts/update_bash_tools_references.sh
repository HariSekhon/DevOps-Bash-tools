#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: Makefile README.md Jenkinsfile *.yaml *.yml */*.sh *.sh
#
#  Author: Hari Sekhon
#  Date: 2023-05-10 00:44:52 +0100 (Wed, 10 May 2023)
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Updates references to bash-tools/ or bash_tools in repos using this as a submodule to account for the repo re-org
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<files>"

help_usage "$@"

min_args 1 "$@"

# uniform prefixes on scripts matching their directory names
prefixes='
git
python
perl
github
gitlab
bitbucket
azure_devops
kubernetes
circleci
buildkite
jenkins
mysql
postgres
mp3
pingdom
shippable
teamcity
spotify
terraform
travis
vagrant
wercker
kafka
aws
gcp
docker
drone
codeship
'

# directory script_prefix mappings
mappings='
lib utils.sh
checks check
checks run

gcp gke
gcp gce
gcp gcr
gcp bigquery

bigdata cloudera
bigdata hadoop
bigdata hdfs
bigdata hive
bigdata impala
bigdata beeline
bigdata zookeeper

bin atlassian_ip_ranges.sh
bin azure_info.sh
bin center.sh
bin clean_caches.sh
bin crt_hash.sh
bin csv_header_indices.sh
bin curl_auth.sh
bin datadog_api.sh
bin decomment.sh
bin delete_empty_dirs.sh
bin digital_ocean_api.sh
bin disable_swap.sh
bin dnsjson.sh
bin elasticsearch_decommission_node.sh
bin exec_interactive.sh
bin find
bin grep_or_append.sh
bin headtail.sh
bin jira_api.sh
bin json2yaml.sh
bin jsondiff.sh
bin jvm
bin keycloak.sh
bin kong_api.sh
bin ldap
bin ldapsearch.sh
bin lint.sh
bin login.sh
bin ngrok_api.sh
bin progress_dots.sh
bin random
bin retry.sh
bin run.sh
bin sbtw
bin scan_duplicate_macs.sh
bin shellcheck.sh
bin split.sh
bin sqlite.sh
bin ssl
bin traefik_api.sh
bin uniq_chars.sh
bin url
bin vault
bin word_frequency.sh
bin yaml2json.sh

configs .vimrc

cicd checkov_resource_count.sh
cicd checkov_resource_count_all.sh
cicd codefresh_cancel_delayed_builds.sh
cicd concourse.sh
cicd coveralls_latest.sh
cicd fly.sh
cicd generate_status_page.sh
cicd gerrit.sh
cicd gerrit_projects.sh
cicd gocd.sh
cicd gocd_api.sh
cicd octopus_api.sh
cicd run_latest_tests.sh
cicd run_tests.sh
cicd selenium_hub_wait_ready.sh
cicd sync_bootstraps_to_adjacent_repos.sh
cicd sync_ci_to_adjacent_repos.sh
cicd sync_configs_to_adjacent_repos.sh

kubernetes argocd
kubernetes datree
kubernetes helm
kubernetes kubeadm
kubernetes kubectl
kubernetes kustomize
kubernetes pluto
kubernetes prometheus.sh

packages install
packages apk
packages apt
packages brew
packages debs
packages rpms
packages nodejs
packages golang
packages ruby
packages yum
'

timestamp "Replacing references"

sed_script="$(
        for prefix in $prefixes; do
            echo "s|bash-tools/${prefix}_|bash-tools/$prefix/${prefix}_|g;"
            echo "s|bash_tools/${prefix}_|bash_tools/$prefix/${prefix}_|g;"
            echo "s|master/${prefix}_|master/$prefix/${prefix}_|g;"
        done
        while read -r directory prefix; do
            if [ -z "$directory" ]; then
                continue
            fi
            # catch prefixes
            echo "s|bash-tools/${prefix}_|bash-tools/$directory/${prefix}_|g;"
            echo "s|bash_tools/${prefix}_|bash_tools/$directory/${prefix}_|g;"
            echo "s|master/${prefix}_|master/$directory/${prefix}_|g;"
            # catch whole scripts
            echo "s|bash-tools/${prefix}\\>|bash-tools/$directory/${prefix}|g;"
            echo "s|bash_tools/${prefix}\\>|bash_tools/$directory/${prefix}|g;"
            echo "s|master/${prefix}\\>|master/$directory/${prefix}|g;"
        done <<< "$mappings"
)"

sed -i "$sed_script" "$@"

echo >&2
timestamp "Search and Replace Done"
echo >&2
timestamp "Remaining references to check:"
echo >&2

ignore_regex="$(for prefix in $prefixes; do echo -n "$prefix|"; done)"
ignore_regex="/(${ignore_regex%|})/"

# need splitting
# shellcheck disable=SC2046
git grep -e 'bash_tools/.' -e 'bash-tools/.' |
grep -Ev -e /setup/ \
        -e "$ignore_regex" \
        -e /bin/ \
        -e /checks/ \
        -e /lib/ \
        -e bash-tools/Makefile.in
