#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-12-10 11:33:52 +0000 (Tue, 10 Dec 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Counts rows for all Impala tables in all databases using adjacent impala_shell.sh script
#
# Tested on Impala 2.7.0, 2.12.0 on CDH 5.10, 5.16 with Kerberos and SSL
#
# For more documentation see the comments at the top of impala_shell.sh

# you will almost certainly have to comment out / remove '-o pipefail' to skip authorization errors such as that documented in impala_list_tables.sh
# and also ignore errors from the 'select count(*)' in the loop as Impala often has metadata errors such as:
#
# ERROR: AnalysisException: Failed to load metadata for table: '<table>'
# CAUSED BY: TableLoadingException: Unsupported type 'void' in column '<column>' of table '<table>'
#
# ============================================================================ #
#
# WARNINGS: Disk I/O error: Failed to open HDFS file hdfs://nameservice1/user/hive/warehouse/<database>.db/<table>/1234a5678b90cd1-ef23a45678901234_5678901234_data.10.parq
# Error(2): No such file or directory
# Root cause: RemoteException: File does not exist: /user/hive/warehouse/<database>.db/<table>/1234a5678b90cd1-ef23a45678901234_5678901234_data.10.parq
#         at org.apache.hadoop.hdfs.server.namenode.INodeFile.valueOf(INodeFile.java:66)
#         at org.apache.hadoop.hdfs.server.namenode.INodeFile.valueOf(INodeFile.java:56)
#         at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.getBlockLocationsInt(FSNamesystem.java:2157)
#         at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.getBlockLocations(FSNamesystem.java:2127)
#         at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.getBlockLocations(FSNamesystem.java:2040)
#         at org.apache.hadoop.hdfs.server.namenode.NameNodeRpcServer.getBlockLocations(NameNodeRpcServer.java:583)
#         at org.apache.hadoop.hdfs.server.namenode.AuthorizationProviderProxyClientProtocol.getBlockLocations(AuthorizationProviderProxyClientProtocol.java:94)
#         at org.apache.hadoop.hdfs.protocolPB.ClientNamenodeProtocolServerSideTranslatorPB.getBlockLocations(ClientNamenodeProtocolServerSideTranslatorPB.java:377)
#         at org.apache.hadoop.hdfs.protocol.proto.ClientNamenodeProtocolProtos$ClientNamenodeProtocol$2.callBlockingMethod(ClientNamenodeProtocolProtos.java)
#         at org.apache.hadoop.ipc.ProtobufRpcEngine$Server$ProtoBufRpcInvoker.call(ProtobufRpcEngine.java:617)
#         at org.apache.hadoop.ipc.RPC$Server.call(RPC.java:1073)
#         at org.apache.hadoop.ipc.Server$Handler$1.run(Server.java:2278)
#         at org.apache.hadoop.ipc.Server$Handler$1.run(Server.java:2274)
#         at java.security.AccessController.doPrivileged(Native Method)
#         at javax.security.auth.Subject.doAs(Subject.java:422)
#         at org.apache.hadoop.security.UserGroupInformation.doAs(UserGroupInformation.java:1924)
#         at org.apache.hadoop.ipc.Server$Handler.run(Server.java:2272)
#

set -eu  # -o pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

# exit the loop subshell if you Control-C
trap 'exit 130' INT

"$srcdir/impala_list_tables.sh" "$@" |
while read -r db table; do
    printf '%s\t%s\t' "$db" "$table"
    #set +e
    "$srcdir/impala_shell.sh" --quiet -Bq "SELECT COUNT(*) FROM \`$db\`.\`$table\`" "$@"
    #if [ $? -eq 130 ]; then
    #    break
    #fi
    #set -e
done
