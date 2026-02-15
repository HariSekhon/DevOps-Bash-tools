--
--  Author: Hari Sekhon
--  Date: 2025-10-28 20:43:20 +0300 (Tue, 28 Oct 2025)
--
--  vim:ts=4:sts=4:sw=4:et
--
--  https///github.com/HariSekhon/DevOps-Bash-tools
--
--  License: see accompanying Hari Sekhon LICENSE file
--
--  If you're using my code you're welcome to connect with me on LinkedIn
--  and optionally send me feedback to help steer this or other code I publish
--
--  https://www.linkedin.com/in/HariSekhon
--

-- .luacheckrc

-- Define globals allowed throughout the project
globals = {
   "vim",    -- for Neovim plugins
   "love",   -- for LÖVE2D projects
}

-- Ignore specific warnings by code
ignore = {
   "631",    -- allow line endings without semicolons
   "212",    -- unused argument
}

-- Allow certain read-only standard globals
read_globals = {
   "os",
   "io",
   "string",
   "table",
   "math",
   "coroutine",
   "debug",
   "utf8",
}

-- Set limits
max_line_length = 100
max_code_line_length = 100
max_string_line_length = 120

-- Exclude certain directories from linting
exclude_files = {
   "vendor/**",
   "build/**",
   "node_modules/**",
}

-- Treat each file as a separate module
std = "lua54"

-- Enable showing warning codes in output
codes = true
