#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-01-16 15:44:24 -0500 (Fri, 16 Jan 2026)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback
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
Checks the internet is available by multiple tests

Waits for the internet to become available before returning

Useful to run in a blocking latch wait fashion in scripts to ensure the internet is available
before running a big operation like my Spotify Playlists API backups

Tests:

- Local Gateway IP is configured (Wifi DHCP has succeeded or we have static details configured)
- Gateway IP is reachable (ping)
  - now optional informational, progresses regardless now as some hotel wifi gateway did not return pings
  even though the end-to-end internet connection was up (router was obviously just set to not respond to ICMP)
- Public IP is reachable (ping to known major public IP 1.1.1.1)
- DNS resolution is working (resolves google.com)
- Public Domain is reachable (ping to google.com)
- Google.com or Baidu.com (if you're running this inside China since Google is blocked there) over HTTPS
- Important Websites available over HTTPS - defaults to GitHub.com but you can override this to others using
  environment variable \$CHECK_INTERNET_IMPORTANT_WEBSITES. In China github.com was often extraordinarily slow to
  respond, probably due to The Great Firewall inspection, so I overrode this for my Spotify-Playlists repo
  to just check api.spotify.com
- China mode - detects if your public IP is in China and if so switches to Chinese accessible site baidu.com
  instead of google.com for DNS, IP and HTTPS tests since Google is blocked in China by The Great Firewall
  (if you're on a VPN in China your public IP will probably be in a different country and it'll use the default
  tests which will work over your VPN)
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

no_more_args "$@"

SECONDS=0

# Sometimes Github.com works and sometimes it doesn't - Great Firewall interference?
# I cannot replace this with another site as this is one of the primary reasons to check internet availability
# before doing git pushes
important_websites="${CHECK_INTERNET_IMPORTANT_WEBSITES:-github.com}"

# XXX: catch 22 - I need to detect if public IP is in China to be able to switch tests to Chinese accessible sites
#      call this after gateway test at least
configure_sites_to_test(){
    if [ -n "${country:-}" ]; then
        # if we're already successfully determined the country and configured relevant sites, skip this
        # this allows repeated calling at each stage to recover in case on stage fails to detect which
        # could result in a stuck loop from race condition when calling this inside China
        return
    fi
    # China detection is best effort and ignore if it fails and just stick with the defaults
    country="$(curl -sS https://ifconfig.co/json | jq -r '.country' || :)"

    if [ "$country" = "China" ]; then
        timestamp "Configuring Site Tests: for China"
        domain="baidu.com"
        public_ip="111.63.65.103"
        websites="baidu.com $important_websites"
    else
        timestamp "Configuring Site Tests: Default"
        domain="google.com"
        public_ip="1.1.1.1"
        websites="google.com $important_websites"
    fi
}

ping_count=1
ping_timeout=2
sleep_seconds=2

get_gateway() {
    "$srcdir/../bin/network_gateway.sh" 2>/dev/null || return 1
}

check_gateway() {
    gateway_ip="$(get_gateway)" || return 1
    if ! [ -n "$gateway_ip" ]; then
        timestamp "FAIL: no Gateway IP detected yet..."
        return 1
    fi

    if ping -c "$ping_count" -W "$ping_timeout" "$gateway_ip" &>/dev/null; then
        timestamp "OK: Gateway IP reachable"
    else
        timestamp "FAIL: Gateway IP '$gateway_ip' unreachable (skipping as some routers are configured to just not respond to ping)"
        return 1
    fi
}

check_public_ip() {
    configure_sites_to_test
    if ping -c "$ping_count" -W "$ping_timeout" "$public_ip" &>/dev/null; then
        timestamp "OK: Public IP reachable"
    else
        timestamp "FAIL: Public IP '$public_ip' unreachable"
        return
    fi
}

check_dns() {
    configure_sites_to_test
    if type -P getent &>/dev/null; then
        getent hosts "$domain" &>/dev/null
    elif type -P dig &>/dev/null; then
        dig +short "$domain" &>/dev/null
    elif type -P host &>/dev/null; then
        host "$domain" &>/dev/null
    elif type -P nslookup &>/dev/null; then
        nslookup "$domain" &>/dev/null
    else
        timestamp "FAIL: DNS domain '$domain' not resolved"
        return 1
    fi
    timestamp "OK: DNS resolved"
}

check_domain_ping() {
    configure_sites_to_test
    if ping -c "$ping_count" -W "$ping_timeout" "$domain" &>/dev/null; then
        timestamp "OK: Domain IP reachable"
    else
        timestamp "FAIL: Domain IP unreachable"
        return 1
    fi
}

check_https(){
    configure_sites_to_test
    local website="$1"
    if curl -sS --fail "https://$website" &>/dev/null; then
        timestamp "OK: $website HTTPS reachable"
    else
        timestamp "FAIL: $website HTTPS unreachable"
        return 1
    fi
}

timestamp "Detecting Default Gateway IP..."
while :; do
    gateway_ip=$(get_gateway)
    if ! is_blank "$gateway_ip"; then
        break
    else
        timestamp "FAIL: no Gateway IP available yet..."
    fi
    sleep "$sleep_seconds"
done

timestamp "Checking Gateway IP available: $gateway_ip"
#while ! check_gateway; do
# no point wasting 5 tries when the hotel wifi will always fail, it just slows down dependent scripts
#for ((i=0; i< 5; i++)); do
#    check_gateway && break
#    sleep "$sleep_seconds"
#done
check_gateway || :

configure_sites_to_test

timestamp "Checking Public IP available: $public_ip"
while ! check_public_ip; do
    sleep "$sleep_seconds"
done

timestamp "Checking DNS resolution to well known domain: $domain"
while ! check_dns; do
    sleep "$sleep_seconds"
done

timestamp "Checking Domain IP reachable: $domain"
while ! check_domain_ping; do
    sleep "$sleep_seconds"
done

for website in $websites; do
    timestamp "Checking HTTPS reachable: $website"
    while ! check_https "$website"; do
        sleep "$sleep_seconds"
    done
done

timestamp "Internet Connection OK within $SECONDS secs"
exit 0
