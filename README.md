# Usage:

```lua
--[[ ################ START INSTALLER ################ ]]
local p_dir = fs.getDir(shell.getRunningProgram())
local function pd_file(file) return fs.combine(p_dir, file) end
local required_files = {
  -- edit these
  pd_file("file_helper.lua") .. ":file_helper.lua",
  "paste:" .. pd_file("goodcounter.lua") .. ":iZa1gNfw",
  "extern:".. pd_file("aukit.lua") .. ":https://raw.githubusercontent.com/MCJack123/AUKit/master/aukit.lua"
  -- don't edit past here
}
if not fs.exists(pd_file("fatlibs")) then
  shell.run("wget https://raw.githubusercontent.com/Fatboychummy-CC/Libraries/main/fatlibs.lua")
end
local need_download = false
for _, file in ipairs(required_files) do if not fs.exists(pd_file(file)) then need_download = true break end end
if need_download then
  local ok, err = pcall(function() require "fatlibs" (table.unpack(required_files)) end)
  if not ok then error(("Failed to install dependencies: %s"):format(err), 0) end
end
--[[ ################  END INSTALLER  ################ ]]
```