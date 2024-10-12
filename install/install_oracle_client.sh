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
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

help_usage "$@"

max_args 1 "$@"

version="${1:-latest}"

#if ! is_linux; then
#    die "ERROR: only Linux is supported at this time"
#fi

timestamp "Installing Oracle InstantClient"
echo

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

parse_rpms_version(){
    local version="$1"
    local rhel_version
    rhel_version="$(awk -F= '/^VERSION=/{print $2}' /etc/*release | sed 's/"//g')"
    local rpms
    # Oracle for some reason doesn't prefix the hrefs with 'https:' must add it ourselves
    rpms="$(
        grep -Eo "//download.oracle.com/[^'\"]+/oracle-instantclient[^'\"]+${version}[^'\"]+\.rpm" <<< "$downloads_page" |
        # remove basiclite rpm since it clashes with basic rpm
        sed '/basiclite/d' |
        sed 's|^|https:|' ||
        die "ERROR: failed to parse RPM packages for version '$version' from downloads page"
    )"
    if is_int "$rhel_version"; then
        timestamp "Determined RHEL version to be: $rhel_version"
    else
        timestamp "Failed to determine RHEL version, will attempt to use latest RHEL RPM version available (best effort for Fedora)"
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
    grep -Eo "//download.oracle.com/[^'\"]+${version}[^'\"]*\.zip" <<< "$downloads_page" |
    # remove basiclite zip since it clashes with basic zip
    sed '/basiclite/d' |
    sed 's|^|https:|' ||
    die "ERROR: failed to parse ZIP packages for version '$version' from downloads page"
}

if [ "$version" = latest ]; then
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

if type -P yum &>/dev/null; then
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
    # libaio1 on Debian is needed by sqlplus to be install for the shared library
    # on RHEL is just called libaio but this code path shouldn't be hit on RHEL systems which should use RPMs
    "$srcdir/../packages/install_packages_if_absent.sh" wget unzip libaio1
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
    echo "IMPORTANT: you will need to set this in your environment for Oracle programs like sqlplus to know where to find its own shared libraries"
    echo
    echo "  export LD_LIBRARY_PATH=/opt/oracle/instantclient"
fi

echo
timestamp "Oracle Client installed successfully"
