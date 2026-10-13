#!/usr/bin/env osascript
--  vim:ts=4:sts=4:sw=4:et
--
--  Author: Hari Sekhon
--  Date: 2024-10-13 20:26:31 +0300 (Sun, 13 Oct 2024)
--
--  https///github.com/HariSekhon/DevOps-Bash-tools
--
--  License: see accompanying Hari Sekhon LICENSE file
--
--  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
--
--  https://www.linkedin.com/in/HariSekhon
--

-- ============================================================================ #
--                             A p p l e S c r i p t
-- ============================================================================ #

-- Gets the list of Applications running in the name format that can be passed to
-- the adjacent script set_frontmost_process.scpt

tell application "System Events"
    set appList to (name of every application process)
end tell

set output to ""

repeat with appName in appList
    set output to output & appName & "\n"
end repeat

-- strip trailing newline
set output to text 1 thru -2 of output

-- doesn't come out right due to carriage returns
--do shell script "echo " & quoted form of output
-- even this outputs carriage returns
--do shell script "echo " & quoted form of output & " | tr '\r' '\n'"

-- annoying pop-up
--display dialog output as text

-- outputs to stderr instead of stdout, use implicit print of last value instead
--log output
output

-- output is unsorted and sorting in Applescript requires crude in-code sorting like Bubblescript to passing array out
-- to shell sort and back which results in a string formatting output one character per line BS, just wrap this in quick
-- shell it's simpler
