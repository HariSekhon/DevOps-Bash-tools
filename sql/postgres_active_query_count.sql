--
--  Author: Hari Sekhon
--  Date: 2020-08-05 15:33:36 +0100 (Wed, 05 Aug 2020)
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

-- PostgreSQL number of active queries
--
-- if consistently > CPU Cores, then upgrade/scale
--
-- Tested on PostgreSQL 12.3

SELECT
  COUNT(*) as active_query_count
FROM
  pg_stat_activity
WHERE
  state='active';
