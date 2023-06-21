---@meta

---@class button-button_options
---@field x integer The X position of the button.
---@field y integer The Y position of the button.
---@field w integer The width of the button.
---@field h integer The height of the button
---@field text string The text to be displayed on the button.
---@field bg_color color The background color of the button.
---@field txt_color color The text color of the button.
---@field highlight_bg_color color The background color of the button when the mouse is held down on it.
---@field highlight_txt_color color The text color of the button when the mouse is held down on it.
---@field callback fun(self:button-button_object) The callback to use when this button is pressed.
---@field text_centered boolean? If the text should be centered. Otherwise it is at the top-left of the object.
---@field text_offset_x integer? If the text is not centered, offset the text by this much on the X axis.
---@field text_offset_y integer? If the text is not centered, offset the text by this much on the Y axis.
---@field top_bar boolean? Whether to draw a top bar using drawing chars.
---@field left_bar boolean? Whether to draw a left bar using drawing chars.
---@field right_bar boolean? Whether to draw a right bar using drawing chars.
---@field bottom_bar boolean? Whether to draw a bottom bar using drawing chars.
---@field bar_color color The color to set the bar if one is set to be drawn.
---@field highlight_bar_color color The bar color when the mouse is held down on the button.

---@class button-button_object
---@field x integer The X position of the button.
---@field y integer The Y position of the button.
---@field w integer The width of the button.
---@field h integer The height of the button
---@field text string The text to be displayed on the button.
---@field bg_color color The background color of the button.
---@field txt_color color The text color of the button.
---@field callback fun(self:button-button_object) The callback to use when this button is pressed.
---@field text_centered boolean If the text should be centered. Otherwise it is at the top-left of the object.
---@field text_offset_x integer If the text is not centered, offset the text by this much on the X axis.
---@field text_offset_y integer If the text is not centered, offset the text by this much on the Y axis.
---@field top_bar boolean Whether to draw a top bar using drawing chars.
---@field left_bar boolean Whether to draw a left bar using drawing chars.
---@field right_bar boolean Whether to draw a right bar using drawing chars.
---@field bottom_bar boolean Whether to draw a bottom bar using drawing chars.
---@field bar_color color The color to set the bar if one is set to be drawn.
---@field holding boolean Used to determine if the player has clicked on the button but hasn't released yet.
---@field enabled boolean Whether or not the button is enabled (accepting events).
---@field drawn boolean Whether or not the button will be drawn on the next update.
---@field remove fun() Remove this button from the buttons.

---@class button-button_input_field : button-button_object Note: the information box only appears when the button has been clicked on.
---@field verification_callback fun(str:string):boolean,string? Verification function to verify the resultant answer.
---@field info_x number The X position of the information box.
---@field info_y number The Y position of the information box.
---@field info_w number The width of the information box.
---@field info_h number The height of the information box.
---@field info_bg_color number The background color of the information box.
---@field info_txt_color number The text color of the information box.
---@field info_text string The text of the information box.
---@field result any The resultant value after running the input box. This will be set right before the callback is ran, and will be available in the callback.
---@field default_text string? The default text to use when writing to this input field.
---@field password_field boolean? If this input is a password field. Censors the input and requires input twice.

---@class button-char_data
---@field char string The character to use.
---@field inverted boolean Whether this character's colors need to be inverted or not.