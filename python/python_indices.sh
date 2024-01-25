#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-19 18:41:58 +0000 (Thu, 19 Mar 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Quick script to convert Python lists to indices for quicker programming debugging / referencing
#
# eg. copy it to stdin from the python debug output - used when figuring out log component indicies
#
# ./python_indices.sh <<< "['one', 'two', 'three']"

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

cat "$@" |
python -c '
from __future__ import print_function
import ast
#import json
import sys
stdin = sys.stdin.read()
my_list = ast.literal_eval(stdin)
#my_list = json.loads(stdin)
i = 0
for item in my_list:
    print(i, item)
    i += 1
'
