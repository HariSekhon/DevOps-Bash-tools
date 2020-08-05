--
--  Author: Hari Sekhon
--  Date: 2020-08-05 14:57:37 +0100 (Wed, 05 Aug 2020)
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

-- PostgreSQL Tables Cache-hit Ratio (should be closer to 1, eg. 0.99)

SELECT
  SUM(heap_blks_read) AS heap_read,
  SUM(heap_blks_hit)  AS heap_hit,
            SUM(heap_blks_hit) /
  (SUM(heap_blks_hit) + SUM(heap_blks_read))
                AS ratio
FROM
  pg_statio_user_tables;
