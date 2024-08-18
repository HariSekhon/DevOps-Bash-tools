Setup
=====

- Package lists used by the `make` build at the top level
  - OS packages - Mac OS X / macOS and Linux distributions (RHEL/CentOS, Debian/Ubuntu, Alpine)
  - language libraries for Python, Perl, Golang
- Simple installation scripts are found in the `../install/install_*.sh` directory for common technologies that make it
  very easy to install software
- the top level `Makefile` installs these packages using `make` for the core CI/CD list or `make desktop` for all the
  extra goodies you might use on your Desktop or Laptop
- configurations in this directory and `../configs` directory make it easy to set up a new laptop / workstation
  every time you work for a new company
- `make link` symlinks all the `../configs` listed in the `files.txt` in this directory

Almost nothing should need to be done manually, a single `make desktop` command and you should be up and running.

### Mac XCode for Developers

Run `git` - it will automatically prompt to install XCode if needed. If git runs, XCode is likely already installed.
