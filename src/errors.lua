--[[
  Error handling module for ConfigForge.
  Provides standardized exit codes and helper functions for error reporting.
]]

local M = {}

-- Exit codes
M.SUCCESS = 0
M.FAILURE = 1
M.USAGE = 2
M.IO_ERROR = 3
M.PARSE_ERROR = 4

--- Terminate the program with an error code and message.
-- @param code number: The exit code to return.
-- @param message string: The error message to display on stderr.
function M.fail(code, message)
  io.stderr:write("Error: " .. tostring(message) .. "\n")
  os.exit(code)
end

--- Assert a condition, terminating with a formatted error if false.
-- @param condition any: The value to test.
-- @param code number: The exit code to use on failure.
-- @param message string: The error message to display on failure.
-- @return any: The condition value if truthy.
function M.assert(condition, code, message)
  if not condition then
    M.fail(code, message)
  end
  return condition
end

return M
