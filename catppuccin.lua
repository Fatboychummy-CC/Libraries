--- Catppuccin palette for CC.

local expect = require "cc.expect".expect

local base_palette = {
  crust     = true,
  mantle    = true,
  base      = true,
  surface_0 = true,
  surface_1 = true,
  surface_2 = true,
  overlay_0 = true,
  overlay_1 = true,
  overlay_2 = true,
  subtext_0 = true,
  subtext_1 = true,
  text      = true,
}

local base_colors = {
  red       = true,
  green     = true,
  blue      = true,
  yellow    = true,
}

local additional_colors = {
  rosewater = true,
  flamingo  = true,
  pink      = true,
  mauve     = true,
  maroon    = true,
  peach     = true,
  teal      = true,
  sky       = true,
  sapphire  = true,
  lavender  = true,
}

---@alias base_color_name
---| "crust"
---| "mantle"
---| "base"
---| "surface_0"
---| "surface_1"
---| "surface_2"
---| "overlay_0"
---| "overlay_1"
---| "overlay_2"
---| "subtext_0"
---| "subtext_1"
---| "text"
---| "red"
---| "green"
---| "blue"
---| "yellow"

---@alias additional_color_name
---| "rosewater"
---| "flamingo"
---| "pink"
---| "mauve"
---| "maroon"
---| "peach"
---| "teal"
---| "sky"
---| "sapphire"
---| "lavender"

local catppuccin_palettes = {
  mocha = {
    crust     = 0x11111b, -- Base colors
    mantle    = 0x181825, -- Base colors
    base      = 0x1e1e2e, -- Base colors
    surface_0 = 0x313244, -- Base colors
    surface_1 = 0x45475a, -- Base colors
    surface_2 = 0x585b70, -- Base colors
    overlay_0 = 0x6c7086, -- Base colors
    overlay_1 = 0x7f849c, -- Base colors
    overlay_2 = 0x9399b2, -- Base colors
    subtext_0 = 0xa6adc8, -- Base colors
    subtext_1 = 0xbac2de, -- Base colors
    text      = 0xcdd6f4, -- Base colors
    red       = 0xf38ba8, -- Base colors
    green     = 0xa6e3a1, -- Base colors
    blue      = 0x89b4fa, -- Base colors
    yellow    = 0xf9e2af, -- Base colors

    rosewater = 0xf5e0dc, -- Additional, by-request colors
    flamingo  = 0xf2cdcd, -- Additional, by-request colors
    pink      = 0xf5c2e7, -- Additional, by-request colors
    mauve     = 0xcba6f7, -- Additional, by-request colors
    maroon    = 0xeba0ac, -- Additional, by-request colors
    peach     = 0xfab387, -- Additional, by-request colors
    teal      = 0x94e2d5, -- Additional, by-request colors
    sky       = 0x89dceb, -- Additional, by-request colors
    sapphire  = 0x74c7ec, -- Additional, by-request colors
    lavender  = 0xb4befe, -- Additional, by-request colors
  },
  macchiato = {
    crust     = 0x181926, -- Base colors
    mantle    = 0x1e2030, -- Base colors
    base      = 0x24273a, -- Base colors
    surface_0 = 0x363a4f, -- Base colors
    surface_1 = 0x494d64, -- Base colors
    surface_2 = 0x5b6078, -- Base colors
    overlay_0 = 0x6e738d, -- Base colors
    overlay_1 = 0x8087a2, -- Base colors
    overlay_2 = 0x939ab7, -- Base colors
    subtext_0 = 0xa5adcb, -- Base colors
    subtext_1 = 0xb8c0e0, -- Base colors
    text      = 0xcad3f5, -- Base colors
    red       = 0xed8796, -- Base colors
    green     = 0xa6da95, -- Base colors
    blue      = 0x8aadf4, -- Base colors
    yellow    = 0xeed49f, -- Base colors

    rosewater = 0xf4dbd6, -- Additional, by-request colors
    flamingo  = 0xf0c6c6, -- Additional, by-request colors
    pink      = 0xf5bde6, -- Additional, by-request colors
    mauve     = 0xc6a0f6, -- Additional, by-request colors
    maroon    = 0xee99a0, -- Additional, by-request colors
    peach     = 0xf5a97f, -- Additional, by-request colors
    teal      = 0x8bd5ca, -- Additional, by-request colors
    sky       = 0x91d7e3, -- Additional, by-request colors
    sapphire  = 0x7dc4e4, -- Additional, by-request colors
    lavender  = 0xb7bdf8, -- Additional, by-request colors
  },
  frappe = {
    crust     = 0x232634, -- Base colors
    mantle    = 0x292c3c, -- Base colors
    base      = 0x303446, -- Base colors
    surface_0 = 0x414559, -- Base colors
    surface_1 = 0x51576d, -- Base colors
    surface_2 = 0x626880, -- Base colors
    overlay_0 = 0x737994, -- Base colors
    overlay_1 = 0x838ba7, -- Base colors
    overlay_2 = 0x949cbb, -- Base colors
    subtext_0 = 0xa5adce, -- Base colors
    subtext_1 = 0xb5bfe2, -- Base colors
    text      = 0xc6d0f5, -- Base colors
    red       = 0xe78284, -- Base colors
    green     = 0xa6d189, -- Base colors
    blue      = 0x8caaee, -- Base colors
    yellow    = 0xe5c890, -- Base colors

    rosewater = 0xf2d5cf, -- Additional, by-request colors
    flamingo  = 0xeebebe, -- Additional, by-request colors
    pink      = 0xf4b8e4, -- Additional, by-request colors
    mauve     = 0xca9ee6, -- Additional, by-request colors
    maroon    = 0xea999c, -- Additional, by-request colors
    peach     = 0xef9f76, -- Additional, by-request colors
    teal      = 0x81c8be, -- Additional, by-request colors
    sky       = 0x99d1db, -- Additional, by-request colors
    sapphire  = 0x85c1dc, -- Additional, by-request colors
    lavender  = 0xbabbf1, -- Additional, by-request colors
  },
  latte = {
    crust     = 0xdce0e8, -- Base colors
    mantle    = 0xe6e9ef, -- Base colors
    base      = 0xeff1f5, -- Base colors
    surface_0 = 0xccd0da, -- Base colors
    surface_1 = 0xbcc0cc, -- Base colors
    surface_2 = 0xacb0be, -- Base colors
    overlay_0 = 0x9ca0b0, -- Base colors
    overlay_1 = 0x8c8fa1, -- Base colors
    overlay_2 = 0x7c7f93, -- Base colors
    subtext_0 = 0x6c6f85, -- Base colors
    subtext_1 = 0x5c5f77, -- Base colors
    text      = 0x4c4f69, -- Base colors
    red       = 0xd20f39, -- Base colors
    green     = 0x40a02b, -- Base colors
    blue      = 0x1e66f5, -- Base colors
    yellow    = 0xdf8e1d, -- Base colors

    rosewater = 0xdc8a78, -- Additional, by-request colors
    flamingo  = 0xdd7878, -- Additional, by-request colors
    pink      = 0xea76cb, -- Additional, by-request colors
    mauve     = 0x8839ef, -- Additional, by-request colors
    maroon    = 0xe64553, -- Additional, by-request colors
    peach     = 0xfe640b, -- Additional, by-request colors
    teal      = 0x179299, -- Additional, by-request colors
    sky       = 0x04a5e5, -- Additional, by-request colors
    sapphire  = 0x209fb5, -- Additional, by-request colors
    lavender  = 0x7287fd, -- Additional, by-request colors
  },
}

--- The base Catppuccin palette. By default, comes with all the 'control' colors, and four of the 'additional' colors:
--- - red
--- - green
--- - blue
--- - yellow
--- 
--- By default, the other colors are not included, and the Lua Language Server will warn you about this.
--- If you are altering the included palette, you will want to use the `full_catpuccin_palette` type:
--- ```lua
--- ---@type full_catpuccin_palette
--- local palette = catppuccin.set_palette("mocha", "rosewater", "flamingo", "pink", "mauve")
--- ```
--- Be warned that this type includes all the colors, but they don't all necessarily exist in the palette. You will
--- need to track the colors you are using yourself.
---@class base_catppuccin_palette
---@field base integer Background panes
---@field crust integer Secondary panes
---@field mantle integer Secondary panes
---@field surface_0 integer Surface elements
---@field surface_1 integer Surface elements
---@field surface_2 integer Surface elements
---@field overlay_0 integer Overlay elements
---@field overlay_1 integer Overlay elements, subtle text
---@field overlay_2 integer Overlay elements, selection background (20-30% opacity)
---@field subtext_0 integer Sub-headlines/labels
---@field subtext_1 integer Sub-headlines/labels
---@field text integer Body copy, main headline.
---@field red integer Errors
---@field green integer Success
---@field blue integer Tags, Pills
---@field yellow integer Warnings
---@field rosewater integer? Cursor
---@field flamingo integer?
---@field pink integer?
---@field mauve integer?
---@field maroon integer?
---@field peach integer?
---@field teal integer?
---@field sky integer?
---@field sapphire integer?
---@field lavender integer?

---@class full_catpuccin_palette : base_catppuccin_palette
---@field rosewater integer Cursor
---@field flamingo integer
---@field pink integer
---@field mauve integer
---@field maroon integer
---@field peach integer
---@field teal integer
---@field sky integer
---@field sapphire integer
---@field lavender integer

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
---@param ... additional_color_name? The names of the additional colors to use. Up to 4 additional colors can be used, and replaces the original 4 included colors. Further customization of the palette can be done using the `replace` method.
---@return base_catppuccin_palette palette The new palette to use.
function catppuccin.set_palette(name, ...)
  expect(1, name, "string")

  local args = table.pack(...)
  if args.n > 4 then
    -- We can only load up to 4 additional colors.
    error("Too many arguments. Expected 1-5, got " .. tostring(args.n + 1), 2)
  elseif args.n > 0 then
    for i = 1, args.n do
      expect(i + 1, args[i], "string")
    end
  end


  if not catppuccin_palettes[name] then
    error("Unknown palette: " .. name, 2)
  end

  local i = 0
  local palette = {}

  for color_name in pairs(base_palette) do
    term.setPaletteColor(2^i, catppuccin_palettes[name][color_name])
    palette[color_name] = 2^i
    i = i + 1
  end

  for argi = 1, args.n do
    local color_name = args[argi]
    if not additional_colors[color_name] or not base_colors[color_name] then
      error("Unknown color: " .. color_name, 2)
    end

    term.setPaletteColor(2^i, catppuccin_palettes[name][color_name])
    palette[color_name] = 2^i
    i = i + 1
  end

  for color_name in pairs(base_colors) do
    if i > 15 then break end
    term.setPaletteColor(2^i, catppuccin_palettes[name][color_name])
    palette[color_name] = 2^i
    i = i + 1
  end

  --- Replace a color in the palette with a new color in the palette.
  --- 
  --- This directly removes the old color from the palette, then adds a new key with the new color's name.
  --- 
  --- This is most useful when you don't need one of the control colors, and want to replace it with one of the additional colors.
  --- For example, if you know you will never use `overlay_2`, you can replace it with `rosewater`:
  --- ```lua
  --- ---@type full_catpuccin_palette
  --- local palette = catppuccin.set_palette("mocha")
  --- palette.replace("overlay_2", "rosewater")
  --- 
  --- -- Don't forget to use the `full_catpuccin_palette` type! This will remove some warnings if you're altering the palette.
  --- ```
  ---@param old_name base_color_name|additional_color_name The name of the color to replace.
  ---@param new_name base_color_name|additional_color_name The name of the new color.
  function palette.replace(old_name, new_name)
    expect(1, old_name, "string")
    expect(2, new_name, "string")

    local old_color = palette[old_name]
    if not old_color then
      error("Color " .. old_name .. " not found in palette.", 2)
    end

    local new_color = catppuccin_palettes[name][new_name]

    if not new_color then
      error("Unknown color: " .. new_name, 2)
    end

    palette[old_name] = nil
    palette[new_name] = old_color
    term.setPaletteColor(old_color, new_color)
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
