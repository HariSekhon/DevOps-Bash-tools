--
--  Author: Hari Sekhon
--  Date: 2026-01-31 09:14:37 -0400 (Sat, 31 Jan 2026)
--
--  vim:ts=4:sts=4:sw=4:et
--
--  https///github.com/HariSekhon/DevOps-Bash-tools
--
--  License: see accompanying Hari Sekhon LICENSE file
--
--  If you're using my code you're welcome to connect with me on LinkedIn
--  and optionally send me feedback
--
--  https://www.linkedin.com/in/HariSekhon
--
--

-- ========================================================================== --
--           M P V   D e l e t e   o n   P l a y   C o m p l e t i o n
-- ========================================================================== --

-- I use this to automatically delete videos I only ever intend to watch once
--
-- Usage:
--
--      MPV_DELETE_ON_EOF=1 mpv file.mp4

local enable = os.getenv("MPV_DELETE_ON_EOF")
if not enable then
    return
end

local mp = require("mp")

local utils = require("mp.utils")

mp.register_event("end-file", function(event)
    if event.reason ~= "eof" then
        return
    end

    local path = mp.get_property("path")
    if not path then
        return
    end

    utils.subprocess({
        args = { "rm", "-f", path },
        cancellable = false,
    })
end)
