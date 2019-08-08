Advanced Bashrc Code - Interactive Functions, Aliases and Shell Customizations
==============================================================

Advanced bashrc code I've been using for 10-15 years. This is a work-in-progress as there are thousands of lines of bashrc stuff still to sanitize and export here from my private repo.

All `*.sh` files in this directory are automatically sourced by .bashrc at the top level which is itself designed to be sourced in your $HOME/.bashrc.

To disable any these source files, simply rename them to not match the `*.sh` glob, eg. => `*.sh.disabled`.

* `aliases.sh` - general aliases
* `functions.sh` - general functions
* `ssh-agent.sh` / `gpg-agent.sh` - auto-starts SSH and GPG agents if not already running, stores and auto-sources their details for new shells to automatically
* `<technology>.sh` - functions and aliases related to day-to-day use of a specific technology such a Git, Kubernetes, Kafka, Docker etc.

More script related functions can be found in the [lib/](https://github.com/HariSekhon/DevOps-Bash-tools/tree/master/lib) directory at the top level.
