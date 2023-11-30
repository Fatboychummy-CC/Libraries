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
---@return boolean success Whether or not the response was successful.
---@return any response The response from PineStore, or the error message.
local function pine_get(url)
  return parse_response(http.get(PINESTORE_ROOT .. url))
end

--- Make a post request PineStore
---@param url string The endpoint to get.
---@param data string The data to send.
---@return boolean success Whether or not the response was successful.
---@return any response The response from PineStore, or the error message.
local function pine_post(url, data)
  return parse_response(http.post(PINESTORE_ROOT .. url, data))
end

--- PineStore API.
---@type pine_store-base
local api = {
  project = {},
  projects = {},
  user = {},
  log = {},
  auth = {}
}

---@diagnostic disable:duplicate-set-field Does @meta do nothing?

-- ########################################################################## --
--                                   Project                                  --
-- ########################################################################## --

function api.project.info(id)
  expect(1, id, "number")

  return pine_get("project/" .. id)
end

function api.project.comments(id)
  expect(1, id, "number")

  return pine_get("project/" .. id .. "/comments")
end

function api.project.changelog(id)
  expect(1, id, "number")

  return pine_get("project/" .. id .. "/changelog")
end

function api.project.changelogs(id)
  expect(1, id, "number")

  return pine_get("project/" .. id .. "/changelogs")
end

-- ########################################################################## --
--                                 Projects                                   --
-- ########################################################################## --

function api.projects.list()
  return pine_get("projects")
end

function api.projects.search(query)
  expect(1, query, "string")

  return pine_get("projects/search/?q=" .. textutils.urlEncode(query))
end

function api.projects.named(name)
  expect(1, name, "string")

  return pine_get("projects/named/?name=" .. textutils.urlEncode(name))
end

-- ########################################################################## --
--                                   User                                     --
-- ########################################################################## --

function api.user.info(id)
  expect(1, id, "number")

  return pine_get("user/" .. id)
end

function api.user.projects(id)
  expect(1, id, "number")

  return pine_get("user/" .. id .. "/projects")
end

-- ########################################################################## --
--                                   Log                                      --
-- ########################################################################## --

function api.log.view(id)
  expect(1, id, "number")

  return pine_post("log/view", textutils.serializeJSON {
    projectId = id
  })
end

function api.log.download(id)
  expect(1, id, "number")

  return pine_post("log/download", textutils.serializeJSON {
    projectId = id
  })
end

-- ########################################################################## --
--                                   Auth                                     --
-- ########################################################################## --

---@FIXME Implement this.


return api