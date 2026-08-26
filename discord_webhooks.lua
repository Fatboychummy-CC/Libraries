--- A simple library for sending messages to Discord webhooks.


---@class DiscordWebhooks.Embed.Footer
---@field text string The footer text.
---@field icon_url string? URL of footer icon (only supports http[s] and attachments)
---@field proxy_icon_url string? A proxied url of footer icon.

---@class DiscordWebhooks.Embed.Field
---@field name string The title section of the field.
---@field value string The body of the field.
---@field inline boolean? Whether this field should display inline (default off).


---@class DiscordWebhooks.Embed
---@field title string? The title of the embed.
---@field type "rich" Always "rich" for webhook embeds.
---@field description string? The description of the embed.
---@field url string? The url of the embed.
---@field timestamp string? ISO8601 timestamp.
---@field color integer? The color code of the embed.
---@field footer DiscordWebhooks.Embed.Footer? The footer object.
---@field fields DiscordWebhooks.Embed.Field[]? Up to 25 fields of information.
local Embed = {}
local E_mt = {__index = Embed}



--- Creates a new embed
---@param title string? The title of the embed.
---@param description string? The body of the embed.
---@return DiscordWebhooks.Embed embed
function Embed.new(title, description)
  ---@type DiscordWebhooks.Embed
  return setmetatable({
    title = title,
    description = description
  }, E_mt)
end



--- Sets the footer of this embed.
---@param text string The footer text.
---@param icon_url string? The footer icon URL.
---@param proxy_icon_url string? The footer icon URL if proxied.
---@return self self For chaining.
function Embed:setFooter(text, icon_url, proxy_icon_url)
  self.footer = {
    text = text,
    icon_url = icon_url,
    proxy_icon_url = proxy_icon_url
  }

  return self
end


--- Adds a field to the embed.
---@param name string The 'title' of the field.
---@param value string The body of the field.
---@param inline boolean? Whether or not this field should be inline.
---@return self self For chaining.
function Embed:addField(name, value, inline)
  if not self.fields then self.fields = {} end
  table.insert(self.fields, {
    name = name,
    value = value,
    inline = inline
  })

  return self
end



local color_lookup = {}
for i = 0, 15 do
  local color = 2^i
  color_lookup[color] = colors.packRGB(term.getPaletteColor(color))
end

--- Sets the embed to a color based on a computercraft color.
--- Note that this uses the palette colors of the terminal when initially set up.
---@param color ccTweaked.colors.color
---@return self self For chaining.
function Embed:setColor(color)
  self.color = color_lookup[color]

  return self
end



--- Sets the embed timestamp to right now.
---@return self self For chaining.
function Embed:setTimestampNow()
  self.timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ") --[[@as string]]

  return self
end



---@class DiscordWebhooks.AllowedMentions
---@field parse DiscordWebhooks.AllowedMentions.MentionType[] Array of allowed mention types.
---@field roles integer[]? The roles IDs the webhook can mention.
---@field users integer[]? The user IDs the webhook can mention.
local AllowedMentions = {}
local AM_mt = {__index = AllowedMentions}



--- Creates a new AllowedMentions object.
function AllowedMentions.new()
  ---@type DiscordWebhooks.AllowedMentions
  return setmetatable({
    parse = textutils.empty_json_array
  }, AM_mt)
end


---@param t table
---@param v any
local function exists(t, v)
  for _, val in pairs(t) do
    if v == val then return true end
  end

  return false
end


--- Allow mentioning the given type.
---@param _type DiscordWebhooks.AllowedMentions.MentionType The mention type to allow.
---@return self self For chaining.
function AllowedMentions:allowMention(_type)
  if self.parse == textutils.empty_json_array then
    self.parse = {}
  end
  if not exists(self.parse, _type) then
    table.insert(self.parse, _type)
  end

  return self
end


local idFmt = "%d"
local function fmtID(id)
  return idFmt:format(id)
end


--- Allow mentioning a user ID.
---@param id string The user ID to mention.
---@return self self For chaining.
function AllowedMentions:allowMentioningUser(id)
  if not self.users then self.users = {} end
  if not exists(self.users, id) then
    table.insert(self.users, id)
  end

  return self
end



--- Allow mentioning a role ID
---@param id string the role ID to mention.
---@return self self For chaining.
function AllowedMentions:allowMentioningRole(id)
  if not self.roles then self.roles = {} end
  if not exists(self.roles, id) then
    table.insert(self.roles, id)
  end

  return self
end



---@class DiscordWebhooks.ClientWebhookMessage
---@field query DiscordWebhooks.ClientWebhookMessage.Query The query parameters of the message.
---@field json DiscordWebhooks.ClientWebhookMessage.JSON The JSON parameters of the message.
local DiscordMessage = {}
local DM_mt = {__index = DiscordMessage}
function DiscordMessage:allowed_mentions()
  return self.json.allowed_mentions
end

---@class DiscordWebhooks.ClientWebhookMessage.Query
---@field wait boolean? Whether to wait for the response object. Defaults to false.
---@field with_components boolean? Whether to respect the `components` field. Defaults to false.
---@field thread_id integer? The thread ID to send to, if needed. No default.

---@class DiscordWebhooks.ClientWebhookMessage.JSON
---@field content string The content of the message.
---@field username string? The username to use for the message.
---@field avatar_url string? The avatar url to use for the message.
---@field tts boolean? Whether to send with TTS enabled.
---@field embeds DiscordWebhooks.Embed[]? An array of up to 10 embed objects.
---@field allowed_mentions DiscordWebhooks.AllowedMentions The AllowedMentions object. We by default supply an AllowedMentions object that suppresses all mentions.

---@alias DiscordWebhooks.AllowedMentions.MentionType
---| "users"
---| "roles"
---| "everyone"



--#region DiscordMessage body

--- Sets the message content.
---@param content string
---@return self self For chaining.
function DiscordMessage:setContent(content)
  self.json.content = content

  return self
end



--- Sets the username of the message.
---@param username string
---@return self self For chaining.
function DiscordMessage:setUsername(username)
  self.json.username = username

  return self
end



--- Sets the avatar_url of the message.
---@param avatar_url string
---@return self self For chaining.
function DiscordMessage:setAvatarUrl(avatar_url)
  self.json.avatar_url = avatar_url

  return self
end



--- Sets TTS state of the message.
---@param tts boolean
---@return self self For chaining.
function DiscordMessage:setTTS(tts)
  self.json.tts = tts

  return self
end


--- Adds an embed to the message.
function DiscordMessage:addEmbed(embed)
  if not self.json.embeds then self.json.embeds = {} end
  table.insert(self.json.embeds, embed)

  return self
end



--- Sets the query parameters.
---@param wait boolean? Whether to wait for the response object. Defaults to false.
---@param thread_id integer? The thread ID to send to, if needed. No default.
function DiscordMessage:setQuery(wait, thread_id)
  self.query.wait = wait
  self.query.thread_id = thread_id

  return self
end



--#endregion DiscordMessage body

---@class DiscordWebhooks.ServerWebhookMessage WIP


---@class DiscordWebhooks
---@field public url string The Discord webhook URL to send messages to.
---@field public username string? The global username to display when sending messages.
---@field public avatar_url string? The global avatar URL to display when sending messages.
local DiscordWebhooks = {}
local DW_mt = {__index = DiscordWebhooks}

---@type table<string, string>
local BASE_HEADERS = {
  ["Content-Type"] = "application/json",
}



--- Combines the given headers with the base headers.
---@param heads table<string, string> The headers.
local function headers(heads)
  for k, v in pairs(BASE_HEADERS) do
    if not heads[k] then -- Allow overriding the headers.
      heads[k] = v
    end
  end

  return heads
end



--- Create a new webhook object.
---@param url string The url to use.
---@param username string? The username to use. If none is given, will use "CC:Tweaked"
---@param avatar_url string? The avatar url to use. If none is given, will be a default discord avatar.
---@return DiscordWebhooks object The new webhook object.
function DiscordWebhooks.new(url, username, avatar_url)
  return setmetatable({
    url = url,
    username = username,
    avatar_url = avatar_url
  }, DW_mt)
end



--- Create a new message object.
---@return DiscordWebhooks.ClientWebhookMessage message The message object.
function DiscordWebhooks:newMessage()
  ---@type DiscordWebhooks.ClientWebhookMessage
  return setmetatable({
    query = {},
    json = {
      content = "",
      allowed_mentions = AllowedMentions.new(),
      username = self.username,
      avatar_url = self.avatar_url
    },
  }, DM_mt)
end



---@param t table<string, string>
---@return string query The table formatted as a url query string ("?key=value&foo=bar")
local function createQueryString(t)
  local query = "?"
  local fmt = "%s=%s"
  local urlFmt = function(s) return textutils.urlEncode(tostring(s)) end
  local function format(key, value)
    return fmt:format(urlFmt(key), urlFmt(value))
  end

  local doAmpersand = false
  for k, v in pairs(t) do
    if doAmpersand then
      query = query .. "&"
    end
    doAmpersand = true

    query = query .. format(k, v)
  end

  return query
end



--- Sends a message over the webhook.
---@param payload DiscordWebhooks.ClientWebhookMessage The message payload object to be serialized.
function DiscordWebhooks:transmit(payload)
  local t = {
    url = self.url .. createQueryString(payload.query),
    method = "POST",
    headers = headers{},
    body = textutils.serializeJSON(payload.json)
  }

  if not payload.query.wait then
    http.request(t)
    return
  end

  return http.post(t)
end



--- Marked deprecated to issue a warning when used.
--- This method will not delete a message on the webhook, it will *delete the webhook*.
---@deprecated
function DiscordWebhooks:DeleteTheWebhookNotAMessageButTheEntireWebhook()
  http.request {
    url = self.url,
    method = "DELETE"
  }
end


DiscordWebhooks.newEmbed = Embed.new
return DiscordWebhooks
