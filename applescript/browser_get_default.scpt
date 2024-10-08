#!/usr/bin/env osascript
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-02-28 13:05:26 +0000 (Mon, 28 Feb 2022)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Returns the default browser in Apple application name usable format, eg. "Google Chrome"

set defaultBrowser to do shell script "defaults read \\
    ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure \\
    | awk -F'\"' '/http;/{print window[(NR)-1]}{window[NR]=$2}'"

if defaultBrowser is "" or defaultBrowser contains "safari" then
    set defaultBrowser to "Safari"
else if defaultBrowser contains "chrome" then
    set defaultBrowser to "Google Chrome"
else if defaultBrowser contains "firefox" then
    set defaultBrowser to "Firefox"
else
    set defaultBrowser to "Unknown"
end if
