--
--  Author: Hari Sekhon
--  Date: 2020-11-24 11:25:23 +0000 (Tue, 24 Nov 2020)
--
--  vim:ts=2:sts=2:sw=2:et:filetype=sql
--
--  https://github.com/HariSekhon/DevOps-Bash-tools
--
--  License: see accompanying Hari Sekhon LICENSE file
--
--  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
--
--  https://www.linkedin.com/in/HariSekhon
--

-- https://www.jetbrains.com/help/teamcity/setting-up-an-external-database.html#MySQL

create database teamcity collate utf8_bin;
create user teamcity identified by 'teamcity';
grant all privileges on teamcity.* to teamcity;
grant process on *.* to teamcity;
