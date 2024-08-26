local expect = require "cc.expect".expect --[[@as fun(arg_n: number, value: any, ...: string)]]

---@class file_helper
local file = {
  working_directory = fs.getDir(shell.getRunningProgram())
}

--- Check if a file exists in the working directory. Shorthand for fs.exists(fs.combine(self.working_directory, filename)).
---@param filename string The file to check.
---@return boolean exists
function file:exists(filename)
  if type(self) ~= "table" then -- shift arguments, not instanced.
    filename = self --[[@as string]]
    self = file --[[@as file_helper]]
  end

  expect(1, filename, "string")

  return fs.exists(fs.combine(self.working_directory, filename))
end

--- Return a table of lines from a file.
---@param filename string The file to be read.
---@param default string[]? The value returned when the file does not exist.
---@return string[] lines
function file:get_lines(filename, default)
  if type(self) ~= "table" then -- shift arguments, not instanced.
    default = filename --[[@as string[]?]]
    filename = self --[[@as string]]
    self = file --[[@as file_helper]]
  end

  expect(1, filename, "string")
  expect(2, default, "table", "nil")

  local lines = {}

  if not fs.exists(fs.combine(self.working_directory, filename)) then
    return default or {n = 0}
  end

  for line in io.lines(fs.combine(self.working_directory, filename)) do
    table.insert(lines, line)
  end
  lines.n = #lines

  return lines
end

--- Return a string containing the entirety of the file read.
---@param filename string The file to be read.
---@param default string? The value returned when the file does not exist.
---@return string data
function file:get_all(filename, default)
  if type(self) ~= "table" then -- shift arguments, not instanced.
    default = filename --[[@as string?]]
    filename = self --[[@as string]]
    self = file --[[@as file_helper]]
  end

  expect(1, filename, "string")
  expect(2, default, "string", "nil")

  local h = io.open(fs.combine(self.working_directory, filename), 'r')

  if not h then
    return default or ""
  end

  local data = h:read "*a"
  h:close()

  return data
end

--- Write data to a file
---@param filename string The file to write to.
---@param data string The data to write.
function file:write(filename, data)
  if type(self) ~= "table" then -- shift arguments, not instanced.
    data = filename --[[@as string]]
    filename = self --[[@as string]]
    self = file --[[@as file_helper]]
  end

  expect(1, filename, "string")
  expect(2, data, "string")

  local h, err = io.open(fs.combine(self.working_directory, filename), 'w')

  if not h then
    error(("Failed to open '%s' for writing: %s"):format(fs.combine(self.working_directory, filename), err), 2)
  end

  h:write(data):close()
end

--- Append data to a file
---@param filename string The file to write to.
---@param data string The data to write.
function file:append(filename, data)
  if type(self) ~= "table" then -- shift arguments, not instanced.
    data = filename --[[@as string]]
    filename = self --[[@as string]]
    self = file --[[@as file_helper]]
  end

  expect(1, filename, "string")
  expect(2, data, "string")

  local h, err = io.open(fs.combine(self.working_directory, filename), 'a')

  if not h then
    error(("Failed to open '%s' for writing: %s"):format(fs.combine(self.working_directory, filename), err), 2)
  end

  h:write(data):close()
end

--- Create an empty file (or empty the contents of an existing file).
---@param filename string The file to write to.
function file:empty(filename)
  if type(self) ~= "table" then -- shift arguments, not instanced.
    filename = self --[[@as string]]
    self = file --[[@as file_helper]]
  end

  expect(1, filename, "string")

  fs.delete(fs.combine(self.working_directory, filename))
  local h, err = io.open(fs.combine(self.working_directory, filename), 'w')

  if not h then
    error(("Failed to open '%s' for writing: %s"):format(fs.combine(self.working_directory, filename), err), 2)
  end

  h:close()
end

--- Return the unserialized contents of the file read.
---@param filename string The file to be read.
---@param default any The value returned when the file does not exist.
---@return any data
function file:unserialize(filename, default)
  if type(self) ~= "table" then -- shift arguments, not instanced.
    default = filename --[[@as any]]
    filename = self --[[@as string]]
    self = file --[[@as file_helper]]
  end

  expect(1, filename, "string")
  -- No expect for default, any type allowed.

  local h = io.open(fs.combine(self.working_directory, filename), 'r')

  if not h then
    return default
  end

  local data = textutils.unserialise(h:read "*a")
  h:close()

  return data
end

--- Write data to a file
---@param filename string The file to write to.
---@param data any The data to write, this will be serialized.
---@param minify boolean? Whether or not to minify the serialized data.
function file:serialize(filename, data, minify)
  if type(self) ~= "table" then -- shift arguments, not instanced.
    minify = data --[[@as boolean?]]
    data = filename --[[@as any]]
    filename = self --[[@as string]]
    self = file --[[@as file_helper]]
  end

  expect(1, filename, "string")
  -- No expect for data, any type allowed.
  expect(3, minify, "boolean", "nil")

  local h, err = io.open(fs.combine(self.working_directory, filename), 'w')

  if not h then
    error(("Failed to open '%s' for writing: %s"):format(fs.combine(self.working_directory, filename), err), 2)
  end

  ---@diagnostic disable-next-line ITS FINE
  h:write(textutils.serialize(data, {compact = minify and true or false})):close()
end

--- Shorthand to delete from the working directory.
---@param filename string The file to delete.
function file:delete(filename)
  if type(self) ~= "table" then -- shift arguments, not instanced.
    filename = self --[[@as string]]
    self = file --[[@as file_helper]]
  end

  expect(1, filename, "string")

  fs.delete(fs.combine(self.working_directory, filename))
end

--- Create an instance of the file helper with a different working directory.
---@param working_directory string? The working directory to use.
---@return file_helper file
function file:instanced(working_directory)
  if type(self) ~= "table" then -- shift arguments, not instanced.
    working_directory = self --[[@as string?]]
    self = file --[[@as file_helper]]
  end

  local new_helper = {
    working_directory = fs.combine(self.working_directory, working_directory)
  }

  return setmetatable(new_helper, {__index = file})
end

--- List the contents of a directory. This is a shorthand for fs.list(fs.combine(self.working_directory, directory)).
---@param directory string? The directory to list.
---@return string[] files
function file:list(directory)
  if type(self) ~= "table" then -- shift arguments, not instanced.
    directory = self --[[@as string]]
    self = file --[[@as file_helper]]
  end

  expect(1, directory, "string", "nil")
  directory = directory or ""

  return fs.list(fs.combine(self.working_directory, directory))
end

--- Check if the path given is a directory. This is a shorthand for fs.isDir(fs.combine(self.working_directory, path)).
---@param path string? The path to check.
---@return boolean is_directory
function file:is_directory(path)
  if type(self) ~= "table" then -- shift arguments, not instanced.
    path = self --[[@as string]]
    self = file --[[@as file_helper]]
  end

  expect(1, path, "string", "nil")
  path = path or ""

  return fs.isDir(fs.combine(self.working_directory, path))
end

return file
