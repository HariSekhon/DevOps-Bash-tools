Hari Sekhon - DevOps Bash Tools
===============================
[![Build Status](https://travis-ci.org/HariSekhon/DevOps-Bash-tools.svg?branch=master)](https://travis-ci.org/HariSekhon/DevOps-Bash-tools)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/c61193dd7dcc418b85149bddf93362e4)](https://www.codacy.com/app/harisekhon/bash-tools)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20OS%20X-blue.svg)](https://github.com/harisekhon/bash-tools#hari-sekhon---bash-tools)
[![DockerHub](https://img.shields.io/badge/docker-available-blue.svg)](https://hub.docker.com/r/harisekhon/centos-github/)

Shell Scripts & Utility Code Library used by all my other [GitHub repos](https://github.com/harisekhon).

For more advanced Systems Administration scripts in other languages, see the repos listed at the bottom of the page.

- Scripts - Linux systems administration scripts
  - installation scripts for various OS packages (RPM, Deb, Apk) for various Linux distros (Redhat RHEL / CentOS / Fedora, Debian / Ubuntu, Alpine)
  - install if absent scripts for Python and Perl modules - good for combining with first attempt to install via system packages, and then these will pull from PyPI or CPAN only those modules which aren't installed. This speeds up builds and uses the standard packaged modules where possible. This is also more reliable than getting random compile errors from CPAN as libraries update and introduce bugs or needing to install too many dev libraries
  - install scripts for Jython and build tools like Gradle and SBT for when Linux distros don't provide packaged versions or where the packaged versions are too old
  - Git branch management
  - utility scripts used from other scripts

- `.bashrc` - shell tuning and sourcing of `.bash.d/*.sh`
- `.bash.d/*.sh` - tonnes of functions and aliases for Linux, Docker, Kubernetes, Kafka, automatic GPG and SSH agent handling etc.
- `lib` - Bash utility libraries full of functions for Docker, environment, CI detection, port and HTTP url availability content checks etc.
- `kafka_wrappers` - scripts to make kafka cli usage easier (for Solr CLI usage see solr-cli.pl in [DevOps Perl Tools](https://github.com/harisekhon/devops-perl-tools))

- Programming language linting:

  - Python (syntax, pep8, pre-byte-compiling)
  - Perl
  - Java
  - Scala
  - Ruby
  - Shell
  - Misc (whitespace, custom enforced checks like not calling quit() in python etc)

- Build System and CI linting:

  - Make
  - Maven
  - SBT
  - Gradle
  - Travis CI

- Data format validation using programs from my [DevOps Python Tools repo](https://github.com/harisekhon/devops-python-tools):

  - CSV
  - JSON
  - Avro
  - Parquet
  - INI / Properties files (Java)
  - LDAP LDIF
  - XML
  - YAML

Currently utilized in the following GitHub repos:

* [Advanced Nagios Plugins Collection](https://github.com/harisekhon/nagios-plugins) - 400+ programs covering every major Hadoop & NoSQL technology and Linux/Unix based infrastructure technologies
* [DevOps Python Tools](https://github.com/harisekhon/devops-python-tools) - 75+ command line tools
* [DevOps Perl Tools](https://github.com/harisekhon/devops-perl-tools) - 25+ command line tools
* [Perl Lib](https://github.com/harisekhon/lib) - Perl utility library
* [PyLib](https://github.com/harisekhon/pylib) - Python utility library
* [Lib-Java](https://github.com/harisekhon/lib-java) - Java utility library
* [Nagios Plugin Kafka](https://github.com/harisekhon/nagios-plugin-kafka) - Kafka Nagios Plugin written in Scala with Kerberos support

[Pre-built Docker images](https://hub.docker.com/u/harisekhon/) are available for those repos (which include this one as a submodule) and the ["docker available"](https://hub.docker.com/r/harisekhon/centos-github/)  icon above links to an [uber image](https://hub.docker.com/r/harisekhon/centos-github/) which contains all my github repos pre-built. There are [Centos](https://hub.docker.com/r/harisekhon/centos-github/), [Debian](https://hub.docker.com/r/harisekhon/debian-github/) and [Ubuntu](https://hub.docker.com/r/harisekhon/ubuntu-github/) versions of this uber Docker image containing all repos.
