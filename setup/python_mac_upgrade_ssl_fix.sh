#!/usr/bin/env bash
#
#  Author: Hari Sekhon
#  Date: 2019-09-16
#
#  https://github.com/harisekhon/devops-bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/harisekhon
#

# from https://stackoverflow.com/questions/24287239/abort-trap-6-when-running-a-python-script

set -euo pipefail

brew update && brew upgrade && brew install openssl
cd /usr/local/Cellar/openssl/1.0.2t/lib
sudo cp libssl.1.0.0.dylib libcrypto.1.0.0.dylib /usr/local/lib/
cd /usr/local/lib
sudo ln -s libssl.1.0.0.dylib libssl.dylib
sudo ln -s libcrypto.1.0.0.dylib libcrypto.dylib
#pip3 install --upgrade packagename
