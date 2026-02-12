# Lua Syntax Tests

This folder contains test cases for checking Lua syntax errors in the openwrt-passwall2 project.

## syntax_checker.lua

A Lua script that recursively scans all `.lua` files in the project and checks for syntax errors using Lua's `loadfile()` function.

### Features
- Cross-platform support (Windows and Unix-like systems)
- Recursive file discovery
- Detailed error reporting with file names and error messages
- Summary of total files checked and errors found
- Exit codes for CI/CD integration (0 for success, 1 for errors)

### Requirements
- Lua interpreter installed and available in PATH

### Usage
Run from the project root directory:

```bash
lua tests/syntax_checker.lua
```

### Example Output
```
Syntax error in luci-app-passwall2/luasrc/controller/main.lua: unexpected symbol near 'end'
Syntax error in luci-app-passwall2/luasrc/model/cbi/passwall2/client/global.lua: 'then' expected near '='

Checked 150 files, found 2 syntax errors.
```

### CI Integration
The script exits with code 1 if any syntax errors are found, making it suitable for use in CI pipelines.

### Alternative: Using Lua Language Server
If you have the Lua Language Server installed (comes with the Sumneko Lua extension), you can also check individual files:

```bash
lua-language-server --check path/to/file.lua
```

For batch checking, you could modify the script to use `lua-language-server --check` instead of `loadfile()` for more advanced error detection.