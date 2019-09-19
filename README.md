Hari Sekhon - DevOps Bash Tools
===============================
[![Build Status](https://travis-ci.org/HariSekhon/DevOps-Bash-tools.svg?branch=master)](https://travis-ci.org/HariSekhon/DevOps-Bash-tools)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/c61193dd7dcc418b85149bddf93362e4)](https://www.codacy.com/app/harisekhon/bash-tools)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20OS%20X-blue.svg)](https://github.com/harisekhon/bash-tools#hari-sekhon---bash-tools)
[![DockerHub](https://img.shields.io/badge/docker-available-blue.svg)](https://hub.docker.com/r/harisekhon/centos-github/)

70+ Shell Scripts, Advanced Bashrc & Utility Code Library used by all my other [GitHub repos](https://github.com/harisekhon).

For more advanced Systems Administration scripts in other languages, see the repos listed at the bottom of the page.

Install OS package dependencies and symlink `.bashrc` and other dot files to $HOME:
```
make install
```
This effectively does `make system-packages setup`, but if you want to only do part of it or have more control:

Symlink `.bashrc` and other dot files to $HOME without installing OS system package dependencies:
```
make setup
```

Install OS system package dependencies:
```
make system-packages
```

- Scripts - Linux systems administration scripts
  - installation scripts for various OS packages (RPM, Deb, Apk) for various Linux distros ([Redhat RHEL](https://www.redhat.com/en/technologies/linux-platforms/enterprise-linux) / [CentOS](https://www.centos.org/) / [Fedora](https://getfedora.org/), [Debian](https://www.debian.org/) / [Ubuntu](https://ubuntu.com/), [Alpine](https://alpinelinux.org/))
  - install if absent scripts for Python and Perl modules - good for combining with first attempt to install via system packages, and then these will pull from [PyPI](https://pypi.org/) or [CPAN](https://www.cpan.org/) only those modules which aren't installed. This speeds up builds and uses the standard packaged modules where possible. This is also more reliable than getting random compile errors from CPAN as libraries update and introduce bugs or needing to install too many dev libraries
  - install scripts for [Jython](https://www.jython.org/) and build tools like [Gradle](https://gradle.org/) and [SBT](https://www.scala-sbt.org/) for when Linux distros don't provide packaged versions or where the packaged versions are too old
  - Git branch management
  - utility scripts used from other scripts
- `.*` - dot conf files for lots of common software eg. advanced `.vimrc`, `.gitconfig`, massive `.gitignore`, `.editorconfig`, `.screenrc`, `.tmux.conf` etc
- `.bashrc` - shell tuning and sourcing of `.bash.d/*.sh`
- `.bash.d/*.sh` - thousands of lines of advanced bashrc code, aliases, functions and environment variables for:
  - [Linux](https://en.wikipedia.org/wiki/Linux) & [Mac](https://en.wikipedia.org/wiki/MacOS)
  - SCM - [Git](https://git-scm.com/), [Mercurial](https://www.mercurial-scm.org/), [Svn](https://subversion.apache.org)
  - [Docker](https://www.docker.com/)
  - [Kubernetes](https://kubernetes.io/)
  - [Kafka](http://kafka.apache.org/)
  - [Vagrant](https://www.vagrantup.com/)
  - automatic GPG and SSH agent handling
  - and lots more - see [.bash.d/README](https://github.com/HariSekhon/DevOps-Bash-tools/blob/master/.bash.d/README.md) for a more detailed list
  - run 'make setup' to link `.bashrc/.bash_profile` and the `.*` dot files to your `$HOME` directory to auto-inherit everything
- `lib/*.sh` - Bash utility libraries full of functions for [Docker](https://www.docker.com/), environment, CI detection ([Travis CI](https://travis-ci.org/), [Jenkins](https://jenkins.io/)), port and HTTP url availability content checks etc.
- `setup/install_*.sh` - various simple to use installation scripts for common technologies like MiniShift, Maven, Gradle, SBT, EPEL, RPMforge, Homebrew, Travis CI, Parquet Tools etc.
- `kafka_wrappers/*.sh` - scripts to make [Kafka](http://kafka.apache.org/) cli usage easier including auto-setting Kerberos to source TGT from environment and auto-populating broker and zookeeper addresses. These are auto-added to the `$PATH` when `.bashrc` is sourced. For something similar for [Solr](https://lucene.apache.org/solr/), see `solr_cli.pl` in [DevOps Perl Tools](https://github.com/harisekhon/devops-perl-tools)

- Programming language linting:

  - [Python](https://www.python.org/) (syntax, pep8, pre-byte-compiling)
  - [Perl](https://www.perl.org/)
  - [Java](https://www.java.com/en/)
  - [Scala](https://www.scala-lang.org/)
  - [Ruby](https://www.ruby-lang.org/en/)
  - [Bash](https://www.gnu.org/software/bash/) / Shell
  - Misc (whitespace, custom enforced checks like not calling quit() in python etc)

- Build System and CI linting:

  - [Make](https://www.gnu.org/software/make/)
  - [Maven](https://maven.apache.org/)
  - [SBT](https://www.scala-sbt.org/)
  - [Gradle](https://gradle.org/)
  - [Travis CI](https://travis-ci.org/)

- Data format validation using programs from my [DevOps Python Tools repo](https://github.com/harisekhon/devops-python-tools):

  - CSV
  - JSON
  - [Avro](https://avro.apache.org/)
  - [Parquet](https://parquet.apache.org/)
  - INI / Properties files (Java)
  - LDAP LDIF
  - XML
  - YAML

Currently utilized in the following GitHub repos:

* [Advanced Nagios Plugins Collection](https://github.com/harisekhon/nagios-plugins) - 450+ programs covering every major Hadoop & NoSQL technology and Linux/Unix based infrastructure technologies
* [DevOps Python Tools](https://github.com/harisekhon/devops-python-tools) - 75+ command line tools
* [DevOps Perl Tools](https://github.com/harisekhon/devops-perl-tools) - 25+ command line tools
* [Perl Lib](https://github.com/harisekhon/lib) - Perl utility library
* [PyLib](https://github.com/harisekhon/pylib) - Python utility library
* [Lib-Java](https://github.com/harisekhon/lib-java) - Java utility library
* [Nagios Plugin Kafka](https://github.com/harisekhon/nagios-plugin-kafka) - Kafka Nagios Plugin written in Scala with Kerberos support

[Pre-built Docker images](https://hub.docker.com/u/harisekhon/) are available for those repos (which include this one as a submodule) and the ["docker available"](https://hub.docker.com/r/harisekhon/centos-github/)  icon above links to an [uber image](https://hub.docker.com/r/harisekhon/centos-github/) which contains all my github repos pre-built. There are [Centos](https://hub.docker.com/r/harisekhon/centos-github/), [Alpine](https://hub.docker.com/r/harisekhon/alpine-github/), [Debian](https://hub.docker.com/r/harisekhon/debian-github/) and [Ubuntu](https://hub.docker.com/r/harisekhon/ubuntu-github/) versions of this uber Docker image containing all repos.
