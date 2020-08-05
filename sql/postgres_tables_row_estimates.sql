--
--  Author: Hari Sekhon
--  Date: 2020-08-05 18:21:15 +0100 (Wed, 05 Aug 2020)
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

-- PostgreSQL table row count estimates in one place, useful when comparing tables or when a table becomes so large you don't want the expense of SELECT COUNT(*) and are happy to use the internal statistics instead
--
-- Tested on PostgreSQL 12.3

SELECT
  schemaname,
  relname,
  n_live_tup
FROM
  --pg_stat_all_tables
  pg_stat_user_tables
ORDER BY
  n_live_tup DESC;
