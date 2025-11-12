#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-11-11 19:48:55 +0100 (Tue, 11 Nov 2025)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Configures Apple Spotlight to be more minimalistic and exclude a lot of rubbish results like web pages

- Enables indexing (needed by Raycast even if replacing Spotlight Search, see HariSekhon/Knowledge repo's Mac page)
- Excludes noisy folders (Downloads, Pictures, external Volumes)
- Disables Siri Suggestions & web results to give priority to local apps (or just use Raycast or Alfred, see Mac page)
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

mac_only

timestamp "Enabling Spotlight indexing"
sudo mdutil -a -i on
echo >&2

timestamp "Clearing Spotlight's temporary caches"
sudo mdutil -E /
echo >&2

timestamp "Adding common folders to Spotlight Privacy list..."

# skip these folder from indexing
excluded_paths=(
  "/System"
  "/Library"
  "/private"
  "/Volumes"
  "$HOME/Downloads"
  "$HOME/Movies"
  "$HOME/Music"
  "$HOME/Pictures"
)

for path in "${excluded_paths[@]}"; do
    if [ -d "$path" ]; then
        timestamp "Excluding path: $path"
        sudo mdutil -i off "$path" >/dev/null 2>&1 || :
    fi
done
echo >&2

timestamp "Disabling Siri & web suggestions in Spotlight"
defaults write com.apple.Spotlight SiriSuggestionsEnabled -bool false
defaults write com.apple.Siri SuggestionsEnabled -bool false
defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool true
defaults write com.apple.Spotlight OrderedItems -array \
  '{"enabled" = 1; "name" = "APPLICATIONS";}' \
  '{"enabled" = 1; "name" = "DOCUMENTS";}' \
  '{"enabled" = 0; "name" = "MENU_DEFINITION";}' \
  '{"enabled" = 0; "name" = "MENU_OTHER";}' \
  '{"enabled" = 0; "name" = "MENU_WEBSEARCH";}' \
  '{"enabled" = 0; "name" = "MENU_SPOTLIGHT_SUGGESTIONS";}'
echo >&2

timestamp "Restarting Spotlight services..."
killall mds >/dev/null 2>&1 || :
killall mds_stores >/dev/null 2>&1 || :
echo >&2

echo "Spotlight config optimized"
echo
echo "- Indexing active for Applications and Documents only"
echo "- Siri and web suggestions disabled"
echo "- Noisy folders excluded"
echo
echo "You can verify with: mdutil -s /"
