--- A simple library for communicating with the PineStore API.

local _expect = require "cc.expect"
local PINESTORE_ROOT = "https://pinestore.cc/api/"

local expect, field = _expect.expect, _expect.field

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

  local success, response = pcall(textutils.unserializeJSON, handle and handle.readAll() or err_handle and err_handle.readAll());

  (handle or err_handle).close()

  if not success or not response then
    if err then
      return false, "Failed to parse response from pinestore: " .. err
    end
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

---@diagnostic disable:duplicate-set-field
-- Does @meta do nothing?

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
  expect(1, id, "string")

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

function pine_api.auth.profile.projects()
  return pine_get("auth/profile/projects", auth_token)
end

function pine_api.auth.profile.update(data)
  expect(1, data, "table")

  -- Validation: Collect the error from `field`, then supply more information about the error.
  local step, pos = "main", -1
  local ok, err = pcall(function()
    -- Validate the input table.
    field(data, "allow_null", "boolean", "nil")
    field(data, "name", "string", "nil")
    field(data, "about", "string", "nil")
    field(data, "about_markdown", "string", "nil")
    field(data, "connections", "table", "nil")

    -- Validate each connection.
    if data.connections then
      step = "connections"
      for i, connection in ipairs(data.connections) do
        pos = i
        field(connection, "id", "string")
        field(connection, "display", "string")
        field(connection, "link", "string", "nil")
      end
    end
  end)

  if not ok then
    if step == "main" then
      -- Error with one of the fields in the main table. We shouldn't need a whole lot more information here.
      -- Just supply the error and make sure it's known that its the caller's fault.
      error(err, 2)
    else
      -- Error with one of the connections. We need to supply more information.
      error(("Connection #%d: %s"):format(pos, err), 2)
    end
  end

  return pine_post("auth/profile/update", textutils.serializeJSON(data), auth_token)
end

function pine_api.auth.profile.get_options()
  return pine_get("auth/profile/options", auth_token)
end

function pine_api.auth.profile.set_options(options)
  expect(1, options, "table")

  -- Validation: Collect the error from `field`, then supply more information about the error.
  local ok, err = pcall(function()
    field(options, "user_discord", "string", "nil")
    field(options, "discord_notifications", "boolean", "nil")
    field(options, "diiscord_noti_comment", "boolean", "nil")
    field(options, "discord_noti_reply", "boolean", "nil")
    field(options, "discord_noti_newfollow_user", "boolean", "nil")
    field(options, "discord_noti_newfollow_project", "boolean", "nil")
    field(options, "discord_noti_following_newproject", "boolean", "nil")
    field(options, "discord_noti_following_projectupdate", "boolean", "nil")
  end)

  if not ok then
    -- We shouldn't need a whole lot more information here.
    -- Just supply the error and make sure it's known that its the caller's fault.
    error(err, 2)
  end

  return pine_post("auth/profile/options", textutils.serializeJSON(options), auth_token)
end

-- ################################################################ --
--                             project                              --
-- ################################################################ --

function pine_api.auth.project.update(project_data)
  expect(1, project_data, "table")

  -- Validation: Collect the error from `field`, then supply more information about the error.
  local ok, err = pcall(function()
    field(project_data, "projectId", "number")
    field(project_data, "allow_null", "boolean", "nil")
    field(project_data, "projectname", "string", "nil")
    field(project_data, "install_command", "string", "nil")
    field(project_data, "download_url", "string", "nil")
    field(project_data, "target_file", "string", "nil")
    field(project_data, "tags", "table", "nil")
    field(project_data, "repository", "string", "nil")
    field(project_data, "description_short", "string", "nil")
    field(project_data, "description", "string", "nil")
    field(project_data, "description_markdown", "string", "nil")
    field(project_data, "keywords", "table", "nil")
    field(project_data, "visible", "boolean", "nil")
    field(project_data, "date_release", "number", "nil")

    local function validate_array(arr)
      local max_n = 0
      for k in pairs(arr) do
        if type(k) ~= "number" then
          error("Array contains non-integer key: " .. tostring(k), 0)
        end

        if k > max_n then
          max_n = k
        end
      end

      -- Now ensure we can count to `max_n` without any holes.
      for i = 1, max_n do
        if arr[i] == nil then
          error("Array contains hole at index " .. i, 0)
        end
      end
    end

    -- Validate `tags` and `keywords` -- they should be string[]
    if project_data.tags then
      validate_array(project_data.tags)

      local ok2, err2 = pcall(function()
        for i, tag in ipairs(project_data.tags) do
          if type(tag) ~= "string" then
            error("Element at index " .. i .. " is not a string", 0)
          end
        end
      end)
      if not ok2 then
        error("Field 'tags': " .. err2, 0)
      end

      validate_array(project_data.tags)
    end

    if project_data.keywords then
      validate_array(project_data.keywords)

      local ok2, err2 = pcall(function()
        for i, keyword in ipairs(project_data.keywords) do
          if type(keyword) ~= "string" then
            error("Element at index " .. i .. " is not a string", 0)
          end
        end
      end)
      if not ok2 then
        error("Field 'keywords': " .. err2, 0)
      end
    end
  end)

  if not ok then
    -- We shouldn't need a whole lot more information here.
    -- Just supply the error and make sure it's known that its the caller's fault.
    -- For some reason `field` does not do this.
    error(err, 2)
  end

  return pine_post("auth/project/update", textutils.serializeJSON(project_data), auth_token)
end

function pine_api.auth.project.new(name)
  expect(1, name, "string")

  return pine_post("auth/project/new", textutils.serializeJSON {
    name = name
  }, auth_token)
end

function pine_api.auth.project.delete(id)
  expect(1, id, "number")

  return pine_post("auth/project/delete", textutils.serializeJSON {
    projectId = id
  }, auth_token)
end

function pine_api.auth.project.publish_update(id, body)
  expect(1, id, "number")
  expect(2, body, "string")

  return pine_post("auth/project/publishupdate", textutils.serializeJSON {
    projectId = id,
    body = body
  }, auth_token)
end

-- ################################################################ --
--                              media                               --
-- ################################################################ --

function pine_api.auth.media.new(id, image)
  expect(1, id, "number")
  expect(2, image, "string")

  return pine_post("auth/media", textutils.serializeJSON {
    projectId = id,
    imageData = image
  }, auth_token)
end

function pine_api.auth.media.remove(id, index)
  expect(1, id, "number")
  expect(2, index, "number")

  return pine_post("auth/media/remove", textutils.serializeJSON {
    projectId = id,
    index = index
  }, auth_token)
end

function pine_api.auth.media.set_thumbnail(id, image)
  expect(1, id, "number")
  expect(2, image, "string")

  return pine_post("auth/media/thumbnail", textutils.serializeJSON {
    projectId = id,
    imageData = image
  }, auth_token)
end

-- ################################################################ --
--                             comment                              --
-- ################################################################ --

function pine_api.auth.comment.new(id, body, reply_id)
  expect(1, id, "number")
  expect(2, body, "string")
  expect(3, reply_id, "number", "nil")

  return pine_post("auth/comment", textutils.serializeJSON {
    projectId = id,
    body = body,
    replyId = reply_id
  }, auth_token)
end

function pine_api.auth.comment.delete(id)
  expect(1, id, "number")

  return pine_post("auth/comment/delete", textutils.serializeJSON {
    commentId = id
  }, auth_token)
end

return pine_api --[[@as pine_store-base]]