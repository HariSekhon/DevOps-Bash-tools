#!/usr/bin/env osascript
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-05-19 01:44:50 +0300 (Mon, 19 May 2025)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# ============================================================================ #
#           Shortens the selected text in the prior window
# ============================================================================ #

# - Replaces "and" with "&"
# - Removes multiple blank lines between paragraphs (which result from the pbpaste/pbcopy pipeline otherwise)
#
# I use this a lot for LinkedIn comments due to the short 1250 character limit

# switch to previous window
tell application "System Events"
	key down command
	keystroke tab
	key up command
end tell

delay 0.3

# copy the selected text
tell application "System Events"
	keystroke "c" using command down
end tell

delay 0.1

# - replace occurrences of the word "and" with "&" using sed with word boundaries
# - crush out multiple blank lines to a single blank line between paragraphs
#   - this is correct the pbpaste | pbcopy copying back multiplying the blank lines
do shell script "pbpaste | gsed -E 's/\\band\\b/\\&/g' | cat -s | pbcopy"

delay 0.1

# paste the modified text over the original selection
tell application "System Events"
	keystroke "v" using command down
end tell
