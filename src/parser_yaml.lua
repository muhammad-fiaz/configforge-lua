--[[
  YAML Parser Module.
  Implements a basic YAML parser supporting maps, lists, and scalars.
]]

local M = {}

-- String utility functions
local function trim(s) return s:match("^%s*(.-)%s*$") end
local function is_empty(s) return s:match("^%s*$") end
local function get_indent(s) return s:find("[^%s]") and (s:find("[^%s]") - 1) or 0 end

--- Parse a scalar value into its Lua equivalent.
-- @param s string: The string representation of the scalar.
-- @return any: The parsed Lua value (number, boolean, string, or nil).
local function parse_scalar(s)
  s = trim(s)
  if s == "" or s == "~" or s == "null" then return nil end
  if s == "true" then return true end
  if s == "false" then return false end
  
  local first = s:sub(1,1)
  local last = s:sub(-1)
  
  -- Handle quoted strings
  if (first == '"' and last == '"') or (first == "'" and last == "'") then
    return s:sub(2, -2)
  end
  
  -- Attempt number conversion
  local n = tonumber(s)
  if n then return n end
  
  return s
end

--- Parse a YAML string into a Lua table.
-- @param str string: The YAML content.
-- @return table: The parsed configuration structure.
function M.parse(str)
  local lines = {}
  for line in str:gmatch("[^\r\n]+") do
    -- Remove comments
    local c = line:find("#")
    if c then 
       line = line:sub(1, c - 1) 
    end
    if not is_empty(line) then
      table.insert(lines, line)
    end
  end
  
  local root = {}
  local refs = {}
  local stack = { {indent = -1, node = root, mode = "map"} }
  
  for _, line in ipairs(lines) do
    local indent = get_indent(line)
    local content = trim(line)
    
    -- Maintain stack based on indentation
    while indent <= stack[#stack].indent do
      table.remove(stack)
    end
    
    if #stack == 0 then error("Indentation error") end
    local tip = stack[#stack]
    
    local is_seq = content:sub(1, 2) == "- " or content == "-"
    
    if is_seq then
       local val_str = content:sub(3)
       local new_node = {}
       
       if is_empty(val_str) then
         -- New object item in list
         table.insert(tip.node, new_node)
         table.insert(stack, {indent = indent, node = new_node, mode = "map"})
       else
          -- Key-value pair or scalar in list
          local k, v = val_str:match("^(.-):%s*(.*)")
          if k then
             -- Inline map
             new_node[k] = is_empty(v) and {} or parse_scalar(v)
             table.insert(tip.node, new_node)
             table.insert(stack, {indent = indent, node = new_node, mode = "map"}) 
          else
             -- Scalar item
             table.insert(tip.node, parse_scalar(val_str))
          end
       end
       
    else
       -- Map key parsing
       local k, v = content:match("^(.-):%s*(.*)")
       if k then
         local key = k
         if is_empty(v) then
           local new_node = {}
           tip.node[key] = new_node
           table.insert(stack, {indent = indent, node = new_node, mode = "map"})
         else
           tip.node[key] = parse_scalar(v)
         end
       else
         error("Invalid line: " .. line)
       end
    end
  end
  
  return root
end

return M
