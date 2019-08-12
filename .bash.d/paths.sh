#!/usr/bin/env bash
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

# add_PATH() is defined in .bashrc since it is used extensively everywhere to deduplicate $PATHs across disparate code and also reloads

perlpath(){
    perl -e 'print join("\n", @INC);'
}

# ============================================================================ #
# Anaconda

# Make sure to customize Anaconda installation and de-select Modify Path otherwise it'll change the bash profile

# for the 'conda' command
add_PATH ~/anaconda/bin

# ============================================================================ #
# Parquet Tools

if [ -d /usr/local/parquet-tools ]; then
    add_PATH "/usr/local/parquet-tools"
fi

# ============================================================================ #
# my main GitHub repos

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
# Ruby Gem commands

# gems will be installed to ~/.gem/ruby/x.y.z/bin

# add newest ruby to path first
#for ruby_bin in $(ls -d ~/.gem/ruby/*/bin 2>/dev/null | tail -r); do
for ruby_bin in $(find ~/.gem/ruby -maxdepth 2 -name bin -type d | tail -r); do
    add_PATH "$ruby_bin"
done

# ============================================================================ #
# Old Stuff

# don't use Mongo any more
#add_PATH "$github/mtools"

#add_PATH "/usr/local/etcd"

#add_PATH "/usr/local/artifactory-oss/bin"
#add_PATH "/usr/local/jmeter/bin"
#add_PATH "/usr/local/jruby/bin"
#add_PATH "/usr/local/jython/bin"
#add_PATH "/usr/local/mongodb/bin"
#add_PATH "/usr/local/mysql/bin"
#add_PATH "/usr/local/mysql/bin"
#add_PATH "/usr/local/neo4j/bin"
#add_PATH "/usr/local/riak/bin"
#add_PATH "/usr/local/scala/bin"

#add_PATH "$HOME/bin/expect"
#add_PATH "$RANCID_HOME/bin"
