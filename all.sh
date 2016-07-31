#!/usr/bin/env bash
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

. "$srcdir/utils.sh"

section "Running Bash Tools ALL"

# do help afterwards for Spark to be downloaded, and then help will find and use downloaded spark for SPARK_HOME
#"$srcdir/help.sh"

# this is usually run after build, no point testing again
#. "$srcdir/check_gradle_build.sh"

. "$srcdir/check_makefile.sh"

# this is usually run after build, no point testing again
#. "$srcdir/check_maven_pom.sh"

. "$srcdir/check_perl_syntax.sh"

. "$srcdir/check_ruby_syntax.sh"

. "$srcdir/python_compile.sh"

. "$srcdir/python_find_quit.sh"

. "$srcdir/pylint.sh"

#"$srcdir/python3.sh"

# this is usually run after build, no point testing again
#. "$srcdir/check_sbt_build.sh"

. "$srcdir/check_shell_syntax.sh"

. "$srcdir/check_travis_yml.sh"

# too heavy to run all the time, isExcluded on every file has really bad performance
#"$srcdir/whitespace.sh"

#for script in $(find . -name 'test*.sh'); do
#    "$srcdir/$script" -vvv
#done

section "Bash Tools All Checks Completed"
