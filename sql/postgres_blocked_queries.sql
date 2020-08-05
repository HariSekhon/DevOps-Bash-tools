--
--  Author: Hari Sekhon
--  Date: 2020-08-05 18:53:54 +0100 (Wed, 05 Aug 2020)
--
--  vim:ts=2:sts=2:sw=2:et:filetype=sql
--
--  https://github.com/harisekhon/bash-tools
--
--  License: see accompanying Hari Sekhon LICENSE file
--
--  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
--
--  https://www.linkedin.com/in/harisekhon
--

-- Lists PostgreSQL queries blocked along with the pids of those holding the locks blocking them
--
-- Requires PostgreSQL >= 9.6
--
-- Tested on PostgreSQL 12.3

SELECT
  pid,
  user,
  pg_blocking_pids(pid) AS blocked_by_pids,
  query AS blocked_query
FROM
  pg_stat_activity
WHERE
  cardinality(pg_blocking_pids(pid)) > 0;
