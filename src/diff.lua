--[[
  Deep difference calculation module.
  Compares two Lua tables recursively and prints the differences.
]]

local M = {}

--- Recursively compares two tables and prints differences to stdout.
-- @param t1 table: The source/original table.
-- @param t2 table: The target/new table.
-- @param prefix string: The current key path (used for recursion).
function M.diff(t1, t2, prefix)
  prefix = prefix or ""
  local keys = {}
  
  -- Collect all unique keys from both tables
  for k in pairs(t1) do keys[k] = true end
  for k in pairs(t2) do keys[k] = true end
  
  -- Sort keys for deterministic output
  local sorted_keys = {}
  for k in pairs(keys) do table.insert(sorted_keys, k) end
  table.sort(sorted_keys, function(a,b) return tostring(a) < tostring(b) end)
  
  for _, k in ipairs(sorted_keys) do
    local v1 = t1[k]
    local v2 = t2[k]
    local key_str = prefix .. tostring(k)
    
    if v1 == nil then
       print(string.format("+ %s: %s", key_str, tostring(v2)))
    elseif v2 == nil then
       print(string.format("- %s: %s", key_str, tostring(v1)))
    elseif type(v1) ~= type(v2) then
       print(string.format("~ %s: %s -> %s", key_str, tostring(v1), tostring(v2)))
    elseif type(v1) == "table" then
       M.diff(v1, v2, key_str .. ".")
    elseif v1 ~= v2 then
       print(string.format("~ %s: %s -> %s", key_str, tostring(v1), tostring(v2)))
    end
  end
end

return M
