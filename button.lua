--- Quick and dirty button library with some slight fanciness.
local strings = require "cc.strings"
local _expect = require "cc.expect"
local field, expect = _expect.field, _expect.expect

---@class edges
---@field TOP button-char_data
---@field BOT button-char_data
---@field LEFT button-char_data
---@field RIGHT button-char_data
---@field CORNER_TL button-char_data
---@field CORNER_TR button-char_data
---@field CORNER_BR button-char_data
---@field CORNER_BL button-char_data
local EDGES = {}
do
  local function add_edge(name)
    return function(char)
      return function(inverted)
        EDGES[name] = { char = char, inverted = inverted }
      end
    end
  end

  add_edge "TOP" '\x83' (false)
  add_edge "BOT" '\x8f' (true)
  add_edge "LEFT" '\x95' (false)
  add_edge "RIGHT" '\x95' (true)
  add_edge "CORNER_TL" '\x97' (false)
  add_edge "CORNER_TR" '\x94' (true)
  add_edge "CORNER_BL" '\x8a' (true)
  add_edge "CORNER_BR" '\x85' (true)
end

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

---@class button-button
local Button = {}

--- Create a new set of buttons.
---@return button-set set The button set.
function Button.set()
  ---@class button-set 
  local set = {
    _buttons = {} ---@type table<integer, button-button_object>
  }

  local function check_buttons(x, y)
    for _, button in ipairs(set._buttons) do
      if x >= button.x and x < button.x + button.w and
          y >= button.y and y < button.y + button.h and
          button.enabled then
        return button
      end
    end
  end

  local function unhold_all()
    for _, button in ipairs(set._buttons) do
      button.holding = false
    end
  end

  --- Create a new button.
  ---@param options button-button_options
  ---@return button-button_object
  function set.new(options)
    expect(1, options, "table")
    field(options, "x", "number")
    field(options, "y", "number")
    field(options, "w", "number")
    field(options, "h", "number")
    field(options, "text", "string")
    field(options, "bg_color", "number")
    field(options, "txt_color", "number")
    field(options, "highlight_txt_color", "number")
    field(options, "highlight_bg_color", "number")
    field(options, "callback", "function")
    field(options, "text_centered", "boolean", "nil")
    field(options, "text_offset_x", "number", "nil")
    field(options, "text_offset_y", "number", "nil")
    field(options, "top_bar", "boolean", "nil")
    field(options, "left_bar", "boolean", "nil")
    field(options, "right_bar", "boolean", "nil")
    field(options, "bottom_bar", "boolean", "nil")
    if options.top_bar or options.left_bar or options.right_bar or options.bottom_bar then
      field(options, "bar_color", "number")
      field(options, "highlight_bar_color", "number")
    end

    local btn = {
      x = options.x,
      y = options.y,
      w = options.w,
      h = options.h,
      text = options.text,
      bg_color = options.bg_color,
      txt_color = options.txt_color,
      highlight_bg_color = options.highlight_bg_color,
      highlight_txt_color = options.highlight_txt_color,
      callback = options.callback,
      text_centered = options.text_centered or false,
      text_offset_x = options.text_offset_x or 0,
      text_offset_y = options.text_offset_y or 0,
      top_bar = options.top_bar or false,
      right_bar = options.right_bar or false,
      left_bar = options.left_bar or false,
      bottom_bar = options.bottom_bar or false,
      bar_color = options.bar_color or colors.white,
      highlight_bar_color = options.highlight_bar_color or colors.white,
      holding = false,
      drawn = true,
      enabled = true
    } --[[@as button-button_object]]

    table.insert(set._buttons, btn)

    return btn
  end

  function set.input_box(options)
    expect(1, options, "table")
    field(options, "x", "number")
    field(options, "y", "number")
    field(options, "w", "number")
    field(options, "h", "nil")
    field(options, "text", "string")
    field(options, "bg_color", "number")
    field(options, "txt_color", "number")
    field(options, "highlight_txt_color", "number")
    field(options, "highlight_bg_color", "number")
    field(options, "callback", "function")
    field(options, "verification_callback", "function")
    field(options, "info_x", "number")
    field(options, "info_y", "number")
    field(options, "info_w", "number")
    field(options, "info_h", "number")
    field(options, "info_bg_color", "number")
    field(options, "info_txt_color", "number")
    field(options, "info_text", "string")
    field(options, "default_text", "string", "nil")
    field(options, "password_field", "boolean", "nil")
    field(options, "password_input_field", "boolean", "nil")

    local callback_proxy = {}

    local function wrapper(f)
      --- Callback wrapper
      ---@param self button-button_input_field
      return function(self, ...)
        -- Handle user input here!
        local input_win = window.create(term.current(), self.x, self.y, self.w + 1, 1, false)
        local info_win = window.create(term.current(), self.info_x, self.info_y, self.info_w, self.info_h, false)

        input_win.setBackgroundColor(self.highlight_bg_color)
        info_win.setBackgroundColor(self.info_bg_color)

        input_win.setTextColor(self.highlight_txt_color)
        info_win.setTextColor(self.info_txt_color)

        input_win.clear()
        info_win.clear()

        input_win.setVisible(true)
        info_win.setVisible(true)

        local function write_info(reason, color)
          local b_text = strings.wrap(reason, self.info_w)
          info_win.setTextColor(color)
          info_win.clear()
          for i, str in ipairs(b_text) do
            info_win.setCursorPos(1, i)
            info_win.write(str)
          end
        end

        write_info(self.info_text, colors.white)

        local old = term.redirect(input_win)

        -- pcall this to protect the old terminal object.
        local ok, err = pcall(function()
          local result, reason
          local previous
          while true do
            input_win.clear()
            input_win.setCursorPos(1, 1)

            ---@diagnostic disable-next-line These are completely valid nils
            result, reason = self.verification_callback(read((self.password_field or self.password_input_field) and "\x07" or nil, nil, nil, self.default_text))

            if self.password_field or self.password_input_field then
              if result ~= nil then
                if self.password_input_field then
                  -- This is a password input field, not a password set field.
                  -- Only prompt the user once.
                  break
                end
                if previous then
                  if previous == result then
                    break -- Passwords good!
                  else
                    write_info("Inputs did not match. Please retry.", colors.red)
                    previous = nil
                  end
                else
                  previous = result
                  write_info("Please confirm.", colors.yellow)
                end
              elseif reason then
                write_info(reason, colors.red)
                previous = nil
              end
            else
              if result ~= nil then -- allow `false` to be an output.
                break
              elseif reason then
                -- Bad result!
                write_info(reason, colors.red)
              end
            end
          end
          self.result = result
        end)

        term.redirect(old)

        if not ok then
          error(err, 0)
        end

        return f(self, ...)
      end
    end

    options.h = 1

    local btn = setmetatable(
      set.new(options),
      {
        __index = callback_proxy,
        __newindex = function(self, index, value)
          callback_proxy[index] = value
        end
      }
    )

    btn.info_x = options.info_x
    btn.info_y = options.info_y
    btn.info_w = options.info_w
    btn.info_h = options.info_h
    btn.info_bg_color = options.info_bg_color
    btn.info_txt_color = options.info_txt_color
    btn.info_text = options.info_text
    btn.verification_callback = options.verification_callback
    btn.default_text = options.default_text
    btn.password_field = options.password_field
    btn.password_input_field = options.password_input_field

    callback_proxy.callback = wrapper(options.callback)
    btn.callback = nil

    return btn --[[@as button-button_input_field]]
  end

  --- Draw all buttons.
  function set.draw()
    for _, button in ipairs(set._buttons) do
      -- Build the blit lines.
      local txt = {}
      local tc = {}
      local bc = {}
      local bg_color = button.holding and BLIT_CONVERT[button.highlight_bg_color] or BLIT_CONVERT[button.bg_color]
      local txt_color = button.holding and BLIT_CONVERT[button.highlight_txt_color] or BLIT_CONVERT[button.txt_color]
      local edge_color = button.holding and BLIT_CONVERT[button.highlight_bar_color] or BLIT_CONVERT[button.bar_color]

      -- initialize the arrays
      for y = 1, button.h do
        txt[y] = {}
        tc[y] = {}
        bc[y] = {}
      end

      -- Set the left bar up, if needed.
      if button.left_bar then
        for y = 1, button.h do
          txt[y][1] = EDGES.LEFT.char
          tc[y][1] = EDGES.LEFT.inverted and bg_color or edge_color
          bc[y][1] = EDGES.LEFT.inverted and edge_color or bg_color
        end
      end

      -- Set up the top bar, if needed.
      if button.top_bar then
        for x = 1, button.w do
          if txt[1][x] then
            -- convert to corner piece.
            txt[1][x] = EDGES.CORNER_TL.char
            tc[1][x] = EDGES.CORNER_TL.inverted and bg_color or edge_color
            bc[1][x] = EDGES.CORNER_TL.inverted and edge_color or bg_color
          else
            -- just add the piece.
            txt[1][x] = EDGES.TOP.char
            tc[1][x] = EDGES.TOP.inverted and bg_color or edge_color
            bc[1][x] = EDGES.TOP.inverted and edge_color or bg_color
          end
        end
      end

      -- Set up the bottom bar, if needed.
      if button.bottom_bar then
        for x = 1, button.w do
          if txt[button.h][x] then
            -- convert to corner piece.
            txt[button.h][1] = EDGES.CORNER_BL.char
            tc[button.h][1] = EDGES.CORNER_BL.inverted and bg_color or edge_color
            bc[button.h][1] = EDGES.CORNER_BL.inverted and edge_color or bg_color
          else
            -- just add the piece.
            txt[button.h][x] = EDGES.BOT.char
            tc[button.h][x] = EDGES.BOT.inverted and bg_color or edge_color
            bc[button.h][x] = EDGES.BOT.inverted and edge_color or bg_color
          end
        end
      end

      -- Set up the right bar, if needed.
      if button.right_bar then
        for y = 1, button.h do
          if txt[y][button.w] then
            -- convert to corner piece.
            if y == button.h then
              -- bottom right
              txt[y][button.w] = EDGES.CORNER_BR.char
              tc[y][button.w] = EDGES.CORNER_BR.inverted and bg_color or edge_color
              bc[y][button.w] = EDGES.CORNER_BR.inverted and edge_color or bg_color
            elseif y == 1 then
              -- top right
              txt[y][button.w] = EDGES.CORNER_TR.char
              tc[y][button.w] = EDGES.CORNER_TR.inverted and bg_color or edge_color
              bc[y][button.w] = EDGES.CORNER_TR.inverted and edge_color or bg_color
            else
              error("This shouldn't happen.")
            end
          else
            -- just add the piece.
            txt[y][button.w] = EDGES.RIGHT.char
            tc[y][button.w] = EDGES.RIGHT.inverted and bg_color or edge_color
            bc[y][button.w] = EDGES.RIGHT.inverted and edge_color or bg_color
          end
        end
      end

      -- Add button text.
      local start_x, text_y
      if button.text_centered then
        start_x, text_y = math.ceil(button.w / 2 - #button.text / 2) + 1, math.ceil(button.h / 2)
      else
        start_x, text_y = 1 + button.text_offset_x, 1 + button.text_offset_y
      end

      local i = 0
      local text = #button.text > button.w and button.text:sub(1, button.w - 3) .. "..." or button.text
      for x = start_x, start_x + #text - 1 do
        i = i + 1
        if x >= 1 and x <= button.w then
          txt[text_y][x] = text:sub(i, i)
        else
          error(("Button attempted drawing outside of its space: %.2f %.2f"):format(text_y, x))
        end
      end

      -- Fill in any gaps, combine all the text objects together, draw.
      for y = 1, button.h do
        for x = 1, button.w do
          txt[y][x] = txt[y][x] or ' '
          tc[y][x] = tc[y][x] or txt_color
          bc[y][x] = bc[y][x] or bg_color
        end

        local text = table.concat(txt[y])
        local foreground = table.concat(tc[y])
        local background = table.concat(bc[y])
        if #text ~= #background or #background ~= #foreground or #text ~= button.w then
          printError("Incorrect lengths for writing button on y", y, ":", #text, #foreground, #background, button.w)
          error("", 0)
        end

        term.setCursorPos(button.x, y + button.y - 1)
        term.blit(text, foreground, background)
      end
    end
  end

  --- Handle an event on all registered buttons.
  ---@param event string The event name
  ---@param mouse_button integer The mouse button pressed.
  ---@param x integer The X position of the press.
  ---@param y integer The Y position of the press.
  function set.event(event, mouse_button, x, y)
    if not event then
      error("Button event handler was passed a nil event.", 2)
    end

    local hit = false

    if mouse_button == 1 then -- we haven't checked if it's a mouse event yet but this should be fine.
      if event == "mouse_click" then
        unhold_all()
        local button = check_buttons(x, y)
        if button then
          button.holding = true
        end
      elseif event == "mouse_up" then
        local button = check_buttons(x, y)
        if button and button.holding then
          button.callback(button)
          hit = true
        end
        unhold_all()
      end
    end

    return hit
  end

  return set
end

return Button
