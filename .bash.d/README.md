Advanced Bashrc Code - Interactive Functions, Aliases and Shell Customizations
==============================================================

Advanced bashrc code I've been using for ~15 years, I've ported nearly 5000 lines to this public repo so far.

All `*.sh` files in this directory are automatically sourced by `.bashrc` at the top level which is itself designed to be sourced in your `$HOME/.bashrc`.

To disable any these source files, simply rename them to not match the `*.sh` glob, eg. => `*.sh.disabled`.

- `aliases.sh` - general aliases
- `functions.sh` - general functions eg. `pass` which prompts for a password which is saved to an environment variable and auto-populated in various top-level API querying scripts built on `curl_auth.sh`
- `env.sh` - general environment variables and var/unvar functions for setting environment variables for the current and all new shell sessions
- `paths.sh` - deduplicated adding to `$PATH` for lots of common places (eg. /usr/sbin, /usr/local/bin, ~/bin) and commands to clearly print one path per line for Bash `$PATH`, Perl `@INC` and Python `sys.path`. Also contains technology specific paths when there is no `<technology>.sh` file. All other includes use `add_PATH()` function defined here.
- `<technology>.sh` - aliases, functions and environment variables to make interactive day-to-day use of a specific technologies easier
  - Cloud / Containerization / Virtualization:
    - `aws.sh` - [AWS](https://aws.amazon.com) functions:
      - `aws_env` - populates credentials from `~/.aws/credentials` / `~/.boto` section given as an argument to `$AWS_ACCESS_KEY` and `$AWS_SECRET_KEY` environment variables and sets `$AWS_PROFILE` to the profile name (defaults to the 'default' profile and creds if no argument is specified)
      - `aws_envs` - prints the available envs configured in the aws credentials file and stars the one currently in use
      - `awk_token` - generates a 24-hour MFA session token, exports it as `$AWS_SESSION_TOKEN` for use with [AWS CLI](https://aws.amazon.com/cli/), and saves it to `~/.aws/token` for loading to other shells that call `aws_env`
    - `docker.sh` - [Docker](https://www.docker.com/) convenient aliases and functions like clearing old containers and dangling image layers to clean up space
    - `kubernetes.sh` - [Kubernetes](https://kubernetes.io/) aliases and functions, managing contexts and namespaces even for periodically regenerated `.kube/config` with refreshed embedded certificates, switching between open source [Kubernetes](https://kubernetes.io/) and Redhat [OpenShift](https://www.openshift.com/) `kubectl` and `oc` commands, automating getting authentication token and Kubernetes API endpoints
    - `vagrant.sh` - [Vagrant](https://www.vagrantup.com/) aliases and functions
  - Automation / Distributed Systems:
    - `ansible.sh` - [Ansible](https://www.ansible.com) aliases and environment variables
    - `kafka.sh` - [Kafka](http://kafka.apache.org/) environment variables for Kerberos security and CLI appropriate heap size (avoids heap allocation failures on VMs that otherwise default to using larger server configured heap size), avoiding need for common broker and zookeeper arguments when using `kafka_wrappers/` scripts by setting your Kafka broker and zookeeper addresses once instead of in every command
  - Coding:
    - `git.sh` - [Git](https://git-scm.com/) aliases and functions
    - `mercurial.sh` - [Mercurial](https://www.mercurial-scm.org/) aliases and functions
    - `svn.sh` - [Svn](https://subversion.apache.org) aliases and functions
    - `java.sh` - [Java](https://www.java.com/en/) detection and setting of `$JAVA_HOME` for Linux and Mac environments
  - OS:
    - `apple.sh` - [Apple Mac OS X / macOS](https://en.wikipedia.org/wiki/MacOS) specific tricks
    - `linux.sh` - [Linux](https://en.wikipedia.org/wiki/Linux) specific miscellaneous bits like X.org
    - `network.sh` - network aliases and functions
    - `ssh.sh` - SSH convenience functions and key management
    - `ssh-agent.sh` / `gpg-agent.sh` - auto-starts SSH and GPG agents if not already running, stores and auto-sources their details for new shells to automatically use them
    - `title.sh` - auto-title tricks for Screen and Terminals

More script related functions can be found in the [lib/](https://github.com/HariSekhon/DevOps-Bash-tools/tree/master/lib) directory at the top level.
