#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-11-14 20:56:43 +0000 (Thu, 14 Nov 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Install Google Cloud SDK - uses packages where available or else installs to $HOME via the script installer
#
# You may want to install manually if using Google App Engine as the docs say to not use the packaged versions of gcloud
# when installing the app engine add-ons (probably due to path write permissions)

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

export PATH="$PATH:$HOME/google-cloud-sdk/bin"

if type -P gcloud &>/dev/null; then
    echo "GCloud already installed, skipping..."
    exit 0
fi

#apt_version="123.0.0-0"
#yum_version="123.0.0"

# installs to $HOME/google-cloud-sdk
install_root_dir=~

apt_optional_packages="
google-cloud-sdk-app-engine-python \
google-cloud-sdk-app-engine-python-extras \
google-cloud-sdk-app-engine-java \
google-cloud-sdk-app-engine-go \
google-cloud-sdk-datalab \
google-cloud-sdk-datastore-emulator \
google-cloud-sdk-gke-gcloud-auth-plugin \
google-cloud-sdk-pubsub-emulator \
google-cloud-sdk-cbt \
google-cloud-sdk-cloud-build-local \
google-cloud-sdk-bigtable-emulator \
kubectl
"

yum_optional_packages="
google-cloud-sdk-app-engine-python
google-cloud-sdk-app-engine-python-extras
google-cloud-sdk-app-engine-java
google-cloud-sdk-app-engine-go
google-cloud-sdk-bigtable-emulator
google-cloud-sdk-datalab
google-cloud-sdk-datastore-emulator
google-cloud-sdk-cbt
google-cloud-sdk-cloud-build-local
google-cloud-sdk-gke-gcloud-auth-plugin
google-cloud-sdk-pubsub-emulator
kubectl
"

sudo=sudo
[ $EUID -eq 0 ] && sudo=""

echo "Installing Google Cloud SDK"
if type -P yum &>/dev/null; then
    $sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOF
    [google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
    yum install -y google-cloud-sdk #-$yum_version
    # want splitting to single line
    # shellcheck disable=SC2086
    yum install -y $yum_optional_packages
# https://cloud.google.com/sdk/docs/downloads-apt-get
elif type -P apt-get &>/dev/null; then
    google_cloud_sdk_source="deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main"
    grep -Fq "$google_cloud_sdk_source" /etc/apt/sources.list.d/google-cloud-sdk.list 2>/dev/null ||
    $sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list <<< "$google_cloud_sdk_source"
    $sudo apt-get install -y apt-transport-https ca-certificates gnupg
    curl -sS https://packages.cloud.google.com/apt/doc/apt-key.gpg |
        $sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    $sudo apt-get update
    $sudo apt-get install -y google-cloud-sdk #=$apt_version
    # want splitting to single line
    # shellcheck disable=SC2086
    $sudo apt-get install -y $apt_optional_packages
elif [[ "$(uname -s)" =~ Darwin|Linux ]]; then
    # https://cloud.google.com/sdk/docs/downloads-interactive
    install_script="$(mktemp -t gcloud_installer.sh.XXXXXX)"
    curl -sS https://sdk.cloud.google.com > "$install_script"
    chmod +x "$install_script"
    "$install_script" --disable-prompts --install-dir="$install_root_dir"
    gcloud components install kubectl
    if [ "$(uname -s)" = Darwin ]; then
        gcloud components install gke-gcloud-auth-plugin
        gke-gcloud-auth-plugin --version
    fi
else
    echo "Unsupported OS '$(uname -s)'" >&2
    exit 1
fi

# requires interactive prompts
#echo "Initializing gcloud..."
#gcloud init
echo
echo "Done. You will need to run 'gcloud init' to set up your profile."
