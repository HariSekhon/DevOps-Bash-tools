--
--  Author: Hari Sekhon
--  Date: 2025-10-28 20:33:02 +0300 (Tue, 28 Oct 2025)
--
--  vim:ts=4:sts=4:sw=4:et
--
--  https///github.com/HariSekhon/DevOps-Bash-tools
--
--  License: see accompanying Hari Sekhon LICENSE file
--
--  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
--
--  https://www.linkedin.com/in/HariSekhon
--

local prevOutput = hs.audiodevice.defaultOutputDevice():name()

hs.audiodevice.watcher.setCallback(function(uid, eventName)
    if eventName == "dOut " then
        local current = hs.audiodevice.defaultOutputDevice():name()
        if current:match("AirPods") then
            hs.execute('/opt/homebrew/bin/SwitchAudioSource -s "Multi-Output Device 1"')
        end
        prevOutput = current
    end
end)

hs.audiodevice.watcher.start()
