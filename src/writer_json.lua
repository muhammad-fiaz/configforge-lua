--[[
  JSON Writer Module.
  Provides functions to serialize Lua tables into formatted JSON strings.
]]

local json = require("src.parser_json")
local M = {}

--- Serializes a Lua table to a JSON string with default settings.
-- @param tbl table: The table to serialize.
-- @return string: The serialized JSON string.
function M.write(tbl)
  return M.pretty_encode(tbl, 0)
end

--- Serializes a Lua table to a pretty-printed JSON string.
-- @param val any: The value to serialize.
-- @param indent_level number: Current indentation level (default 0).
-- @return string: The pretty-printed JSON string.
function M.pretty_encode(val, indent_level)
  local t = type(val)
  if t == "table" then
     -- Determine if array or object
     local is_array = false
     local max = 0
     for k, v in pairs(val) do
        if type(k) == "number" and k > 0 then
           if k > max then max = k end
           is_array = true
        else
           is_array = false
           break
        end
     end
     if next(val) == nil then is_array = true end -- Treat empty table as array

     local indent_str = string.rep("  ", indent_level)
     local next_indent_str = string.rep("  ", indent_level + 1)
     
     if is_array then
        if next(val) == nil then return "[]" end
        local res = "[\n"
        local items = {}
        for i, v in ipairs(val) do
           table.insert(items, next_indent_str .. M.pretty_encode(v, indent_level + 1))
        end
        res = res .. table.concat(items, ",\n") .. "\n" .. indent_str .. "]"
        return res
     else
        if next(val) == nil then return "{}" end
        local res = "{\n"
        local items = {}
        -- Sort keys for deterministic output
        local keys = {}
        for k in pairs(val) do table.insert(keys, k) end
        table.sort(keys)
        
        for _, k in ipairs(keys) do
           local v = val[k]
           table.insert(items, next_indent_str .. json.encode(k) .. ": " .. M.pretty_encode(v, indent_level + 1))
        end
        res = res .. table.concat(items, ",\n") .. "\n" .. indent_str .. "}"
        return res
     end
  else
     -- Use the basic encoder for primitives to handle escaping
     return json.encode(val)
  end
end

return M
