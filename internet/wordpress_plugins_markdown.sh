#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-12-14 19:44:36 -0600 (Sun, 14 Dec 2025)
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Generates a Markdown list of Wordpress plugins for documentation purposes

You must run this from inside the Wordpress installation root

Runs PHP to get the PluginURI which is not exposed by the 'wp plugin list' command

Tested on Wordpress 6
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

no_more_args "$@"

wp core version

# don't want expansion
# shellcheck disable=SC2016
wp eval '
require_once ABSPATH . "wp-admin/includes/plugin.php";

$plugins = get_plugins();

foreach ($plugins as $plugin) {
  $name = $plugin["Name"];
  $url  = $plugin["PluginURI"] ?: "https://wordpress.org/plugins/" . sanitize_title($name) . "/";
  $desc = rtrim($plugin["Description"], ".");

  echo "- [$name]($url) - $desc\n";
}
'
