#!/bin/sh
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-02-26 09:31:22 +0000 (Fri, 26 Feb 2021)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Downgrades Pip version if Python < 3 because pip has dropped support for the widely used Python 2.7
#
# Avoids this error:
#
# Traceback (most recent call last):
#   File "/usr/lib64/python2.7/runpy.py", line 162, in _run_module_as_main
#     "__main__", fname, loader, pkg_name)
#   File "/usr/lib64/python2.7/runpy.py", line 72, in _run_code
#     exec code in run_globals
#   File "/usr/lib/python2.7/site-packages/pip/__main__.py", line 21, in <module>
#     from pip._internal.cli.main import main as _main
#   File "/usr/lib/python2.7/site-packages/pip/_internal/cli/main.py", line 60
#     sys.stderr.write(f"ERROR: {exc}")
#                                    ^

set -eu
[ -n "${DEBUG:-}" ] && set -x

if ! pip --version >/dev/null 2>&1; then
    echo "pip --version failed"
    if python --version 2>&1 | grep -q '^Python 2'; then
        echo "Python is legacy version 2"
        echo "Installing pip < 21.0 to be able to run"
        easy_install 'pip < 21.0'
    fi
fi
