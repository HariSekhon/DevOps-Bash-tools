#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-10-12 01:54:30 +0300 (Sat, 12 Oct 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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
. "$srcdir/../lib/utils.sh"

downloads_url="https://www.oracle.com/database/technologies/instant-client/linux-x86-64-downloads.html"

opt_base="/opt/oracle"

# shellcheck disable=SC2034,SC2154
usage_description="
Installs the Oracle InstantClient packages including SQLPlus, JDBC, ODDC, SDK and Tools

If the first arg is 'list' then just lists discovered versions and exits so you can choose the version you want if not using latest

Version can be a prefix major or major.minor number and it'll take whatever the first patch version of that release which is found

Some RPM versions will not install on some versions of Redhat based systems due to compatibility, you are advised to try the latest version

You can also look here and fetch manually if you really want:

    $downloads_url

On RHEL systems installs all RPMs

On non-RHEL systems installs all Zips to $opt_base

If you get this error (eg. on Amazon Linux 2 when trying to install Oracle Client version 23):

    Error: Invalid version flag: or

then install an older version by passing it an arg of a major version and letting the script figure out the rest, eg.

    ${0##*/} 21
"
# On Mac it ignores the version arg and always installs the latest DMGs

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

help_usage "$@"

max_args 1 "$@"

version="${1:-latest}"

#if ! is_linux && ! is_mac; then
#    die "ERROR: only Linux and Mac are supported at this time"
#fi

if ! is_linux; then
    die "ERROR: only Linux is supported at this time"
fi

timestamp "Installing Oracle InstantClient"
echo

if is_linux && ! am_root; then
    die "You need to be root on Linux to run this script as it installs software"
fi

if is_linux; then
    # xargs is needed by install_packages_if_absent.sh
    if ! type -P xargs &>/dev/null; then
        "$srcdir/../packages/install_packages.sh" findutils  # contains xargs for RHEL8
    fi
    "$srcdir/../packages/install_packages_if_absent.sh" curl ca-certificates

    timestamp "Fetching downloads page: $downloads_url"
    downloads_page="$(curl "$downloads_url")"
    echo

    timestamp "Parsing available versions"
    versions="$(
        grep -Eo "oracle-instantclient[^'\"]*basic[^'\"]*rpm" <<< "$downloads_page" |
        sed '
            s/^.*basic[[:alpha:]]*-//;
            s/-.*$//; s/.rpm$//;
            s/linuxx64//;
            /^[[:space:]]*$/d
        ' |
        sort -Vur
        #die "ERROR: No versions parsed from downloads url: $downloads_url"
    )"
    echo

    versions_found="Versions found:

    $versions
    "

    if [ "$version" = list ]; then
        echo "$versions_found"
        exit 1
    fi

    log "$versions_found"
fi

parse_rpms_version(){
    local version="$1"
    local rhel_version
    rhel_version="$(awk -F= '/^VERSION=/{print $2}' /etc/*release | sed 's/"//g')"
    local rpms
    # Oracle for some reason doesn't prefix the hrefs with 'https:' must add it ourselves
    # XXX: SECURITY: this regex must remain as tight as possible known chars as these packages are passed to the CLI yum install command further down
    #      and this could open you to a Shell Injection attack if you mess with this
    #      KNOWN GOOD CHARS WHITELISTING ONLY - NO '.' sloppiness can be allowed here !!
    rpms="$(
        grep -Eo "//download.oracle.com/[[:alnum:]/._-]+/oracle-instantclient[[:alnum:]._-]+${version}[[:alnum:]._-]+\.rpm" <<< "$downloads_page" |
        # remove basiclite rpm since it clashes with basic rpm
        sed '/basiclite/d' |
        sed 's|^|https:|' ||
        die "ERROR: failed to parse RPM packages for version '$version' from downloads page"
    )"
    if grep -qi amazon /etc/*-release; then
        timestamp "Detected Amazon Linux, ignoring version"
        rhel_version=""
    fi
    if is_int "$rhel_version"; then
        timestamp "Determined RHEL version to be: $rhel_version"
    else
        timestamp "Failed to determine RHEL version, will attempt to use latest RHEL RPM version available (best effort for Fedora and Amazon Linux)"
        rhel_version="$(
            # -m 1 still outputs 2 matches from the first line :-/
            grep -Eom1 '\.el[[:digit:]]+\.x86_64.rpm' <<< "$rpms" |
            tr ' ' '\n' |
            head -n 1 |
            sed 's/^\.el//; s/\..*$//' || :
            #die "Failed to parse latest RHEL version from available RPMs"
        )"
        # older versions of client do not have el suffixes
        #if ! is_int "$rhel_version"; then
        #    die "ERROR: failed to parse latest RHEL version from available RPMs, got unexpected non-integer: '$rhel_version'"
        #fi
    fi
    if is_int "$rhel_version"; then
        timestamp "Parsing RPMs for RHEL $rhel_version"
        grep -E "\\.el$rhel_version\\.x86_64\\.rpm" <<< "$rpms" ||
        die "ERROR: failed to parse RPM packages for RHEL version $rhel_version"
    else
        echo "$rpms"
    fi
}

parse_zips_version(){
    local version="$1"
    # Oracle for some reason doesn't prefix the hrefs with 'https:' must add it ourselves
    # XXX: SECURITY: this regex must remain as tight as possible known chars as these zips are passed to the CLI unzip command further down
    #      and this could open you to a Shell Injection attack if you mess with this
    #      KNOWN GOOD CHARS WHITELISTING ONLY - NO '.' sloppiness can be allowed here !!
    grep -Eo "//download.oracle.com/[[:alnum:]/._-]+${version}[[:alnum:]._-]*\.zip" <<< "$downloads_page" |
    # remove basiclite zip since it clashes with basic zip
    sed '/basiclite/d' |
    sed 's|^|https:|' ||
    die "ERROR: failed to parse ZIP packages for version '$version' from downloads page"
}

if is_mac; then
    arch="$(get_arch)"
    dmgs="
        https://download.oracle.com/otn_software/mac/instantclient/instantclient-basic-macos-$arch.dmg
        https://download.oracle.com/otn_software/mac/instantclient/instantclient-sqlplus-macos-$arch.dmg
        https://download.oracle.com/otn_software/mac/instantclient/instantclient-tools-macos-$arch.dmg
        https://download.oracle.com/otn_software/mac/instantclient/instantclient-sdk-macos-$arch.dmg
        https://download.oracle.com/otn_software/mac/instantclient/instantclient-jdbc-macos-$arch.dmg
        https://download.oracle.com/otn_software/mac/instantclient/instantclient-odbc-macos-$arch.dmg
    "
elif [ "$version" = latest ]; then
    timestamp "Using version 'latest'"
    version="$(head -n1 <<< "$versions")"
    timestamp "Latest version determined to be: $version"
    # use permalink to latest version
    rpms="
        https://download.oracle.com/otn_software/linux/instantclient/oracle-instantclient-basic-linuxx64.rpm
        https://download.oracle.com/otn_software/linux/instantclient/oracle-instantclient-sqlplus-linuxx64.rpm
        https://download.oracle.com/otn_software/linux/instantclient/oracle-instantclient-tools-linuxx64.rpm
        https://download.oracle.com/otn_software/linux/instantclient/oracle-instantclient-devel-linuxx64.rpm
        https://download.oracle.com/otn_software/linux/instantclient/oracle-instantclient-jdbc-linuxx64.rpm
        https://download.oracle.com/otn_software/linux/instantclient/oracle-instantclient-odbc-linuxx64.rpm
    "
    zips="
        https://download.oracle.com/otn_software/linux/instantclient/instantclient-basic-linuxx64.zip
        https://download.oracle.com/otn_software/linux/instantclient/instantclient-sqlplus-linuxx64.zip
        https://download.oracle.com/otn_software/linux/instantclient/instantclient-tools-linuxx64.zip
        https://download.oracle.com/otn_software/linux/instantclient/instantclient-sdk-linuxx64.zip
        https://download.oracle.com/otn_software/linux/instantclient/instantclient-jdbc-linuxx64.zip
        https://download.oracle.com/otn_software/linux/instantclient/instantclient-odbc-linuxx64.zip
    "
else
    if ! grep -Fq "$version" <<< "$versions"; then
        die "ERROR: requested version '$version' does not match list of available versions:

$versions
"
    fi
    version="${version%%.}"
    version="$(
        grep -Eo -m 1 "^${version}(\.[[:digit:].]+$)*$" <<< "$versions" ||
        die "ERROR: Failed to find version prefixed with: $version"
    )"
    timestamp "Requested version matched available version: $version"
fi

if is_mac; then
    timestamp "Installing DMGs on Mac"
    cd ~/Downloads
    for dmg in $dmgs; do
        timestamp "Fetching DMG: $dmg"
        wget -c "$dmg"
        open "${dmg##*/}"
    done
elif type -P yum &>/dev/null; then
    if [ -z "${rpms:-}" ]; then
        # we did not set the permalink rpms because script wasn't passed latest
        timestamp "On RHEL-based system, determining RPM package to install"
        rpms="$(parse_rpms_version "$version")"
    fi
    echo
    timestamp "Installing RPMs"
    # want splitting
    # shellcheck disable=SC2086
    yum install -y $rpms
else
    # libaio shared library is needed by sqlplus
    "$srcdir/../packages/install_packages_if_absent.sh" wget unzip
    if grep -q Ubuntu /etc/*-release; then
        "$srcdir/../packages/install_packages_if_absent.sh" libaio-dev
    elif grep -q Debian /etc/*-release; then
        "$srcdir/../packages/install_packages_if_absent.sh" libaio1
    elif grep -qi redhat /etc/*-release; then
        "$srcdir/../packages/install_packages_if_absent.sh" libaio
    fi
    if [ -z "${zips:-}" ]; then
        # we did not set the permalink zips because script wasn't passed latest
        timestamp "On non-RHEL-based system, falling back to using zips"
        zips="$(parse_zips_version "$version")"
    fi
    timestamp "Installing zips"
    mkdir -p -v "$opt_base"
    cd "$opt_base"
    # want splitting
    # shellcheck disable=SC2086
    for zip in $zips; do
        wget -c "$zip"
        # don't overwrite existing files for safety to not risk breaking an existing installation
        unzip -n "${zip##*/}"
    done
    echo
    timestamp "Linking newest instantclient_* installation to $PWD/instantclient to make a more stable path for LD_LIBRARY_PATH"
    # want newer one linked, easier than using find for this
    # shellcheck disable=SC2012
    ln -sfv "$(ls -dt instantclient_* | head -n1)" instantclient
    echo
    if [ -f /usr/lib/x86_64-linux-gnu/libaio.so.1t64 ]; then
        if ! [ -f /usr/lib/x86_64-linux-gnu/libaio.so.1 ]; then
            # Ubuntu doesn't work without this
            timestamp "Linking /usr/lib/x86_64-linux-gnu/libaio.so.1t64 to /usr/lib/x86_64-linux-gnu/libaio.so.1 because sqlplus looks for libaio.so.1 and fails otherwise"
            ln -sv /usr/lib/x86_64-linux-gnu/libaio.so.1t64 /usr/lib/x86_64-linux-gnu/libaio.so.1
        fi
        echo
    fi
    echo
    echo "IMPORTANT: you will need to set this in your environment for Oracle programs like sqlplus to know where to find its own shared libraries"
    echo
    echo "  export LD_LIBRARY_PATH=/opt/oracle/instantclient"
fi

echo
timestamp "Oracle Client installed successfully"
