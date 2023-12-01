--- A simple library for communicating with the PineStore API.

local expect = require "cc.expect".expect
local PINESTORE_ROOT = "https://pinestore.cc/api/"

--- Parse a response from PineStore.
---@param handle BinaryResponse|Response? The response from PineStore.
---@param err string? The error message, if any.
---@param err_handle BinaryResponse|Response? The error handle, if any.
---@return boolean success Whether or not the response was successful.
---@return any response The response from PineStore, or the error message.
local function parse_response(handle, err, err_handle)
  if not handle and not err_handle then
    return false, "Failed to connect to PineStore: " .. err
  end

  local success, response = pcall(textutils.unserializeJSON, handle or err_handle);

  (handle or err_handle).close()

  if not success or not response then
    return false, "Failed to parse response from pinestore."
  end

  if response and not response.success then
    return false, "Failed to get information from pinestore: " .. response.error
  end

  return true, response
end

--- Make a get request to PineStore.
---@param url string The endpoint to get.
---@param authorization string? The authorization token to use.
---@return boolean success Whether or not the response was successful.
---@return any response The response from PineStore, or the error message.
local function pine_get(url, authorization)
  return parse_response(http.get(
    PINESTORE_ROOT .. url,
    {
      ---@diagnostic disable-next-line If it's nil it shrimply doesn't get appended.
      authorization = authorization
    }
  ))
  ---@FIXME actually implement the authorization part.
end

--- Make a post request PineStore
---@param url string The endpoint to get.
---@param data string The data to send.
---@param authorization string? The authorization token to use.
---@return boolean success Whether or not the response was successful.
---@return any response The response from PineStore, or the error message.
local function pine_post(url, data, authorization)
  return parse_response(http.post(
    PINESTORE_ROOT .. url,
    data,
    {
      ["Content-Type"] = "application/json",
      ---@diagnostic disable-next-line If it's nil it shrimply doesn't get appended.
      authorization = authorization
    }
  ))

  ---@FIXME Actually implement the authorization part.
end

--- PineStore API.
---@type pine_store-base
local pine_api = {
  project = {},
  projects = {},
  user = {},
  log = {},
  auth = {
    profile = {},
    project = {},
    media = {},
    comment = {}
  }
}
local auth_token = nil ---@type string?

---@diagnostic disable:duplicate-set-field Does @meta do nothing?

-- ########################################################################## --
--                               Non-authorized                               --
-- ########################################################################## --

-- ################################################################ --
--                              Project                             --
-- ################################################################ --

function pine_api.project.info(id)
  expect(1, id, "number")

  return pine_get("project/" .. id)
end

function pine_api.project.comments(id)
  expect(1, id, "number")

  return pine_get("project/" .. id .. "/comments")
end

function pine_api.project.changelog(id)
  expect(1, id, "number")

  return pine_get("project/" .. id .. "/changelog")
end

function pine_api.project.changelogs(id)
  expect(1, id, "number")

  return pine_get("project/" .. id .. "/changelogs")
end

-- ################################################################ --
--                            Projects                              --
-- ################################################################ --

function pine_api.projects.list()
  return pine_get("projects")
end

function pine_api.projects.search(query)
  expect(1, query, "string")

  return pine_get("projects/search/?q=" .. textutils.urlEncode(query))
end

function pine_api.projects.named(name)
  expect(1, name, "string")

  return pine_get("projects/named/?name=" .. textutils.urlEncode(name))
end

-- ################################################################ --
--                              User                                --
-- ################################################################ --

function pine_api.user.info(id)
  expect(1, id, "number")

  return pine_get("user/" .. id)
end

function pine_api.user.projects(id)
  expect(1, id, "number")

  return pine_get("user/" .. id .. "/projects")
end

-- ################################################################ --
--                               Log                                --
-- ################################################################ --

function pine_api.log.view(id)
  expect(1, id, "number")

  return pine_post("log/view", textutils.serializeJSON {
    projectId = id
  })
end

function pine_api.log.download(id)
  expect(1, id, "number")

  return pine_post("log/download", textutils.serializeJSON {
    projectId = id
  })
end

-- ########################################################################## --
--                                 Authorized                                 --
-- ########################################################################## --


-- ################################################################ --
--                             profile                              --
-- ################################################################ --

function pine_api.auth.profile.info()
  return pine_get("auth/profile", auth_token)
end

return pine_api