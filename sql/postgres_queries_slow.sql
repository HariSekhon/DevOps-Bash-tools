--
--  Author: Hari Sekhon
--  Date: 2020-08-05 17:24:59 +0100 (Wed, 05 Aug 2020)
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

-- PostgreSQL queries currently executing that have taken over 30 secs
--
-- a current snapshot alternative to slow query log
--
-- Tested on PostgreSQL 12.3

SELECT
  now() - query_start as "runtime",
  usename,
  datname,
  wait_event,
  state,
  query
FROM
  pg_stat_activity
WHERE
  now() - query_start > '30 seconds'::interval
ORDER BY
  runtime DESC;
