--- This file contains specific error definitions for the challenge runner.

---@class Errors
local errors = {}

local TRACEBACK_FORMATTER = "%s : %s\n%s\n\n%s"
local ERROR_FORMATTER = "%s : %s\n%s"

local error_mt = {
  __tostring = function(self)
    if self.traceback then
      return TRACEBACK_FORMATTER:format(self.type, self.message, self.details, self.traceback)
    end

    return ERROR_FORMATTER:format(self.type, self.message, self.details)
  end
}

local function _error(t)
  -- I know it says the level defaults to 1, but in order to skip the extra
  -- function calls here, we need to set it to 2 to skip the error function.
  local level = t.level or 2

  return error(
    setmetatable({
      message = t.message or "An unknown error occurred",
      details = t.details or "No details provided",
      type = t.type or "UnknownError",
      traceback = debug.traceback(nil, level) or "No traceback available"
    }, error_mt)
    , level)
end

---@class CustomError
---@field message string The error message.
---@field details string? Detailed information about the error, if applicable.
---@field traceback string? The traceback of the error, usually injected by this error module.
---@field type ErrorType The type of error.

---@alias ErrorType
---| '"UserError"' # An error caused by the user.
---| '"InternalError"' # An error caused by the challenge runner itself.
---| '"ChallengeError"' # An error caused by the challenge itself.
---| '"NetworkError"' # An error caused by a network issue.
---| '"AuthenticationError"' # An error caused by authentication issues.
---| '"UnknownError"' # An error of unknown origin.

---@class UserError : CustomError
---@field type '"UserError"'

---@param message string The error message.
---@param details string? Detailed information about the error, if applicable.
---@param level integer? The level of the error, defaults to 1.
function errors.UserError(message, details, level)
  return _error {
    message = message,
    details = details,
    type = "UserError",
    traceback = debug.traceback(),
    level = level
  }
end

---@class InternalError : CustomError
---@field type '"InternalError"'

---@param message string The error message.
---@param details string? Detailed information about the error, if applicable.
---@param level integer? The level of the error, defaults to 1.
function errors.InternalError(message, details, level)
  return _error {
    message = message,
    details = details,
    traceback = debug.traceback(),
    type = "InternalError",
    level = level
  }
end

---@class ChallengeError : CustomError
---@field type '"ChallengeError"'

---@param message string The error message.
---@param details string? Detailed information about the error, if applicable.
---@param level integer? The level of the error, defaults to 1.
function errors.ChallengeError(message, details, level)
  return _error {
    message = message,
    details = details,
    traceback = debug.traceback(),
    type = "ChallengeError",
    level = level
  }
end

---@class NetworkError : CustomError
---@field type '"NetworkError"'

---@param message string The error message.
---@param details string? Detailed information about the error, if applicable.
---@param level integer? The level of the error, defaults to 1.
function errors.NetworkError(message, details, level)
  return _error {
    message = message,
    details = details,
    type = "NetworkError",
    traceback = debug.traceback(),
    level = level
  }
end

---@class AuthenticationError : CustomError
---@field type '"AuthenticationError"'

---@param message string The error message.
---@param details string? Detailed information about the error, if applicable.
---@param level integer? The level of the error, defaults to 1.
function errors.AuthenticationError(message, details, level)
  return _error {
    message = message,
    details = details,
    type = "AuthenticationError",
    traceback = debug.traceback(),
    level = level
  }
end

---@param message string The error message.
---@param details string? Detailed information about the error, if applicable.
---@param type ErrorType|string The type of error.
---@param level integer? The level of the error, defaults to 1.
function errors.CustomError(message, details, type, level)
  return _error {
    message = message,
    details = details,
    type = type,
    traceback = debug.traceback(),
    level = level
  }
end

return errors
