#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2015-11-05 23:29:15 +0000 (Thu, 05 Nov 2015)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# don't run this here, it needs to be called explicitly otherwise will fail 'make test deep-clean'
#"$srcdir/check_docker_clean.sh"

if [ -z "${BASH_EXCLUDED_FILES_FUNCTION:-}" ]; then
    if [ -f tests/excluded.sh ]; then
        export BASH_EXCLUDED_FILES_FUNCTION=tests/excluded.sh
    fi
fi

"$srcdir/check_license_exists.sh"
"$srcdir/check_readme_exists.sh"

"$srcdir/check_symlinks.sh"

"$srcdir/check_aws_no_git_credentials.sh"

"$srcdir/check_git_no_merge_remnants.sh"

"$srcdir/check_git_commit_authors.sh"

"$srcdir/check_github_actions_workflows_without_checkout.sh" || :

"$srcdir/check_github_actions_workflow_injection.sh"

if [ -z "${NO_JSON_CHECK:-}" ]; then
    "$srcdir/check_json.sh"
fi

if [ -z "${NO_XML_CHECK:-}" ]; then
    "$srcdir/check_xml.sh"
    if [ -n "${VALIDATE_XML_BASIC:-}" ]; then
        if type -P validate_xml.py &>/dev/null; then
            validate_xml.py .
        fi
    fi
fi

if [ -z "${NO_YAML_CHECK:-}" ]; then
    "$srcdir/check_yaml.sh"
    if [ -n "${VALIDATE_YAML_BASIC:-}" ]; then
        if type -P validate_yaml.py &>/dev/null; then
            validate_yaml.py .
        fi
    fi
fi

"$srcdir/check_bash_duplicate_defs.sh" || :

# duplicate packages eg. in nagios-plugins submodules
# ./pylib/setup/deb-packages-dev.txt:libkrb5-dev
# ./lib/setup/deb-packages-dev.txt:libkrb5-dev
"$srcdir/check_duplicate_packages.sh" || :

"$srcdir/check_duplicate_dependencies.sh"

"$srcdir/check_shebang_non_executable.sh"

# false alerts on the second line of this construct
#
# if [ -x $srcdir/script.sh ]; then
#     $srcdir/script.sh
#
#"$srcdir/check_srcdir_references.sh"

"$srcdir/check_bash_syntax.sh"

# want splitting
# shellcheck disable=SC2046
"$srcdir/check_bash_references.sh" . $(for x in setup lib; do [ -f "$x" ] && echo "$x"; done)

"$srcdir/check_bash_arrays.sh"

"$srcdir/check_shell_commands_dash_protections.sh"

"$srcdir/check_tests_run_qualified.sh"

"$srcdir/check_makefiles.sh"

"$srcdir/check_vagrantfiles.sh"

if [ -z "${NO_DOCKERFILE_CHECK:-}" ]; then
    "$srcdir/check_dockerfiles.sh"
fi

if [ -z "${NO_DOCKER_COMPOSE_CHECK:-}" ]; then
    "$srcdir/check_docker_compose.sh"
fi

if [ -z "${NO_ANSIBLE_PLAYBOOK_CHECK:-}" ]; then
    "$srcdir/check_ansible_playbooks.sh"
fi

# this is usually run after build, no point testing again
if [ -z "${NO_MAVEN_POM_CHECK:-}" ]; then
    "$srcdir/check_maven_pom.sh"
fi

# this is usually run after build, no point testing again
if [ -z "${NO_GRADLE_BUILD_CHECK:-}" ]; then
    "$srcdir/check_gradle_build.sh"
fi

# =======
# XXX: not enabling by default because too simplistic for real projects, likely to cause cross-reference breakages
if [ -n "${GROOVYC_CHECK:-}" ]; then
    "$srcdir/check_groovyc.sh"
fi

if [ -n "${JAVAC_CHECK:-}" ]; then
    "$srcdir/check_javac.sh"
fi
# =======

if [ -z "${NO_PERL_SYNTAX_CHECK:-}" ]; then
    "$srcdir/check_perl_syntax.sh"
fi

if [ -z "${NO_RUBY_SYNTAX_CHECK:-}" ]; then
    "$srcdir/check_ruby_syntax.sh"
fi

if [ -z "${NO_PYTHON_COMPILE:-}" ]; then
    "$srcdir/../python/python_compile.sh"
fi

if [ -z "${NO_PYTHON_MISC_CHECK:-}" ]; then
    "$srcdir/check_python_misc.sh"
fi

if [ -z "${NO_PYTHON_ASSERT_CHECK:-}" ]; then
    WARN_ONLY=1 "$srcdir/check_python_asserts.sh"
fi

if [ -z "${NO_PYTHON_EXCEPTION_PASS_CHECK:-}" ]; then
    "$srcdir/check_python_exception_pass.sh"
fi

if [ -z "${NO_PYTHON_PYLINT_CHECK:-}" ]; then
    "$srcdir/check_python_pylint.sh"
fi

if [ -z "${NO_JAVASCRIPT_ESLINT_CHECK:-}" ]; then
    "$srcdir/check_javascript_eslint.sh"
fi

#"$srcdir/../python/python3.sh"

# this is usually run after build, no point testing again
#. "$srcdir/check_sbt_build.sh"

"$srcdir/check_readme_badges.sh"

if [ -z "${NO_CIRCLECI_CHECK:-}" ]; then
    "$srcdir/check_circleci_config.sh"
fi
if [ -z "${NO_CONCOURSE_CHECK:-}" ]; then
    "$srcdir/check_concourse_config.sh"
fi
if [ -z "${NO_CODEFRESH_CHECK:-}" ]; then
    "$srcdir/check_codefresh_config.sh"
fi
if [ -z "${NO_DRONE_CHECK:-}" ]; then
    "$srcdir/check_drone_yml.sh"
fi
if [ -z "${NO_GITLAB_CHECK:-}" ]; then
    "$srcdir/check_gitlab_ci_yml.sh"
fi
if [ -z "${NO_TRAVISCI_CHECK:-}" ]; then
    "$srcdir/check_travis_yml.sh" || :  # broken library dependency highline on Fedora
fi
if ! is_CI &&
   [ -n "${SHIPPABLE_TOKEN:-}" ]; then
    "$srcdir/check_shippable_readme_ids.sh"
fi

"$srcdir/check_tld_chars.sh"

"$srcdir/check_no_tabs.sh"

# too heavy to run all the time, isExcluded on every file has really bad performance
"$srcdir/check_whitespace.sh"

"$srcdir/check_no_suid_guid_shell_scripts.sh"

# ========================================
# Expensive checks, do separately in CI/CD
#
#"$srcdir/check_url_links.sh"

#"$srcdir/check_pytools.sh"

#for script in $(find . -name 'test*.sh'); do
#    "$srcdir/$script" -vvv
#done

time_taken "$bash_tools_start_time" "Bash Tools All Checks Completed in"
section2 "Bash Tools All Checks Completed"
echo
