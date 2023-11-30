---@meta

---@class pine_store-base
---@field project pine_store-project_root
---@field projects pine_store-projects_root
---@field user pine_store-user_root
---@field log pine_store-log_root
---@field auth pine_store-auth_root

-- ########################################################################## --
--                                   Project                                  --
-- ########################################################################## --

---@class pine_store-project_root
local project_root = {}

--- Get information about a project from PineStore.
---@param id integer The ID of the project to get.
---@return boolean success Whether or not the request was successful.
---@return pine_store-response_project|string response The response from PineStore, or the error message.
function project_root.info(id) end

--- Get a list of comments on a project.
---@param id integer The ID of the project to get comments from.
---@return boolean success Whether or not the request was successful.
---@return pine_store-response_comments|string response The response from PineStore, or the error message.
function project_root.comments(id) end

--- Get the most recent changelog entry of a project.
---@param id integer The ID of the project to get the changelog from.
---@return boolean success Whether or not the request was successful.
---@return pine_store-response_changelog|string response The response from PineStore, or the error message.
function project_root.changelog(id) end

--- Get a list of changelog entries for a project.
---@param id integer The ID of the project to get the changelogs from.
---@return boolean success Whether or not the request was successful.
---@return pine_store-response_changelogs|string response The response from PineStore, or the error message.
function project_root.changelogs(id) end

-- ########################################################################## --
--                                  Projects                                  --
-- ########################################################################## --

---@class pine_store-projects_root
local projects_root = {}

--- Get a list of all projects.
---@return boolean success Whether or not the request was successful.
---@return pine_store-response_projects|string response The response from PineStore, or the error message.
function projects_root.list() end

--- Search for projects.
---@param query string The query to search for.
---@return boolean success Whether or not the request was successful.
---@return pine_store-response_projects|string response The response from PineStore, or the error message.
function projects_root.search(query) end

--- Get information about a project from PineStore by name (requires an exact match).
---@param name string The name of the project to get.
---@return boolean success Whether or not the request was successful.
---@return pine_store-response_project|string response The response from PineStore, or the error message.
function projects_root.named(name) end

-- ########################################################################## --
--                                    User                                    --
-- ########################################################################## --

---@class pine_store-user_root
local user_root = {}

--- Get information about a user from PineStore.
---@param id integer The ID of the user to get.
---@return boolean success Whether or not the request was successful.
---@return pine_store-response_user|string response The response from PineStore, or the error message.
function user_root.info(id) end

--- Get a list of projects owned by a user.
---@param id integer The ID of the user to get projects from.
---@return boolean success Whether or not the request was successful.
---@return pine_store-response_projects|string response The response from PineStore, or the error message.
function user_root.projects(id) end

-- ########################################################################## --
--                                    Log                                     --
-- ########################################################################## --

---@class pine_store-log_root
local log_root = {}

--- Register a view for a project.
---@param id integer The ID of the project to register a view for.
---@return boolean success Whether or not the request was successful.
---@return pine_store-response_base|string response The response from PineStore, or the error message.
---@deprecated PineStore warns that this endpoint is mainly used on the front-end for the site, and that it is not recommended to use it.
function log_root.view(id) end

--- Register a download for a project.
---@param id integer The ID of the project to register a download for.
---@return boolean success Whether or not the request was successful.
---@return pine_store-response_base|string response The response from PineStore, or the error message.
function log_root.download(id) end

---@class pine_store-auth_root
local auth_root = {} ---@FIXME I will document this part later...

-- ########################################################################## --
--                             Response objects                               --
-- ########################################################################## --

---@class pine_store-response_base
---@field success boolean Whether or not the request was successful.
---@field error string? The error message, if success is false.

---@class pine_store-response_project : pine_store-response_base
---@field project pine_store-project? The project data, if success is true.

---@class pine_store-response_comments : pine_store-response_base
---@field comments pine_store-comment[]? The comments, if success is true.

---@class pine_store-response_changelog : pine_store-response_base
---@field changelog pine_store-changelog? The changelog, if success is true.

---@class pine_store-response_changelogs : pine_store-response_base
---@field changelogs pine_store-changelog[]? The changelogs, if success is true.

---@class pine_store-response_projects : pine_store-response_base
---@field projects pine_store-project[]? The projects, if success is true.

---@class pine_store-response_user : pine_store-response_base
---@field user pine_store-user? The user data, if success is true.

---@class pine_store-project
---@field id integer The ID of the project.
---@field date_added integer The UNIX timestamp corresponding to when the project was added to PineStore.
---@field date_updated integer The UNIX timestamp corresponding to when the project was last updated.
---@field date_release integer The UNIX timestamp corresponding to when the project was released on PineStore.
---@field date_publish integer The UNIX timestamp corresponding to when the project was published on PineStore.
---@field owner_discord string The Discord ID of the owner of the project.
---@field owner_name string The name of the owner of the project.
---@field name string The name of the project.
---@field install_command string The command to run to install the project.
---@field download_url string? The URL to download the project from.
---@field target_file string? The file to run after installation is complete.
---@field tags string A list of tags for the project, comma-separated.
---@field repository string? The URL to the repository for the project.
---@field description_short string? A short description of the project.
---@field description string? A long description of the project.
---@field description_markdown string? A long description of the project, in Markdown format.
---@field has_thumbnail bool_integer Whether or not the project has a thumbnail.
---@field hide_thumbnail bool_integer Whether or not the thumbnail should be hidden.
---@field media_count integer The number of media items for the project.
---@field keywords string A list of keywords for the project, comma-separated.
---@field downloads integer The number of downloads for the project.
---@field downloads_recent integer The number of downloads for the project in the last 30 days.
---@field views integer The number of views for the project.
---@field visible bool_integer Whether or not the project is visible.

---@class pine_store-comment
---@field id integer The ID of the comment.
---@field project_id integer The ID of the project the comment is on.
---@field reply_id integer? The ID of the comment this comment is a reply to, if it is replying to another comment.
---@field user_discord string The Discord ID of the user who posted the comment.
---@field user_name string The name of the user who posted the comment.
---@field timestamp integer The UNIX timestamp corresponding to when the comment was posted.
---@field body string The body of the comment.

---@class pine_store-changelog
---@field project_id string The ID of the project the changelog is for.
---@field timestamp integer The UNIX timestamp corresponding to when the changelog was posted.
---@field body string The body of the changelog.

---@class pine_store-user
---@field discord_id string The Discord ID of the user.
---@field joined_on integer The UNIX timestamp corresponding to when the user joined PineStore.
---@field name string The name of the user.
---@field about string? A short description of the user.
---@field about_markdown string? A short description of the user, in Markdown format.
---@field connections pine_store-connection[]? A list of connections for the user.

---@class pine_store-connection
---@field id pine_store-connection_type The type of connection.
---@field display string The display name of the connection.
---@field link string The link to the connection.

---@alias pine_store-connection_type
---| '"discord"' # Discord
---| '"github"' # GitHub
---| '"twitterx"' # Twitter/X
---| '"youtube"' # YouTube
---| '"twitch"' # Twitch
---| '"reddit"' # Reddit
---| '"steam"' # Steam
---| string # Other

---@alias bool_integer
---| '1'
---| '0'

-- ########################################################################## --
--                                   Auth                                     --
-- ########################################################################## --

---@FIXME Implement this.