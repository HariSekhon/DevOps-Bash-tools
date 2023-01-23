#!/usr/bin/env python3
#  coding=utf-8
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-12-05 22:03:56 +0000 (Mon, 05 Dec 2022)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

"""

Detects whether the macOS screen is locked

If locked, prints 'true' and returns exit code 0
If unlocked, prints 'false' and returns exit code 1

Useful to avoid automated keystrokes or mouse_clicks while on locked screen which can make it hard to login back in

"""

from __future__ import print_function

import sys
import Quartz

if __name__ == '__main__':
    # false positive
    # pylint: disable=no-member
    d = Quartz.CGSessionCopyCurrentDictionary()
    if 'CGSSessionScreenIsLocked' in d and d['CGSSessionScreenIsLocked'] == 1:
        print('true')
        sys.exit(0)
    else:
        print('false')
        sys.exit(1)
