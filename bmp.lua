--- Lua implementation of the bitmap file format -- reading and writing.

local expect = require "cc.expect".expect

---@alias color_table_entry {[1]:integer, [2]:integer, [3]:integer}

---@class bmp-image
---@field width integer The width of the image, in pixels.
---@field height integer The height of the image, in pixels.
---@field colors_used integer The number of colors used in the image.
---@field color_table color_table_entry[] The color table for the image. Zero-indexed, as the data is binary values.
---@field data integer[][] The image data, as a 2D array of integers. The integers are indices into the color table.
---@field _bits_per_pixel integer The number of bits per pixel in the image.
---@field _compression integer The compression type used in the image.
---@field _important_colors integer The number of important colors in the image.

---@class bool-bmp-image
---@field width integer The width of the image, in pixels.
---@field height integer The height of the image, in pixels.
---@field data boolean[][] The image data, as a 2D array of booleans.
---@field is_bool true Always true, to indicate that this has been converted to boolean data.

---@class bmp
local bmp = {}

--- Read a BMP file and return the image data.
---@param path string The path to the BMP file.
---@return bmp-image image The BMP data as image data.
function bmp.read(path)
  local handle = fs.open(path, "rb") --[[@as BinaryReadHandle? ]]
  if not handle then
    error("File not found.", 2)
  end

  local signature = handle.read(2)
  if not signature or signature ~= "BM" then
    handle.close()
    error("Invalid BMP signature.", 2)
  end

  local _error = error
  local function error(str, level)
    pcall(handle.close)
    _error(str, level + 1)
  end


  local invalidated = false --- Used to ensure further read attempts do not error with 'attempt to use closed file'.

  --- Read n bytes from the file handle, as a number.
  ---@param n number The number of bytes to read.
  ---@return number? value The value read, or nil if the file is invalid.
  local function r_n_size(n)
    if invalidated then return end
    local data = handle.read(n)
    if not data then
      handle.close()
      invalidated = true
      return
    end

    ---@diagnostic disable-next-line:redundant-return-value I DONT CARE
    return string.unpack("<I" .. n, data)
  end

  local file_size = r_n_size(4)
  local reserved = r_n_size(4)
  local data_offset = r_n_size(4)

  if not file_size or not reserved or not data_offset
      or reserved ~= 0 or file_size == 0 or data_offset < 54 then
    error("Invalid BMP file header data.", 2)
  end

  local info_header_size = r_n_size(4)
  local width = r_n_size(4)
  local height = r_n_size(4)
  local planes = r_n_size(2)
  local bits_per_pixel = r_n_size(2)
  local compression = r_n_size(4)
  local image_size = r_n_size(4)
  local x_pixels_per_meter = r_n_size(4)
  local y_pixels_per_meter = r_n_size(4)
  local colors_used = r_n_size(4)
  local important_colors = r_n_size(4)

  if not info_header_size or not width or not height or not planes or not bits_per_pixel
      or not compression or not image_size or not x_pixels_per_meter or not y_pixels_per_meter
      or not colors_used or not important_colors then
    error("Invalid or incomplete BMP info header data.", 2)
  end

  -- Does this value take into account the color table's size?
  -- If not, this check will need to be removed.
  -- Looking at an "official" looking documentation page, it looks to be correct.
  -- http://www.martinreddy.net/gfx/2d/BMP.txt
  -- Leaving this note for future me.
  if info_header_size ~= 40 then
    error(("Unsupported BMP file: Info header size incorrect. Got %d."):format(info_header_size), 2)
  end

  -- I have no clue what this even does, so if it's different then it's unsupported.
  if planes ~= 1 then
    error(("Unsupported BMP file: Invalid color plane count. Got %d."):format(planes), 2)
  end

  -- Compression type 0 is no compression, 1 is RLE-8, and 2 is RLE-4.
  -- We will initially only support no compression, but may add RLE-8 and RLE-4 support later.
  if compression > 0 then
    error(("Unsupported BMP file: Compression type not supported. Got %d."):format(compression), 2)
  end

  -- Computercraft only supports a 16-color palette, so we only support 4 bits per pixel.
  -- However, CraftOS-PC Graphics Mode can support up to 256, so we can support 8 bits per pixel too.
  if bits_per_pixel < 1 or bits_per_pixel > 8 then
    error(("Unsupported BMP file: Bits per pixel count not supported. Got %d."):format(bits_per_pixel), 2)
  end

  if colors_used == 0 then
    error("Unsupported BMP file: WHY ARE THERE NO COLORS (can this even happen)?", 2)
  end

  -- Color table size if 4x<colors used> bytes.
  local color_table = {}

  for i = 0, colors_used - 1 do
    local b = r_n_size(1)
    local g = r_n_size(1)
    local r = r_n_size(1)
    local a = r_n_size(1)

    if not b or not g or not r or not a then
      error(("Invalid or incomplete BMP color table data (index %d)."):format(i), 2)
    end

    color_table[i] = {r, g, b}
  end

  -- Woo, time to finally read the image data.
  local data = {}

  -- Seek to the start of the image data.
  handle.seek("set", data_offset)

  -- The image data is stored in rows, with each row being padded to a multiple of 4 bytes.
  -- This means that the row size is always a multiple of 4 bytes.
  -- total size is image_size, so we can calculate the row size by dividing by
  -- height. IFF the resultant number is not divisible by 4, we should throw an error.

  -- If we want any level of compression, we will need to change this check in
  -- the future.

  -- local row_size = math.floor(image_size / height)
  -- Image size can be zero, as I have recently learned, so instead our row size
  -- can be calculated by the width and bits per pixel.
  local row_size = math.ceil(width * bits_per_pixel / 8) -- in bytes!
  -- Then we need to round to nearest 4 bytes.
  row_size = math.ceil(row_size / 4) * 4 -- in bytes!
  -- And calculate how many bits we need to remove from each line.
  local bits_to_remove = row_size * 8 - width * bits_per_pixel


  local extractions = bits_per_pixel == 1 and 8
    or bits_per_pixel == 4 and 2 or bits_per_pixel == 8 and 1
    or error("Unsupported BMP file: Bits per pixel count not supported.", 2)
  if row_size % 4 ~= 0 then
    error("Invalid BMP file: Row size is not a multiple of 4 bytes.", 2)
  end

  for _ = 1, height do
    local row = {}
    for _ = 1, row_size do
      local byte = r_n_size(1)
      if not byte then
        error("Invalid or incomplete BMP image data.", 2)
      end

      -- The actual bits in the byte are stored in reverse order.
      -- There might be a better way to read this, but I'm not sure what it is.
      for i = extractions - 1, 0, -1 do
        row[#row + 1] = bit32.extract(byte, bits_per_pixel * i, bits_per_pixel)
      end
    end

    -- Remove the extra bits from the end of the row.
    for _ = 1, bits_to_remove do
      table.remove(row)
    end

    data[#data + 1] = row
  end

  pcall(handle.close)

  -- Since BMP scanlines are stored bottom-to-top, we need to reverse the data.
  local reversed_data = {}
  for i = #data, 1, -1 do
    reversed_data[#reversed_data + 1] = data[i]
  end

  ---@type bmp-image
  local bmp_image = {
    width = width,
    height = height,
    colors_used = colors_used,
    color_table = color_table,
    data = data,
    reversed_data = reversed_data,
    _bits_per_pixel = bits_per_pixel,
    _compression = compression,
    _important_colors = important_colors,
  }

  return bmp_image
end

--- Build binary BMP data from image data.
---@param data bmp-image The image data to write.
function bmp.build(data)
  expect(1, data, "table")

  if data.is_bool then
    error("Cannot write boolean image data to a BMP file.", 2)
  end
  if data.colors_used > 256 then
    error("Cannot write BMP files with more than 256 colors.", 2)
  end
  if data.colors_used <= 1 then
    error("Cannot write BMP files with no colors.", 2)
  end

  -- 2d array of bytes.
  ---@type integer[][]
  local image_bytes = {}

  if data._bits_per_pixel == 1 then
    -- If there are only two colors, we can use a 1-bit image.
    for y = 1, #data.data do
      local row = {} ---@type integer[]
      local row_length = 0

      for x = 1, #data.data[y], 8 do
        -- Read a byte at a time.
        local byte = 0

        for i = 0, 7 do
          if data.data[y][x + i] == 1 then
            byte = byte + 2 ^ (7 - i)
          end
        end

        row[#row + 1] = byte
        row_length = row_length + 1
      end

      -- Pad the row to a multiple of 4 bytes.
      if row_length % 4 ~= 0 then 
        for i = 1, 4 - row_length % 4 do
          row[#row + 1] = 0
        end
      end

      image_bytes[#image_bytes + 1] = row
    end
  elseif data._bits_per_pixel == 4 then
    -- If there are 16 colors or less, we can use a 4-bit image.
    for y = 1, #data.data do
      local row = {} ---@type integer[]
      local row_length = 0

      for x = 1, #data.data[y], 2 do
        -- Read a byte at a time.
        local byte = 0

        for i = 0, 1 do
          byte = byte + data.data[y][x + i] * 2 ^ (4 - i * 4)
        end

        row[#row + 1] = byte
        row_length = row_length + 1
      end

      -- Pad the row to a multiple of 4 bytes.
      if row_length % 4 ~= 0 then
        for i = 1, 4 - row_length % 4 do
          row[#row + 1] = 0
        end
      end

      image_bytes[#image_bytes + 1] = row
    end
  elseif data._bits_per_pixel == 8 then
    -- If there are 256 colors or less, we can use an 8-bit image.
    for y = 1, #data.data do
      local row = {} ---@type integer[]
      local row_length = 0

      for x = 1, #data.data[y] do
        row[#row + 1] = data.data[y][x]
        row_length = row_length + 1
      end

      -- Pad the row to a multiple of 4 bytes.
      if row_length % 4 ~= 0 then
        for i = 1, 4 - row_length % 4 do
          row[#row + 1] = 0
        end
      end

      image_bytes[#image_bytes + 1] = row
    end
  end

  -- Check the image data:
  -- 1. No underflow.
  -- 2. No overflow.
  for y = 1, #data.data do
    local Ys = data.data[y]
    for x = 1, #Ys do
      local color = Ys[x]
      if color < 0 or color >= data.colors_used then
        error(("Invalid color index at (%d, %d): %d"):format(x, y, color), 2)
      end
    end
  end

  -- Parse the image data down to a binary string
  local image_data = ""
  for i = 1, #image_bytes do --#image_bytes, 1, -1 do
    local row = {} ---@type string[]

    for j = 1, #image_bytes[i] do
      -- Convert each byte to a char
      row[j] = string.char(image_bytes[i][j])
    end

    -- Concatenate the row
    image_data = image_data .. table.concat(row)
  end

  local function pack_n_size(size, value)
    return string.pack("<I" .. size, value)
  end

  -- BMP header data
  local file_size ---@type string The size of the file in bytes as a binary string
  local reserved = '\0\0\0\0' ---@type string 4 bytes of reserved data, binary string
  local data_offset = pack_n_size(4, 54 + 4 * data.colors_used) ---@type string The offset to the start of the image data, binary string

  -- BMP info header data
  local info_header_size = pack_n_size(4, 40) ---@type string The size of the info header, 40 bytes, binary string
  local width = pack_n_size(4, data.width) ---@type string The width of the image in pixels, binary string
  local height = pack_n_size(4, data.height) ---@type string The height of the image in pixels, binary string
  local planes = pack_n_size(2, 1) ---@type string The number of color planes, binary string
  local bits_per_pixel = pack_n_size(2, data._bits_per_pixel) ---@type string The number of bits per pixel, binary string
  local compression = '\0\0\0\0' ---@type string The compression type, none, binary string
  local image_size = '\0\0\0\0' ---@type string The size of the image data (only really needed for compression), binary string
  local x_pixels_per_meter = '\0\0\0\0' ---@type string The number of pixels per meter in the x direction, binary string
  local y_pixels_per_meter = '\0\0\0\0' ---@type string The number of pixels per meter in the y direction, binary string
  local colors_used = pack_n_size(4, data.colors_used) ---@type string The number of colors used in the image, binary string
  local important_colors = '\0\0\0\0' ---@type string The number of important colors in the image, binary string

  ---@type string Color table data, binary string
  local color_table = ""

  for i = 0, data.colors_used - 1 do
    local color = data.color_table[i]
    color_table = color_table .. string.char(color[3], color[2], color[1], 0)
  end

  -- Combine everything into the semi-final binary string
  -- Also, can we just say, this is horrific to look at.
  local combined = reserved .. data_offset .. info_header_size .. width .. height
    .. planes .. bits_per_pixel .. compression .. image_size .. x_pixels_per_meter
    .. y_pixels_per_meter .. colors_used .. important_colors .. color_table .. image_data

  -- Calculate the file size
  file_size = pack_n_size(4, #combined + 6) -- 6 bytes for signature (2) and file size (4)

  return "BM" .. file_size .. combined
end

--- Write BMP data to a file.
---@param path string The path to write the BMP file to.
---@param data bmp-image The BMP data to write.
function bmp.write(path, data)
  expect(1, path, "string")
  expect(2, data, "table")

  local binary_data = bmp.build(data)

  local handle = fs.open(path, "wb") --[[@as BinaryWriteHandle? ]]
  if not handle then
    error("Failed to open file for writing.", 2)
  end

  local ok, err = pcall(handle.write, binary_data)
  if not ok then
    handle.close()
    error(err, 2)
  end

  handle.close()
end

--- Convert BMP data to boolean image data. Meant for monochrome BMPs, but can be used for any BMP.
---@param data bmp-image The BMP data to convert.
---@param selection integer? The color index to convert to true, defaults to 0 (the first color in the color table).
---@return bool-bmp-image bool_data The BMP data as boolean image data.
function bmp.boolify(data, selection)
  expect(1, data, "table")
  expect(2, selection, "number", "nil")
  selection = selection or 0

  local bool_data = {}

  -- Copy the data, converting the selected color to true and all others to false.
  for i = 1, #data do
    local row = {}
    for j = 1, #data[i] do
      row[j] = data[i][j] == selection
    end
    bool_data[i] = row
  end

  -- Copy the other data.
  bool_data.width = data.width
  bool_data.height = data.height

  -- Inject notice that this is a boolean image.
  bool_data.is_bool = true

  return bool_data
end

--- Create a lookup table of the closest CC color to each color in the BMP color table.
---@param data bmp-image The BMP data to create the lookup table for.
---@param palette_func nil|fun(color:integer):number,number,number The function to get the RGB values for a CC color index. For example, you might pass `term.getPaletteColor` or `term.nativePaletteColor` as this argument. Defaults to `term.getPaletteColor`.
---@param refill boolean? For BMP files which have more than 16 colors, this will allow multiple colors to be mapped to the same CC color. Defaults to false.
---@param gfxmode boolean? Whether to use the CraftOS-PC Graphics Mode's 256-color palette. Defaults to false.
---@param gfxmode_add_colors boolean? If gfxmode is true, this being true will allow creation of colors in CraftOS-PC's palette. Defaults to false.
---@return table<integer, integer> lookup_table The lookup table, indexed by BMP color index, with the value being the closest CC color index.
function bmp.create_color_lookup_table(data, palette_func, refill, gfxmode, gfxmode_add_colors)
  expect(1, data, "table")
  expect(2, palette_func, "function", "nil")
  expect(3, refill, "boolean", "nil")
  expect(4, gfxmode, "boolean", "nil")
  expect(5, gfxmode_add_colors, "boolean", "nil")
  palette_func = palette_func or term.getPaletteColor

  if type(gfxmode) == "boolean" or type(gfxmode_add_colors) == "boolean" then
    error("gfxmode args not yet implemented.", 2)
  end


  local colors_lookup = {}
  local lookup_table = {}

  --- Create a lookup table of CC's 16 color indexes to their RGB values, in 0-255 instead of 0-1.
  local function create_lookup()
    for i = 0, 15 do
      local lookup_data = {palette_func(2^i)}

      for j = 1, 3 do
        lookup_data[j] = math.floor(lookup_data[j] * 255)
      end

      colors_lookup[2^i] = lookup_data
    end
  end

  create_lookup()

  -- Create a copy of the BMP color table.
  local color_table = {}
  for i = 0, data.colors_used - 1 do
    local color = data.color_table[i]
    color_table[i] = {color[1], color[2], color[3]}
  end

  -- Go over every color then check and store which is the closest CC color (and distance).
  -- Once complete, store the closest color in the lookup table and remove it from the colors_lookup table.
  -- Repeat until all colors are matched.
  local function reduce()
    local closest_cc_color = 0
    local closest_color = 0
    local closest_distance = math.huge

    -- For each CC color index...
    for i = 0, 15 do
      -- Get the RGB values for the CC color.
      local cc_color = 2^i
      local cc_data = colors_lookup[cc_color]

      -- If the CC color exists...
      if cc_data then
        -- For each color in the BMP color table...
        for j = 0, data.colors_used - 1 do
          -- Get the RGB values for the BMP color.
          local color = color_table[j]

          -- If the BMP color exists...
          if color then
            -- Calculate the distance between the two colors.
            local distance = 0

            for k = 1, 3 do
              -- We add the square of the difference between the two colors.
              distance = distance + (color[k] - cc_data[k]) ^ 2
            end

            -- If the distance is less than the closest distance, update the closest color.
            if distance < closest_distance then
              closest_distance = distance
              closest_color = j
              closest_cc_color = cc_color
            end
          end
        end

        -- If the closest distance is 0, we can stop looking, we've found an exact match.
        if closest_distance == 0 then
          break
        end
      end
    end

    -- Store the closest color in the lookup table and remove it from the color table.
    lookup_table[closest_color] = closest_cc_color
    color_table[closest_color] = nil
    colors_lookup[closest_cc_color] = nil
  end

  -- Go over every color in the BMP color table, reducing the colors until all are matched.
  -- Yes this is probably inefficient as all hell. Want to make it better?
  -- PRs welcome.
  while next(color_table) do
    reduce()

    if not next(colors_lookup) then
      if not refill then
        error("Not enough colors in the palette to match all colors in the BMP color table.", 2)
      end

      create_lookup()
    end
  end

  return lookup_table
end

return bmp