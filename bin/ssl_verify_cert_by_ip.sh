#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-09-22 13:03:06 +0100 (Thu, 22 Sep 2022)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
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
Verifies the SSL certificates for FQDNs at specific IP addresses via curl

Useful to test SSL source addresses for CDNs, such as Cloudflare Proxied sources before enabling SSL Full-Strict Mode for end-to-end, or Kubernetes ingresses (see also curl_k8s_ingress.sh)

Port defaults to 443 if not specified

If any of the arguments are a file, then reads the contents of that file as the 'FQDN,IP,Port' tuples, one per line either comma or space separated. Useful for bulk testing.


For a better version of this see check_ssl_cert.pl in the Advanced Nagios Plugins Collection:

    check_ssl_cert.pl - checks Expiry days remaining, Domain, Subject Alternative Names, SNI

    https://github.com/HariSekhon/Nagios-Plugins
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="fqdn:ip[:port] [ fqdn2:ip[:port]] [fqdn3:ip[:port]] ... ]"

help_usage "$@"

min_args 1 "$@"

exitcode=0

# otherwise will silently fail getting openssl output on incorrect host
set +o pipefail

check_fqdn_ip(){
    local fqdn="$1"
    local ip="$2"
    local port="${3:-443}"
    local url="https://$fqdn"
    echo -n "Checking SSL '$url' at '$ip': "
    set +e
    if curl -s --fail "$url" --resolve "$fqdn:$port:$ip" &>/dev/null; then
        echo "OK"
    else
        echo "FAILED"
        exitcode=1
    fi
    set -e
}

parse_arg(){
    local arg="$1"
    fqdn="${arg%%:*}"
    ip_port="${arg#*:}"
    ip="${ip_port%%:*}"
    port="${ip_port##*:}"
    if [ "$port" = "$ip" ]; then
       port=""
    fi
    echo "$fqdn" "$ip" "$port"
}

process_arg(){
    local arg="$1"
    read -r fqdn ip port < <(parse_arg "$arg")
    check_fqdn_ip "$fqdn" "$ip" "$port"
}

validate_arg(){
    local arg="$1"
    read -r fqdn ip port < <(parse_arg "$arg")
    if [ -n "$port" ]; then
        if ! [[ "$port" =~ ^[[:digit:]]+$ ]]; then
            die "Invalid Port '$port' detected in '$arg'"
        fi
    fi
    # shellcheck disable=SC2154
    if ! [[ "$ip" =~ ^$ip_regex$ ]]; then
        die "Invalid IP '$ip' detected in '$arg'"
    fi
    #if ! [[ "$fqdn" =~ ^$domain_regex$ ]]; then
    #    die "Invalid FQDN '$fqdn' given in '$arg'"
    #fi
}

parse_file(){
    local filename="$1"
    sed 's/#.*//;
         /^[[:space:]]*$/d;
         s/[,:]/ /g' "$filename"
}

process_file(){
    local filename="$1"
    parse_file "$filename" |
    while read -r fqdn ip port; do
        check_fqdn_ip "$fqdn" "$ip" "$port"
    done
}

validate_file(){
    local filename="$1"
    parse_file "$filename" |
    while read -r fqdn ip port; do
        validate_arg "$fqdn:$ip:$port"
    done
}

# pre-validate before running anything, quicker
for arg; do
    if [ -f "$arg" ]; then
        validate_file "$arg"
        continue
    else
        validate_arg "$arg"
    fi
done

for arg; do
    if [ -f "$arg" ]; then
        process_file "$arg"
        continue
    else
        process_arg "$arg"
    fi
done

exit $exitcode
