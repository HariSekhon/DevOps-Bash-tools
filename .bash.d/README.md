Advanced Bashrc Code - Interactive Functions, Aliases and Shell Customizations
==============================================================

Advanced bashrc code I've been using for ~15 years, I've ported nearly 5000 lines to this public repo so far.

All `*.sh` files in this directory are automatically sourced by .bashrc at the top level which is itself designed to be sourced in your $HOME/.bashrc.

To disable any these source files, simply rename them to not match the `*.sh` glob, eg. => `*.sh.disabled`.

* `aliases.sh` - general aliases
* `functions.sh` - general functions
* `paths.sh` - deduplicated adding to `$PATH` for lots of common places (eg. /usr/sbin, /usr/local/bin, ~/bin) and technologies that don't have enough to justify their own `<technology>.sh` (which use `add_PATH()` from here), commands to clearly print on per line Bash `$PATH`, Perl `@INC` and Python `sys.path` components
* `env.sh` - general environment variables and var/unvar functions for setting environment variables for the current and all new shell sessions
* `ssh-agent.sh` / `gpg-agent.sh` - auto-starts SSH and GPG agents if not already running, stores and auto-sources their details for new shells to automatically
* `title.sh` - auto-title tricks for Screen and Terminals
* `<technology>.sh` - aliases, functions and environment variables to make interactive day-to-day use of a specific technologies easier, for example:
  * `ansible.sh` - [Ansible](https://www.ansible.com) aliases and environment variables
  * `apple.sh` - [Apple Mac OS X / macOS](https://en.wikipedia.org/wiki/MacOS) Mac specific tricks
  * `aws.sh` - auto-populates [AWS](https://aws.amazon.com/) credentials from your ~/.boto credentials files to `$AWS_ACCESS_KEY` and `$AWS_SECRET_KEY` environment variables for use with other tools without having to maintain the credentials in multiple places
  * `docker.sh` - [Docker](https://www.docker.com/) convenient aliases and functions like clearing old containers and dangling image layers to clean up space
  * `git.sh` - [Git](https://git-scm.com/) aliases and functions
  * `java.sh` - [Java](https://www.java.com/en/) detection and setting of `$JAVA_HOME` for Linux and Mac environments
  * `kafka.sh` - [Kafka](http://kafka.apache.org/) environment variables for Kerberos security, fixing to high heap defaults for CLI commands and things for kafka_wrappers/ convenience scripts to reduce the number of redundant arguments like setting your Kafka broker and zookeeper nodes
  * `kubernetes.sh` -[Kubernetes](https://kubernetes.io/) aliases and functions for daily ease of use, contexts, maintaining switching to a namespace despite `.kube/config` regeneration due to certificate expiry, switching between open source [Kubernetes](https://kubernetes.io/) and Redhat [OpenShift](https://www.openshift.com/) `kubectl` and `oc` commands, automating getting authentication token and Kubernetes API endpoints
  * `linux.sh` - [Linux](https://en.wikipedia.org/wiki/Linux) specific stuff like X.org bits
  * `network.sh` - network aliases and functions
  * `ssh.sh` - SSH convenience functions and key management
  * `vagrant.sh` - [Vagrant](https://www.vagrantup.com/) aliases and functions

More script related functions can be found in the [lib/](https://github.com/HariSekhon/DevOps-Bash-tools/tree/master/lib) directory at the top level.
