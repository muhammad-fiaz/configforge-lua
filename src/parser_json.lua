--[[
  JSON Parser Module.
  Implements a compliant JSON decoder following standard syntax rules.
]]

local M = {}

local escape_char_map = {
  ["\\"] = "\\",
  ["\""] = "\"",
  ["\b"] = "b",
  ["\f"] = "f",
  ["\n"] = "n",
  ["\r"] = "r",
  ["\t"] = "t",
}

local escape_char_map_inv = { ["/"] = "/" }
for k, v in pairs(escape_char_map) do
  escape_char_map_inv[v] = k
end

-- Helper to encode nil values
local function encode_nil(val)
  return "null"
end

-- Helper to encode Lua tables as JSON objects or arrays
local function encode_table(val, stack)
  local res = {}
  stack = stack or {}
  
  if stack[val] then error("circular reference") end
  stack[val] = true
  
  -- Determine if the table represents an array (dense integer keys)
  local function is_array_check(t)
    if next(t) == nil then return true end -- Treat empty table as array by default
    local i = 0
    for _ in pairs(t) do
      i = i + 1
      if t[i] == nil then return false end
    end
    return true
  end
  
  if is_array_check(val) then
    local items = {}
    for i, v in ipairs(val) do
      table.insert(items, M.encode(v, stack))
    end
    stack[val] = nil
    return "[" .. table.concat(items, ",") .. "]"
  else
    local items = {}
    for k, v in pairs(val) do
      if type(k) ~= "string" then
        error("JSON object keys must be strings")
      end
      table.insert(items, M.encode(k, stack) .. ":" .. M.encode(v, stack))
    end
    stack[val] = nil
    return "{" .. table.concat(items, ",") .. "}"
  end
end

local function encode_string(val)
  return '"' .. val:gsub('[%z\1-\31\\"]', function(c)
    return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte()))
  end) .. '"'
end

local function encode_number(val)
  return tostring(val)
end

--- Encode a Lua value into a JSON string.
-- @param val any: The value to encode.
-- @param stack table: Internal stack for circular reference detection.
-- @return string: The JSON string representation.
function M.encode(val, stack)
  local t = type(val)
  if t == "nil" then return encode_nil(val) end
  if t == "string" then return encode_string(val) end
  if t == "number" then return encode_number(val) end
  if t == "boolean" then return tostring(val) end
  if t == "table" then return encode_table(val, stack) end
  error("Unexpected type: " .. t)
end

-- Decoder Implementation

local function create_set(...)
  local res = {}
  for i = 1, select("#", ...) do res[select(i, ...)] = true end
  return res
end

local space_chars = create_set(" ", "\t", "\r", "\n")
local delim_chars = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
local escape_chars = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
local literals = { ["true"] = true, ["false"] = false, ["null"] = nil }

local function next_char(str, idx, set, negate)
  for i = idx, #str do
    local is_member = set[str:sub(i, i)]
    if negate then
      if not is_member then return i end
    else
      if is_member then return i end
    end
  end
  return #str + 1
end

local function decode_error(str, idx, msg)
  local line_count = 1
  local col_count = 1
  for i = 1, idx - 1 do
    col_count = col_count + 1
    if str:sub(i, i) == "\n" then
      line_count = line_count + 1
      col_count = 1
    end
  end
  error(string.format("%s at line %d col %d", msg, line_count, col_count))
end

local function codepoint_to_utf8(n)
  if n < 0x80 then return string.char(n)
  elseif n < 0x800 then return string.char(0xc0 + (n / 64), 0x80 + (n % 64))
  elseif n < 0x10000 then return string.char(0xe0 + (n / 4096), 0x80 + ((n / 64) % 64), 0x80 + (n % 64))
  else return string.char(0xf0 + (n / 262144), 0x80 + ((n / 4096) % 64), 0x80 + ((n / 64) % 64), 0x80 + (n % 64)) end
end

local function parse_unicode_escape(s)
  local n1 = tonumber(s:sub(3, 6), 16)
  local low = s:find("\\u%x%x%x%x", 7)
  if low ~= 7 then return codepoint_to_utf8(n1), 6 end
  local n2 = tonumber(s:sub(9, 12), 16)
  if n1 >= 0xd800 and n1 <= 0xdbff and n2 >= 0xdc00 and n2 <= 0xdfff then
      return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000), 12
  end
  return codepoint_to_utf8(n1), 6
end

local function parse_string(str, i)
  local res = ""
  local j = i + 1
  local k = j
  while j <= #str do
    local x = str:byte(j)
    if x < 32 then decode_error(str, j, "control character in string") end
    if x == 92 then -- backslash
      res = res .. str:sub(k, j - 1)
      j = j + 1
      local c = str:sub(j, j)
      if c == "u" then
        local hex = str:sub(j + 1, j + 5)
        if not hex:find("%x%x%x%x") then decode_error(str, j, "invalid unicode escape") end
        local utf8, len = parse_unicode_escape(str:sub(j - 2, j + 9))
        res = res .. utf8
        j = j + len - 2
      else
        if not escape_chars[c] then decode_error(str, j, "invalid escape char '" .. c .. "'") end
        res = res .. escape_char_map_inv[c]
      end
      k = j + 1
    elseif x == 34 then -- quote
      res = res .. str:sub(k, j - 1)
      return res, j + 1
    end
    j = j + 1
  end
  decode_error(str, i, "expected closing quote for string")
end

local function parse_number(str, i)
  local x = next_char(str, i, delim_chars, false)
  local s = str:sub(i, x - 1)
  local n = tonumber(s)
  if not n then decode_error(str, i, "invalid number '" .. s .. "'") end
  return n, x
end

local function parse_literal(str, i)
  local x = next_char(str, i, delim_chars, false)
  local word = str:sub(i, x - 1)
  if not literals[word] and word ~= "null" then
     if word == "false" then return false, x end
     if word == "true" then return true, x end
     decode_error(str, i, "invalid literal '" .. word .. "'")
  end
  return literals[word], x
end

-- Recursive parser core
local function parse(str, i)
  local i = next_char(str, i, space_chars, true)
  local c = str:sub(i, i)
  if c == "{" then
    local res = {}
    i = next_char(str, i + 1, space_chars, true)
    if str:sub(i, i) == "}" then return res, i + 1 end
    while true do
      local key, val
      key, i = parse(str, i)
      if type(key) ~= "string" then decode_error(str, i, "expected string key") end
      i = next_char(str, i, space_chars, true)
      if str:sub(i, i) ~= ":" then decode_error(str, i, "expected ':'") end
      val, i = parse(str, i + 1)
      res[key] = val
      i = next_char(str, i, space_chars, true)
      local ch = str:sub(i, i)
      i = i + 1
      if ch == "}" then return res, i end
      if ch ~= "," then decode_error(str, i, "expected ',' or '}'") end
    end
  elseif c == "[" then
    local res = {}
    i = next_char(str, i + 1, space_chars, true)
    if str:sub(i, i) == "]" then return res, i + 1 end
    while true do
      local val
      val, i = parse(str, i)
      table.insert(res, val)
      i = next_char(str, i, space_chars, true)
      local ch = str:sub(i, i)
      i = i + 1
      if ch == "]" then return res, i end
      if ch ~= "," then decode_error(str, i, "expected ',' or ']'") end
    end
  elseif c == '"' then
    return parse_string(str, i)
  elseif c:match("[%d%-]") then
    return parse_number(str, i)
  else
    return parse_literal(str, i)
  end
end

--- Decode a JSON string into a Lua table.
-- @param str string: The JSON string to decode.
-- @return table: The decoded Lua table.
function M.decode(str)
  if type(str) ~= "string" then error("expected argument of type string") end
  local res, idx = parse(str, 1)
  idx = next_char(str, idx, space_chars, true)
  if idx <= #str then decode_error(str, idx, "trailing garbage") end
  return res
end

-- Alias for consistency with other modules
M.parse = M.decode

return M
