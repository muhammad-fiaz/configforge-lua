#!/usr/bin/env lua
--[[
  ConfigForge Entry Point.
  Sets up the package path and invokes the CLI logic.
]]

package.path = package.path .. ";./?.lua"

local cli = require("src.cli")

if arg then
  -- Safely execute the CLI runner
  local ok, err = pcall(function() cli.run(arg) end)
  if not ok then
     io.stderr:write("Unexpected Error: " .. tostring(err) .. "\n")
     os.exit(1)
  end
end
