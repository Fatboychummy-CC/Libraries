--- A simple library containing various display utilities.
local _expect = require "cc.expect"
local expect, field = _expect.expect, _expect.field

local half_char = '\x95'
local BLIT_CONVERT = {
  [1] = '0',
  [2] = '1',
  [4] = '2',
  [8] = '3',
  [16] = '4',
  [32] = '5',
  [64] = '6',
  [128] = '7',
  [256] = '8',
  [512] = '9',
  [1024] = 'a',
  [2048] = 'b',
  [4096] = 'c',
  [8192] = 'd',
  [16384] = 'e',
  [32768] = 'f',
}

---@class display_utils-display_utils
local dutil = {}

--- Create a percentage bar which uses drawing characters to be higher fidelity.
---@param options display_utils-hfpb_options The options for the percentage bar.
---@return display_utils-hfpb percent_bar The bar object. Use .Draw() to draw this.
function dutil.high_fidelity_percent_bar(options)
  expect(1, options, "table")
  field(options, "x", "number")
  field(options, "y", "number")
  field(options, "w", "number")
  field(options, "h", "number")
  field(options, "background", "number")
  field(options, "filled", "number")
  field(options, "current", "number")
  field(options, "allow_overflow", "boolean", "nil")

  local bar = {
    x = options.x,
    y = options.y,
    w = options.w,
    h = options.h,
    background = options.background,
    filled = options.filled,
    current = options.current,
    allow_overflow = options.allow_overflow or false,
    percent = 0
  }

  local function replace_char_at(str, x, new)
    if x <= 1 then
      return new .. str:sub(2)
    elseif x == #str then
      return str:sub(1, -2) .. new
    elseif x > #str then
      return str
    end
    return str:sub(1, x - 1) .. new .. str:sub(x + 1)
  end

  function bar.draw()
    local fill = math.floor(bar.percent * (bar.w * 2) + 0.5) -- this should mark how many half_chars are needed
    if not bar.allow_overflow then
      fill = math.min(bar.w * 2, fill)
    end
    local first_half = fill % 2 == 1
    local zero = fill == 0
    fill = math.floor(fill / 2 + 0.5)

    local fill_str = string.rep(' ', bar.w)
    local bg = BLIT_CONVERT[bar.filled]:rep(fill) .. BLIT_CONVERT[bar.background]:rep(bar.w - fill)
    local txt = BLIT_CONVERT[bar.filled]:rep(bar.w)
    
    if not zero then
      if first_half then
        fill_str = replace_char_at(fill_str, fill, half_char)
        txt = replace_char_at(txt, fill, BLIT_CONVERT[bar.current])
        bg = replace_char_at(bg, fill, BLIT_CONVERT[bar.background])
      else -- second half
        fill_str = replace_char_at(fill_str, fill, half_char)
        bg = replace_char_at(bg, fill, BLIT_CONVERT[bar.current])
      end
    end

    if #txt ~= #bg or #bg ~= #fill_str or #txt ~= bar.w then
      printError("Incorrect lengths for writing bar:", #fill_str, #txt, #bg, bar.w)
      print(("  \"%s\""):format(fill_str))
      print(("  \"%s\""):format(txt))
      print(("  \"%s\""):format(bg))
      error("", 0)
    end

    for y = bar.y, bar.y + bar.h - 1 do
      term.setCursorPos(bar.x, y)
      term.blit(fill_str, txt, bg)
    end
  end

  return bar --[[@as display_utils-hfpb]]
end

return dutil