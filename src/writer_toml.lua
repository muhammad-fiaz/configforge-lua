--[[
  TOML Writer Module.
  Serializes simple Lua tables to TOML format.
]]

local M = {}

local function is_array(t)
  if type(t) ~= "table" then return false end
  if next(t) == nil then return false end
  return t[1] ~= nil
end

local function encode_value(val)
  local t = type(val)
  if t == "string" then return string.format("%q", val) end
  if t == "number" then return tostring(val) end
  if t == "boolean" then return tostring(val) end
  if t == "table" then
     if is_array(val) then
       local parts = {}
       for _, v in ipairs(val) do
         table.insert(parts, encode_value(v))
       end
       return "[" .. table.concat(parts, ", ") .. "]"
     else
       -- Inline table for nested values in key-value pairs
       local parts = {}
       for k,v in pairs(val) do 
         table.insert(parts, k .. " = " .. encode_value(v)) 
       end
       return "{" .. table.concat(parts, ", ") .. "}"
     end
  end
  return '""'
end

--- Serializes a table to TOML format.
-- @param tbl table: The table to serialize.
-- @return string: The TOML string.
function M.write(tbl)
  local lines = {}
  local sections = {}
  
  -- Pass 1: Primitives at root
  for k, v in pairs(tbl) do
    if type(v) ~= "table" then
      table.insert(lines, k .. " = " .. encode_value(v))
    elseif is_array(v) then
       table.insert(lines, k .. " = " .. encode_value(v))
    else
       -- Deferred for section pass
       sections[k] = v
    end
  end
  
  -- Pass 2: Sections
  for k, v in pairs(sections) do
    table.insert(lines, "")
    table.insert(lines, "[" .. k .. "]")
    for k2, v2 in pairs(v) do
      table.insert(lines, k2 .. " = " .. encode_value(v2))
    end
  end
  
  return table.concat(lines, "\n")
end

return M
