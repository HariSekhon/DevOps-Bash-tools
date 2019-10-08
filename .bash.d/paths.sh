#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2006 (forked from .bashrc)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# ============================================================================ #
#                                   $ P A T H
# ============================================================================ #

# general path additions that aren't big enough to have their own <technology>.sh file

# this is sourced in .bashrc before .bash.d/*.sh because add_PATH() is used extensively everywhere to deduplicate $PATHs across disparate code and also reloads before it gets to this point in the .bash.d/*.sh lexically ordered list

if type add_PATHS &>/dev/null && [ -n "${PATHS_SET:-}" ]; then
    return
fi

srcdir="${srcdir:-$(dirname "${BASH_SOURCE[0]}")/..}"

# shellcheck disable=SC1090
. "$srcdir/.bash.d/os_detection.sh"

# see the effect of inserting a path like so
# PYTHONPATH=/path/to/blah pythonpath
pythonpath(){
    python -c 'from __future__ import print_function; import sys; [print(_) for _ in sys.path if _]'
}
# enable this to avoid creating .pyc files (sometimes they trip you up executing outdated python code)
# export PYTHONDONTWRITEBYTECODE=1

# see the effect of inserting a path like so
# PERL5LIB=/path/to/blah perlpath
perlpath(){
    perl -e 'print join("\n", @INC);'
}

# ============================================================================ #

#export PATH="${PATH%%:~/github*}"
add_PATH(){
    local env_var
    local path
    if [ $# -gt 1 ]; then
        env_var="$1"
        path="$2"
    else
        env_var=PATH
        path="${1:-}"
    fi
    path="${path%/}"
    if ! [[ "${!env_var}" =~ (^|:)$path(:|$) ]]; then
        export $env_var="${!env_var}:$path"
    fi
}

if [ -d ~/perl5/lib/perl5 ]; then
    add_PATH PERL5LIB ~/perl5/lib/perl5
fi

add_PATH "/bin"
add_PATH "/usr/bin"
add_PATH "/sbin"
add_PATH "/usr/sbin"
add_PATH "/usr/local/sbin"
add_PATH "/usr/local/bin"
add_PATH "$srcdir"
add_PATH ~/bin
for x in ~/bin/*; do
    [ -d "$x" ] || continue
    add_PATH "$x"
done

if [ -d ~/Library/Python ]; then
    for x in ~/Library/Python/*/bin; do
        [ -d "$x" ] || continue
        add_PATH "$x"
    done
fi

# do the same with MANPATH
#if [ -d ~/man ]; then
#    MANPATH=~/man${MANPATH:-:}
#    export MANPATH
#fi


# ============================================================================ #
#                         M y   G i t H u b   r e p o s
# ============================================================================ #

# $github defined in aliases.sh
# shellcheck disable=SC2154
add_PATH "$github/bash-tools"
add_PATH "$github/pytools"
add_PATH "$github/tool"
add_PATH "$github/tools"
add_PATH "$github/go-tools"
add_PATH "$github/nagios-plugins"
add_PATH "$github/nagios-plugin-kafka"
add_PATH "$github/spotify"

# ============================================================================ #
#                                A n a c o n d a
# ============================================================================ #

# Make sure to customize Anaconda installation and de-select Modify Path otherwise it'll change the bash profile

# for the 'conda' command
add_PATH ~/anaconda/bin

# ============================================================================ #
#                           P a r q u e t   T o o l s
# ============================================================================ #

if [ -d /usr/local/parquet-tools ]; then
    add_PATH "/usr/local/parquet-tools"
fi

# ============================================================================ #
#                       R u b y   G e m   c o m m a n d s
# ============================================================================ #

# gems will be installed to ~/.gem/ruby/x.y.z/bin

# add newest ruby to path first
#for ruby_bin in $(ls -d ~/.gem/ruby/*/bin 2>/dev/null | tail -r); do
for ruby_bin in $(find ~/.gem/ruby -maxdepth 2 -name bin -type d 2>/dev/null | tail -r); do
    add_PATH "$ruby_bin"
done

# ============================================================================ #
#                                  G o l a n g
# ============================================================================ #

GOPATH="$github/go-tools"

# manual installation of 1.5 mismatches with HomeBrew 1.6 installed to $PATH and
#export GOROOT="/usr/local/go"
# causes:
# imports runtime/internal/sys: cannot find package "runtime/internal/sys" in any of:
# /usr/local/go/src/runtime/internal/sys (from $GOROOT)
# /Users/hari/github/go-tools/src/runtime/internal/sys (from $GOPATH)
# shellcheck disable=SC2230
if type -P go &>/dev/null; then
    if [ -n "$APPLE" ]; then
        GOROOT="$(dirname "$(dirname "$(greadlink -f "$(which go)")")")"
    else
        GOROOT="$(dirname "$(dirname "$(readlink -f "$(which go)")")")"
    fi
    export GOROOT
    add_PATH "$GOROOT/bin"
    add_PATH "$GOROOT/libexec/bin"
    add_PATH "$GOPATH/bin"
fi

# ============================================================================ #

link_latest(){
    # -p suffixes / on dirs, which we grep filter on to make sure we only link dirs
    # shellcheck disable=SC2010
    ls -d -p "$@" |
    grep "/$"  |
    tail -n 1  |
    while read -r path; do
        [ -d "$path" ] || continue
        #local path_noversion="$( echo "$path" | perl -pn -e 's/-\d+(\.v?\d+)*(-\d+|-[a-z]+)?\/?$//' )"
        local path_noversion
        path_noversion="$(perl -pn -e 's/-\d+[\.\w\d-]+\/?$//' <<< "$path")"
        if [ "$path_noversion" = "$path" ]; then
            echo "FAILED to strip version, linking back on itself will create a link in subdir"
            return 1
        fi
        [ -e "$path_noversion" ] && [ ! -L "$path_noversion" ] && continue
        if [ -n "$APPLE" ]; then
            local ln_opts="-h"
        else
            local ln_opts="-T"
        fi
        # if you're in 'admin' group on Mac you don't really need to sudo here
        # shellcheck disable=SC2154
        $sudo ln -vfs $ln_opts "$path" "$path_noversion"
    done
}


# ============================================================================ #
# ============================================================================ #
#                               O l d   S t u f f
# ============================================================================ #

# Most of the stuff below has been migrated to Docker rather than /usr/local installs

# ============================================================================ #
#                            A p a c h e   D r i l l
# ============================================================================ #

#link_latest /usr/local/apache-drill-*
#export DRILL_HOME=/usr/local/apache-drill
#add_PATH "$DRILL_HOME/bin"


# ============================================================================ #
#                                    M i s c
# ============================================================================ #

#add_PATH "/usr/local/etcd"
#add_PATH "/usr/local/artifactory-oss/bin"
#add_PATH "/usr/local/jmeter/bin"
#add_PATH "/usr/local/jruby/bin"
#add_PATH "/usr/local/jython/bin"
#add_PATH "/usr/local/mysql/bin"

#add_PATH ~/bin/expect
#add_PATH "$RANCID_HOME/bin"
#add_PATH /usr/lib/bin/distcc
#add_PATH "/usr/lib/nagios/plugins"
#add_PATH "/usr/nagios/libexec"
#add_PATH "/usr/nagios/libexec/contrib"

#if [ -n "$APPLE" ]; then
#    # MacPort and Octave installation
#    add_PATH /opt/local/bin
#
#    if [ -d "/Applications/VMware Fusion.app/Contents/Library" ]; then
#        add_PATH "/Applications/VMware Fusion.app/Contents/Library"
#    fi
#fi

# ============================================================================ #
#                               C a s s a n d r a
# ============================================================================ #

#export CASSANDRA_HOME=/usr/local/cassandra
#export CCM_HOME=/usr/local/ccm
#add_PATH "$CASSANDRA_HOME/bin"
#add_PATH "$CASSANDRA_HOME/tools/bin"
#add_PATH "$CCM_HOME/bin"


# ============================================================================ #
#                           E l a s t i c s e a r c h
# ============================================================================ #

#export ELASTICSEARCH_HOME=/usr/local/elasticsearch
#add_PATH "$ELASTICSEARCH_HOME/bin"


# ============================================================================ #
#                               C o u c h b a s e
# ============================================================================ #

#export COUCHBASE_HOME="/Applications/Couchbase Server.app/Contents/Resources/couchbase-core"
#alias cbq="$COUCHBASE_HOME/bin/cbq"
#add_PATH "$COUCHBASE_HOME/bin"


# ============================================================================ #
#                                  G r o o v y
# ============================================================================ #

# brew install groovy
#export GROOVY_HOME=/usr/local/opt/groovy/libexec
# brew uninstall groovy
# brew install groovysdk
#export GROOVY_HOME=/usr/local/opt/groovysdk/libexec

# using SDK Man now, sourced at end of private .bashrc


# ============================================================================ #
#                        H a d o o p   E c o s y s t e m
# ============================================================================ #

## ln -s  /usr/local/hadoop-x.y.z /usr/local/hadoop
## ln -s  /usr/local/hbase-x.y.z /usr/local/hadoop
## ln -s /usr/local/zookeeper-x.y.z /usr/local/zookeeper
#
# #find /usr/local -type d -name 'hadoop-*' -o -name 'hbase-*' -o -name 'zookeeper-*' -maxdepth 1 | while read path; do sudo ln -vfsh "$path" "${path%%-*}"; done
# link_latest '/usr/local/hadoop-*' '/usr/local/hbase-*' '/usr/local/pig-*' '/usr/local/zookeeper-*'
# chown -R hari /usr/local/{hadoop,hbase,zookeeper}
# re-enabled HADOOP_HOME for Kite SDK

#export HADOOP_HOME="/usr/local/hadoop"    # Deprecated. Annoying error msgs
#export HADOOP_PREFIX="/usr/local/hadoop"  # Hate this
## For OSX
#export HADOOP_OPTS="$HADOOP_OPTS -Djava.security.krb5.realm= -Djava.security.krb5.kdc="
#export HBASE_OPTS="  $HBASE_OPTS -Djava.security.krb5.realm= -Djava.security.krb5.kdc="
#export HBASE_HOME=/usr/local/hbase
#export PIG_HOME=/usr/local/pig
#export ZOOKEEPER_HOME=/usr/local/zookeeper
#add_PATH "$HADOOP_PREFIX/bin"
#add_PATH "$HBASE_HOME/bin"
#add_PATH "$PIG_HOME/bin"
#add_PATH "$ZOOKEEPER_HOME/bin"

#export MAHOUT_HOME=/usr/local/mahout
## indicates to run locally instead of on Hadoop
#export MAHOUT_LOCAL=true
#add_PATH "$MAHOUT_HOME/bin"


# ============================================================================ #
#                              0 x d a t a   H 2 O
# ============================================================================ #

#export H2O_HOME=/usr/local/h2o
#alias h2o="cd $H2O_HOME && java -jar h2o.jar -Xmx1g"


# ============================================================================ #
#                                   J e t t y
# ============================================================================ #

#export JETTY_HOME="/usr/local/jetty-hightide"
#alias jetty="cd $JETTY_HOME/ && java -jar start.jar"


# ============================================================================ #
#                                   M e s o s
# ============================================================================ #

# this breaks parsing if supplying without port and causes duplicate --master switch if supplying the switch manually to mesos-slave or mesos-slave.sh
#export MESOS_MASTER=$HOST:5050

# link_latest /usr/local/mesos
#export MESOS_HOME=/usr/local/mesos
#add_PATH "$MESOS_HOME/bin"

#if [ -n "$APPLE" ]; then
#    export MESOS_NATIVE_JAVA_LIBRARY=/usr/local/mesos/src/.libs/libmesos.dylib
#else
#    # check this path
#    export MESOS_NATIVE_JAVA_LIBRARY=/usr/local/mesos/lib/libmesos.so
#fi
# deprecated old var
#export MESOS_NATIVE_LIBRARY="$MESOS_NATIVE_JAVA_LIBRARY"


# ============================================================================ #
#                                 M o n g o D B
# ============================================================================ #

#export MONGO_HOME=/usr/local/mongo
#add_PATH "$MONGO_HOME/bin"
#add_PATH "$github/mtools"


# ============================================================================ #
#                                   N e o 4 J
# ============================================================================ #

#export NEO4J_HOME="/usr/local/neo4j"
#add_PATH "$NEO4J_HOME/bin"


# ============================================================================ #
#                                    S o l r
# ============================================================================ #

# find /usr/local -type d -name 'apache-solr-*' -maxdepth 1 | while read path; do sudo ln -vfsh "$path" "${path%%-*}"; done
# link_latest '/usr/local/apache-solr-*'
# ln -vsf /usr/local/apache-solr /usr/local/solr
# 3.x
#export SOLR_HOME=/usr/local/apache-solr
# 4.x
#export SOLR_HOME=/usr/local/solr
#export APACHE_SOLR_HOME="$SOLR_HOME"
#add_PATH "$SOLR_HOME/bin"
#add_PATH "$SOLR_HOME/example/scripts/cloud-scripts"


# ============================================================================ #
#                                   S t o r m
# ============================================================================ #

#export STORM_HOME=/usr/local/storm
#add_PATH "$STORM_HOME/bin"


# ============================================================================ #
#                                 T a c h y o n
# ============================================================================ #

#export TACHYON_HOME=/usr/local/tachyon
#add_PATH "$TACHYON_HOME/bin"

# ============================================================================ #
#                              B a s h o   R i a k
# ============================================================================ #

#export RIAK_HOME=/usr/local/riak
#add_PATH "$RIAK_HOME/bin"


# ============================================================================ #
#                                   S c a l a
# ============================================================================ #

#add_PATH "/usr/local/scala/bin"


# ============================================================================ #
#                                   S p a r k
# ============================================================================ #

#export SPARK_HOME=/usr/local/spark
#add_PATH "$SPARK_HOME/bin"


# ============================================================================ #
#                               S o n a r Q u b e
# ============================================================================ #

#export SONAR_SCANNER_HOME=/usr/local/sonar-scanner
#add_PATH "$SONAR_SCANNER_HOME/bin"


# ============================================================================ #
#                       TypeSafe Activator - Akka, Play
# ============================================================================ #

# link_latest /usr/local/activator-dist-*
#export ACTIVATOR_HOME=/usr/local/activator-dist
#add_PATH "$ACTIVATOR_HOME"

export PATHS_SET=1
