#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2006 (forked from .bashrc)
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
#                                   $ P A T H
# ============================================================================ #

# general path additions that aren't big enough to have their own <technology>.sh file

# this is sourced in .bashrc before .bash.d/*.sh because add_PATH() is used extensively everywhere to deduplicate $PATHs across disparate code and also reloads before it gets to this point in the .bash.d/*.sh lexically ordered list

if type add_PATH &>/dev/null && [ -n "${PATHS_SET:-}" ]; then
    return
fi

bash_tools="${bash_tools:-$(dirname "${BASH_SOURCE[0]}")/..}"

# unreliable that HOME is set, ensure shell evaluates to the right thing before we use it
[ -n "${HOME:-}" ] || HOME=~

github="${github:-$HOME/github}"

# shellcheck disable=SC1090,SC1091
. "$bash_tools/.bash.d/os_detection.sh"

# ============================================================================ #

repaths(){
    unset PATHS_SET
    # shellcheck disable=SC1091
    source "$bash_tools/.bash.d/paths.sh"
}

#export PATH="${PATH%%:~/github*}"
add_PATH(){
    export PATH="$PATH:$1"
    # this clever stuff kills performance and I want my shell to open faster
    # it's not worth saving a few duplicates in $PATH
    # was used by dedupe paths at the end of this file
    #local env_var
    #local path
    #if [ $# -gt 1 ]; then
    #    env_var="$1"
    #    path="$2"
    #else
    #    env_var=PATH
    #    path="${1:-}"
    #fi
    #path="${path%/}"
    #path="${path//[[:space:]]/}"
    #if [[ "$path" =~ \$ ]]; then
    #    echo "WARNING: skipping add path '$path' for safety"
    #    return
    #fi
    #if ! [[ "${!env_var}" =~ (^|:)$path(:|$) ]]; then
    #    # shellcheck disable=SC2140
    #    eval "$env_var"="${!env_var}:$path"
    #fi
    ## to prevent Empty compile time value given to use lib at /Users/hari/perl5/lib/perl5/perl5lib.pm line 17.
    ##PERL5LIB="${PERL5LIB##:}"
    ## fix for Codeship having a space after one of the items in their $PATH, causing the second half of the $PATH to error out as a command
    #eval "$env_var"="${!env_var//[[:space:]]/}"
    #eval "$env_var"="${!env_var##:}"
    #export "${env_var?env_var not defined in add_PATH}"
}

# use 'which -a'
#
#binpaths(){
#    if [ $# != 1 ]; then
#        echo "usage: binpaths <binary>"
#        return 1
#    fi
#    local bin="$1"
#    tr ':' '\n' <<< "$PATH" |
#    while read -r path; do
#        if [ -x "$path/$bin" ]; then
#            echo "$path/$bin"
#        fi
#    done
#}

add_PATH "/bin"
add_PATH "/usr/bin"
add_PATH "/sbin"
add_PATH "/usr/sbin"
add_PATH "/usr/local/sbin"
add_PATH "/usr/local/bin"
add_PATH "/usr/local/opt/python/libexec/bin"  # Mac brew installed Python, must be ahead of ~/anaconda/bin below
add_PATH "/opt/homebrew/bin/"  # on new M1 Macs
add_PATH "$bash_tools"
add_PATH ~/bin
add_PATH ~/.local/bin
while read -r x; do
    # much less noisy to just just find the right dirs instead of testing lots of files
    #[ -d "$x" ] || continue
    #if [ -d "$x/bin" ]; then
    #    add_PATH "$x/bin"
    #else
        add_PATH "$x"
    #fi
done < <(for x in "$bash_tools" ~/bin; do find "$x" -maxdepth 2 -type d -name bin; done)

# Serverless.com framework
if [ -d ~/.serverless/bin ]; then
    add_PATH ~/.serverless/bin
fi

# HomeBrew on Linux
if [ -d /opt/homebrew/bin ]; then
    add_PATH /opt/homebrew/bin
fi

# HomeBrew on Linux
if [ -d ~/.linuxbrew/bin ]; then
    add_PATH ~/.linuxbrew/bin
fi

# AWS CLI Linux install location
if [ -d ~/.local/bin ]; then
    add_PATH ~/.local/bin
fi

# AWS SAM CLI Linux install location
if [ -d "/home/linuxbrew/.linuxbrew/bin" ]; then
    add_PATH "/home/linuxbrew/.linuxbrew/bin"
fi

# Rancher Desktop
if [ -d ~/.rd/bin ]; then
    add_PATH ~/.rd/bin
fi

if [ -d ~/.pulumi/bin ]; then
    add_PATH ~/.pulumi/bin
fi

#add_PATH "${JX_HOME:-$HOME/.jx}/bin"
add_PATH ~/.jx/bin

# do the same with MANPATH
if [ -d ~/man ]; then
    MANPATH=~/man:"${MANPATH:-}"
    export MANPATH
fi

# added to .bash_profile by SnowSQL installer
#if [ -d /Applications/SnowSQL.app/Contents/MacOS ]; then
#    add_PATH /Applications/SnowSQL.app/Contents/MacOS
#fi

# so that you can open files in IntelliJ from the command line: idea <filename>
if [ -d "/Applications/IntelliJ IDEA CE.app/Contents/MacOS" ]; then
    add_PATH "/Applications/IntelliJ IDEA CE.app/Contents/MacOS"
fi

if [ -d "/Applications/Visual Studio Code.app" ]; then
    # don't need this one as you can just 'code /path/to/filename' to open the file in VS Code
    #add_PATH "/Applications/Visual Studio Code.app/Contents/MacOS"  # Electron IDE is here
    add_PATH "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"  # code CLI is here
fi

# ============================================================================ #
#                                A n a c o n d a
# ============================================================================ #

# Make sure to customize Anaconda installation and de-select Modify Path otherwise it'll change the bash profile

# XXX: WARNING - this will appear earlier in the $PATH than the python bin paths, so if you have it installed, you should use it
#                otherwise pylint for example may be called from anaconda/bin but not have the pip modules necessary to check files, leading to CI breakages

# for the 'conda' command
add_PATH ~/anaconda/bin

# version installed by HomeBrew
add_PATH /usr/local/anaconda3/bin


# ============================================================================ #
#                           P a r q u e t   T o o l s
# ============================================================================ #

for x in ~/bin/parquet-tools-*; do
    if [ -d "$x" ]; then
        add_PATH "$x"
    fi
done

if [ -d /usr/local/parquet-tools ]; then
    add_PATH "/usr/local/parquet-tools"
fi


# ============================================================================ #
#                         M y   G i t H u b   r e p o s
# ============================================================================ #

# $github defined in aliases.sh
# shellcheck disable=SC2154
add_PATH "$bash_tools"
while read -r x; do
    add_PATH "$x"
done < <(find "$bash_tools" -maxdepth 1 -type d)
add_PATH "$github/go-tools"
add_PATH "$github/go"
add_PATH "$github/go-tools/bin"
add_PATH "$github/go/bin"
add_PATH "$github/perl-tools"
add_PATH "$github/perl"
add_PATH "$github/pytools"
add_PATH "$github/tools"
#add_PATH "$github/tool"
add_PATH "$github/nagios-plugins"
add_PATH "$github/nagios-plugin-kafka"
add_PATH "$github/spotify"
add_PATH "$github/spotify-tools"

if is_linux; then
    add_PATH ~/.buildkite-agent/bin
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
        if is_mac; then
            local ln_opts="-h"
        else
            local ln_opts="-T"
        fi
        # if you're in 'admin' group on Mac you don't really need to sudo here
        # shellcheck disable=SC2154
        $sudo ln -vfs $ln_opts -- "$path" "$path_noversion"
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

#if is_mac; then
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

#if is_mac; then
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

# slows down new shells
#dedupe_paths(){
#    local var="${1:-PATH}"
#    local path_tmp=""
#    # <( ) only works in Bash, but breaks when sourced from sh
#    # <( ) also ignores errors which don't get passed through the /dev/fd
#    # while read -r path; do
#    #done < <(tr ':' '\n' <<< "$PATH")
#    local IFS=':'
#    for path in ${!var}; do
#        if [[ "$path" =~ ^[[:space:]]*$ ]]; then
#            continue
#        fi
#        if ! [[ "$path_tmp" =~ :$path(:|$) ]]; then
#            path_tmp="$path_tmp:$path"
#        fi
#    done
#    eval export "$var"="\"$path_tmp\""
#}

# call in z_final.sh
#dedupe_paths

export PATHS_SET=1
