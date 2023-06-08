# Usage:

```lua
shell.run("wget run https://raw.githubusercontent.com/Fatboychummy-CC/Libraries/main/fatlibs.lua")
local ok, err = pcall(function()
  require "fatlibs" (
    "file_helper.lua:file_helper.lua",
    "paste:goodcounter.lua:iZa1gNfw",
    "extern:aukit.lua:https://raw.githubusercontent.com/MCJack123/AUKit/master/aukit.lua"
  )
end)
if not ok then error(("Failed to install dependencies: %s"):format(err)) end
```