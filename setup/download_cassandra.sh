#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-04-28 15:39:09 +0100 (Tue, 28 Apr 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Installs Java and downloads Cassandra to $PWD

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
#. "$srcdir/bash-tools/lib/utils.sh"

if ! type -P wget &>/dev/null ||
     type -P apk; then  # Alpine built-in wget isn't good enough
    "$srcdir/../packages/install_packages.sh" wget
fi

#/usr/lib/jvm/jre/bin/
if ! type -P java &>/dev/null; then
    "$srcdir/../install/install_java.sh"
fi

CASSANDRA_VERSION="${CASSANDRA_VERSION:-3.11.4}"

TAR="apache-cassandra-$CASSANDRA_VERSION-bin.tar.gz"

url="http://www.apache.org/dyn/closer.lua?filename=cassandra/$CASSANDRA_VERSION/$TAR&action=download"

url_archive="http://archive.apache.org/dist/cassandra/$CASSANDRA_VERSION/$TAR"

echo "Downloading Cassandra tarball:"
# --max-redirect - some apache mirrors redirect a couple times and give you the latest version instead
#                  but this breaks stuff later because the link will not point to the right dir
#                  (and is also the wrong version for the tag)
wget -t 10 --max-redirect 1 --retry-connrefused -O "$TAR" "$url" || \
wget -t 10 --max-redirect 1 --retry-connrefused -O "$TAR" "$url_archive"

echo "Extracting tarball:"
tar zxf "$TAR"

echo "Removing tarball:"
rm -fv -- "$TAR"

# check tarball was extracted to the right place, helps ensure it's the right version and the link will work
if ! test -d "apache-cassandra-$CASSANDRA_VERSION"; then
    echo "apache-cassandra-$CASSANDRA_VERSION directory not found from extracted tarball!"
    exit 1
fi

echo "Symlinking cassandra:"
ln -sv -- "apache-cassandra-$CASSANDRA_VERSION" cassandra

if [ -f /.dockerenv ]; then
    echo "Running inside docker, removing docs:"
    rm -rf -- cassandra/doc cassandra/javadoc
fi
