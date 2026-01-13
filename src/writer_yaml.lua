--[[
  YAML Writer Module.
  Exports Lua tables to YAML format.
]]

local M = {}

--- Check if a table represents a sequential array.
-- @param t table: The table to check.
-- @return boolean: True if array-like, false otherwise.
local function is_array(t)
  if type(t) ~= "table" then return false end
  local i = 0
  for _ in pairs(t) do
      i = i + 1
      if t[i] == nil then return false end
  end
  return true
end

--- Escape string for safe YAML output.
-- @param s string: The input string.
-- @return string: The escaped/quoted string.
local function escape_string(s)
  if s == "" then return '""' end
  -- Quote strings that resemble numbers, booleans, or contain special characters
  if tonumber(s) or s == "true" or s == "false" or s == "null" or s == "~" then
     return '"' .. s .. '"'
  end
  if s:find("[:{},&*#?|<>=!@%%%[%]%-]") or s:find("^%s") or s:find("%s$") then
    return '"' .. s:gsub('"', '\\"') .. '"'
  end
  return s
end

--- Recursively dump a value to YAML format string.
-- @param val any: The value to dump.
-- @param indent number: Current indentation level.
-- @return string: The formatted YAML string.
local function dump(val, indent)
  local t = type(val)
  local prefix = string.rep("  ", indent)

  if t == "nil" then return "null" end
  if t == "number" or t == "boolean" then return tostring(val) end
  if t == "string" then return escape_string(val) end
  
  if t == "table" then
     if next(val) == nil then return "{}" end -- Empty map/array
     
     local lines = {}
     if is_array(val) then
       for _, v in ipairs(val) do
         local sub = dump(v, indent + 1)
         if type(v) == "table" and not is_array(v) and next(v) ~= nil then
           -- Complex object inside array
           table.insert(lines, prefix .. "- " .. sub:gsub("^%s+", "")) 
         else
           table.insert(lines, prefix .. "- " .. sub:gsub("^%s+", ""))
         end
       end
     else
       -- Map: sort keys for deterministic output
        local keys = {}
        for k in pairs(val) do table.insert(keys, k) end
        table.sort(keys, function(a,b) return tostring(a) < tostring(b) end)
        
        for _, k in ipairs(keys) do
           local v = val[k]
           local key_str = tostring(k)
           local val_str = dump(v, indent + 1)
           
           if type(v) == "table" and next(v) ~= nil then
              if is_array(v) then
                  table.insert(lines, prefix .. key_str .. ":\n" .. val_str)
              else
                  table.insert(lines, prefix .. key_str .. ":\n" .. val_str)
              end
           else
              table.insert(lines, prefix .. key_str .. ": " .. val_str:gsub("^%s+", ""))
           end
        end
     end
     return table.concat(lines, "\n")
  end
  return tostring(val)
end

--- Serialize a table to YAML.
-- @param tbl table: The table to serialize.
-- @return string: The YAML string.
function M.write(tbl)
  return dump(tbl, 0)
end

return M
