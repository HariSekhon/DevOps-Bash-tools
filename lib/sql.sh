#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-10-11 01:45:42 +0300 (Fri, 11 Oct 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
# shellcheck disable=SC2034
srcdir_sql_lib="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# try to infer the SQL dialect from the filename or path hoping there is a clue in a naming convention somewhere along the path of directory of file naming convention
#
# written to be able to auto-infer what the --dialect arg to sqlfluff should be for check_sqlfluff.sh script but can be reused for other SQL tools as this is a generally useful thing to be able to infer
#
infer_sql_dialect_from_path(){
    local path="$1"
    local basename="${path##*/}"
    if [[ "$path" =~ mysql ]] ||
       [[ "$path" =~ mariadb ]]; then
        echo "mysql"
        return
    # postgres covers postgresql via substring match, no need for postgresql specific match
    elif [[ "$path" =~ postgres ]]; then
        echo "postgres"
        return
    elif [[ "$path" =~ oracle ]] ||
         [[ "$basename" =~ \.plsql$ ]]; then
        echo "oracle"
        return
    elif [[ "$path" =~ mssql ]] ||
         # do not path match tsql as it could have unintended consequences of matching the end of unrelated <word>sql
         #[[ "$path" =~ tsql ]] ||
         [[ "$path" =~ transactsql ]] ||
         [[ "$path" =~ microsoft ]] ||
         [[ "$basename" =~ \.tsql$ ]]; then
        echo "mssql"
        return
    elif [[ "$path" =~ athena ]]; then
        echo "athena"
        return
    elif [[ "$path" =~ bigquery ]]; then
        echo "bigquery"
        return
    elif [[ "$path" =~ databricks ]] ||
         [[ "$path" =~ sparksql ]]; then
        echo "sparksql"
        return
    elif [[ "$path" =~ hive ]]; then
         # don't try this as HSQLDB uses this file extension and most Hive practioners don't (I used to be one back in Cloudera and Hortonworks days for much of the 2010s)
         #[[ "$path" =~ \.hsql ]]; then
        echo "hive"
        return
    elif [[ "$path" =~ redshift ]] ||
         [[ "$basename" =~ \.rd$ ]]; then
        echo "vertica"
        return
    elif [[ "$path" =~ vertica ]] ||
         [[ "$basename" =~ \.vsql$ ]]; then
        echo "vertica"
        return
    elif [[ "$path" =~ teradata ]] ||
         [[ "$basename" =~ \.td$ ]]; then
        echo "teradata"
        return
    elif [[ "$path" =~ greenplum ]] ||
         [[ "$basename" =~ \.gpd$ ]]; then
        echo "greenplum"
        return
    elif [[ "$path" =~ clickhouse ]] ||
         [[ "$basename" =~ \.ch$ ]]; then
        echo "greenplum"
        return
    elif [[ "$path" =~ duckdb ]] ||
         [[ "$basename" =~ \.duck$ ]]; then
        echo "greenplum"
        return
    else
        # Remaining dialects that we don't have special multi-rules or priorities for, shorten the code with a simple direct mapping loop, reference:
        #
        #   https://docs.sqlfluff.com/en/stable/reference/dialects.html
        #
            # I use words like materialize often and don't trust it to be inferred as an SQL dialect
            #materialize \
        for dialect in \
            db2 \
            exasol \
            snowflake \
            soql \
            sqlite \
            trino \
            ; do
            if [[ "$path" =~ $dialect ]]; then
                echo "$dialect"
                return
            fi
        done

    fi
    echo "Failed to detect SQL dialect from path '$path'" >&2
    return 1
}
