--- Catppuccin palette for CC.

local expect = require "cc.expect".expect

local catppuccin_palettes = {
  mocha = {
    crust     = 0x11111b, -- 1
    mantle    = 0x181825, -- 2
    base      = 0x1e1e2e, -- 3
    surface_0 = 0x313244, -- 4
    surface_1 = 0x45475a, -- 5
    surface_2 = 0x585b70, -- 6
    overlay_0 = 0x6c7086, -- 7
    overlay_1 = 0x7f849c, -- 8
    overlay_2 = 0x9399b2, -- 9
    subtext_0 = 0xa6adc8, -- 10
    subtext_1 = 0xbac2de, -- 11
    text      = 0xcdd6f4, -- 12
    red       = 0xf38ba8, -- 13
    green     = 0xa6e3a1, -- 14
    blue      = 0x89b4fa, -- 15
    yellow    = 0xf9e2af, -- 16
  },
  macchiato = {
    crust     = 0x181926, -- 1
    mantle    = 0x1e2030, -- 2
    base      = 0x24273a, -- 3
    surface_0 = 0x363a4f, -- 4
    surface_1 = 0x494d64, -- 5
    surface_2 = 0x5b6078, -- 6
    overlay_0 = 0x6e738d, -- 7
    overlay_1 = 0x8087a2, -- 8
    overlay_2 = 0x939ab7, -- 9
    subtext_0 = 0xa5adcb, -- 10
    subtext_1 = 0xb8c0e0, -- 11
    text      = 0xcad3f5, -- 12
    red       = 0xed8796, -- 13
    green     = 0xa6da95, -- 14
    blue      = 0x8aadf4, -- 15
    yellow    = 0xeed49f, -- 16
  },
  frappe = {
    crust     = 0x232634, -- 1
    mantle    = 0x292c3c, -- 2
    base      = 0x303446, -- 3
    surface_0 = 0x414559, -- 4
    surface_1 = 0x51576d, -- 5
    surface_2 = 0x626880, -- 6
    overlay_0 = 0x737994, -- 7
    overlay_1 = 0x838ba7, -- 8
    overlay_2 = 0x949cbb, -- 9
    subtext_0 = 0xa5adce, -- 10
    subtext_1 = 0xb5bfe2, -- 11
    text      = 0xc6d0f5, -- 12
    red       = 0xe78284, -- 13
    green     = 0xa6d189, -- 14
    blue      = 0x8caaee, -- 15
    yellow    = 0xe5c890, -- 16
  },
  latte = {
    crust     = 0xdce0e8, -- 1
    mantle    = 0xe6e9ef, -- 2
    base      = 0xeff1f5, -- 3
    surface_0 = 0xccd0da, -- 4
    surface_1 = 0xbcc0cc, -- 5
    surface_2 = 0xacb0be, -- 6
    overlay_0 = 0x9ca0b0, -- 7
    overlay_1 = 0x8c8fa1, -- 8
    overlay_2 = 0x7c7f93, -- 9
    subtext_0 = 0x6c6f85, -- 10
    subtext_1 = 0x5c5f77, -- 11
    text      = 0x4c4f69, -- 12
    red       = 0xd20f39, -- 13
    green     = 0x40a02b, -- 14
    blue      = 0x1e66f5, -- 15
    yellow    = 0xdf8e1d, -- 16
  },
}

---@class catppuccin_palette
---@field crust integer
---@field mantle integer
---@field base integer
---@field surface_0 integer
---@field surface_1 integer
---@field surface_2 integer
---@field overlay_0 integer
---@field overlay_1 integer
---@field overlay_2 integer
---@field subtext_0 integer
---@field subtext_1 integer
---@field text integer
---@field red integer
---@field green integer
---@field blue integer
---@field yellow integer

---@class catppuccin
local catppuccin = {}

---@alias palette table<string, color>

---@alias catppuccin_palette_name
---| "mocha" # Original, darkest palette.
---| "macchiato" # Medium contrast dark palette.
---| "frappe" # Light theme with subdued colors.
---| "latte" # Lightest theme.

--- Set the color palette to Catppuccin.
---@param name catppuccin_palette_name The name of the palette to use.
---@return catppuccin_palette palette The new palette to use.
function catppuccin.set_palette(name)
  expect(1, name, "string")

  if not catppuccin_palettes[name] then
    error("Unknown palette: " .. name, 2)
  end

  local i = 0
  local palette = {}

  for color_name, color in pairs(catppuccin_palettes[name]) do
    term.setPaletteColor(2^i, color)
    palette[color_name] = 2^i
    i = i + 1
  end

  return palette
end

--- Reset the color palette to the default.
function catppuccin.reset_palette()
  for i = 0, 15 do
    term.setPaletteColor(2^i, term.nativePaletteColor(2^i))
  end
end

return catppuccin
