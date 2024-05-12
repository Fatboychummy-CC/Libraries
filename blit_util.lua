--- This library is a small assistant library for working with `term.blit`.
--- It allows you to use `print` or `write`-like methods to blit text with text
--- wrapping.

local expect = require "cc.expect".expect

---@class blit_util
local blit_util = {}

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
