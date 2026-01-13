# ConfigForge

A production-ready open-source CLI tool to convert configuration files between formats.  
**Version**: 1.0  
**License**: MIT  
**OS**: Cross-platform (Windows, Linux, macOS)  

## Supported Formats

- **JSON** (`.json`) - Strict standard JSON.
- **YAML** (`.yaml`, `.yml`) - Block and flow styles supported.
- **TOML** (`.toml`) - Standard sections and key-value pairs.
- **ENV** (`.env`) - Key-value environment variables with nesting support via delimiters.

## Prerequisites

- **Lua 5.4**: The tool requires Lua 5.4 runtime environment.
  - Windows: [Lua Binaries](http://luabinaries.sourceforge.net/)
  - Linux: `sudo apt install lua5.4`
  - macOS: `brew install lua`
  
## Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/muhammad-fiaz/configforge-lua.git
    cd configforge-lua
    ```

2.  **Verify Installation:**
    Run the help command (or run without arguments) to verify:
    ```bash
    lua configforge.lua
    ```

## Usage and Examples

The tool officially supports **Any-to-Any** conversion. You can convert from any supported format to any other supported format.

### 1. Example Files

Create an `example.json` file with the following content:

```json
{
  "app": {
    "name": "ConfigForge",
    "version": "1.0.0",
    "debug": true,
    "port": 8080
  },
  "database": {
    "host": "localhost",
    "retries": 3
  },
  "features": [
    "conversion",
    "validation",
    "diff"
  ]
}
```

### 2. Format Conversion

**Common Conversions (JSON Source)**
```bash
lua configforge.lua convert example.json example.yaml
lua configforge.lua convert example.json example.toml
lua configforge.lua convert example.json example.env
```

**Any-to-Any Examples**
It is valid to convert between any pair of formats:

*YAML to TOML*
```bash
lua configforge.lua convert example.yaml output.toml
```

*ENV to JSON*
```bash
lua configforge.lua convert example.env output.json
```

*TOML to YAML*
```bash
lua configforge.lua convert example.toml output.yaml
```

**Note on ENV Files**: 
When converting *to* ENV, nested structures are flattened (e.g., `app.port` become `APP_PORT`). 
When converting *from* ENV, this flat structure is preserved as keys (e.g., `APP_PORT` remains `APP_PORT`).

### 3. Validation

Check if a file has valid syntax.

```bash
lua configforge.lua validate example.json
# Output: Valid json syntax.
```

### 4. Diff Mode

Compare two configuration files to see structural differences. This works across different formats.

**Compare JSON vs YAML:**
```bash
lua configforge.lua diff example.json example.yaml
```
*Output (if identical):*
(No output means files are structurally identical)

**Compare ENV vs TOML:**
```bash
lua configforge.lua diff example.env example.toml
```

## Command Reference

| Command | Syntax | Description |
|---------|--------|-------------|
| `convert` | `convert <input> <output>` | Convert file format. Supports JSON, YAML, TOML, ENV. |
| `validate` | `validate <file>` | Validate file syntax. |
| `diff` | `diff <file1> <file2>` | Compare two files structurally. |

## Exit Codes

| Code | Description |
|------|-------------|
| `0`  | Success |
| `1`  | Generic Failure / Runtime Error |
| `2`  | Usage Error (Invalid arguments) |
| `3`  | I/O Error (File not found, permission denied) |
| `4`  | Parse Error (Invalid syntax in config file) |

## Project Structure

```
configforge-lua/
├── configforge.lua   # Entry point
├── main.lua          # Wrapper entry point
├── LICENSE           # MIT License
├── README.md         # Documentation
└── src/
    ├── cli.lua           # CLI Logic
    ├── detect.lua        # Format detection
    ├── diff.lua          # Diff logic
    ├── errors.lua        # Error handling
    ├── parser_*.lua      # For JSON, YAML, TOML, ENV
    └── writer_*.lua      # For JSON, YAML, TOML, ENV
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
