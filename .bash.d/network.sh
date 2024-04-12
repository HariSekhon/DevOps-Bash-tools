#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2006 - 2012 (forked from .bashrc)
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
#                                 N e t w o r k
# ============================================================================ #

bash_tools="${bash_tools:-$(dirname "${BASH_SOURCE[0]}")/..}"

# shellcheck disable=SC1090,SC1091
. "$bash_tools/.bash.d/os_detection.sh"

alias 4="ping 4.2.2.1"
alias 8="ping 8.8.8.8"

alias ping="ping -n"
alias p="ping"

pingwait="-w"
is_mac && pingwait="-W"

alias ping_google="while true; do ping www.google.com && break; sleep 1 || break; done"
alias g=ping_google

# watch_url.pl is in DevOps-Perl-tools repo which should be in $PATH
alias watchu="watch_url.pl"
# watch google
# https because http often gets intercepted by routers + proxies giving false 200 OKs where there is an internet issue
alias wg="watch_url.pl https://google.com"

# ============================================================================ #
#                         Y o u r   I P   A d d r e s s
# ============================================================================ #

# local/internal IP address
myip(){
    ifconfig | grep 'inet[[:space:]]' | grep -v 127.0.0.1 | awk '{print $2}'
}

# public IP address
ifconfigco(){
    curl ifconfig.co
    # something else to consider with jq for lat/long coordinates, ASN, country etc
    #curl ifconfig.co/json
}

ipinfo(){
    # returns json without /ip with region, reverse dns hostname, city, region, country, lat/long coordinates, org, postcode, timezone
    curl ipinfo.io/ip
}

ipify(){
    curl http://api.ipify.org/
    echo
}

# doesn't welcome automation / curl - requires captchas now so obsolete
#whatismyip(){
#    #lynx -dump $(lynx -dump www.whatismyip.com | tail -n 1)
#    lynx -useragent="Mozilla" -dump www.whatismyip.com 2>/dev/null | awk '/Your Public IPv[46] is:/ {print $6}'
#}

# ============================================================================ #
#                               F u n c t i o n s
# ============================================================================ #

checkhost(){
    if [ -z "$1" ]; then
        echo "usage: checkhost hostname/ip"
        return 1
    fi
    if grep -qi "unknown host" <<< "$(ping -c 1 "$pingwait" 1 "$1" 2>&1)"; then
        echo "Unknown host"
        return 1
    fi
}

n(){
    if type -P host &>/dev/null; then
        host "$@"
    elif type -P nslookup &>/dev/null; then
        nslookup "$@"
    else
        echo "neither host nor nslookup were found in the path"
        return 1
    fi
}
alias h=n

getip(){
    host "$@" | grep "has address" | awk '{print $4; exit}'
}

tping(){
    while true; do
        #echo -n "`date '+%F %T'`   "
        local output
        output="$(ping -c 1 "$pingwait" 2 "$@" |
                  grep -v -e statistics \
                          -e "transmitted" \
                          -e "rtt min/avg/max/mdev" \
                          -e "bytes of data" \
                          -e "^[[:space:]]*$" \
                          -e "^PING " \
                          -e "round-trip"
                 )"
        echo "$(date '+%F %T')   ${output:-no response from $1}"
        sleep 1
    done
}
tpinggw(){
    tping "$(get_gw)" "$@"
}

# for trying to find those damn wifi capture portals that disappear but block your internet http proxying
opengw(){
    local gateway
    gateway="$(get_gw)"
    open "http://$gateway"
    open "https://$gateway"
}

port(){
    if [ -z "$2" ]; then
        echo "You must supply a hostname/ip address to test followed by a port number"
        return 1
    fi
    #sudo nmap $1 -p $2 ${@:3} -P0 | grep tcp
    nc -zv "$1" "$2" 2>&1 | grep -v "DNS fwd/rev misma" | sed 's/[^]]*\] //'
}

testport(){
    if [ -z "$2" ]; then
        echo "You must supply a hostname/ip address to test followed by a port number"
        return 1
    fi
    while true; do
        timestampcmd port "$1" "$2"
        sleep 1
    done
}

hammerport(){
    for i in {1..500}; do
        printf "%-3s: " "$i"
        nc -z -v "$1" "$2"
    done
}

halfopen(){
    while true; do
        echo -n "half-open connections: "
        netstat -ant | grep c SYN_RECV
        sleep 1
    done
}

get_gw(){
    local gw
    gw="$(netstat -rn | awk '/^default/ {print $2;exit}')"
    if [ -z "$gw" ]; then
        echo "Could not find gateway, no default route! " >&2
        return 1
    fi
    echo "$gw"
}

gw(){
    local gw
    gw="$(get_gw)"
    [ -n "$gw" ] || return 1
    ping "$gw"
}


z(){
    local gw
    gw="$(get_gw)"
    if [ -n "$gw" ]; then
        whenup "$gw" &&
        whenup 4.2.2.1 &&
        whenup www.google.com echo "INTERNET OK"
    else
        echo "Couldn't find gateway, cannot test upstream connectivity!"
        return 1
    fi
}

browser(){
    if [ -n "${BROWSER:-}" ]; then
        "$BROWSER" "$@"
    elif is_mac; then
        open "${*:-http://google.com}"
    else
        echo "\$BROWSER environment variable not set and not on Mac OSX, not sure which browser to use, aborting..."
        return 1
    fi
}

browse(){
    if isGit . &>/dev/null && git remote -v | grep -qi http; then
        gitbrowse "$@"
    else
        browser "$@"
    fi
}

downorjustme(){
    browser "http://www.downforeveryoneorjustme.com/$1"
}

# directs to the same as downorjustme
isupme(){
    browser "http://www.isup.me/$1"
}

chrome(){
    if is_mac; then
        # opens in most recent Chrome window
        # could use one of these: --new --args --incognito --new-window
        open -a 'Google Chrome' "${*:-http://www.google.com}"
    else
        checkprog google-chrome || return 1
        google-chrome "${*:-http://www.google.com}" &
    fi

}

ff(){
    if is_mac; then
        open -a 'Firefox' "http://${*:-www.google.com}"
    else
        checkprog firefox || return 1
        firefox "${*:-http://www.google.com}" &
    fi
}

gg(){
    if [ -z "$*" ]; then
        browser &
    else
        searchterm="${*// /%20}"
        browser "http://www.google.com/search?q=$searchterm" &
    fi
}

netcraft(){
    checkprog firefox || return 1
    browser "http://uptime.netcraft.com/up/graph?site=$*" &
}

wikipedia(){
    checkprog "firefox" || return 1
    local searchterm
    searchterm="${*// /%20}"
    browser "http://en.wikipedia.org?search=$searchterm&go=Go" &
}
alias wiki=wikipedia

definition(){
    checkprog "firefox" || return 1
    local searchterm
    searchterm="${*// /%20}"
    # hl=en&q=test&btnI=I%27m+Feeling+Lucky&meta=&aq=f
    browser "http://www.google.co.uk/search?hl=en&q=definition+$searchterm&btnI=I%27m+Feeling+Lucky" &
}
# alias def=definition

# gh(){
#     url="http://www.google.com/search?q="
#     browser "${url}site%3A$*" &
#     browser "${url}site%3A$* login" &
#     browser "${url}link%3A$*" &
#     browser "${url}related%3A$*" &
# }


retry(){
    local cmd="$1"
    local host="${2##*@}"
    #local user="${2%%@*}"
    local args=("${@:3}")
    if [ -z "$host" ]; then
        echo "You must supply a hostname or ip address to connect to"
        return 2
    fi
    if [ "$cmd" = "ssh" ] || [ "$cmd" = "rdp" ]; then
        whenup "$host" || return 1
    fi
    #[ "$cmd" = "ssh" ] && host="root@$host"
    if [ "$cmd" = "ssh" ]; then
        until port "${host##*@}" 22 >/dev/null; do
            tstamp "trying $host port 22"
            sleep 1
        done
    elif [ "$cmd" = "rdp" ]; then
        until port "$host" 3389 >/dev/null; do
            tstamp "trying $host port 3389"
            sleep 1
        done
    fi
    [ "$cmd" = "ssh" ] && printargs="" || printargs="${args[*]}"
    until "$cmd" "$host" "${args[@]}"; do
        sleep 1
        tstamp "trying $cmd $host $printargs"
    done
    echo >/dev/null
}


rdp(){
    if is_mac; then
        "/Applications/Remote Desktop Connection.app/Contents/MacOS/Remote Desktop Connection" "$@" &
    else
        [ -n "$1" ] || return 1
        local resolution="800x600"
        if [ "$(xdpyinfo | awk '/dimensions/ {print $2}' | sed 's/x.*//')" -gt 1024 ]; then
            resolution="1024x768"
        fi
        if type -P krdc &>/dev/null; then
            krdc "rdp:/$WINDOWSDOMAIN\\$WINDOWSUSER@$*" &
            exit 0
        elif type -P rdesktop &>/dev/null; then
            rdesktop -u "$WINDOWSUSER" -d "$WINDOWSDOMAIN" "$@" -g "$resolution" &
            exit 0
        else
            echo  "Could not find krdc or rdesktop in path"
            return 1
        fi
    fi
}

rerdp(){
    retry "whenport $1 3389; rdp" "$1"
}


# ============================================================================ #
#                                   L i n u x
# ============================================================================ #

if is_linux; then

    ipl(){
        iptables -L | nl
    }

fi


# ============================================================================ #
#                                 M a c   O S X
# ============================================================================ #

if ! is_mac; then
    return
fi

dnsservers(){
    scutil --dns | grep 'nameserver\[[0-9]*\]' | sort -u
}

flushdns(){
    dscacheutil -flushcache
    sudo killall -HUP mDNSResponder
}
alias flushcache=flushdns

#APPLE_INTERFACES="Ethernet Airport"
#APPLE_INTERFACES="$(networksetup -listallnetworkservices | grep -E 'Ethernet|Wi-Fi')"
unset APPLE_INTERFACES

get_apple_interfaces(){
    networksetup -listallnetworkservices | grep -E 'Ethernet|Wi-Fi'
}

# Cisco AnyConnect set these rules which mess up my ability to connect directly to VirtualBox VMs on HostOnly Networking
cleardeny(){
    sudo ipfw delete "$(sudo ipfw list | grep deny | awk '{print $1}')"
}
ipfwqflush(){
    sudo ipfw -q flush
}

isMacNetworkService(){
    local interface="$1"
    if [ "$interface" != "Thunderbolt Ethernet" ] &&
       [ "$interface" != "Wi-Fi" ]; then
        echo "interface must be one of Thunderbolt Ethernet or Wi-Fi"
        return 1
    fi
}

set_dns(){
    get_apple_interfaces |
    while read -r interface; do
        sudo networksetup -setdnsservers "$interface" "$@"
    done
}

set_dns_search(){
    get_apple_interfaces |
    while read -r interface; do
        sudo networksetup -setsearchdomains "$interface" "$@"
    done
}

set_dns_search_empty(){
        set_dns_search "Empty"
}
# this wasn't found as an alias from another function
clear_dns_search(){
    set_dns_search_empty
}

function publicdns(){
    set_dns 4.2.2.1 4.2.2.2 4.2.2.3 4.2.2.4 4.2.2.5 4.2.2.6
    set_dns_search_empty
}

function dhcpdns(){
    clear_dns_search # hangs without this as I think it tries to query DNS for all the suffixes in the list
    set_dns "Empty"
    #networksetup -setsearchdomains <networkservice> <domain1> [domain2]
}

get_wifi_interface(){
    networksetup -listnetworkserviceorder |
    grep "Hardware.*Wi-Fi" |
    sed 's/.*: //;s/)$//'
}

get_wifi_network(){
    networksetup -getairportnetwork "$(get_wifi_interface)" | sed 's/^Current Wi-Fi Network: //'
}

set_wifi_network(){
    networksetup -setairportnetwork "$(get_wifi_interface)" "$*"
}

wifi(){
    if [ $# -eq 1 ]; then
        airport on
        set_wifi_network "$1"
    elif [ $# -eq 0 ]; then
        get_wifi_network
    else
        echo "usage: wifi <network>"
        return 1
    fi
}

wifi_networks_preferred(){
    networksetup -listpreferredwirelessnetworks "$(get_wifi_interface)"
}

airport(){
    networksetup -setairportpower "$(get_wifi_interface)" "$1"
}
alias air=airport

airportr(){
    airport off
    airport on
}
alias airr=airportr
alias ag="airr; g"

watchwifi(){
    scnum 39
    while true; do
        checkwifi
        sleep 30 || break
    done
}

checkwifi(){
    # needs to be global otherwise will be forgotten between runs of this program
    [ -z "$wifi_failures" ] && wifi_failures=0
    for((i=1;i<=3;i++)); do
        if ping -c1 -W1 4.2.2.1 >/dev/null; then
            if [ "$wifi_failures" -gt 0 ]; then
                tstamp "wifi recovered from $wifi_failures failures"
            fi
            wifi_failures=0
            return
        else
            ((wifi_failures+=1))
            tstamp "$wifi_failures wifi failures"
        fi
    done
    timestamp "RESTARTING WIFI"
    airportr
}

setdhcp(){
    isMacNetworkService "$1" || return 1;
    sudo networksetup -setdhcp "$1"
}

renewdhcp(){
    sudo ipconfig set "$1" DHCP
}

#sethomenet(){
#    isMacNetworkService "$1" || return 1;
#    sudo networksetup -setmanual "$1" x.x.x.x 255.255.255.0 x.x.x.1
#    sudo route delete 0.0.0.0
#    sudo route add 0.0.0.0 x.x.x.1
#    publicdns
#}
