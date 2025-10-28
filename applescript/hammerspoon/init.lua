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

local function getFirstMultiOutputDevice()
    local handle = io.popen("/opt/homebrew/bin/SwitchAudioSource -a | grep -m1 '^Multi-Output Device'")
    if not handle then return nil end
    local result = handle:read("*l")
    handle:close()
    return result
end

local function switchToMultiOutput()
    local target = getFirstMultiOutputDevice()
    if target and #target > 0 then
        hs.execute(string.format('/opt/homebrew/bin/SwitchAudioSource -s "%s"', target))
        hs.notify.new({title="Audio Output Switched", informativeText="Now using: " .. target}):send()
    else
        hs.notify.new(
			{
				title="Audio Switch Failed",
				informativeText="No Multi-Output Device found - you must first configure one" +
							    ", see HariSekhon/Knowledge-Base Mac and Audio pages for details"
			}
		):send()
    end
end

local prevOutput = hs.audiodevice.defaultOutputDevice():name()

hs.audiodevice.watcher.setCallback(function(uid, eventName)
    if eventName == "dOut " then
        local current = hs.audiodevice.defaultOutputDevice():name()
        if current:match("AirPods") then
            switchToMultiOutput()
        end
        prevOutput = current
    end
end)

hs.audiodevice.watcher.start()
