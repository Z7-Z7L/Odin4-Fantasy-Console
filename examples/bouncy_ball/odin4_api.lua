---@meta

--------------------------------------------------
-- ODIN4 LUA API
-- Editor-only definitions.
-- Implementations are provided by the Odin runtime.
--------------------------------------------------

---@class Odin4
local odin4 = {}

--------------------------------------------------
-- GRAPHICS
--------------------------------------------------

---Clears the entire screen with a selected color.
---
---Color is a 2-bit palette index (0-3).
---@param color integer Color index (0-3).
function cls(color) end

---Changes the active color palette.
---@param id integer Palette ID:
---| 0 # Blueprint
---| 1 # Gameboy
---| 2 # Luminous
---| 3 # Grayscale
function set_palette(id) end

---Draws a single pixel on the screen.
---@param x integer X coordinate.
---@param y integer Y coordinate.
---@param color integer Color index (0-3).
function pset(x, y, color) end

---Draws an outlined rectangle.
---Coordinates are inclusive.
---@param x0 integer Top-left X coordinate.
---@param y0 integer Top-left Y coordinate.
---@param x1 integer Bottom-right X coordinate.
---@param y1 integer Bottom-right Y coordinate.
---@param color integer Color index (0-3).
function rect(x0, y0, x1, y1, color) end

---Draws a filled rectangle.
---Coordinates are inclusive.
---@param x0 integer Top-left X coordinate.
---@param y0 integer Top-left Y coordinate.
---@param x1 integer Bottom-right X coordinate.
---@param y1 integer Bottom-right Y coordinate.
---@param color integer Color index (0-3).
function rectfill(x0, y0, x1, y1, color) end

---Draws an 8x8 sprite.
---Color 0 is transparent.
---@param sprite_id integer Sprite ID (0-127).
---@param x integer Screen X coordinate.
---@param y integer Screen Y coordinate.
---@param flip_x? boolean Flip horizontally.
---@param flip_y? boolean Flip vertically.
function spr(sprite_id, x, y, flip_x, flip_y) end

---Draws a section of the tilemap.
---Each tile is 8x8 pixels.
---The tilemap is 40x25 cells.
---@param cell_x integer Starting tilemap X coordinate.
---@param cell_y integer Starting tilemap Y coordinate.
---@param screen_x integer Destination screen X coordinate.
---@param screen_y integer Destination screen Y coordinate.
---@param width integer Number of tiles horizontally.
---@param height integer Number of tiles vertically.
function map(cell_x, cell_y, screen_x, screen_y, width, height) end

---Draws text using the built-in 3x5 pixel font.
---Lowercase letters are automatically converted to uppercase.
---Newlines are supported.
---@param str string Text to draw.
---@param x integer Starting X coordinate.
---@param y integer Starting Y coordinate.
---@param color integer Color index (0-3).
function text(str, x, y, color) end

--------------------------------------------------
-- INPUT
--------------------------------------------------

---Checks whether a button is down.
---@param id integer Button ID:
---| 0 # Right
---| 1 # Left
---| 2 # Up
---| 3 # Down
---| 4 # Button A
---| 5 # Button B
---@return boolean down Whether the button is down.
function btn(id) end

--------------------------------------------------
-- SYSTEM
--------------------------------------------------

---Returns the current frame counter.
---The counter ranges from 0 to 255.
---@return integer frames Current frame counter.
function frame_count() end

---Returns screen width.
---@return integer screen width.
function get_width() end

---Returns screen height.
---@return integer screen height.
function get_height() end

--------------------------------------------------
-- AUDIO
--------------------------------------------------

---Plays a sound effect on audio channel 1.
---@param frequency integer Sound frequency in Hz.
---@param volume integer Volume (0-255).
---@param duration integer Duration in frames.
---@param slide integer Frequency slide per frame.
---@param duty integer Waveform duty setting.
function sfx_ch1(frequency, volume, duration, slide, duty) end

---Plays a sound effect on audio channel 2.
---@param frequency integer Sound frequency in Hz.
---@param volume integer Volume (0-255).
---@param duration integer Duration in frames.
function sfx_ch2(frequency, volume, duration) end

---Stops a sound effect on the specified channel.
---NOTE: This function must be registered in Odin
---before it becomes available in Lua.
---@param channel integer Audio channel (1 or 2).
function sfx_stop(channel) end

--------------------------------------------------
-- SPRITE FLAGS
--------------------------------------------------

---Checks whether a sprite flag is enabled.
---@param sprite_id integer Sprite ID (0-127).
---@param flag integer Flag index (0-7).
---@return integer value 0 or 1.
function check_flag(sprite_id, flag) end

--------------------------------------------------
-- MEMORY
--------------------------------------------------

---Reads a byte from user-accessible memory.
---The address is relative to USER_ADDR.
---@param address integer Memory offset.
---@return integer value Byte value (0-255).
function peek(address) end

---Writes a byte to user-accessible memory.
---The address is relative to USER_ADDR.
---@param address integer Memory offset.
---@param value integer Byte value (0-255).
function poke(address, value) end

return odin4
