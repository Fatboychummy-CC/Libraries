--- This library is a small assistant library for working with `term.blit`.
--- It allows you to use `print` or `write`-like methods to blit text with text
--- wrapping.

local expect = require "cc.expect".expect

---@class blit_util
local blit_util = {}

--- Give an entire string a solid blit background and text color.
---@param message string The message to blit.
---@param text_color string|integer The text color to use.
---@param bg_color string|integer The background color to use.
---@return string text The blit text (the same as inputted).
---@return string text_color The blit text color.
---@return string bg_color The blit background color.
function blit_util.solid_colors(message, text_color, bg_color)
  expect(1, message, "string")
  expect(2, text_color, "string", "number")
  expect(3, bg_color, "string", "number")

  if type(text_color) == "number" then
    text_color = colors.toBlit(text_color)
  end
  if type(bg_color) == "number" then
    bg_color = colors.toBlit(bg_color)
  end

  text_color = text_color:rep(#message)
  bg_color = bg_color:rep(#message)

  return message, text_color, bg_color
end

--- Combine values into valid blit strings, in the format of
--- 
--- --> `a1 .. a2 .. a3, t1 .. t2 .. t3, b1 .. b2 .. b3`.
--- 
--- The input values are expected to be in the order
--- 
--- --> `a1, t1, b1, a2, t2, b2, a3, t3, b3`.
--- 
--- ```lua
--- local text, text_color, bg_color = blit_util.combine(
---   -- Normal usage: black text, white background
---   "Hello ", "ffffff", "000000", 
--- 
---   -- Table overload, allows daisychaining of blit_util functions
---   { blit_util.solid_background("world!", colors.white, colors.black) } 
--- )
--- 
--- term.blit(text, text_color, bg_color)
--- ```
---@param ... string|table The values to combine. Tables will be pulled apart to allow for multiple values if calling functions.
---@return string text The combined text values.
---@return string text_color The combined text color values.
---@return string bg_color The combined background color values.
function blit_util.combine(...)
  local text = ""
  local text_color = ""
  local bg_color = ""

  local args = table.pack(...)

  local fixed_args = {}

  -- Rip subtables out and insert them as if they were arguments.
  for i = 1, args.n do
    local arg = args[i]
    if type(arg) == "table" then
      for j = 1, #arg do
        table.insert(fixed_args, arg[j])
      end
    else
      table.insert(fixed_args, arg)
    end
  end

  if #fixed_args % 3 ~= 0 then
    error("Total argument count (after table explosion) not divisible by 3.", 2)
  end

  for i = 1, #fixed_args, 3 do
    local s1, s2, s3 = fixed_args[i], fixed_args[i + 1], fixed_args[i + 2]
    expect(i, s1, "string")
    expect(i + 1, s2, "string")
    expect(i + 2, s3, "string")

    if #s1 ~= #s2 or #s1 ~= #s3 then
      error(("Bad arguments %d, %d, %d: Must be same length (got %d, %d, %d)"):format(i, i + 1, i + 2, #s1, #s2, #s3), 2)
    end

    text = text .. s1
    text_color = text_color .. s2
    bg_color = bg_color .. s3
  end

  return text, text_color, bg_color
end

--- Writes text to the screen in `blit` format, with word wrapping.
---@param body string The text to print.
---@param fg_color string The colors to use for the text.
---@param bg_color string The colors to use for the background.
function blit_util.write(body, fg_color, bg_color)
  expect(1, body, "string")
  expect(2, fg_color, "string")
  expect(3, bg_color, "string")

  if #body ~= #fg_color or #body ~= #bg_color then
    error("Arguments must be the same length", 2)
  end

  local w, h = term.getSize()
  local x, y = term.getCursorPos()

  local lines_printed = 0
  local function newLine()
    if y + 1 <= h then
      term.setCursorPos(1, y + 1)
    else
      term.setCursorPos(1, h)
      term.scroll(1)
    end
    x, y = term.getCursorPos()
    lines_printed = lines_printed + 1
  end

  -- print the line with proper word wrapping
  while #body > 0 do
    local whitespace = string.match(body, "^[ \t]+")
    if whitespace then
      -- print whitespace
      term.blit(whitespace, string.sub(fg_color, 1, #whitespace), string.sub(bg_color, 1, #whitespace))
      x, y = term.getCursorPos()

      body = string.sub(body, #whitespace + 1)
      fg_color = string.sub(fg_color, #whitespace + 1)
      bg_color = string.sub(bg_color, #whitespace + 1)
    end

    local newline = string.match(body, "^\n")
    if newline then
      -- print newlines
      newLine()

      body = string.sub(body, 2)
      fg_color = string.sub(fg_color, 2)
      bg_color = string.sub(bg_color, 2)
    end

    local text = string.match(body, "^[^ \t\n]+")
    if text then
      body = string.sub(body, #text + 1)
      local fg_begin = string.sub(fg_color, 1, #text)
      local bg_begin = string.sub(bg_color, 1, #text)
      fg_color = string.sub(fg_color, #text + 1)
      bg_color = string.sub(bg_color, #text + 1)

      if #text > w then
        -- print a multiline word
        while #text > 0 do
          if x > w then
            newLine()
          end
          term.blit(text, fg_begin, bg_begin)

          text = string.sub(text, w - x + 2)
          fg_begin = string.sub(fg_begin, w - x + 2)
          bg_begin = string.sub(bg_begin, w - x + 2)

          x, y = term.getCursorPos()
        end
      else
        -- print a word normally
        if x + #text - 1 > w then
          newLine()
        end
        term.blit(text, fg_begin, bg_begin)
        x, y = term.getCursorPos()
      end
    end
  end

  return lines_printed
end

--- Prints text to the screen, with word wrapping.
---@param body string The text to print.
---@param fg_color string The colors to use for the text.
---@param bg_color string The colors to use for the background.
function blit_util.print(body, fg_color, bg_color)
  expect(1, body, "string")
  expect(2, fg_color, "string")
  expect(3, bg_color, "string")

  if #body ~= #fg_color or #body ~= #bg_color then
    error("Arguments must be the same length", 2)
  end

  local lines_printed = blit_util.write(body, fg_color, bg_color)
  lines_printed = lines_printed + blit_util.write("\n", 'f', '0')

  return lines_printed
end

return blit_util
