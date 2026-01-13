--[[
  ENV Writer Module.
  Exports Lua tables to .env format, flattening nested structures.
]]

local json = require("src.parser_json")
local M = {}

local function to_env_string(val)
  if type(val) == "string" then return val end
  return tostring(val)
end

local function needs_quotes(val)
  if val:find("[=%s#]") then return true end
  if val:find('"') or val:find("'") then return true end
  return false
end

local function quote_val(val)
  return '"' .. val:gsub('"', '\\"') .. '"'
end

--- Serializes a table to ENV format.
-- Nested tables are flattened with underscore separators.
-- Arrays are JSON-encoded.
-- @param tbl table: The table to serialize.
-- @return string: The ENV formatted string.
function M.write(tbl)
  local lines = {}
  
  local function flatten(t, prefix, out)
    for k, v in pairs(t) do
      local key_part = tostring(k):upper():gsub("[^A-Z0-9_]", "_")
      local current_key = prefix and (prefix .. "_" .. key_part) or key_part
      
      if type(v) == "table" then
        -- Check if array
        local is_array = false
        if next(v) == nil then 
            is_array = true 
        else
            for k2 in pairs(v) do
                if type(k2) == "number" then is_array = true else is_array = false break end
            end
        end

        if is_array then
          -- Serialize arrays as JSON strings
          local val = json.encode(v)
          val = quote_val(val)
          table.insert(out, current_key .. "=" .. val)
        else
          -- Recursively flatten nested maps
          flatten(v, current_key, out)
        end
      else
        local val = to_env_string(v)
        if needs_quotes(val) then
          val = quote_val(val)
        end
        table.insert(out, current_key .. "=" .. val)
      end
    end
  end
  
  -- Flatten and sort logic
  local flat_list = {}
  flatten(tbl, nil, flat_list)
  table.sort(flat_list)
  
  return table.concat(flat_list, "\n")
end

return M
