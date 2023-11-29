--- A simple library for communicating with the PineStore API.

local expect = require "cc.expect".expect
local PINESTORE_ROOT = "https://pinestore.cc/api/"

--- Parse a response from PineStore.
---@param url string The endpoint to get.
---@return boolean success Whether or not the response was successful.
---@return any response The response from PineStore, or the error message.
local function parse_get(url)
  local data, err, err_data = http.get(PINESTORE_ROOT .. url)

  if not data and not err_data then
    return false, "Failed to connect to PineStore: " .. err
  end

  local success, response = pcall(textutils.unserializeJSON, data or err_data);

  (data or err_data).close()

  if not success or not response then
    return false, "Failed to parse response from pinestore."
  end

  if response and not response.success then
    return false, "Failed to get information from pinestore: " .. response.error
  end

  return true, response
end

--- Parse a response from PineStore (Using POST this time :D)
---@param url string The endpoint to get.
---@param data string The data to send.
---@return boolean success Whether or not the response was successful.
---@return any response The response from PineStore, or the error message.
local function parse_post(url, data)
  local data, err, err_data = http.post(PINESTORE_ROOT .. url, data)

  if not data and not err_data then
    return false, "Failed to connect to PineStore: " .. err
  end

  local success, response = pcall(textutils.unserializeJSON, data or err_data);

  (data or err_data).close()

  if not success or not response then
    return false, "Failed to parse response from pinestore."
  end

  if response and not response.success then
    return false, "Failed to get information from pinestore: " .. response.error
  end

  return true, response
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

---@diagnostic disable:duplicate-set-field We need to do this to document the API.

-- ########################################################################## --
--                                   Project                                  --
-- ########################################################################## --

function api.project.info(id)
  expect(1, id, "number")

  return parse_get("project/" .. id)
end

function api.project.comments(id)
  expect(1, id, "number")

  return parse_get("project/" .. id .. "/comments")
end

function api.project.changelog(id)
  expect(1, id, "number")

  return parse_get("project/" .. id .. "/changelog")
end

function api.project.changelogs(id)
  expect(1, id, "number")

  return parse_get("project/" .. id .. "/changelogs")
end

-- ########################################################################## --
--                                 Projects                                   --
-- ########################################################################## --

function api.projects.list()
  return parse_get("projects")
end

function api.projects.search(query)
  expect(1, query, "string")

  return parse_get("projects/search/?q=" .. textutils.urlEncode(query))
end

function api.projects.named(name)
  expect(1, name, "string")

  return parse_get("projects/named/?name=" .. textutils.urlEncode(name))
end

-- ########################################################################## --
--                                   User                                     --
-- ########################################################################## --

function api.user.info(id)
  expect(1, id, "number")

  return parse_get("user/" .. id)
end

function api.user.projects(id)
  expect(1, id, "number")

  return parse_get("user/" .. id .. "/projects")
end

-- ########################################################################## --
--                                   Log                                      --
-- ########################################################################## --

function api.log.view(id)
  expect(1, id, "number")

  return parse_post("log/view", textutils.serializeJSON {
    projectId = id
  })
end

function api.log.download(id)
  expect(1, id, "number")

  return parse_post("log/download", textutils.serializeJSON {
    projectId = id
  })
end


return api