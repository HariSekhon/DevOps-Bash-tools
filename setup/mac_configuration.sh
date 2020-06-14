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

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

# require password immediately after sleep / screen saver
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# auto-restart after a system freeze
#sudo systemsetup -setrestartfreeze on

# Check for software updates daily, not just once per week
#defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

# Disable local Time Machine snapshots
#sudo tmutil disablelocal

# Trackpad: enable tap to click for this user and for the login screen
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Enable “natural” (Lion-style) scrolling
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true

# Increase sound quality for Bluetooth headphones/headsets
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

# Avoid creating .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Automatically open a new Finder window when a volume is mounted
defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

# ============================================================================ #
# Finder:

# set Downloads as the default location for new Finder windows
defaults write com.apple.finder NewWindowTarget -string "PfDe"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Downloads/"

# allow copying from Quick Look preview
defaults write com.apple.finder QLEnableTextSelection -bool true

# show the ~/Library folder
#chflags nohidden ~/Library

# Empty Trash securely by default
defaults write com.apple.finder EmptyTrashSecurely -bool true

# disable the warning before emptying the Trash
#defaults write com.apple.finder WarnOnEmptyTrash -bool false

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
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

#killall Finder

# ============================================================================ #
# Preview:
# set to false to not re-open previous documents from last Preview session
defaults write com.apple.Preview NSQuitAlwaysKeepsWindows -bool true

#killall Preview

# ============================================================================ #
# Screenshots:

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
# Dock:

# hide non-active apps
#defaults write com.apple.dock static-only -bool TRUE

# stop apps saving to iCloud by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# pop-up instantly
defaults write com.apple.dock autohide-delay         -float 0  # secs
# disappear instantly
defaults write com.apple.dock autohide-time-modifier -float 0

# revert to default delay
#defaults delete com.apple.dock autohide-delay
#defaults write com.apple.dock autohide-time-modifier

# enable Dashboard with widgets
#defaults write com.apple.dashboard mcx-disabled -boolean false

#killall Dock

# ============================================================================ #

# Enable AirDrop over Ethernet and on unsupported Macs running Lion
#defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

# Change indexing order and disable some search results
#defaults write com.apple.spotlight orderedItems -array \
#	'{"enabled" = 1;"name" = "APPLICATIONS";}' \
#	'{"enabled" = 1;"name" = "SYSTEM_PREFS";}' \
#	'{"enabled" = 0;"name" = "DIRECTORIES";}' \
#	'{"enabled" = 0;"name" = "PDF";}' \
#	'{"enabled" = 0;"name" = "FONTS";}' \
#	'{"enabled" = 0;"name" = "DOCUMENTS";}' \
#	'{"enabled" = 0;"name" = "MESSAGES";}' \
#	'{"enabled" = 0;"name" = "CONTACT";}' \
#	'{"enabled" = 0;"name" = "EVENT_TODO";}' \
#	'{"enabled" = 0;"name" = "IMAGES";}' \
#	'{"enabled" = 0;"name" = "BOOKMARKS";}' \
#	'{"enabled" = 0;"name" = "MUSIC";}' \
#	'{"enabled" = 0;"name" = "MOVIES";}' \
#	'{"enabled" = 0;"name" = "PRESENTATIONS";}' \
#	'{"enabled" = 0;"name" = "SPREADSHEETS";}' \
#	'{"enabled" = 0;"name" = "SOURCE";}' \
#	'{"enabled" = 1;"name" = "MENU_DEFINITION";}' \
#	'{"enabled" = 0;"name" = "MENU_OTHER";}' \
#	'{"enabled" = 0;"name" = "MENU_CONVERSION";}' \
#	'{"enabled" = 1;"name" = "MENU_EXPRESSION";}' \
#	'{"enabled" = 0;"name" = "MENU_WEBSEARCH";}' \
#	'{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}'

echo "Some settings won't take effect until you restart Finder. When you're ready, run:

killall Finder
killall Dock
killall SystemUIServer
"
