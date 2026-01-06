--
--  Author: Hari Sekhon
--  Date: 2026-01-05 13:32:14 -0500 (Mon, 05 Jan 2026)
--
--  vim:ts=4:sts=4:sw=4:et
--
--  https///github.com/HariSekhon/DevOps-Bash-tools
--
--  License: see accompanying Hari Sekhon LICENSE file
--
--  If you're using my code you're welcome to connect with me on LinkedIn
--  and optionally send me feedback to help steer this or other code I publish
--
--  https://www.linkedin.com/in/HariSekhon
--

-- ========================================================================= --
--                      MPV Lua Resume Conditions Script
-- ========================================================================= --

-- luacheck: globals mp

-- only resume for videos longer than 10 minutes
local min_length = 600

-- only resume if more than 5 minutes in
local min_watch_time = 300

-- only resume for videos with these file extensions
local allowed_ext = {
    avi  = true,
    mkv  = true,
    mp4  = true,
    part = true, -- for incomplete files
}

-- disable mpv's automatic resume saving globally
mp.set_property("save-position-on-quit", "no")

local should_resume = false

-- used just to capture home dir for automatic pathing if $HOME is somehow not set
local function shell(cmd)
    local f = io.popen(cmd)
    if not f then return "" end
    local out = f:read("*a") or ""
    f:close()
    return out:gsub("%s+$", "")
end

local home = os.getenv("HOME") or shell("cd && pwd")

 -- path prefixes - only save for media files under these directories
local allowed_dirs = {
    --"/mnt/media/videos/",
    home .. "/Downloads/",
}

mp.register_event("file-loaded", function()
    local path = mp.get_property("path", "")
    local duration = mp.get_property_number("duration", 0)

    if duration < min_length then
        mp.set_property("save-position-on-quit", "no")
        return
    end

    -- only save on quit for these file extensions
    local ext = path:match("^.+%.([^./]+)$")
    if not ext or not allowed_ext[ext:lower()] then
        mp.set_property("save-position-on-quit", "no")
        return
    end

    -- only resume for videos with these path prefixes
    for _, dir in ipairs(allowed_dirs) do
        if path:sub(1, #dir) == dir then
            should_resume = true
            -- clashes with shutdown event handler logic now
            --mp.set_property("save-position-on-quit", "yes")
            return
        end
    end

    mp.set_property("save-position-on-quit", "no")
end)

mp.register_event("shutdown", function()
    if not should_resume then
        mp.commandv("delete-watch-later-config")
        return
    end

    local pos = mp.get_property_number("time-pos", 0)
    if pos < min_watch_time then
        mp.commandv("delete-watch-later-config")
        return
    end

    mp.commandv("write-watch-later-config")
end)
