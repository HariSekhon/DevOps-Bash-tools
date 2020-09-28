#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-01 21:01:50 +0000 (Sun, 01 Mar 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# ============================================================================ #
#                            M a c   S e t t i n g s
# ============================================================================ #

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# ============================================================================ #

# TIP: how to figure out settings keys
#
# 1. defaults read > settings.json
# 2. Make your changes in the UI
# 3. defaults read > settings2.json
# 4. diff settings.json settings2.json

# ============================================================================ #
#                                T r a c k p a d
# ============================================================================ #

# ============
# tap to click
defaults write com.apple.trackpad forceClick -bool false
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool false
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
#                                K e y b o a r d
# ============================================================================ #

# "Apple Global Domain" === NSGlobalDomain
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain KeyRepeat -int 2

# make Fn key show hotkeys in touch bar on newer Macs
defaults write com.apple.touchbar.agent.PresentationModeFnModes.appWithControlStrip -string fullControlStrip

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
#   - tput comes out to 80 cols x 70 lines too conservative
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
#                             S c r e e n s a v e r
# ============================================================================ #

# require password immediately after sleep / screen saver
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# enable bottom left Hot Corners to activate Screensaver, require password after 5 seconds
defaults write com.apple.dock wvous-bl-corner -int 5
defaults write com.apple.dock wvous-bl-modifier -int 0

# ============================================================================ #
#                             S c r e e n s h o t s
# ============================================================================ #

# save screenshots to Desktop
defaults write com.apple.screencapture location -string "${HOME}/Desktop"

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

# auto-hide dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock static-only -bool true

# pop-up instantly
defaults write com.apple.dock autohide-delay         -float 0  # secs
# disappear instantly
defaults write com.apple.dock autohide-time-modifier -float 0

# revert to default dock delays
#defaults delete com.apple.dock autohide-delay
#defaults delete com.apple.dock autohide-time-modifier

# hide non-active apps
#defaults write com.apple.dock static-only -bool true

# stop apps saving to iCloud by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# enable Dashboard with widgets
#defaults write com.apple.dashboard mcx-disabled -boolean false

#killall Dock

# ============================================================================ #
#                           M i s c e l l a n e o u s
# ============================================================================ #

# auto-restart after a system freeze
sudo systemsetup -setrestartfreeze on

# Check for software updates daily, not just once per week
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

# Disable local Time Machine snapshots
sudo tmutil disable local

# Increase sound quality for Bluetooth headphones/headsets
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

# ============================================================================ #
#                                  F i n d e r
# ============================================================================ #

# TODO: set Finder to columns that are auto-wide

# set Downloads as the default location for new Finder windows
defaults write com.apple.finder NewWindowTarget -string "PfDe"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Downloads/"

# allow copying from Quick Look preview
defaults write com.apple.finder QLEnableTextSelection -bool true

# show the ~/Library folder
chflags nohidden ~/Library

# Empty Trash securely by default
defaults write com.apple.finder EmptyTrashSecurely -bool true

# disable the warning before emptying the Trash
defaults write com.apple.finder WarnOnEmptyTrash -bool false

# show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

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

# Automatically open a new Finder window when a volume is mounted
defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

#killall Finder

# ============================================================================ #
#                                 P r e v i e w
# ============================================================================ #

# set to false to not re-open previous documents from last Preview session
defaults write com.apple.Preview NSQuitAlwaysKeepsWindows -bool true

#killall Preview

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
