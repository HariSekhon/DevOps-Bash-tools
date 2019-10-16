Hari Sekhon - DevOps Bash Tools
===============================
[![Build Status](https://travis-ci.org/HariSekhon/DevOps-Bash-tools.svg?branch=master)](https://travis-ci.org/HariSekhon/DevOps-Bash-tools)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/c61193dd7dcc418b85149bddf93362e4)](https://www.codacy.com/app/harisekhon/bash-tools)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20OS%20X-blue.svg)](https://github.com/harisekhon/bash-tools#hari-sekhon---bash-tools)
[![DockerHub](https://img.shields.io/badge/docker-available-blue.svg)](https://hub.docker.com/r/harisekhon/centos-github/)

80+ Shell Scripts, Advanced Bashrc & Utility Code Library used by all my other [GitHub repos](https://github.com/harisekhon).

For more advanced Systems Administration scripts in other languages, see the repos listed at the bottom of the page.

These scripts can be used straight from the git clone, but see setup benefits of `make install` next.

### Quick Setup

```
make install
```

- Adds sourcing to `.bashrc`/`.bash_profile` to automatically inherit all `.bash.d/*.sh` environment enhancements for all technologies (see [Inventory Overview](https://github.com/harisekhon/devops-bash-tools#Inventory-Overview) below)
- Symlinks all `.*` config files to `$HOME` for git, vim, top, htop, screen, tmux, editorconfig, ansible etc.
- Installs OS package dependencies for all scripts (detects the OS and installs the right RPMs, Debs, Apk or Mac HomeBrew packages)
- Installs Python packages including [AWS CLI](https://aws.amazon.com/cli/)

`make install` effectively does `make system-packages bash python aws`, but if you want to pick and choose from different sections, see [Individual Setup Parts](https://github.com/harisekhon/devops-bash-tools#Individual-Setup-Parts) below.

### Inventory Overview:

- Scripts - Linux systems administration scripts:
  - installation scripts for various OS packages (RPM, Deb, Apk) for various Linux distros ([Redhat RHEL](https://www.redhat.com/en/technologies/linux-platforms/enterprise-linux) / [CentOS](https://www.centos.org/) / [Fedora](https://getfedora.org/), [Debian](https://www.debian.org/) / [Ubuntu](https://ubuntu.com/), [Alpine](https://alpinelinux.org/))
  - install if absent scripts for Python, Perl, Ruby and Golang modules - good for minimizing the number of source code installs by first running the OS install scripts and then only building modules which aren't already detected as installed (provided by system packages), speeding up builds and reducing the likelihood of compile failures
  - install scripts for [Jython](https://www.jython.org/) and build tools like [Gradle](https://gradle.org/) and [SBT](https://www.scala-sbt.org/) for when Linux distros don't provide packaged versions or where the packaged versions are too old
  - Git branch management
  - utility scripts used from other scripts
- `.*` - dot conf files for lots of common software eg. advanced `.vimrc`, `.gitconfig`, massive `.gitignore`, `.editorconfig`, `.screenrc`, `.tmux.conf` etc.
  - `.vimrc` - contains many awesome vim tweaks, plus hotkeys for linting lots of different file types in place, including Python, Perl, Bash / Shell, Dockerfiles, JSON, YAML, XML, CSV, INI / Properties files, LDAP LDIF etc without leaving the editor!
  - `.gitconfig` and extensive `.gitignore` - the bashrc profile also auto-uses `diff-so-fancy` for nicer diffs if found in `$PATH`
- `.bashrc` - shell tuning and sourcing of `.bash.d/*.sh`
- `.bash.d/*.sh` - thousands of lines of advanced bashrc code, aliases, functions and environment variables for:
  - [Linux](https://en.wikipedia.org/wiki/Linux) & [Mac](https://en.wikipedia.org/wiki/MacOS)
  - SCM - [Git](https://git-scm.com/), [Mercurial](https://www.mercurial-scm.org/), [Svn](https://subversion.apache.org)
  - [AWS](https://aws.amazon.com/)
  - [Docker](https://www.docker.com/)
  - [Kubernetes](https://kubernetes.io/)
  - [Kafka](http://kafka.apache.org/)
  - [Vagrant](https://www.vagrantup.com/)
  - automatic GPG and SSH agent handling for handling encrypted private keys without re-entering passwords, and lazy evaluation to only prompt key load the first time SSH is called
  - and lots more - see [.bash.d/README](https://github.com/HariSekhon/DevOps-Bash-tools/blob/master/.bash.d/README.md) for a more detailed list
  - run `make bash` to link `.bashrc`/`.bash_profile` and the `.*` dot config files to your `$HOME` directory to auto-inherit everything
- `lib/*.sh` - Bash utility libraries full of functions for [Docker](https://www.docker.com/), environment, CI detection ([Travis CI](https://travis-ci.org/), [Jenkins](https://jenkins.io/)), port and HTTP url availability content checks etc. Sourced from all my other [GitHub repos](https://github.com/harisekhon) to make setting up Dockerized tests easier.
- `setup/install_*.sh` - various simple to use installation scripts for common technologies like [Ansible](https://www.ansible.com/), [Terraform](https://www.terraform.io/), [MiniKube](https://kubernetes.io/docs/setup/learning-environment/minikube/) and [MiniShift](https://www.okd.io/minishift/) (Kubernetes / [Redhat OpenShift](https://www.openshift.com/)/[OKD](https://www.okd.io/) dev VMs), [Maven](https://maven.apache.org/), [Gradle](https://gradle.org/), [SBT](https://www.scala-sbt.org/), [EPEL](https://fedoraproject.org/wiki/EPEL), [RPMforge](http://repoforge.org/), [Homebrew](https://brew.sh/), [Travis CI](https://travis-ci.org/), [Parquet Tools](https://github.com/apache/parquet-mr/tree/master/parquet-tools) etc.
- `kafka_wrappers/*.sh` - scripts to make [Kafka](http://kafka.apache.org/) CLI usage easier including auto-setting Kerberos to source TGT from environment and auto-populating broker and zookeeper addresses. These are auto-added to the `$PATH` when `.bashrc` is sourced. For something similar for [Solr](https://lucene.apache.org/solr/), see `solr_cli.pl` in the [DevOps Perl Tools](https://github.com/harisekhon/devops-perl-tools) repo.

- Programming language linting:

  - [Python](https://www.python.org/) (syntax, pep8, pre-byte-compiling)
  - [Perl](https://www.perl.org/)
  - [Java](https://www.java.com/en/)
  - [Scala](https://www.scala-lang.org/)
  - [Ruby](https://www.ruby-lang.org/en/)
  - [Bash](https://www.gnu.org/software/bash/) / Shell
  - Misc (whitespace, custom enforced checks like not calling `quit()` in Python programs etc.)

- Build System & CI linting:

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

#### Individual Setup Parts

Optional, only if you don't do the full `make install`.

Install only OS system package dependencies and [AWS CLI](https://aws.amazon.com/cli/) via Python Pip (doesn't symlink anything to `$HOME`):
```
make
```

Source `.bashrc`, `.bash_profile` and symlink dot config files to `$HOME` (doesn't install OS system package dependencies):
```
make link
```
undo via
```
make unlink
```

Install only OS system package dependencies (doesn't include [AWS CLI](https://aws.amazon.com/cli/) or Python packages):
```
make system-packages
```

Install [AWS CLI](https://aws.amazon.com/cli/):
```
make aws
```

Install generically useful Python CLI tools and modules (includes [AWS CLI](https://aws.amazon.com/cli/), autopep8 etc):
```
make python
```
