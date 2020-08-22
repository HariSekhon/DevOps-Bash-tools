#!/usr/bin/env bash
# shellcheck disable=SC1090
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2015-11-05 23:29:15 +0000 (Thu, 05 Nov 2015)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -z "${PROJECT:-}" ]; then
    export PROJECT=bash-tools
fi

pushd "$srcdir" >/dev/null

# shellcheck source=lib/utils.sh
. "lib/utils.sh"

# shellcheck source=lib/docker.sh
. "lib/docker.sh"

popd >/dev/null || :

section "Running Bash Tools ALL"

# Breaks on CentOS Docker without this, although works on Debian, Ubuntu and Alpine without
export LINES="${LINES:-25}"
export COLUMNS="${COLUMNS:-80}"

declare_if_inside_docker

bash_tools_start_time="$(start_timer)"

# do help afterwards for Spark to be downloaded, and then help will find and use downloaded spark for SPARK_HOME
#"$srcdir/help.sh"

# this is usually run after build, no point testing again
#. "$srcdir/check_gradle_build.sh"

# don't run this here, it needs to be called explicitly otherwise will fail 'make test deep-clean'
#"$srcdir/check_docker_clean.sh"

"$srcdir/check_aws_no_git_credentials.sh"

"$srcdir/check_git_no_merge_remnants.sh"

"$srcdir/check_git_commit_authors.sh"

"$srcdir/check_bash_duplicate_defs.sh" || :

# duplicate packages eg. in nagios-plugins submodules
# ./pylib/setup/deb-packages-dev.txt:libkrb5-dev
# ./lib/setup/deb-packages-dev.txt:libkrb5-dev
"$srcdir/check_duplicate_packages.sh" || :

"$srcdir/check_duplicate_dependencies.sh"

"$srcdir/check_non_executable_scripts.sh"

"$srcdir/check_tests_run_qualified.sh"

. "$srcdir/check_makefiles.sh"

. "$srcdir/check_vagrantfiles.sh"

# this is usually run after build, no point testing again
#. "$srcdir/check_maven_pom.sh"

. "$srcdir/check_perl_syntax.sh"

. "$srcdir/check_ruby_syntax.sh"

. "$srcdir/python_compile.sh"

. "$srcdir/check_python_misc.sh"

WARN_ONLY=1 . "$srcdir/check_python_asserts.sh"

. "$srcdir/check_python_exception_pass.sh"

. "$srcdir/check_python_pylint.sh"

#"$srcdir/python3.sh"

# this is usually run after build, no point testing again
#. "$srcdir/check_sbt_build.sh"

. "$srcdir/check_bash_syntax.sh"

. "$srcdir/check_bash_arrays.sh"

"$srcdir/check_readme_badges.sh"

"$srcdir/check_travis_yml.sh"
"$srcdir/check_circle_ci_yml.sh"
"$srcdir/check_gitlab_ci_yml.sh"
"$srcdir/check_drone_yml.sh"
if ! is_CI &&
   [ -n "${SHIPPABLE_TOKEN:-}" ]; then
    "$srcdir/check_shippable_readme_ids.sh"
fi
"$srcdir/check_concourse_config.sh"
"$srcdir/check_codefresh_config.sh"

. "$srcdir/check_tld_chars.sh"

# too heavy to run all the time, isExcluded on every file has really bad performance
. "$srcdir/check_whitespace.sh"

. "$srcdir/check_no_tabs.sh"

. "$srcdir/check_dockerfiles.sh"

. "$srcdir/check_docker_compose.sh"

# TODO: enable later and tweak configs
#. "$srcdir/check_ansible_playbooks.sh"
#. "$srcdir/check_json.sh"
#. "$srcdir/check_yaml.sh"

#"$srcdir/check_pytools.sh"

#for script in $(find . -name 'test*.sh'); do
#    "$srcdir/$script" -vvv
#done

time_taken "$bash_tools_start_time" "Bash Tools All Checks Completed in"
section2 "Bash Tools All Checks Completed"
echo
