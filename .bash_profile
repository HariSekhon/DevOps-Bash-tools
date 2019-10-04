#
#  Author: Hari Sekhon
#  Date: 2006-06-28 23:25:09 +0100 (Wed, 28 Jun 2006)
#

# ~/.bash_profile: executed by bash(1) for login shells.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

trap clear EXIT

# the default umask is set in /etc/login.defs
#umask 022

if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
#welcome

# from brew install bash-completion
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"

#sudo setmixer -V pcm 100

# ============================================================================ #
# This should be automatically added to ~/.bash_profile when you install SDKman (setup/install_sdkman.sh):
#
##THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
#export SDKMAN_DIR="/Users/hari.sekhon/.sdkman"
#[[ -s "/Users/<user>/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/<user>/.sdkman/bin/sdkman-init.sh"
