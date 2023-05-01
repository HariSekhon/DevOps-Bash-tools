#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-27 10:35:08 +0100 (Thu, 27 Aug 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Backs up Kubernetes Etcd database on a kubeadm cluster to etcd-kubernetes-backup-DATETIMESTAMP.tar.gz, containing the Etcd database snapshot and PKI certs

Requires 'etcdctl' to be in \$PATH

When restoring, you must restore all nodes because the restore will override the cluster id and member id so the nodes won't communicate on partial nodes restore. Restores of lost nodes require new node has the same IP address

Tested on Etcd v3
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

#min_args 1 "$@"

backup_timestamp="$(date '+%F_%H%M')"

backup_dir="etcd-snapshot-$backup_timestamp.db"
backup_tar="etcd-kubernetes-backup-$backup_timestamp.tar.gz"

export ETCDCTL_API=3

timestamp "backing up Etcd database to directory $backup_dir"
# should be root
etcdctl snapshot save "$backup_dir" \
                      --cacert /etc/kubernetes/pki/etcd/server.crt \
                      --cert   /etc/kubernetes/pki/etcd/ca.crt \
                      --key    /etc/kubernetes/pki/etcd/ca.key
echo >&2
timestamp "checking Etcd backup"
etcdctl --write-out table snapshot status "$backup_dir"

echo >&2
timestamp "tar'ing Etcd backup and /etc/kubernetes/pki/etc certs"
tar cvzf "$backup_tar" "$backup_dir" /etc/kubernetes/pki/etc
