#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-10-13 00:59:42 +0300 (Sun, 13 Oct 2024)
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Downloads the latest Oracle SQLcl command line client to /usr/local/ and links it to /usr/local/bin
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

timestamp "Installing Oracle SQLcl command line client"
echo

# sometimes on Mac /usr/local is writeable by the user, in which case don't enforce sudo
if ! [ -w /usr/local ] || ! [ -w /usr/local/bin ]; then
#if ! am_root; then
    die "ERROR: must be root to run this script as it will download and unpack to /usr/local"
fi

# permalink to latest release
download_url="https://download.oracle.com/otn_software/java/sqldeveloper/sqlcl-latest.zip"
install_base="/usr/local"

timestamp "Downloading: $download_url"
wget -c "$download_url"
echo

# unsure the files are created as rwxr-xr-x octal permissions otherwise users will get this error trying to run the sql / sqlcl wrapper:
#
#   Error: Could not find or load main class oracle.dbtools.raptor.scriptrunner.cmdline.SqlCli
#   Caused by: java.lang.ClassNotFoundException: oracle.dbtools.raptor.scriptrunner.cmdline.SqlCli
#
# no, it's not this, the stupid zip is unpacking the files with 0640 permissions
#umask 0022

timestamp "Unzipping to $install_base/"
unzip -n sqlcl-latest.zip -d "$install_base/"
echo

timestamp "Fixing library permissions"
# don't print this in case it scares users
#timestamp "Fixing stupid default 0640 permissions on '$install_base/sqlcl/lib/*' to avoid this error:
#
#Error: Could not find or load main class oracle.dbtools.raptor.scriptrunner.cmdline.SqlCli
#Caused by: java.lang.ClassNotFoundException: oracle.dbtools.raptor.scriptrunner.cmdline.SqlCli
#"
chmod -R o+r "$install_base/sqlcl/lib"
echo

# clashes with GNU parallel which installs an 'sql' program in the path so link this to sqlcl to avoid path priority clashes
#if ! [ -e /usr/local/bin/sql ]; then
#    timestamp "Linking $install_base/sqlcl/bin/sql to /usr/local/bin/ for \$PATH convenience"
#    ln -sv "$install_base/sqlcl/bin/sql" /usr/local/bin/
#    echo
#fi

# Symlinking sql to /usr/local/bin doesn't work as the script naively so not follow it's own symlink refernce
# to find its adjacent libraries, resuling in this error:
#
#   Error: Could not find or load main class oracle.dbtools.raptor.scriptrunner.cmdline.SqlCli
#   Caused by: java.lang.ClassNotFoundException: oracle.dbtools.raptor.scriptrunner.cmdline.SqlCli
#
#if ! [ -e /usr/local/bin/sqlcl ]; then
#    timestamp "Linking $install_base/sqlcl/bin/sql to /usr/local/bin/sqlcl for \$PATH convenience"
#    ln -sv "$install_base/sqlcl/bin/sql" /usr/local/bin/sqlcl
#    echo
#fi

# Instead, create a stub script instead

stub_script="/usr/local/bin/sqlcl"
if ! [ -e "$stub_script" ]; then
    timestamp "Creating stub script for \$PATH convenience: $stub_script"
    cat > "$stub_script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
#cd "$install_base/sqlcl/bin"
#./sql "\$@"
"$install_base/sqlcl/bin/sql" "\$@"
EOF
    chmod +x "$stub_script"
    echo
fi

timestamp "Completed installation of SQLcl oracle client"
echo
#timestamp "Don't forget to add /usr/local/sqlcl/bin to your \$PATH and check for clashes with other programs called 'sql' in your path (GNU Parallels puts one in /usr/local/bin/ for example)"
timestamp "Call SQLcl as 'sqlcl' which should be in your \$PATH now"
echo
echo "SQLcl version:"
sqlcl -version
