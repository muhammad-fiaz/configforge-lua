--[[
  TOML Parser Module.
  Implements a basic TOML parser.
]]

local M = {}

local function trim(s) return s:match("^%s*(.-)%s*$") end

--- Parse a TOML value string.
-- @param v string: The raw value string.
-- @return any: The parsed Lua value.
local function parse_value(v)
  v = trim(v)
  if v == "true" then return true end
  if v == "false" then return false end
  if v:match("^%d+$") then return tonumber(v) end
  if v:match("^%d+%.%d+$") then return tonumber(v) end
  if v:sub(1,1) == '"' and v:sub(-1) == '"' then return v:sub(2,-2) end
  if v:sub(1,1) == '[' and v:sub(-1) == ']' then
     -- Simple inline array parsing
     local content = v:sub(2,-2)
     local arr = {}
     for item in content:gmatch("[^,]+") do
       table.insert(arr, parse_value(item))
     end
     return arr
  end
  return v
end

--- Parse TOML content into a Lua table.
-- @param content string: The TOML string.
-- @return table: The parsed configuration.
function M.parse(content)
  local root = {}
  local current_table = root
  
  for line in content:gmatch("[^\r\n]+") do
    line = line:match("^[^#]*") -- Strip comments
    line = trim(line)
    
    if line ~= "" then
      local section = line:match("^%[(.*)%]$")
      if section then
        -- Start new table section
        current_table = {}
        root[section] = current_table
      else
        local k, v = line:match("^(.-)%s*=%s*(.*)$")
        if k then
          current_table[trim(k)] = parse_value(v)
        end
      end
    end
  end
  
  return root
end

return M
