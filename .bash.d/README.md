Bashrc Interactive Functions, Aliases and Shell Customizations
==============================================================

All `*.sh` files in this directory are automatically sourced by .bashrc at the top level which is itself designed to be sourced in your $HOME/.bashrc.

To disable any these source files, simply rename them to not match the `*.sh` glob, eg. => `*.sh.disabled`.

* `aliases.sh` - general aliases
* `functions.sh` - general functions
* `<technology>.sh` - functions and aliases related to day-to-day use of a specific technology such a Git, Kubernetes, Kafka, Docker etc.

More script related functions can be found in the [lib/](https://github.com/HariSekhon/DevOps-Bash-tools/tree/master/lib) directory at the top level.
