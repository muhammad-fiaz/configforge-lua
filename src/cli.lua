--[[
  CLI Controller Module.
  Orchestrates command execution, file I/O, and library loading.
]]

local detect = require("src.detect")
local errors = require("src.errors")
local diff = require("src.diff")

local M = {}

--- Read full content of a file.
-- @param path string: File path.
-- @return string: File content.
local function read_file(path)
  local f = io.open(path, "r")
  if not f then errors.fail(errors.IO_ERROR, "Could not open file: " .. path) end
  local content = f:read("*a")
  f:close()
  return content
end

--- Write content to a file.
-- @param path string: File path.
-- @param content string: Content to write.
local function write_file(path, content)
  local f = io.open(path, "w")
  if not f then errors.fail(errors.IO_ERROR, "Could not write to file: " .. path) end
  f:write(content)
  f:close()
end

--- Dynamically load the parser module for a given format.
-- @param format string: Format identifier (e.g., 'json').
-- @return table: The loaded module.
local function get_parser(format)
  local ok, lib = pcall(require, "src.parser_" .. format)
  if not ok then errors.fail(errors.FAILURE, "Could not load parser for format: " .. format) end
  return lib
end

--- Dynamically load the writer module for a given format.
-- @param format string: Format identifier (e.g., 'json').
-- @return table: The loaded module.
local function get_writer(format)
  local ok, lib = pcall(require, "src.writer_" .. format)
  if not ok then errors.fail(errors.FAILURE, "Could not load writer for format: " .. format .. "\nError: " .. tostring(lib)) end
  return lib
end

--- Convert a configuration file to another format.
-- @param input_path string: Source file path.
-- @param output_path string: Destination file path.
function M.convert(input_path, output_path)
  local input_fmt = detect.detect(input_path)
  local output_fmt = detect.detect(output_path)
  
  local content = read_file(input_path)
  local parser = get_parser(input_fmt)
  
  local ok, data = pcall(parser.parse, content)
  if not ok then errors.fail(errors.PARSE_ERROR, "Failed to parse " .. input_path .. ": " .. tostring(data)) end
  
  local writer = get_writer(output_fmt)
  local ok, output = pcall(writer.write, data)
  if not ok then errors.fail(errors.FAILURE, "Failed to generate " .. output_fmt .. ": " .. tostring(output)) end
  
  write_file(output_path, output)
  print("Converted " .. input_path .. " to " .. output_path)
end

--- Validate the syntax of a configuration file.
-- @param input_path string: File path to validate.
function M.validate(input_path)
  local input_fmt = detect.detect(input_path)
  local content = read_file(input_path)
  local parser = get_parser(input_fmt)
  
  local ok, data = pcall(parser.parse, content)
  if not ok then
    print("Validation Failed: " .. tostring(data))
    os.exit(errors.PARSE_ERROR)
  else
    print("Valid " .. input_fmt .. " syntax.")
  end
end

--- Compare two configuration files.
-- @param path1 string: First file path.
-- @param path2 string: Second file path.
function M.diff(path1, path2)
  local fmt1 = detect.detect(path1)
  local fmt2 = detect.detect(path2)
  
  local c1 = read_file(path1)
  local c2 = read_file(path2)
  
  local p1 = get_parser(fmt1)
  local p2 = get_parser(fmt2)
  
  local ok1, d1 = pcall(p1.parse, c1)
  if not ok1 then errors.fail(errors.PARSE_ERROR, "Failed to parse " .. path1) end
  
  local ok2, d2 = pcall(p2.parse, c2)
  if not ok2 then errors.fail(errors.PARSE_ERROR, "Failed to parse " .. path2) end
  
  diff.diff(d1, d2)
end

--- Main entry point for CLI argument processing.
-- @param args table: Command line arguments.
function M.run(args)
  if #args < 1 then
    errors.fail(errors.USAGE, "Usage: configforge <command> [args]")
  end
  
  local cmd = args[1]
  
  if cmd == "convert" then
    if #args ~= 3 then errors.fail(errors.USAGE, "Usage: configforge convert <input> <output>") end
    M.convert(args[2], args[3])
  elseif cmd == "validate" then
    if #args ~= 2 then errors.fail(errors.USAGE, "Usage: configforge validate <file>") end
    M.validate(args[2])
  elseif cmd == "diff" then
    if #args ~= 3 then errors.fail(errors.USAGE, "Usage: configforge diff <file1> <file2>") end
    M.diff(args[2], args[3])
  else
    errors.fail(errors.USAGE, "Unknown command: " .. cmd)
  end
end

return M
