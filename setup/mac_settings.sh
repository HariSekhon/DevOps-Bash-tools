#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-01 21:01:50 +0000 (Sun, 01 Mar 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# ============================================================================ #
#                            M a c   S e t t i n g s
# ============================================================================ #

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================================ #
#                  B a c k u p   B e f o r e   A p p l y i n g
# ============================================================================ #

# If you do mess something up, you can also go in to Time Machine and get the ~/Library/Preferences/ plist back,
# 'defaults import' it and then restart the daemons

backup_dir="$srcdir/mac_settings"

mkdir -pv "$backup_dir"

backup="$backup_dir/settings-backup-$(date '+%F_%H%M%S')-$HOSTNAME.json"

echo "creating ~/.bash_sessions_disable touchfile to stop 'Restore sessions' on every shell open"
touch ~/.bash_sessions_disable
echo

echo "backing up mac settings to $backup before applying new settings"
defaults read > "$backup"

# ============================================================================ #
# Set Dark Theme without requiring restart

# will prompt to allow Terminal to control System Events which is useful to enable anyway for Apple Scripting eg. ../applescript/*.scpt
osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to 1'

# toggle between light and dark theme by setting it to the opposite of its current setting
#osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to not dark mode'

# ============================================================================ #

# References:
#
# https://ss64.com/osx/defaults.html
#
# https://github.com/herrbischoff/awesome-macos-command-line

# TIP: how to figure out settings keys
#
# 1. defaults read > settings.json
# 2. Make your changes in the UI
# 3. defaults read > settings2.json
# 4. diff settings.json settings2.json

# This now automated using the adjacent script mac_diff_settings.sh
# which saves copies of the before and after configs and diffs them,
# before dropping in to the new config to explore the full settings paths

# "Apple Global Domain" === NSGlobalDomain
defaults write NSGlobalDomain AppleActionOnDoubleClick Maximize
defaults write NSGlobalDomain AppleInterfaceStyle -string Dark
defaults write NSGlobalDomain AppleEnableMenuBarTransparency -bool true
defaults write NSGlobalDomain AppleSpacesSwitchOnActivate 1
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool true
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain AppleMetricUnits -bool true
defaults write NSGlobalDomain AppleTemperatureUnit -string "Celsius"
defaults write NSGlobalDomain com.apple.sound.beep.flash -bool false

defaults write com.apple.menuextra.battery ShowPercent -string "YES"

defaults write com.apple.menuextra.clock DateFormat -string "EEE d MMM  HH:mm"
defaults write com.apple.menuextra.clock FlashDateSeparators -bool false
defaults write com.apple.menuextra.clock IsAnalog -bool false

# Remove Shutdown & Restart buttons at login window
#defaults write com.apple.loginwindow ShutDownDisabled -bool true
#defaults write com.apple.loginwindow RestartDisabled -bool true
#defaults write com.apple.loginwindow LoginwindowText "Your Message"

# turn off the annoying "Application Downloaded from Internet" quarantine warning
#defaults write com.apple.LaunchServices LSQuarantine -bool false

# disable annoying crash prompt
defaults write com.apple.CrashReporter DialogType none  # set to 'prompt' to restore

# disable dashboard widgets (saves RAM)
defaults write com.apple.dashboard mcx-disabled -boolean true

defaults write com.apple.systemuiserver "NSStatusItem Visible com.apple.menuextra.TimeMachine" -bool true
defaults write com.apple.systemuiserver "NSStatusItem Visible com.apple.menuextra.airport"     -bool true
defaults write com.apple.systemuiserver "NSStatusItem Visible com.apple.menuextra.appleuser"   -bool true
defaults write com.apple.systemuiserver "NSStatusItem Visible com.apple.menuextra.battery"     -bool true
defaults write com.apple.systemuiserver "NSStatusItem Visible com.apple.menuextra.bluetooth"   -bool true
defaults write com.apple.systemuiserver "NSStatusItem Visible com.apple.menuextra.volume"      -bool true
defaults write com.apple.systemuiserver "NSStatusItem Visible com.apple.menuextra.clock"       -bool true


# ============================================================================ #
#                                K e y b o a r d
# ============================================================================ #

# fast keyboard repeat and low delay
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain KeyRepeat -int 2

# make Fn key show hotkeys in touch bar on newer Macs
defaults write com.apple.touchbar.agent.PresentationModeFnModes.appWithControlStrip -string fullControlStrip

# ============================================================================ #
#                                T r a c k p a d
# ============================================================================ #

# ============
# tap to click
defaults write com.apple.trackpad forceClick -bool false
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool false
defaults write com.apple.AppleMultitouchTrackpad USBMouseStopsTrackpad -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool false

defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerTapGesture -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerTapGesture -int 0

# ============================
# tap to click on login screen
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# OS version on login screen
defaults write com.apple.loginwindow AdminHostInfo HostName

# ==============
# Trackpad Speed - choose an int/float in the range 0-3:
# 0 = slowest
# 3 = fastest
defaults write com.apple.trackpad.scaling -float 3

# ===========
# right-click
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
# click bottom right corner for right-click - doesn't work
#defaults write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick -int 2
#defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2

# ===============
# Haptic feedback
# 0: Light
# 1: Medium
# 2: Firm
defaults write com.apple.AppleMultitouchTrackpad.FirstClickThreshold -int 0
defaults write com.apple.AppleMultitouchTrackpad.SecondClickThreshold -int 0
defaults write com.apple.AppleMultitouchTrackpad.ForceSuppressed -int 0
defaults write com.apple.AppleMultitouchTrackpad ActuationStrength -int 0

# =======================================
# Enable “natural” (Lion-style) scrolling
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true

# Maximize window when double clicking the bar
defaults write NSGlobalDomain AppleActionOnDoubleClick -string Maximize

# ============================================================================ #
#                                T e r m i n a l
# ============================================================================ #

# use the custom 'Hari' profile
defaults write com.apple.Terminal "Default Window Settings" -string "Hari"
defaults write com.apple.Terminal "Startup Window Settings" -string "Hari"

# ===============
# open maximized:
# - MacBook Pro 15" 2013 has 204 x 59
# - MacBook Pro 15" 2018 has 239 x 72
# - if you're running a 13" Macbook Pro this will be different again, let's infer the size using the current terminal
# - $LINES and $COLUMNS aren't automatically available in a non-interactive script shell, so if not set fall back to 'tput'
#   - tput falls back to 80 cols x 24 lines - too conservative
#     - now instead relying on $COLUMNS and $LINES being exported by shell profile .bash.d/env.sh
#       - this relies on user having already maximized your Terminal window before running this
COLUMNS="${COLUMNS:-$(tput cols)}"
LINES="${LINES:-$(tput lines)}"
# try to squeaze the terminal right to the edges
((COLUMNS+=1))
((LINES+=1))

# this is a blob and cannot be descended in to using 'defaults' command :'-(
# so we load from a saved Terminal -> Preferences -> Profiles -> Hari -> Settings -> Export file and override the $LINES and $COLUMNS
mac_terminal_settings="$(cat "$srcdir/Hari.terminal")"
mac_terminal_settings="${mac_terminal_settings/<integer>239</<integer>$COLUMNS<}"
mac_terminal_settings="${mac_terminal_settings/<integer>72</<integer>$LINES<}"
defaults write com.apple.Terminal "Window Settings" -dict-add Hari "$mac_terminal_settings"

# ============================================================================ #
#                              T a s k   B a r
# ============================================================================ #

defaults write com.apple.controlcenter "NSStatusItem Visible Bluetooth" -int 1

# ============================================================================ #
#               S c r e e n s a v e r   &   H o t   C o r n e r s
# ============================================================================ #

# require password after screensaver
defaults write com.apple.screensaver askForPassword -bool true

# gives 5 secs grace before requiring password in case you accidentally hit a hot corner
defaults write com.apple.screensaver askForPasswordDelay -int 5

# bottom left Hot Corner activates Screensaver
defaults write com.apple.dock wvous-bl-corner -int 5
defaults write com.apple.dock wvous-bl-modifier -int 0

# top right Hot Corner puts display to sleep
defaults write com.apple.dock wvous-tr-corner -int 10
defaults write com.apple.dock wvous-tr-modifier -int 0

# ============================================================================ #
#                             S c r e e n s h o t s
# ============================================================================ #

# save screenshots to Desktop
mkdir -p -v ~/Desktop/Screenshots
# put them under a Screenshots folder, it's cleaner than having them all over your background
defaults write com.apple.screencapture location -string ~/Desktop/Screenshots

defaults write com.apple.screencapture "show-thumbnail" -bool "true"

# save in PNG format (default, other options: BMP, GIF, JPG, PDF, TIFF)
defaults write com.apple.screencapture type -string "png"
#defaults write com.apple.screencapture type JPG

# default screenshot file name
# defaults write com.apple.screencapture name "myScreenShot"

# disable drop shadows in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# killall SystemUIServer

# ============================================================================ #
#                                    D o c k
# ============================================================================ #

# auto-hide Dock
defaults write com.apple.dock autohide -bool true

# make Dock appear on all screens - this is important so that cmd-tab window switching appears there too as it follows the Dock screen
defaults write com.apple.dock appswitcher-all-displays -bool true

# hide non-active apps
# XXX: careful this wipes out your Dock and reversing it to false doesn't restore your Dock items
# If you mess up your Dock it is difficult to regenerate programmatically, so I suggest you go in to Time Machine and get the ~/Library/Preferences/com.apple.dock.plist back, 'defaults import' and then killall Dock to get back your icons
#defaults write com.apple.dock static-only -bool true

# pop-up instantly
defaults write com.apple.dock autohide-delay         -float 0  # secs
# disappear instantly
defaults write com.apple.dock autohide-time-modifier -float 0

# speed up Mission Control animations
defaults write com.apple.dock expose-animation-duration -float 0.12

# revert to default dock delays
#defaults delete com.apple.dock autohide-delay
#defaults delete com.apple.dock autohide-time-modifier

# stop apps saving to iCloud by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# enable Dashboard with widgets
#defaults write com.apple.dashboard mcx-disabled -boolean false

# make hidden app icons translucent
defaults write com.apple.Dock showhidden -bool true

# show indicator lights for open applications in the dock
defaults write com.apple.dock show-process-indicators -bool true

# disable bouncing icons
defaults write com.apple.dock no-bouncing -bool true

# don't minimize to applications, it's more obvious when they're on the far right
defaults write com.apple.dock minimize-to-application -bool false

defaults write com.apple.dock mineffect scale  # faster than 'genie'

# don't leave closed apps in the dock
defaults write com.apple.dock show-recents -bool no
defaults write com.apple.dock recent-apps -array # intentionally empty

#killall Dock

# ============================================================================ #
#                           M i s c e l l a n e o u s
# ============================================================================ #

# Use network time
sudo systemsetup -setusingnetworktime on

# auto-restart after a system freeze
sudo systemsetup -setrestartfreeze on

# restore windows after reboot
defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool true
defaults write -g NSQuitAlwaysKeepsWindows -bool true

# Check for software updates daily, not just once per week
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

# Disable local Time Machine snapshots
#sudo tmutil disable local

defaults write com.apple.TimeMachine AutoBackup -int 1
# default 3600 = 1 hour backup interval
#sudo defaults write /System/Library/Launch Daemons/com.apple.backupd-auto StartInterval -int 1800

# Increase sound quality for Bluetooth headphones/headsets
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

# Expanded print options
defaults write -g PMPrintingExpandedStateForPrint -bool true
defaults write -g PMPrintingExpandedStateForPrint2 -bool true

# Expand file save dialog
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# ============================================================================ #
#                                  F i n d e r
# ============================================================================ #

# TODO: set Finder to columns that are auto-wide

# hide Desktop icons
#defaults write com.apple.finder CreateDesktop -bool false

# set Desktop as the default location for new Finder windows
#defaults write com.apple.finder NewWindowTarget -string "PfDe"
# set Downloads as the default location for new Finder windows
defaults write com.apple.finder NewWindowTarget -string "PfLo"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Downloads/"
defaults write com.apple.finder NSNavLastRootDirectory -string "file://${HOME}/Downloads/"

# default to Details view
defaults write com.apple.finder FXPreferredViewStyle        -string Nlsv
defaults write com.apple.finder TrashViewSettings           -string Nlsv
defaults write com.apple.finder SearchRecentsSavedViewStyle -string Nlsv

# allow copying from Quick Look preview
defaults write com.apple.finder QLEnableTextSelection -bool true

# show the ~/Library folder
chflags nohidden ~/Library

# show Status Bar
defaults write com.apple.finder ShowStatusBar -bool true

# Empty Trash securely by default
defaults write com.apple.finder EmptyTrashSecurely -bool true

# Automatically remove Trash > 30 days
defaults write com.apple.finder FXRemoveOldTrashItems -bool true

# don't disable the warning before emptying the Trash in case you hit Cmd-Del then Cmd-Shift-Del data could be lost
defaults write com.apple.finder WarnOnEmptyTrash -bool true

# show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# show the scroll bar all the time
defaults write NSGlobalDomain AppleShowScrollBars -string WhenScrolling # or Automatic or Always

# close always confirms changes
defaults write NSGlobalDomain NSCloseAlwaysConfirmsChanges -bool true

# show path bar
defaults write com.apple.finder ShowPathbar -bool true

# display full POSIX path as Finder window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Show icons for hard drives, servers, and removable media on the desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop         -bool true
defaults write com.apple.finder ShowMountedServersOnDesktop     -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop     -bool true

# Avoid creating .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
# Don't create .DS_Store files on USB drives - probably don't want this if you use external hard drives a lot
#defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true


# Automatically open a new Finder window when a volume is mounted
defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
defaults write com.apple.finder    OpenWindowForNewRemovableDisk -bool true

# Enable 'Quit' menu item in Finder
#defaults write com.apple.finder QuitMenuItem -bool true
defaults write com.apple.finder QuitMenuItem -bool false

#killall Finder

# ============================================================================ #
#                                 P r e v i e w
# ============================================================================ #

# set to false to not re-open previous documents from last Preview session
defaults write com.apple.Preview NSQuitAlwaysKeepsWindows -bool true

#killall Preview

# ============================================================================ #
#                       A u t o m a t i c   U p d a t e s
# ============================================================================ #

# Auto check for updates
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

# Auto download updates in background
defaults write com.apple.SoftwareUpdate AutomaticDownload -bool true

# Don't install App updates automatically
defaults write com.apple.commerce AutoUpdate -bool false

# Don't install MacOS updates automatically
defaults write com.apple.commerce AutoUpdateRestartRequired -bool false

# Don't install Security updates automatically
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -bool false

# ============================================================================ #

# Enable AirDrop over Ethernet and on unsupported Macs running Lion
#defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

# Change indexing order and disable some search results
#defaults write com.apple.spotlight orderedItems -array \
#   '{"enabled" = 1;"name" = "APPLICATIONS";}' \
#   '{"enabled" = 1;"name" = "SYSTEM_PREFS";}' \
#   '{"enabled" = 0;"name" = "DIRECTORIES";}' \
#   '{"enabled" = 0;"name" = "PDF";}' \
#   '{"enabled" = 0;"name" = "FONTS";}' \
#   '{"enabled" = 0;"name" = "DOCUMENTS";}' \
#   '{"enabled" = 0;"name" = "MESSAGES";}' \
#   '{"enabled" = 0;"name" = "CONTACT";}' \
#   '{"enabled" = 0;"name" = "EVENT_TODO";}' \
#   '{"enabled" = 0;"name" = "IMAGES";}' \
#   '{"enabled" = 0;"name" = "BOOKMARKS";}' \
#   '{"enabled" = 0;"name" = "MUSIC";}' \
#   '{"enabled" = 0;"name" = "MOVIES";}' \
#   '{"enabled" = 0;"name" = "PRESENTATIONS";}' \
#   '{"enabled" = 0;"name" = "SPREADSHEETS";}' \
#   '{"enabled" = 0;"name" = "SOURCE";}' \
#   '{"enabled" = 1;"name" = "MENU_DEFINITION";}' \
#   '{"enabled" = 0;"name" = "MENU_OTHER";}' \
#   '{"enabled" = 0;"name" = "MENU_CONVERSION";}' \
#   '{"enabled" = 1;"name" = "MENU_EXPRESSION";}' \
#   '{"enabled" = 0;"name" = "MENU_WEBSEARCH";}' \
#   '{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}'

# ============================================================================ #

echo "Some settings won't take effect until you restart the processes. When you've saved your work and are ready, run:

sudo killall Finder
sudo killall Dock
sudo killall cfprefsd
sudo killall SystemUIServer
sudo killall Terminal
"
