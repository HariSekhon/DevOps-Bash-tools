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
--  If you're using my code you're welcome to connect with me on LinkedIn
--  and optionally send me feedback to help steer this or other code I publish
--
--  https://www.linkedin.com/in/HariSekhon
--

-- ========================================================================== --
--             H a m m e r s p o o n   L U A   i n i t   s c r i p t
-- ========================================================================== --

-- luacheck: ignore 631

-- Defines Mac system event handlers such as:
--
--      https://github.com/HariSekhon/Knowledge-Base/blob/main/audio.md#automatically-switch-to-using-multi-output-device-when-connecting-headphones

-- 'hs' is a Hammerspoon global
-- luacheck: globals hs getFirstBlackholeInputDevice getFirstMultiOutputDevice switchToBlackholeInput switchToMultiOutput

--local audioSwitchLog = hs.logger.new('audioSwitch', 'info')
local log = hs.logger.new('audioSwitch', 'info')

local lastSwitch = 0
local debounceTime = 1  -- seconds

--local function getFirstMultiOutputDevice()
--
-- global so we can check it from Hammerspoon Console for debugging
function getFirstMultiOutputDevice()
    local handle = io.popen("/opt/homebrew/bin/SwitchAudioSource -a -t output | grep -i -m1 '^Multi-Output Device'")
    if not handle then return nil end
    local result = handle:read("*l")
    handle:close()
    return result
end

function getFirstBlackholeInputDevice()
    local handle = io.popen("/opt/homebrew/bin/SwitchAudioSource -a -t input | grep -i -m1 '^BlackHole'")
    if not handle then return nil end
    local result = handle:read("*l")
    handle:close()
    return result
end

--local function switchToMultiOutput()
--
-- global so we can check it from Hammerspoon Console for debugging
function switchToBlackholeInput()
    local target = getFirstBlackholeInputDevice()
    if target and #target > 0 then
        hs.execute(string.format('/opt/homebrew/bin/SwitchAudioSource -t input -s "%s"', target))
        hs.notify.new({title="Audio Input Switched", informativeText="Now using: " .. target}):send()
        print("Audio Input Switched to " .. target)
    else
        hs.notify.new(
			{
				title="Audio Switch Failed",
				informativeText="No Blackhole Input Device found - you must first install Blackhole" ..
							    ", see HariSekhon/Knowledge-Base Mac and Audio pages for details"
			}
		):send()
        -- duplicates timestamp in the console and doesn't even prefix info level
        --log.w("Audio Output Switch Failed")
        print("Audio Input Switch Failed")
    end
end

-- global so we can check it from Hammerspoon Console for debugging
function switchToMultiOutput()
    local target = getFirstMultiOutputDevice()
    if target and #target > 0 then
        hs.execute(string.format('/opt/homebrew/bin/SwitchAudioSource -t output -s "%s"', target))
        hs.notify.new({title="Audio Output Switched", informativeText="Now using: " .. target}):send()
        -- duplicates timestamp in the console and doesn't even prefix info level
        --log.i("Audio Output Switched to " .. target)
        print("Audio Output Switched to " .. target)
    else
        hs.notify.new(
			{
				title="Audio Switch Failed",
				informativeText="No Multi-Output Device found - you must first configure one" ..
							    ", see HariSekhon/Knowledge-Base Mac and Audio pages for details"
			}
		):send()
        -- duplicates timestamp in the console and doesn't even prefix info level
        --log.w("Audio Output Switch Failed")
        print("Audio Output Switch Failed")
    end
end

--local prevOutput = hs.audiodevice.defaultOutputDevice():name()

--hs.audiodevice.watcher.setCallback(function(uid, eventName)
hs.audiodevice.watcher.setCallback(function(_, eventName)
    print("Audio event:", eventName, hs.audiodevice.defaultOutputDevice():name())
    -- eventName turns out to be 'nil'
    --if eventName == "dOut " then
        local current = hs.audiodevice.defaultOutputDevice():name()
        if current:match("AirPods") then
            --switchToMultiOutput()
            local now = hs.timer.secondsSinceEpoch()
            if now - lastSwitch > debounceTime then
                lastSwitch = now
                log.d("Debounce OK, switching output")
                hs.timer.doAfter(0.5, switchToBlackholeInput)  -- small delay for macOS to settle
                hs.timer.doAfter(0.5, switchToMultiOutput)  -- small delay for macOS to settle
            else
                log.d("Debounced, skipping switch")
            end
        end
        --prevOutput = current
    --end
end)

hs.audiodevice.watcher.start()
