-- This is NOT a library like the other files here, instead, it is a script used
-- to run tests for the libraries.

local suite = require "Framework"
local working_dir = shell.dir()

local args = {...}
local test_folder = ""

for i, argument in ipairs(args) do
  if argument == "-v" or argument == "--verbose" or argument == "-verbose" then
    require "Framework.logger".verbose = true
  else
    test_folder = argument
  end
end

if test_folder == "" then
  print("No test folder supplied, running *all* tests.")
  suite.load_tests(fs.combine(working_dir, "tests"))
else
  suite.load_tests(fs.combine(working_dir, "tests", test_folder))
end


suite.run_all_suites()