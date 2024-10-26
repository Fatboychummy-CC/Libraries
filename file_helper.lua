local expect = require "cc.expect".expect --[[@as fun(arg_n: number, value: any, ...: string)]]

---@class file_helper
local file = {
  working_directory = fs.getDir(shell.getRunningProgram())
}

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

  local data = h:read "*a" ---@diagnostic disable-line guh
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
---@param filename string? The file to write to.
function file:empty(filename)
  if type(self) ~= "table" then -- shift arguments, not instanced.
    filename = self --[[@as string]]
    self = file --[[@as file_helper]]
  end

  expect(1, filename, "string", "nil")
  filename = filename or ""

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

  local data = textutils.unserialise(h:read "*a") ---@diagnostic disable-line guh
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

-- ####################################################################
-- # The following functions are shorthands for fs library functions. #
-- ####################################################################

--- Check if a file exists in the working directory. Shorthand for fs.exists(fs.combine(self.working_directory, filename)).
---@param filename string? The file to check.
---@return boolean exists
function file:exists(filename)
  if type(self) ~= "table" then -- shift arguments, not instanced.
    filename = self --[[@as string]]
    self = file --[[@as file_helper]]
  end

  expect(1, filename, "string", "nil")
  filename = filename or ""

  return fs.exists(fs.combine(self.working_directory, filename))
end

--- Delete a file in the working directory. This is a shorthand for fs.delete(fs.combine(self.working_directory, filename)).
---@param filename string? The file to delete.
function file:delete(filename)
  if type(self) ~= "table" then -- shift arguments, not instanced.
    filename = self --[[@as string]]
    self = file --[[@as file_helper]]
  end

  expect(1, filename, "string", "nil")
  filename = filename or ""

  fs.delete(fs.combine(self.working_directory, filename))
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

--- Open a file normally, alias to `fs.open(fs.combine(self.working_directory, filename), mode)`.
---@param filename string The file to open.
---@param mode string The mode to open the file in.
---@return ReadHandle|WriteHandle|BinaryReadHandle|BinaryWriteHandle|nil handle The file handle, or nil if it could not be opened.
function file:open(filename, mode)
  if type(self) ~= "table" then -- shift arguments, not instanced.
    filename = self --[[@as string]]
    mode = filename --[[@as string]]
    self = file --[[@as file_helper]]
  end

  expect(1, filename, "string")
  expect(2, mode, "string")

  return fs.open(fs.combine(self.working_directory, filename), mode)
end

--- Check if a file is read-only. This is a shorthand for fs.isReadOnly(fs.combine(self.working_directory, filename)).
---@param path string? The file path to check.
---@return boolean is_read_only
function file:is_read_only(path)
  if type(self) ~= "table" then -- shift arguments, not instanced.
    path = self --[[@as string]]
    self = file --[[@as file_helper]]
  end

  expect(1, path, "string", "nil")
  path = path or ""

  return fs.isReadOnly(fs.combine(self.working_directory, path))
end

--- Get the directory a file is stored in. This is a shorthand for fs.getDir(fs.combine(self.working_directory, filename)).
---@param path string? The file path to check.
---@return string directory
function file:get_dir(path)
  if type(self) ~= "table" then -- shift arguments, not instanced.
    path = self --[[@as string]]
    self = file --[[@as file_helper]]
  end

  expect(1, path, "string", "nil")
  path = path or ""

  return fs.getDir(fs.combine(self.working_directory, path))
end

--- Get the name of a file. This is a shorthand for fs.getName(fs.combine(self.working_directory, filename)).
---@param path string? The file path to check.
---@return string name
function file:get_name(path)
  if type(self) ~= "table" then -- shift arguments, not instanced.
    path = self --[[@as string]]
    self = file --[[@as file_helper]]
  end

  expect(1, path, "string", "nil")
  path = path or ""

  return fs.getName(fs.combine(self.working_directory, path))
end

--- Get the size of a file. This is a shorthand for fs.getSize(fs.combine(self.working_directory, filename)).
---@param path string? The file path to check.
---@return integer size The size of the file, in bytes.
function file:get_size(path)
  if type(self) ~= "table" then -- shift arguments, not instanced.
    path = self --[[@as string]]
    self = file --[[@as file_helper]]
  end

  expect(1, path, "string", "nil")
  path = path or ""

  return fs.getSize(fs.combine(self.working_directory, path))
end

--- Get the free space in the given directory. This is a shorthand for fs.getFreeSpace(fs.combine(self.working_directory, path)).
---@param path string? The directory to check.
---@return integer|"unlimited" free_space The free space in the directory, in bytes.
function file:get_free_space(path)
  if type(self) ~= "table" then -- shift arguments, not instanced.
    path = self --[[@as string]]
    self = file --[[@as file_helper]]
  end

  expect(1, path, "string", "nil")
  path = path or ""

  return fs.getFreeSpace(fs.combine(self.working_directory, path))
end

--- Make a directory in the working directory. This is a shorthand for fs.makeDir(fs.combine(self.working_directory, path)). 
---@param path string? The directory to create.
function file:make_dir(path)
  if type(self) ~= "table" then -- shift arguments, not instanced.
    path = self --[[@as string]]
    self = file --[[@as file_helper]]
  end

  expect(1, path, "string", "nil")
  path = path or ""

  fs.makeDir(fs.combine(self.working_directory, path))
end

--- Move a file in the working directory. This is a shorthand for fs.move(fs.combine(self.working_directory, from), fs.combine(self.working_directory, to)).
---@param from string The file to move.
---@param to string The destination of the file.
function file:move(from, to)
  if type(self) ~= "table" then -- shift arguments, not instanced.
    to = from --[[@as string]]
    from = self --[[@as string]]
    self = file --[[@as file_helper]]
  end

  expect(1, from, "string")
  expect(2, to, "string")

  fs.move(fs.combine(self.working_directory, from), fs.combine(self.working_directory, to))
end

--- Copy a file in the working directory. This is a shorthand for fs.copy(fs.combine(self.working_directory, from), fs.combine(self.working_directory, to)).
---@param from string The file to copy.
---@param to string The destination of the file.
function file:copy(from, to)
  if type(self) ~= "table" then -- shift arguments, not instanced.
    to = from --[[@as string]]
    from = self --[[@as string]]
    self = file --[[@as file_helper]]
  end

  expect(1, from, "string")
  expect(2, to, "string")

  fs.copy(fs.combine(self.working_directory, from), fs.combine(self.working_directory, to))
end

return file
