#!/usr/bin/env lua

-- Lua Syntax Checker for openwrt-passwall2 project
-- This script recursively checks all .lua files for syntax errors

local total_files = 0
local error_count = 0

-- Function to check syntax of a single file
function check_syntax(file)
    total_files = total_files + 1
    local func, err = loadfile(file)
    if not func then
        error_count = error_count + 1
        print("Syntax error in " .. file .. ": " .. err)
    end
end

-- Detect OS and set appropriate command to find .lua files recursively
local cmd
if package.config:sub(1,1) == '\\' then
    -- Windows
    cmd = 'dir /s /b "*.lua" 2>nul'
else
    -- Unix-like systems
    cmd = 'find . -name "*.lua" -type f'
end

-- Execute the command and process each file
local p = io.popen(cmd)
if p then
    for line in p:lines() do
        -- Trim any trailing whitespace
        line = line:gsub("%s+$", "")
        if line ~= "" then
            check_syntax(line)
        end
    end
    p:close()
else
    print("Error: Could not execute file listing command")
    os.exit(1)
end

-- Print summary
print(string.format("\nChecked %d files, found %d syntax errors.", total_files, error_count))

-- Exit with error code if syntax errors were found
if error_count > 0 then
    os.exit(1)
end