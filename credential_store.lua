--- This library is a simple credential store for storing encrypted credentials
--- for various sites.
--- 
--- The library uses a combination of PBKDF2 for key derivation, SHA-256 for
--- hashing, and ChaCha20 for encryption. The library also uses a simple
--- file-based storage system for storing the credentials.
--- 
--- This library is released to the public domain under The Unlicense.
--- Originally created by Fatboychummy.

local expect = require "cc.expect".expect
local chacha20 = require "ccryptolib.chacha20"
local sha256 = require "ccryptolib.sha256"
local random = require "ccryptolib.random"
local file_helper = (function() -- Minified from https://github.com/Fatboychummy-CC/Libraries/blob/main/file_helper.lua
  ---@diagnostic disable-next-line
  local a=require"cc.expect".expect;local b={working_directory=fs.getDir(shell.getRunningProgram())}function b:get_lines(c,d)if type(self)~="table"then d=c;c=self;self=b end;a(1,c,"string")a(2,d,"table","nil")local e={}if not fs.exists(fs.combine(self.working_directory,c))then return d or{n=0}end;for f in io.lines(fs.combine(self.working_directory,c))do table.insert(e,f)end;e.n=#e;return e end;function b:get_all(c,d)if type(self)~="table"then d=c;c=self;self=b end;a(1,c,"string")a(2,d,"string","nil")local g=io.open(fs.combine(self.working_directory,c),'r')if not g then return d or""end;local h=g:read"*a"g:close()return h end;function b:write(c,h)if type(self)~="table"then h=c;c=self;self=b end;a(1,c,"string")a(2,h,"string")local g,i=io.open(fs.combine(self.working_directory,c),'w')if not g then error(("Failed to open '%s' for writing: %s"):format(fs.combine(self.working_directory,c),i),2)end;g:write(h):close()end;function b:append(c,h)if type(self)~="table"then h=c;c=self;self=b end;a(1,c,"string")a(2,h,"string")local g,i=io.open(fs.combine(self.working_directory,c),'a')if not g then error(("Failed to open '%s' for writing: %s"):format(fs.combine(self.working_directory,c),i),2)end;g:write(h):close()end;function b:empty(c)if type(self)~="table"then c=self;self=b end;a(1,c,"string","nil")c=c or""fs.delete(fs.combine(self.working_directory,c))local g,i=io.open(fs.combine(self.working_directory,c),'w')if not g then error(("Failed to open '%s' for writing: %s"):format(fs.combine(self.working_directory,c),i),2)end;g:close()end;function b:unserialize(c,d)if type(self)~="table"then d=c;c=self;self=b end;a(1,c,"string")local g=io.open(fs.combine(self.working_directory,c),'r')if not g then return d end;local h=textutils.unserialise(g:read"*a")g:close()return h end;function b:serialize(c,h,j)if type(self)~="table"then j=h;h=c;c=self;self=b end;a(1,c,"string")a(3,j,"boolean","nil")local g,i=io.open(fs.combine(self.working_directory,c),'w')if not g then error(("Failed to open '%s' for writing: %s"):format(fs.combine(self.working_directory,c),i),2)end;g:write(textutils.serialize(h,{compact=j and true or false})):close()end;function b:instanced(k)if type(self)~="table"then k=self;self=b end;local l={working_directory=fs.combine(self.working_directory,k)}return setmetatable(l,{__index=b})end;function b:exists(c)if type(self)~="table"then c=self;self=b end;a(1,c,"string","nil")c=c or""return fs.exists(fs.combine(self.working_directory,c))end;function b:delete(c)if type(self)~="table"then c=self;self=b end;a(1,c,"string","nil")c=c or""fs.delete(fs.combine(self.working_directory,c))end;function b:list(m)if type(self)~="table"then m=self;self=b end;a(1,m,"string","nil")m=m or""return fs.list(fs.combine(self.working_directory,m))end;function b:is_directory(n)if type(self)~="table"then n=self;self=b end;a(1,n,"string","nil")n=n or""return fs.isDir(fs.combine(self.working_directory,n))end;function b:open(c,o)if type(self)~="table"then c=self;o=c;self=b end;a(1,c,"string")a(2,o,"string")return fs.open(fs.combine(self.working_directory,c),o)end;function b:is_read_only(n)if type(self)~="table"then n=self;self=b end;a(1,n,"string","nil")n=n or""return fs.isReadOnly(fs.combine(self.working_directory,n))end;function b:get_dir(n)if type(self)~="table"then n=self;self=b end;a(1,n,"string","nil")n=n or""return fs.getDir(fs.combine(self.working_directory,n))end;function b:get_name(n)if type(self)~="table"then n=self;self=b end;a(1,n,"string","nil")n=n or""return fs.getName(fs.combine(self.working_directory,n))end;function b:get_size(n)if type(self)~="table"then n=self;self=b end;a(1,n,"string","nil")n=n or""return fs.getSize(fs.combine(self.working_directory,n))end;function b:get_free_space(n)if type(self)~="table"then n=self;self=b end;a(1,n,"string","nil")n=n or""return fs.getFreeSpace(fs.combine(self.working_directory,n))end;function b:make_dir(n)if type(self)~="table"then n=self;self=b end;a(1,n,"string","nil")n=n or""fs.makeDir(fs.combine(self.working_directory,n))end;function b:move(p,q)if type(self)~="table"then q=p;p=self;self=b end;a(1,p,"string")a(2,q,"string")fs.move(fs.combine(self.working_directory,p),fs.combine(self.working_directory,q))end;function b:copy(p,q)if type(self)~="table"then q=p;p=self;self=b end;a(1,p,"string")a(2,q,"string")fs.copy(fs.combine(self.working_directory,p),fs.combine(self.working_directory,q))end;return b
end)() --[[@as file_helper]]

local errors = (function() -- Minified from https://github.com/Fatboychummy-CC/Libraries/blob/main/errors.lua
  ---@diagnostic disable-next-line
  local a={}local b="%s : %s\n%s\n\n%s"local c="%s : %s\n%s"local d={__tostring=function(self)if self.traceback then return b:format(self.type,self.message,self.details,self.traceback)end;return c:format(self.type,self.message,self.details)end}local function e(f)local g=f.level or 2;return error(setmetatable({message=f.message or"An unknown error occurred",details=f.details or"No details provided",type=f.type or"UnknownError",traceback=debug.traceback(nil,g)or"No traceback available"},d),g)end;function a.UserError(h,i,g)return e{message=h,details=i,type="UserError",traceback=debug.traceback(),level=g}end;function a.InternalError(h,i,g)return e{message=h,details=i,traceback=debug.traceback(),type="InternalError",level=g}end;function a.ChallengeError(h,i,g)return e{message=h,details=i,traceback=debug.traceback(),type="ChallengeError",level=g}end;function a.NetworkError(h,i,g)return e{message=h,details=i,type="NetworkError",traceback=debug.traceback(),level=g}end;function a.AuthenticationError(h,i,g)return e{message=h,details=i,type="AuthenticationError",traceback=debug.traceback(),level=g}end;function a.Error(h,i,j,g)return e{message=h,details=i,type=j,traceback=debug.traceback(),level=g}end;return a
end)() --[[@as Errors]]

random.initWithTiming()

local PBKDF2_ROUNDS = 10000
local PBKDF2_SALT_SIZE = 128
local CHACHA20_ROUNDS = 20
local CHACHA20_NONCE_SIZE = 12

local credential_directory = file_helper:instanced(".credential_store")

---@class CredentialEntry
---@field site_name string The name of the site.
---@field hash string The hash of the encryption key.
---@field salt_verification string The salt used for verification of the encryption key.
---@field salt_encryption string The salt used to generate the hash of the encryption key.
---@field created integer The UTC timestamp of when the entry was created.
---@field expiry integer? The UTC timestamp of when the entry will expire, if it will expire.
---@field type CredentialType The type of the entry.

---@class UserPassCredentialEntry : CredentialEntry
---@field username string The username for the site, encrypted.
---@field password string The password for the site, encrypted.
---@field nonce_uname string The nonce used to encrypt the username.
---@field nonce_pass string The nonce used to encrypt the password.

---@class TokenCredentialEntry : CredentialEntry
---@field token string The authentication token for the site, encrypted.
---@field nonce_token string The nonce used to encrypt the token.

---@class credential_store
local credential_store = {
  ---@enum CredentialType
  ENTRY_TYPES = {
    USER_PASS = "up",
    TOKEN = "token"
  },
  entries = {}
}

--- Display a percentage based on progress.
---@param y number The y position to display the progress at. Starts at x=1.
---@param stage number The current stage of the progress. Use this if you want to merge multiple actions into one percentage.
---@param stage_max number The maximum stage of the progress. Use this if you want to merge multiple actions into one percentage.
local function progress(y, stage, stage_max)
  if not y then error("bruh", 2) end
  y = y - 1

  stage = stage or 1
  stage_max = stage_max or 1

  local set = "|/-\\|"
  local idx = 1
  local multiplier = 1 / stage_max
  local start = (stage - 1) / stage_max

  return function(iter)
    term.setCursorPos(1, y)
    if iter ~= PBKDF2_ROUNDS then
      term.write(set:sub(idx, idx))
      term.write(("%3d%%"):format(math.floor(((iter / PBKDF2_ROUNDS) * multiplier + start) * 100 + 0.5)))
    else
      term.write(("\xb7%3d%%"):format(math.floor((multiplier + start) * 100 + 0.5)))
    end

    idx = idx + 1
    if idx > #set then idx = 1 end
  end
end

--- Wait until the user hits either y or n.
---@return boolean hit_y Whether the user hit y.
local function y_n()
  term.setCursorBlink(true)
  local _, key
  repeat
    _, key = os.pullEvent("key")
  until key == keys.y or key == keys.n
  os.pullEvent("char") -- consume the char event this also generates.
  term.setCursorBlink(false)
  print(key == keys.y and "y" or "n")

  return key == keys.y
end

--- Read a verification passphrase for a site.
---@param site_name string The name of the site to get the passphrase for.
---@param pbkdf2_salt string The salt used for the verification hash.
---@param pbkdf2_hash string The verification hash.
---@param stage number The current stage of the progress, used if multiple actions are being merged into one percentage.
---@param stage_max number The maximum stage of the progress, used if multiple actions are being merged into one percentage.
local function read_expected_passphrase(site_name, pbkdf2_salt, pbkdf2_hash, stage, stage_max)
  local passphrase
  local f = 0

  repeat
    if f >= 3 then
      print()
      errors.AuthenticationError("Too many incorrect passphrase attempts.", "Please try again.")
    elseif f ~= 0 then
      printError(" Incorrect passphrase, please try again.")
    end
    f = f + 1

    print("Please enter the passphrase to unlock credentials for site", site_name)
    write("\xb7\xb7\xb7\xb7\xb7> ")
    passphrase = read("*") --[[@as string bro this literally cannot return nil]]
    local _, y = term.getCursorPos()
  until sha256.pbkdf2(passphrase, pbkdf2_salt, PBKDF2_ROUNDS, progress(y, stage, stage_max)) == pbkdf2_hash

  sleep()

  return passphrase
end

--- Read an expiry date for a credential entry.
---@return integer? expiry The expiry date in UTC milliseconds, if given.
local function read_expiry_date()
  print("Please enter the expiry date for this entry in the format 'YYYY-MM-DD HH:MM:SS' (UTC).")
  print("Leave blank for no expiry.")
  write("> ")

  ---@type string|integer|nil
  local expiry
  repeat
    if expiry then
      printError("Invalid date format.")
    end

    expiry = read() --[[@as string]]
    if expiry == "" then
      return
    end

    local year, month, day, hour, minute, second = expiry:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
    if year then
      expiry = os.time {
        year = tonumber(year), ---@diagnostic disable-line:assign-type-mismatch
        month = tonumber(month), ---@diagnostic disable-line:assign-type-mismatch
        day = tonumber(day), ---@diagnostic disable-line:assign-type-mismatch
        hour = tonumber(hour), ---@diagnostic disable-line:assign-type-mismatch
        min = tonumber(minute), ---@diagnostic disable-line:assign-type-mismatch
        sec = tonumber(second) ---@diagnostic disable-line:assign-type-mismatch We know these are numbers if they are valid values.
      } * 1000
    else
      expiry = nil
    end
  until type(expiry) == "number"

  return expiry
end

--- Compute how long until a given timestamp.
---@param timestamp integer? The timestamp to compute the relative date for.
---@param now integer? The current time, if not given, it will be calculated.
---@return string relative_date The relative date.
---@return boolean near_expiry Whether the entry is near expiry.
---@return boolean expired Whether the entry has expired.
local function relative_expiry(timestamp, now)
  if not timestamp then
    return "never", false, false
  end
  now = now or os.epoch "utc"

  if timestamp < now then
    return "expired", true, true
  end

  local diff = timestamp - now
  local year, day, hour, minute = 365 * 24 * 60 * 60 * 1000, 24 * 60 * 60 * 1000, 60 * 60 * 1000, 60 * 1000
  local years = math.floor(diff / year)
  local days = math.floor((diff % year) / day)
  local hours = math.floor((diff % day) / hour)
  local minutes = math.floor((diff % hour) / minute)

  if years > 0 then
    return ("%d years, %d days"):format(years, days), false, false
  elseif days > 0 then
    return ("%d days, %d hours"):format(days, hours), false, false
  elseif hours > 0 then
    return ("%d hours, %d minutes"):format(hours, minutes), true, false
  elseif minutes > 0 then
    return ("%d minutes"):format(minutes), true, false
  end

  return "less than a minute", true, false
end

--- Test if an entry has expired, if it has, remove any nonce data and salt data.
---@param entry CredentialEntry The entry to test.
---@return boolean expired Whether the entry has expired.
local function test_expiry(entry)
  expect(1, entry, "table")

  local message, near_expiry, expired = relative_expiry(entry.expiry)

  if expired then
    -- Salts
    entry.salt_verification = nil
    entry.salt_encryption = nil

    -- Username/Password nonces
    entry.nonce_uname = nil ---@diagnostic disable-line:inject-field We are not injecting, we are removing.
    entry.nonce_pass = nil  ---@diagnostic disable-line:inject-field We are not injecting, we are removing.

    -- Token nonces
    entry.nonce_token = nil ---@diagnostic disable-line:inject-field We are not injecting, we are removing.

    return true
  end

  -- Display a warning if under a day left.
  if near_expiry then
    term.setTextColor(colors.yellow)
    print("Warning: The credentials for", entry.site_name, "in", message)
    term.setTextColor(colors.white)
  end

  return false
end

--- Convert binary to hex.
---@param binary string The binary data to convert.
---@return string hex The hex data.
local function bin_to_hex(binary)
  return (binary:gsub(".", function(c)
    return ("%02x"):format(c:byte())
  end))
end

--- Check if the credential store is enabled or not.
---@return boolean enabled Whether the credential store is enabled.
function credential_store.is_credential_store_enabled()
  return not credential_directory:exists(".disabled")
end

--- Enable the credential store.
---@return boolean ok Whether the operation was successful (User must confirm).
function credential_store.enable_credential_store()
  -- If the store is already enabled, return true.
  if credential_store.is_credential_store_enabled() then
    print("The credential store is already enabled.")
    return true
  end

  write("Are you sure you want to ")
  term.setTextColor(colors.yellow)
  write("enable ")
  term.setTextColor(colors.white)
  write("the credential store (y/n)? ")

  -- If the user doesn't confirm, cancel the operation.
  if not y_n() then
    return false
  end

  -- The user has confirmed, delete the disabled file.
  credential_directory:delete(".disabled")

  return true
end

--- Disable the credential store.
---@return boolean ok Whether the operation was successful (User must confirm).
function credential_store.disable_credential_store()
  -- If the store is already disabled, return true.
  if not credential_store.is_credential_store_enabled() then
    print("The credential store is already disabled.")
    return true
  end

  term.setTextColor(colors.orange)
  write("Warning: ")
  term.setTextColor(colors.white)
  write("Disabling the credential store will ")
  term.setTextColor(colors.orange)
  write("remove ")
  term.setTextColor(colors.white)
  print("all stored credentials.")
  term.setTextColor(colors.orange)
  print("  This action is not reversible.")
  term.setTextColor(colors.red)
  write("Are you sure you want to disable the credential store? (y/n)? ")
  term.setTextColor(colors.white)

  -- If the user doesn't confirm, cancel the operation.
  if not y_n() then
    return false
  end

  -- Delete all the other files in the store.
  for _, file in ipairs(credential_directory:list()) do
    credential_directory:delete(file)
  end

  -- Create the empty file to indicate that the store is disabled.
  credential_directory:empty(".disabled")

  print("All stored credentials have been removed, and the credential store has been disabled.")

  return true
end

--- Get the filename for an entry given the site name and entry type.
---@param site_name string The name of the site.
---@param entry_type CredentialType The type of the entry.
---@return string filename The filename for the entry.
local function _entry_filename(site_name, entry_type)
  return ("%s_%s.lson"):format(site_name, entry_type)
end

--- Check if an entry exists in the credential store.
---@param site_name string The name of the site to check for.
---@param entry_type CredentialType The type of the entry to check for.
---@return boolean exists Whether the entry exists.
local function _entry_exists(site_name, entry_type)
  return credential_directory:exists(_entry_filename(site_name, entry_type))
end

--- Check if an entry type is valid.
---@param entry_type CredentialType The type of the entry to check.
---@param details string The details that should be provided in the error message, if one is thrown.
local function _entry_type_valid(entry_type, details)
  for _, v in pairs(credential_store.ENTRY_TYPES) do
    if v == entry_type then
      return
    end
  end

  errors.InternalError(
    ("Invalid entry type '%s'"):format(entry_type),
    details,
    3
  )
end

--- Remove an entry from the credential store.
---@param site_name string The name of the site to remove the entry for.
---@param entry_type CredentialType The type of the entry to remove.
---@return boolean ok Whether the operation was successful.
function credential_store.entries.remove(site_name, entry_type)
  expect(1, site_name, "string")
  expect(2, entry_type, "string")

  -- Ensure the entry type is valid.
  _entry_type_valid(entry_type, "This is a bug in the caller of `entries.remove`.")

  -- Check if the entry exists.
  if not _entry_exists(site_name, entry_type) then
    print("No entry found for", site_name, "of type", entry_type)
    return false
  end

  -- Confirm the deletion.
  write("Are you sure you want to remove the entry for ")
  write(site_name)
  write(" (y/n)? ")
  if not y_n() then
    return false
  end

  -- Actually delete the entry.
  credential_directory:delete(_entry_filename(site_name, entry_type))

  return true
end

--- Check if an entry exists in the credential store.
---@param site_name string The name of the site to check for.
---@param entry_type CredentialType The type of the entry to check for.
---@return boolean exists Whether the entry exists.
function credential_store.entries.exists(site_name, entry_type)
  expect(1, site_name, "string")
  expect(2, entry_type, "string")

  -- Ensure the entry type is valid.
  _entry_type_valid(entry_type, "This is a bug in the caller of `entries.exists`.")

  return credential_directory:exists(_entry_filename(site_name, entry_type))
end

--- Get a raw entry from the credential store.
---@param site_name string The name of the site to get the entry for.
---@param entry_type CredentialType The type of the entry to get.
---@return boolean ok Whether the operation was successful.
---@return CredentialEntry? entry The entry for the site.
function credential_store.entries.get(site_name, entry_type)
  expect(1, site_name, "string")
  expect(2, entry_type, "string")

  -- Ensure the entry type is valid.
  _entry_type_valid(entry_type, "This is a bug in the caller of `entries.get`.")

  -- Check if the entry exists.
  if not _entry_exists(site_name, entry_type) then
    print("No entry found for", site_name, "of type", entry_type)
    return false
  end

  -- Actually get the entry.
  local entry = credential_directory:unserialize(_entry_filename(site_name, entry_type))

  if not entry then
    errors.InternalError(
      ("Failed to unserialize credential data for site %s"):format(site_name),
      "Is the file corrupted?"
    )
  end

  return true, entry
end

--- Get all the entries in the credential store.
---@return CredentialEntry[] entries The entries in the credential store.
function credential_store.entries.get_all()
  local files = credential_directory:list()

  ---@type CredentialEntry[]
  local entries = {}

  for _, file in ipairs(files) do
    local entry = credential_directory:unserialize(file) --[[@as CredentialEntry]]

    if not entry then
      errors.InternalError(
        ("Failed to unserialize credential data for file %s"):format(file),
        "Is the file corrupted?"
      )
    end

    table.insert(entries, entry)
  end

  return entries
end

--- Write an entry to the credential store. This will overwrite any existing entry.
---@param site_name string The name of the site to add the entry for.
---@param entry_type CredentialType The type of the entry to add.
---@param entry CredentialEntry The entry to add.
---@return boolean ok Whether the operation was successful.
function credential_store.entries.write(site_name, entry_type, entry)
  expect(1, site_name, "string")
  expect(2, entry_type, "string")
  expect(3, entry, "table")

  -- Ensure the entry type is valid.
  _entry_type_valid(entry_type, "This is a bug in the caller of `entries.write`.")

  -- Actually add the entry.
  credential_directory:serialize(_entry_filename(site_name, entry_type), entry, true)

  return true
end

--- Get a basic username/password combo for a site. This will either use the encrypted cache or prompt the user for the credentials.
---@param site_name string The name of the site to get the credentials for.
---@param username string? The username to use. If not given, will prompt the user on the current terminal. Ignored if an entry already exists.
---@param password string? The password to use. If not given, will prompt the user on the current terminal. Ignored if an entry already exists.
---@param expiry integer? The expiry date for the credentials (utc timestamp). If not given, will prompt the user on the current terminal.
---@param passphrase string? The passphrase to use for the encryption. If not given, will prompt the user on the current terminal.
---@param no_output boolean? Whether to suppress ALL output to the terminal. If true, will return false if any user input is required (i.e: missing fields).
---@return boolean ok Whether the operation was successful.
---@return string? username The username for the site.
---@return string? password The password for the site.
function credential_store.get_user_pass(site_name, username, password, expiry, passphrase, no_output)
  expect(1, site_name, "string")
  expect(2, username, "string", "nil")
  expect(3, password, "string", "nil")
  expect(4, expiry, "number", "nil")
  expect(5, passphrase, "string", "nil")
  expect(6, no_output, "boolean", "nil")

  local _write = write
  local _print = print
  local _printError = printError

  local function write(...) if not no_output then _write(...) end end
  local function print(...) if not no_output then _print(...) end end
  local function printError(...) if not no_output then _printError(...) end end

  -- First, check if we already have any cached data for this site.
  local exists = credential_store.entries.exists(site_name, credential_store.ENTRY_TYPES.USER_PASS)
  local store_enabled = credential_store.is_credential_store_enabled()

  -- It exists, prompt the user for the encryption password.
  if store_enabled and exists then
    if no_output and not passphrase then
      return false -- cannot prompt the user for input if no_output is true.
    end

    local ok, entry = credential_store.entries.get(site_name, credential_store.ENTRY_TYPES.USER_PASS) --[[@as UserPassCredentialEntry]]

    if not ok then
      errors.InternalError(
        ("Failed to unserialize credential data for site %s"):format(site_name),
        "Is the file corrupted?"
      )
    end

    if test_expiry(entry) then
      -- Overwrite the expired entry.
      credential_store.entries.write(site_name, credential_store.ENTRY_TYPES.USER_PASS, entry)
      errors.AuthenticationError("The credentials have expired.")
    end

    if not entry.hash or not entry.salt_verification or not entry.salt_encryption or not entry.nonce_uname or not entry.nonce_pass or not entry.username or not entry.password then
      errors.InternalError(
        "Missing credential data in credential store.",
        "Is the file corrupted?"
      )
    end

    passphrase = passphrase or read_expected_passphrase(site_name, entry.salt_verification, entry.hash, 1, 2)

    print()
    --print("\n      Calculating encryption hash...")
    local _, y = term.getCursorPos()
    local encryption_hash = sha256.pbkdf2(passphrase, entry.salt_encryption, PBKDF2_ROUNDS, no_output and function() end or progress(y, 2, 2))

    print("\nDecrypting credentials...")
    local username = chacha20.crypt(encryption_hash, entry.nonce_uname, entry.username, CHACHA20_ROUNDS)
    local password = chacha20.crypt(encryption_hash, entry.nonce_pass, entry.password, CHACHA20_ROUNDS)

    return true, username, password
  end

  -- It doesn't exist, prompt the user for new credentials (if needed)
  if no_output and (not username or not password or not passphrase or not expiry) then
    return false -- cannot prompt the user for input if no_output is true.
  end

  print("Please enter the username for", site_name)
  write("> ")
  username = username or read() --[[@as string]]

  -- We only need to confirm the password if it wasn't passed as an argument.
  local _confirm_password = not password
  print("Please enter the password for", site_name)
  write("> ")
  password = password or read("*") --[[@as string]]

  -- All of this we can ignore if the store is disabled.
  if store_enabled then
    if _confirm_password then
      -- Password confirmation
      print("Confirm the password for", site_name)
      write("> ")
      local confirm_password = read("*") --[[@as string]]
      if password ~= confirm_password then
        printError("Passwords do not match.")
        return false
      end
    end

    -- Passphrase
    -- We only need to confirm the passphrase if it wasn't passed as an argument.
    local _confirm_passphrase = not passphrase
    print("Please enter a passphrase to encrypt these credentials (32 characters max).")
    write("> ")
    passphrase = passphrase or read("*") --[[@as string]]
    if #passphrase > 32 then
      printError("Passphrase is too long.")
      return false
    end

    -- Passphrase confirmation
    if _confirm_passphrase then
      print("Please confirm the passphrase.")
      write("> ")
      local confirm_passphrase = read("*") --[[@as string]]
      if passphrase ~= confirm_passphrase then
        printError("Passphrases do not match.")
        return false
      end
    end

    -- Hash encryption key.
    print("      Hashing passphrase...")
    local salt_verification = random.random(PBKDF2_SALT_SIZE)
    local _, y = term.getCursorPos()
    local hash_verification = sha256.pbkdf2(passphrase, salt_verification, PBKDF2_ROUNDS, no_output and function() end or progress(y, 1, 2))
    local nonce_uname = random.random(CHACHA20_NONCE_SIZE)
    local nonce_pass = random.random(CHACHA20_NONCE_SIZE)

    -- Hash verification key.
    local salt_encryption = random.random(PBKDF2_SALT_SIZE)
    local encryption_hash = sha256.pbkdf2(passphrase, salt_encryption, PBKDF2_ROUNDS, no_output and function() end or progress(y, 2, 2))

    -- Actually encrypt the credentials.
    print("\nEncrypting credentials...")
    local encrypted_username = chacha20.crypt(encryption_hash, nonce_uname, username, CHACHA20_ROUNDS)
    local encrypted_password = chacha20.crypt(encryption_hash, nonce_pass, password, CHACHA20_ROUNDS)

    -- Build the entry
    ---@type UserPassCredentialEntry
    local entry = {
      site_name = site_name,
      username = encrypted_username,
      password = encrypted_password,
      nonce_uname = nonce_uname,
      nonce_pass = nonce_pass,
      salt_verification = salt_verification,
      salt_encryption = salt_encryption,
      hash = hash_verification,
      type = credential_store.ENTRY_TYPES.USER_PASS,

      created = os.epoch "utc",
      expiry = expiry or read_expiry_date(),
    }

    -- Save the credentials.
    print("Saving credentials...")
    credential_store.entries.write(site_name, credential_store.ENTRY_TYPES.USER_PASS, entry)
  end

  return true, username, password
end

--- Get an authentication token for a site.
---@param site_name string The name of the site to get the token for.
---@param token string? The token to use. If not given, will prompt the user on the current terminal. Ignored if an entry already exists.
---@param passphrase string? The passphrase to use for the encryption. If not given, will prompt the user on the current terminal.
---@param expiry integer? The expiry date for the token (utc timestamp). If not given, will prompt the user on the current terminal.
---@param no_output boolean? Whether to suppress ALL output to the terminal. If true, will return false if any user input is required (i.e: missing fields).
---@return boolean ok Whether the operation was successful.
---@return string? token The authentication token for the site.
function credential_store.get_token(site_name, token, passphrase, expiry, no_output)
  expect(1, site_name, "string")
  expect(2, token, "string", "nil")
  expect(3, passphrase, "string", "nil")
  expect(4, no_output, "boolean", "nil")

  local _write = write
  local _print = print
  local _printError = printError

  local function write(...) if not no_output then _write(...) end end
  local function print(...) if not no_output then _print(...) end end
  local function printError(...) if not no_output then _printError(...) end end

  -- First, check if we already have any cached data for this site.
  local exists = credential_store.entries.exists(site_name, credential_store.ENTRY_TYPES.TOKEN)
  local store_enabled = credential_store.is_credential_store_enabled()

  -- It exists, prompt the user for the encryption password.
  if store_enabled and exists then
    if no_output and not passphrase then
      return false -- cannot prompt the user for input if no_output is true.
    end

    local ok, entry = credential_store.entries.get(site_name, credential_store.ENTRY_TYPES.TOKEN) --[[@as TokenCredentialEntry]]

    if not ok then
      errors.InternalError(
        ("Failed to unserialize credential data for site %s"):format(site_name),
        "Is the file corrupted?"
      )
    end

    if test_expiry(entry) then
      -- Overwrite the expired entry with the nonce data removed.
      credential_store.entries.write(site_name, credential_store.ENTRY_TYPES.TOKEN, entry)
      errors.AuthenticationError("The credentials have expired.")
    end

    if not entry.hash or not entry.salt_verification or not entry.salt_encryption or not entry.nonce_token or not entry.token then
      errors.InternalError(
        "Missing credential data in credential store.",
        "Is the file corrupted?"
      )
    end

    passphrase = passphrase or read_expected_passphrase(site_name, entry.salt_verification, entry.hash, 1, 2)

    print()
    --print("\n      Calculating encryption hash...")
    local _, y = term.getCursorPos()
    local encryption_hash = sha256.pbkdf2(passphrase, entry.salt_encryption, PBKDF2_ROUNDS, no_output and function() end or progress(y, 2, 2))

    print("\nDecrypting token...")
    local token = chacha20.crypt(encryption_hash, entry.nonce_token, entry.token, CHACHA20_ROUNDS)

    return true, token
  end

  -- It doesn't exist, prompt the user for new credentials.
  if no_output and (not token or not passphrase or not expiry) then
    return false -- cannot prompt the user for input if no_output is true.
  end
  print("Please paste the authentication token for", site_name)
  write("> ")
  token = token or read() --[[@as string]]

  -- All of this we can ignore if the store is disabled.
  if store_enabled then
    -- Passphrase
    local _confirm_passphrase = not passphrase
    print("Please enter a passphrase to encrypt this token (32 characters max).")
    write("> ")
    passphrase = passphrase or read("*") --[[@as string]]
    if #passphrase > 32 then
      printError("Passphrase is too long.")
      return false
    end

    -- Passphrase confirmation
    -- We only need to confirm the passphrase if it wasn't passed as an argument.
    if _confirm_passphrase then
      print("Please confirm the passphrase.")
      write("> ")
      local confirm_passphrase = read("*") --[[@as string]]
      if passphrase ~= confirm_passphrase then
        printError("Passphrases do not match.")
        return false
      end
    end

    -- Hash encryption key.
    print("      Hashing passphrase...")
    local salt_verification = random.random(PBKDF2_SALT_SIZE)
    local _, y = term.getCursorPos()
    local hash_verification = sha256.pbkdf2(passphrase, salt_verification, PBKDF2_ROUNDS, no_output and function() end or progress(y, 1, 2))
    local nonce_token = random.random(CHACHA20_NONCE_SIZE)

    -- Hash verification key.
    local salt_encryption = random.random(PBKDF2_SALT_SIZE)
    local encryption_hash = sha256.pbkdf2(passphrase, salt_encryption, PBKDF2_ROUNDS, no_output and function() end or progress(y, 2, 2))

    -- Actually encrypt the token.
    print("\nEncrypting token...")
    local encrypted_token = chacha20.crypt(encryption_hash, nonce_token, token, CHACHA20_ROUNDS)

    -- Build the entry
    ---@type TokenCredentialEntry
    local entry = {
      site_name = site_name,
      token = encrypted_token,
      nonce_token = nonce_token,
      salt_verification = salt_verification,
      salt_encryption = salt_encryption,
      hash = hash_verification,
      type = credential_store.ENTRY_TYPES.TOKEN,

      created = os.epoch "utc",
      expiry = expiry or read_expiry_date()
    }

    -- Save the credentials.
    print("Saving token...")
    credential_store.entries.write(site_name, credential_store.ENTRY_TYPES.TOKEN, entry)
  end

  return true, token
end

--- List all the entries in the credential store.
function credential_store.list_credentials()
  if not credential_store.is_credential_store_enabled() then
    print("The credential store is disabled.")
    return
  end

  local entries = credential_store.entries.get_all()

  if #entries == 0 then
    print("No entries found in the credential store.")
    return
  end

  -- Collect the entry data for tabulation.
  local entries_to_tabulate = {}
  for _, entry in ipairs(entries) do
    ---@type string we will be overwriting this with a string value.
    local entry_type = entry.type

    if entry_type == credential_store.ENTRY_TYPES.USER_PASS then
      entry_type = "User/Pass"
    elseif entry_type == credential_store.ENTRY_TYPES.TOKEN then
      entry_type = "Token"
    else
      entry_type = "Unknown"
    end

    table.insert(entries_to_tabulate, {
      "  " .. entry.site_name,
      entry_type,
      bin_to_hex(entry.hash):sub(1, 5) .. "...",
      entry.expiry and relative_expiry(entry.expiry) or "Never"
    })
  end

  -- Display the entries.
  print("Entries in the credential store:\n")
  textutils.tabulate(
    colors.yellow, {"  Site ", "Type ", "Hash ", "Expiry "},
    colors.yellow, {"  \x8c\x8c\x8c\x8c\x8c", "\x8c\x8c\x8c\x8c\x8c", "\x8c\x8c\x8c\x8c\x8c", "\x8c\x8c\x8c\x8c\x8c\x8c\x8c"},
    colors.white, table.unpack(entries_to_tabulate)
  )
  print()
end

return credential_store
