--
--  Author: Hari Sekhon
--  Date: 2020-08-05 18:16:55 +0100 (Wed, 05 Aug 2020)
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

-- List PostgreSQL Locks
--
-- Tested on PostgreSQL 12.3

SELECT
  t.schemaname,
  t.relname,
  l.locktype,
  page,
  virtualtransaction,
  pid,
  mode,
  granted
FROM
  pg_locks l,
  --pg_stat_user_tables t
  pg_stat_all_tables t
WHERE
  l.relation = t.relid
ORDER BY
  relation ASC;
