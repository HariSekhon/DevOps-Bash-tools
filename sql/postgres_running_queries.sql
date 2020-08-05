--
--  Author: Hari Sekhon
--  Date: 2020-08-05 12:54:34 +0100 (Wed, 05 Aug 2020)
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

-- Running queries for PostgreSQL >= 9.2

SELECT
  pid,
  age(clock_timestamp(), query_start),
  usename,
  query
FROM
  pg_stat_activity
WHERE
  query != '<IDLE>'
    AND
  query NOT ILIKE '%pg_stat_activity%'
ORDER BY
  query_start DESC;
