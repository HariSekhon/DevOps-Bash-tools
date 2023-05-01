#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  shellcheck disable=SC2016
#
#  Author: Hari Sekhon
#  Date: 2019-12-10 11:33:52 +0000 (Tue, 10 Dec 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -eu  # -o pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Counts rows for all Impala tables in all databases using adjacent impala_shell.sh script

Output format:

<database>.<table>     <row_count>


FILTER environment variable will restrict to matching fully qualified tables (<db>.<table>)


Tested on Impala 2.7.0, 2.12.0 on CDH 5.10, 5.16 with Kerberos and SSL


For more documentation see the comments at the top of impala_shell.sh

For a better version written in Python see DevOps Python tools repo:

https://github.com/HariSekhon/DevOps-Python-tools

'set -o pipefail' is commented out to skip authorization errors such as that documented in impala_list_tables.sh
and also ignore errors from the 'select count(*)' in the loop as Impala often has metadata errors such as:

ERROR: AnalysisException: Failed to load metadata for table: '<table>'
CAUSED BY: TableLoadingException: Unsupported type 'void' in column '<column>' of table '<table>'

============================================================================ #
"'
WARNINGS: Disk I/O error: Failed to open HDFS file hdfs://nameservice1/user/hive/warehouse/<database>.db/<table>/1234a5678b90cd1-ef23a45678901234_5678901234_data.10.parq
Error(2): No such file or directory
Root cause: RemoteException: File does not exist: /user/hive/warehouse/<database>.db/<table>/1234a5678b90cd1-ef23a45678901234_5678901234_data.10.parq
        at org.apache.hadoop.hdfs.server.namenode.INodeFile.valueOf(INodeFile.java:66)
        at org.apache.hadoop.hdfs.server.namenode.INodeFile.valueOf(INodeFile.java:56)
        at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.getBlockLocationsInt(FSNamesystem.java:2157)
        at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.getBlockLocations(FSNamesystem.java:2127)
        at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.getBlockLocations(FSNamesystem.java:2040)
        at org.apache.hadoop.hdfs.server.namenode.NameNodeRpcServer.getBlockLocations(NameNodeRpcServer.java:583)
        at org.apache.hadoop.hdfs.server.namenode.AuthorizationProviderProxyClientProtocol.getBlockLocations(AuthorizationProviderProxyClientProtocol.java:94)
        at org.apache.hadoop.hdfs.protocolPB.ClientNamenodeProtocolServerSideTranslatorPB.getBlockLocations(ClientNamenodeProtocolServerSideTranslatorPB.java:377)
        at org.apache.hadoop.hdfs.protocol.proto.ClientNamenodeProtocolProtos$ClientNamenodeProtocol$2.callBlockingMethod(ClientNamenodeProtocolProtos.java)
        at org.apache.hadoop.ipc.ProtobufRpcEngine$Server$ProtoBufRpcInvoker.call(ProtobufRpcEngine.java:617)
        at org.apache.hadoop.ipc.RPC$Server.call(RPC.java:1073)
        at org.apache.hadoop.ipc.Server$Handler$1.run(Server.java:2278)
        at org.apache.hadoop.ipc.Server$Handler$1.run(Server.java:2274)
        at java.security.AccessController.doPrivileged(Native Method)
        at javax.security.auth.Subject.doAs(Subject.java:422)
        at org.apache.hadoop.security.UserGroupInformation.doAs(UserGroupInformation.java:1924)
        at org.apache.hadoop.ipc.Server$Handler.run(Server.java:2272)
'

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<impala_shell_options>]"

help_usage "$@"


exec "$srcdir/impala_foreach_table.sh" "SELECT COUNT(*) FROM {db}.{table}" "$@"
