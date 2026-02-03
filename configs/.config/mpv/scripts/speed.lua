--
--  Author: Hari Sekhon
--  Date: 2026-02-03 01:15:14 -0300 (Tue, 03 Feb 2026)
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
--                               M P V   S p e e d
-- ========================================================================== --

-- I use this to automatically increase playback speed for some videos using direnv
--
-- Usage:
--
--      MPV_SPEED=2 mpv file.mp4
--
-- Now you can add this to an .envrc and all videos started locally in that dir will increase playback speed:
--
--      export MPV_SPEED=2
--
-- See documentation at:
--
--      https://github.com/HariSekhon/Knowledge-Base/blob/main/direnv.md
--
--      https://github.com/HariSekhon/Knowledge-Base/blob/main/mpv.md

local msg = require("mp.msg")

local mp = require("mp")
--local utils = require("mp.utils")

local script_name = mp.get_script_name()
msg.info(script_name .. " loaded")

local speed = os.getenv("MPV_SPEED")

if speed then
    speed = tonumber(speed)
    if speed and speed > 0 then
        mp.set_property_number("speed", speed)
        mp.msg.info("Playback speed set from MPV_SPEED=" .. speed)
    else
        mp.msg.warn("Invalid MPV_SPEED value")
    end
end
