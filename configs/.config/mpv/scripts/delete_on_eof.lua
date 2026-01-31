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

local msg = require("mp.msg")

local enable = os.getenv("MPV_DELETE_ON_EOF")
if not enable then
    msg.info("MPV_DELETE_ON_EOF environment variable not set, script disabled")
    return
end

local mp = require("mp")
local utils = require("mp.utils")

local script_name = mp.get_script_name()
msg.info(script_name .. " loaded")

-- have to store the path at file-loaded time because it is cleared by the time we hit end-file
local path = nil

mp.register_event("file-loaded", function()
    path = mp.get_property("stream-open-filename")
    msg.info("file-loaded path: " .. tostring(path))
end)

-- checked timing of when the stream-open-filename was available, it was cleared later by end-file
--mp.add_timeout(0.01, function()
--    local path = mp.get_property("stream-open-filename")
--    msg.info("delayed path=" .. tostring(path))
--end)

mp.register_event("end-file", function(event)
    msg.info("end-file event fired, reason: " .. tostring(event.reason))
    if event.reason ~= "eof" then
        msg.info("end-file event is not an EOF, doing nothing")
        return
    end

    msg.info("path=" .. tostring(path))
    if not path then
        msg.error("Failed to get path, aborting")
        return
    end
    if path:match("^[%w+.-]+://") then
        msg.warn("Not a local file, skipping")
        return
    end
    --if path then
    --    path = utils.join_path(utils.getcwd(), path)
    --end

    msg.warn("Deleting video file due to MPV_DELETE_ON_EOF environment variable being set: " .. tostring(path))
    local result = utils.subprocess({
        args = { "rm", "-vf", path },
        cancellable = false,
    })
    msg.info("rm exit status=" .. tostring(result.status))
    if result.status == 0 then
        mp.osd_message("Deleted file: " .. tostring(path))
    end
end)
