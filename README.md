Hari Sekhon - DevOps Bash Tools
===============================

[![Build Status](https://travis-ci.org/HariSekhon/DevOps-Bash-tools.svg?branch=master)](https://travis-ci.org/HariSekhon/DevOps-Bash-tools)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/c61193dd7dcc418b85149bddf93362e4)](https://www.codacy.com/app/harisekhon/bash-tools)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20OS%20X-blue.svg)](https://github.com/harisekhon/bash-tools#hari-sekhon---bash-tools)
[![DockerHub](https://img.shields.io/badge/docker-available-blue.svg)](https://hub.docker.com/r/harisekhon/centos-github/)

100+ Shell Scripts, Advanced Bash environment & Utility Code Library used by all my other [GitHub repos](https://github.com/harisekhon) CI builds.

Contains:

- Systems Administation scripts - scripts to make systems administration faster and easier for common tasks, including wrappers to common commands that auto-populate required switches and advanced bashrc functions like `pass` which prompts for a password (star echo'd to screen) and stores it in the shell environment ram, which several scripts can then use to curl APIs without re-entering the password each time, nor exposing passwords on the CLI or in audit logs from command logging
- Scripts for CI builds across all my other repos, forming a drop-in framework containing many common checks
- Bash environment enhancements - advanced `.bashrc` + `.bash.d/*.sh`, advanced configuration files for common tools like [vim](https://www.vim.org/), [screen](https://www.gnu.org/software/screen/), [tmux](https://github.com/tmux/tmux/wiki), installs the best sysadmin packages like those above plus [AWS CLI](https://aws.amazon.com/cli/), [jq](https://stedolan.github.io/jq/) and many others, adds dynamic Git and shell behaviour enhancements, colouring, functions, aliases and automatic pathing of many common installation locations for many major languages like Python, Perl, Ruby, NodeJS...
- Utility library used in many scripts here and sourced from other repos, using the 2 libraries
  - `.bash.d` - interactive library (huge)
  - `lib` - script library

For more advanced Systems Administration scripts in other languages, see the repos listed at the bottom of the page.

These scripts can be used straight from the git clone, but see setup benefits of `make install` next.

Hari Sekhon

Cloud & Big Data Contractor, United Kingdom

(ex-Cloudera, former Hortonworks Consultant)

[https://www.linkedin.com/in/harisekhon](https://www.linkedin.com/in/harisekhon)
###### (you're welcome to connect with me on LinkedIn)

### Quick Setup

```
make install
```

- Adds sourcing to `.bashrc`/`.bash_profile` to automatically inherit all `.bash.d/*.sh` environment enhancements for all technologies (see [Inventory Overview](https://github.com/harisekhon/devops-bash-tools#Inventory-Overview) below)
- Symlinks all `.*` config files to `$HOME` for [git](https://git-scm.com/), [vim](https://www.vim.org/), top, [htop](https://hisham.hm/htop/), [screen](https://www.gnu.org/software/screen/), [tmux](https://github.com/tmux/tmux/wiki), [editorconfig](https://editorconfig.org/), [Ansible](https://www.ansible.com/) etc.
- Installs OS package dependencies for all scripts (detects the OS and installs the right RPMs, Debs, Apk or Mac HomeBrew packages)
- Installs Python packages including [AWS CLI](https://aws.amazon.com/cli/)

`make install` effectively does `make system-packages bash python aws`, but if you want to pick and choose from different sections, see [Individual Setup Parts](https://github.com/harisekhon/devops-bash-tools#Individual-Setup-Parts) below.

### Inventory Overview

- Scripts - [Linux](https://en.wikipedia.org/wiki/Linux) / [Mac](https://en.wikipedia.org/wiki/MacOS) systems administration scripts:
  - installation scripts for various OS packages (RPM, Deb, Apk) for various Linux distros ([Redhat RHEL](https://www.redhat.com/en/technologies/linux-platforms/enterprise-linux) / [CentOS](https://www.centos.org/) / [Fedora](https://getfedora.org/), [Debian](https://www.debian.org/) / [Ubuntu](https://ubuntu.com/), [Alpine](https://alpinelinux.org/))
  - install if absent scripts for Python, Perl, Ruby, NodeJS and Golang packages - good for minimizing the number of source code installs by first running the OS install scripts and then only building modules which aren't already detected as installed (provided by system packages), speeding up builds and reducing the likelihood of compile failures
  - install scripts for [Jython](https://www.jython.org/) and build tools like [Gradle](https://gradle.org/) and [SBT](https://www.scala-sbt.org/) for when Linux distros don't provide packaged versions or where the packaged versions are too old
  - Git branch management
  - utility scripts used from other scripts
- `.*` - dot conf files for lots of common software eg. advanced `.vimrc`, `.gitconfig`, massive `.gitignore`, `.editorconfig`, `.screenrc`, `.tmux.conf` etc.
  - `.vimrc` - contains many awesome [vim](https://www.vim.org/) tweaks, plus hotkeys for linting lots of different file types in place, including Python, Perl, Bash / Shell, Dockerfiles, JSON, YAML, XML, CSV, INI / Properties files, LDAP LDIF etc without leaving the editor!
  - `.screenrc` - fancy [screen](https://www.gnu.org/software/screen/) configuration including advanced colour bar, large history, hotkey reloading, auto-blanking etc.
  - `.tmux.conf` - fancy [tmux](https://github.com/tmux/tmux/wiki) configuration include advanced colour bar and plugins, settings, hotkey reloading etc.
  - [Git](https://git-scm.com/):
    - `.gitconfig` - advanced Git configuration
    - `.gitignore` - extensive Git ignore of trivial files you shouldn't commit
    - enhanced Git diffs
    - protections against committing AWS access keys & secrets keys, merge conflict unresolved files
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
- `aws*.sh` - various [AWS](https://aws.amazon.com/) scripts for EC2 metadata, Spot Termination, SSM Parameter Store secret put from prompt, IAM Credential Reports on IAM users without MFA, old access keys and passwords, old user accounts that haven't logged in or used an access key recently, show password policy / set hardened password policy, show unattached IAM policies, show account summary to check various details including root account MFA enabled and no access keys etc.
- `gce*.sh` - [Google Cloud](https://cloud.google.com/) scripts for [GCE](https://cloud.google.com/compute/) metadata API and pre-emption
- `curl_auth.sh` - wraps curl to send your username and password from environment variables or interactive prompt through a ram file descriptor to avoid using the `-u`/`--user` argument which can be logged by the OS, exposing your credentials in plaintext in log files
- `k8s_api.sh` - finds Kubernetes API and runs your curl arguments against it, auto-getting authorization token and populating `Authorization: Bearer` header
- `ldapsearch.sh` - wraps ldapsearch inferring settings from environment, can use environment variables for overrides
- `ldap_user_recurse.sh` / `ldap_group_recurse.sh` - recurse Active Directory LDAP users upwards to find all parent groups, or groups downwards to find all nested users (useful for debugging LDAP integration and group-based permissions)
- `zookeeper_client.sh` - wraps zookeeper-client, auto-finds the zookeeper quorum from `/etc/**/*-site.xml` to make it faster and easier to connect
- `beeline.sh` - connects to [HiveServer2](https://cwiki.apache.org/confluence/display/Hive/HiveServer2+Overview) via beeline, auto-populating Kerberos and SSL settings, and using `$HIVESERVER_HOST` environment variable so you can connect with no arguments (prompts for HiveServer2 address if you haven't set this environment variable)
- `beeline_zk.sh` - connects to [HiveServer2](https://cwiki.apache.org/confluence/display/Hive/HiveServer2+Overview) HA via beeline, auto-populating SSL and ZooKeeper service discovery settings (specify `$ZOOKEEPERS` environment variable to override)
- `impala_shell.sh` - connects to [Impala](https://impala.apache.org/) via impala-shell, parsing the Hadoop topology map and selecting a random datanode to connect to its Impalad. This is mostly for convenience to shorten commands and while it acts as a poor man's load balancer, you might want to instead use my real load balancer [HAProxy config for Impala](https://github.com/HariSekhon/HAProxy-configs) (and many other Big Data & NoSQL technologies). Optional environment variables `$IMPALA_HOST` (eg. point to HAProxy load balancer) and `IMPALA_SSL=1` (or use regular impala-shell `--ssl` argument pass through)
- `hdfs_checksum*.sh` - walks an HDFS directory tree and outputs HDFS native checksums, MD5-of-MD5 or the portable externally comparable CRC32, in serial or in parallel to save time
- `hdfs_find_replication_factor_1.sh` / `hdfs_set_replication_factor_3.sh` - finds HDFS files with replication factor 1 / sets HDFS files with replication factor <=2 to replication factor 3 to repair replication safety and avoid no replica alarms during maintenance operations (see also Python API version in the [DevOps Python Tools](https://github.com/harisekhon/devops-python-tools) repo)
- `hdfs_file_size.sh` / `hdfs_file_size_including_replicas.sh` - quickly differentiate HDFS files raw size vs total replicated size
- `cloudera_manager_impala_queries.sh` - queries [Cloudera Manager](https://www.cloudera.com/products/product-components/cloudera-manager.html) for recent [Impala](https://impala.apache.org/) queries
- `check_*.sh` - extensive collection of generalized tests that can be applied to any repo (these run against all my GitHub repos via CI)
- `git*.sh` - various useful Git scripts like iterating all branches executing command arguments, submodule handling, merging master updates to all branches, fetching GitHub users public SSH keys for quick local installation etc.
- `perl*.sh` - various Perl utilities including scripts to generate fatpacks (self-contained programs with all CPAN modules built-in), find the Perl library base, find where a Perl CLI tool is installed (system vs user, useful when it gets installed to a place that isn't in your `$PATH`, where `which` won't help), print the perl module search path, find unused CPAN modules in project, find duplicate CPAN modules between projects and sub-projects, bulk install file lists of CPAN modules, install CPAN packages only when not present in perl path (either OS packages or CPAN) to avoid needless installations, saving time and reducing build failures
- `python*.sh` - various Python utilities including scripts to byte-compile, find the Python library base, find where a Python CLI tool is installed (system vs user, useful when it gets installed to a place that isn't in your `$PATH`, where `which` won't help), print the module search path, find unused pip modules in projects, find duplicate pip modules between projects and sub-projects, convert Python module names to import names, bulk install file lists of packages, install packages only when not present in python path (either OS or pip - avoids pip installing packages provided by OS, speeds up builds and reduces build failures
  - all builds across all my GitHub repos now `make system-packages` before `make pip` / `make cpan` to shorten how many packages need installing, reducing chances of build failures

- Programming language linting:

  - [Python](https://www.python.org/) (syntax, pep8, byte-compiling, reliance on asserts which can be disabled at runtime, except/pass etc.)
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

* [DevOps Python Tools](https://github.com/harisekhon/devops-python-tools) - 80+ DevOps CLI tools for AWS, Hadoop, HBase, Spark, Log Anonymizer, Ambari Blueprints, AWS CloudFormation, Linux, Docker, Spark Data Converters & Validators (Avro / Parquet / JSON / CSV / INI / XML / YAML), Elasticsearch, Solr, Travis CI, Pig, IPython

* [The Advanced Nagios Plugins Collection](https://github.com/harisekhon/nagios-plugins) - 450+ programs for Nagios monitoring your Hadoop & NoSQL clusters. Covers every Hadoop vendor's management API and every major NoSQL technology (HBase, Cassandra, MongoDB, Elasticsearch, Solr, Riak, Redis etc.) as well as message queues (Kafka, RabbitMQ), continuous integration (Jenkins, Travis CI) and traditional infrastructure (SSL, Whois, DNS, Linux)

* [DevOps Perl Tools](https://github.com/harisekhon/perl-tools) - 25+ DevOps CLI tools for Hadoop, HDFS, Hive, Solr/SolrCloud CLI, Log Anonymizer, Nginx stats & HTTP(S) URL watchers for load balanced web farms, Dockerfiles & SQL ReCaser (MySQL, PostgreSQL, AWS Redshift, Snowflake, Apache Drill, Hive, Impala, Cassandra CQL, Microsoft SQL Server, Oracle, Couchbase N1QL, Dockerfiles, Pig Latin, Neo4j, InfluxDB), Ambari FreeIPA Kerberos, Datameer, Linux...

* [HAProxy-configs](https://github.com/harisekhon/haproxy-configs) - 80+ HAProxy Configs for Hadoop, Big Data, NoSQL, Docker, Elasticsearch, SolrCloud, HBase, Cloudera, Hortonworks, MapR, MySQL, PostgreSQL, Apache Drill, Hive, Presto, Impala, ZooKeeper, OpenTSDB, InfluxDB, Prometheus, Kibana, Graphite, SSH, RabbitMQ, Redis, Riak, Rancher etc.

* [Dockerfiles](https://github.com/HariSekhon/Dockerfiles) - 50+ DockerHub public images for Docker & Kubernetes - Hadoop, Kafka, ZooKeeper, HBase, Cassandra, Solr, SolrCloud, Presto, Apache Drill, Nifi, Spark, Mesos, Consul, Riak, OpenTSDB, Jython, Advanced Nagios Plugins & DevOps Tools repos on Alpine, CentOS, Debian, Fedora, Ubuntu, Superset, H2O, Serf, Alluxio / Tachyon, FakeS3

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

Adds sourcing to `.bashrc` and `.bash_profile` and symlinks dot config files to `$HOME` (doesn't install OS system package dependencies):

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

### Full Help

```
> make help

 Usage:

  Common Options:

    make help                   show this message
    make build                  installs all dependencies - OS packages and any language libraries via native tools eg. pip, cpanm, gem, go etc that are not available via OS packages
    make system-packages        installs OS packages only (detects OS via whichever package manager is available)
    make test                   run tests
    make clean                  removes compiled / generated files, downloaded tarballs, temporary files etc.

    make submodules             initialize and update submodules to the right release (done automatically by build / system-packages)

    make cpan                   install any modules listed in any cpan-requirements.txt files if not already installed

    make pip                    install any modules listed in any requirements.txt files if not already installed

    make python-compile         compile any python files found in the current directory and 1 level of subdirectory
    make pycompile

    make github                 open browser at github project
    make readme                 open browser at github's README
    make github-url             print github url and copy to clipboard

    make ls-files               print list of files in project
    make ls-code                print list of code files, excluding READMEs and other peripheral files
    make wc                     show line counts of the files and grand total
    make wc-code                show line counts of only code files and total

  Repo specific options:

    make install                builds all script dependencies, installs AWS CLI, symlinks all config files to $HOME and adds sourcing of bash profile

    make link                   symlinks all config files to $HOME and adds sourcing of bash profile
    make unlink                 removes all symlinks pointing to this repo's config files and removes the sourcing lines from .bashrc and .bash_profile

    make python-desktop         installs all Python Pip packages for desktop workstation listed in setup/pip-packages-desktop.txt
    make perl-desktop           installs all Perl CPAN packages for desktop workstation listed in setup/cpan-packages-desktop.txt
    make ruby-desktop           installs all Ruby Gem packages for desktop workstation listed in setup/gem-packages-desktop.txt
    make golang-desktop         installs all Golang packages for desktop workstation listed in setup/go-packages-desktop.txt

    make desktop                installs all of the above + many desktop OS packages listed in setup/

    make bootstrap              all of the above + installs a bunch of major common workstation software packages like Ansible, Terraform, MiniKube, MiniShift, SDKman, Travis CI, CCMenu, Parquet tools etc.

    make ls-scripts             print list of scripts in this project, ignoring code libraries in lib/ and .bash.d/
    make wc-scripts             show line counts of the scripts and grand total
    make wc-scripts2            show line counts of only scripts and total

    make vim                    installs Vundle and plugins
    make tmux                   installs TMUX plugin for kubernetes context
    make ccmenu                 installs and (re)configures CCMenu to watch this and all other major HariSekhon GitHub repos

    make aws                    installs AWS CLI tools
    make gcp                    installs GCloud SDK
    make gcp-shell              sets up GCP Cloud Shell: installs core packages and links configs
make: *** [help] Error 3
```

(`make help` exits with error code 3 like most of my programs to differentiate from build success to make sure a stray `help` argument doesn't cause silent build failure with exit code 0)

### Stargazers over time

[![Stargazers over time](https://starchart.cc/HariSekhon/DevOps-Bash-tools.svg)](https://starchart.cc/HariSekhon/DevOps-Bash-tools)
