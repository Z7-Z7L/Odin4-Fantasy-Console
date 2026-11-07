local pos = {x = 45, y = 80}
local rec = {width = 10, height = 10}
local vel = {x = 1, y = 1}
local col_count = 1 -- collision count

local current_palette = 0
local palette_timer = 0

function _init()

end

function _update()
  -- apply velocity
  pos.x = pos.x + vel.x
  pos.y = pos.y + vel.y

  -- palette timer
  palette_timer = palette_timer + 1

  -- collision
  if pos.x >= get_width() - rec.width then
    vel.x = -math.random(1, 3)
    col_count = col_count + 1
  end

  if pos.x <= 0 then
    vel.x = math.random(1, 3)
    col_count = col_count + 1
  end

  if pos.y >= get_height() - rec.height then
    vel.y = -math.random(1, 3)
    col_count = col_count + 1
  end

  if pos.y <= 0 then
    vel.y = math.random(1, 3)
    col_count = col_count + 1
  end

  -- changing palette for every 50 frames
  if palette_timer >= 50 then
    palette_timer = 0
    current_palette = (current_palette + 1) % 4
  end

  set_palette(current_palette)
end

function _draw()
  cls(0)
  text(tostring(col_count),0,0, 1)
  rectfill(pos.x, pos.y, pos.x + rec.width, pos.y + rec.height, 2)
end
