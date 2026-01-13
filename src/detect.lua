--[[
  File format detection module.
  Determines the configuration format based on file extensions.
]]

local errors = require("src.errors")
local M = {}

-- Mapping of file extensions to internal format identifiers
local ext_map = {
  json = "json",
  yaml = "yaml",
  yml = "yaml",
  toml = "toml",
  env = "env"
}

--- Detects the format of a file based on its extension.
-- @param filename string: The file path or name.
-- @return string: The detected format identifier (e.g., 'json', 'yaml').
-- @raise Exits with USAGE error if detection fails or extension is unsupported.
function M.detect(filename)
  local ext = filename:match("^.+(%..+)$")
  if not ext then
    errors.fail(errors.USAGE, "Could not detect file extension for: " .. filename)
  end
  
  -- Remove leading dot and normalize to lowercase
  ext = ext:sub(2):lower()
  
  local format = ext_map[ext]
  if not format then
    errors.fail(errors.USAGE, "Unsupported file extension: ." .. ext)
  end
  
  return format
end

return M
