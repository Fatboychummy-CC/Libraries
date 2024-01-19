---@class file_helper
local file = {
  working_directory = fs.getDir(shell.getRunningProgram())
}

--- Check if a file exists in the working directory. Shorthand for fs.exists(fs.combine(file.working_directory, filename)).
---@param filename string The file to check.
---@return boolean exists
function file.exists(filename)
  return fs.exists(fs.combine(file.working_directory, filename))
end

--- Return a table of lines from a file.
---@param filename string The file to be read.
---@param default string[]? The value returned when the file does not exist.
---@return string[] lines
function file.get_lines(filename, default)
  local lines = {}

  if not fs.exists(fs.combine(file.working_directory, filename)) then
    return default or {}
  end

  for line in io.lines(fs.combine(file.working_directory, filename)) do
    table.insert(lines, line)
  end
  lines.n = #lines

  return lines
end

--- Return a string containing the entirety of the file read.
---@param filename string The file to be read.
---@param default string? The value returned when the file does not exist.
---@return string data
function file.get_all(filename, default)
  local h = io.open(fs.combine(file.working_directory, filename), 'r')

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
function file.write(filename, data)
  local h, err = io.open(fs.combine(file.working_directory, filename), 'w')

  if not h then
    error(("Failed to open '%s' for writing: %s"):format(fs.combine(file.working_directory, filename), err), 2)
  end

  h:write(data):close()
end

--- Append data to a file
---@param filename string The file to write to.
---@param data string The data to write.
function file.append(filename, data)
  local h, err = io.open(fs.combine(file.working_directory, filename), 'a')

  if not h then
    error(("Failed to open '%s' for writing: %s"):format(fs.combine(file.working_directory, filename), err), 2)
  end

  h:write(data):close()
end

--- Return the unserialized contents of the file read.
---@param filename string The file to be read.
---@param default any The value returned when the file does not exist.
---@return any data
function file.unserialize(filename, default)
  local h = io.open(fs.combine(file.working_directory, filename), 'r')

  if not h then
    return default or ""
  end

  local data = textutils.unserialise(h:read "*a")
  h:close()

  return data
end

--- Write data to a file
---@param filename string The file to write to.
---@param data string|number|table|boolean|nil The data to write, this will be serialized.
---@param minify boolean? Whether or not to minify the serialized data.
function file.serialize(filename, data, minify)
  local h, err = io.open(fs.combine(file.working_directory, filename), 'w')

  if not h then
    error(("Failed to open '%s' for writing: %s"):format(fs.combine(file.working_directory, filename), err), 2)
  end

  h:write(textutils.serialize(data, {compact = minify and true or false, allow_repetitions=true})):close()
end

--- Shorthand to delete from the working directory.
---@param filename string The file to delete.
function file.delete(filename)
  fs.delete(fs.combine(file.working_directory, filename))
end

return file
