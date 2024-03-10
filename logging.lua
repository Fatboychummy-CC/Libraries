--- Logging library to aid with logging things to files and whatnot.

local expect = require "cc.expect".expect

---@class logging
local logging = {
  ---@enum logging-log_level
  LOG_LEVEL = {
    DEBUG = 0,
    INFO = 1,
    WARN = 2,
    ERROR = 3,
    FATAL = 4
  }
}
local errored = false
local warned = false
local log_level = logging.LOG_LEVEL.INFO
local log_window = term.current()

local log_lines = {
  n = 0
}

local log_file_formatter = "[%s][%s] %s"
local log_formatter = "[%s][%s] "
local level_text_formatter = "0%s00%s00"

local function blit_print(text, text_color, back_color, printed, level)
  log_window.blit(text, text_color, back_color)

  local old = term.redirect(log_window)
  local old_c = term.getTextColor()
  term.setTextColor(
    level == logging.LOG_LEVEL.WARN and colors.orange
      or level == logging.LOG_LEVEL.ERROR and colors.red
      or colors.white
  )
  print(printed)
  term.setTextColor(old_c)
  term.redirect(old)
end

--- Log information to the window and file.
---@param context string The context name.
---@param level logging-log_level The log level to use.
---@param level_name string The name of the log level.
---@param ... any The values to be included in the log. Concatenated with a space.
local function log(context, level, level_name, ...)
  if level >= log_level then
    local args = table.pack(...)
    if args.n == 0 then
      args = {n = 1, "Nothing."}
    end

    for i = 1, args.n do
      args[i] = tostring(args[i])
    end
    local combined = table.concat(args, ' ')

    log_lines.n = log_lines.n + 1
    log_lines[log_lines.n] = log_file_formatter:format(
      level_name,
      context,
      combined
    )

    local text = log_formatter:format(level_name, context)
    local t_color = level == logging.LOG_LEVEL.DEBUG and '8' -- light gray
      or level == logging.LOG_LEVEL.INFO and '0' -- white
      or level == logging.LOG_LEVEL.WARN and '4' -- yellow
      or level == logging.LOG_LEVEL.ERROR and '1' -- orange
      or level == logging.LOG_LEVEL.FATAL and 'e' -- red
      or '6' -- pink

    blit_print(
      text,
      level_text_formatter:format(
        t_color:rep(#level_name), t_color:rep(#context)
      ),
      ('f'):rep(#text),
      combined,
      level
    )
  end
end

--- Create a new logging context.
---@param name string The name of the context.
---@return logging-log_context context The context object.
function logging.create_context(name)
  expect(1, name, "string")

  ---@class logging-log_context
  local context = {}

  --- Log something with a custom level and level name.
  ---@param level logging-log_level The level to log at.
  ---@param level_name string The name of the level.
  ---@param ... any The values to be included in the log. Concatenated with a space.
  function context.log(level, level_name, ...)
    log(name, level, level_name, ...)
  end

  --- Send a debug message to the log.
  ---@param ... any The values to be included in the log. Concatenated with a space.
  function context.debug(...)
    log(name, logging.LOG_LEVEL.DEBUG, "DEBUG", ...)
  end

  --- Send an informational message to the log.
  ---@param ... any The values to be included in the log. Concatenated with a space.
  function context.info(...)
    log(name, logging.LOG_LEVEL.INFO, "INFO", ...)
  end

  --- Send a warning to the log.
  ---@param ... any The values to be included in the log. Concatenated with a space.
  function context.warn(...)
    log(name, logging.LOG_LEVEL.WARN, "WARN", ...)
  end

  --- Send an error to the log.
  ---@param ... any The values to be included in the log. Concatenated with a space.
  function context.error(...)
    log(name, logging.LOG_LEVEL.ERROR, "ERROR", ...)
  end

  function context.fatal(...)
    log(name, logging.LOG_LEVEL.FATAL, "FATAL", ...)
  end

  return setmetatable(context, logging)
end

--- Set the display level of the log. Log entries that are below this value will not be logged.
---@param level logging-log_level The log level.
function logging.set_level(level)
  expect(1, level, "number")

  log_level = level
end

--- Set the window that the logger uses. Otherwise will just output to whatever `term.current()` is at the time of requiring.
---@param win Redirect The window object to log to.
function logging.set_window(win)
  expect(1, win, "table")

  log_window = win
end

--- Check if an error has been thrown since the last time errors were cleared.
---@return boolean errored
function logging.has_errored()
  return errored
end

--- Check if a warn has occurred since the last time warns were cleared.
---@return boolean warned
function logging.has_warned()
  return warned
end

--- Clear the errors.
function logging.clear_error()
  errored = false
end

--- Clear the warns.
function logging.clear_warn()
  warned = false
end

--- Dump the log to a file.
---@param filename string The file to dump to.
---@param dont_clear boolean? If true, does not clear the log after dumping.
function logging.dump_log(filename, dont_clear)
  local h, err = fs.open(filename, 'w') --[[@as WriteHandle]]

  if not h then error(err, 0) end

  for _, line in ipairs(log_lines) do
    h.writeLine(line)
  end
  h.close()

  if not dont_clear then
    log_lines = {n = 0}
  end
end

return logging
