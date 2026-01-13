--[[
  ENV Parser Module.
  Parses .env files into key-value pairs.
]]

local M = {}

local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

--- Parse ENV content.
-- @param content string: The file content.
-- @return table: Parsed key-value pairs.
function M.parse(content)
  local res = {}
  for line in content:gmatch("[^\r\n]+") do
    -- Ignore comments and empty lines
    if not line:match("^%s*#") and not line:match("^%s*$") then
      local eq = line:find("=")
      if eq then
        local key = trim(line:sub(1, eq-1))
        local val = trim(line:sub(eq+1))
        
        -- Handle quotes
        local first = val:sub(1,1)
        local last = val:sub(-1)
        if (first == '"' and last == '"') or (first == "'" and last == "'") then
          val = val:sub(2, -2)
        else
            -- Strip inline comments
            local c_idx = val:find("%s+#")
            if c_idx then
                val = trim(val:sub(1, c_idx-1))
            end
        end
        
        res[key] = val
      end
    end
  end
  return res
end

return M
