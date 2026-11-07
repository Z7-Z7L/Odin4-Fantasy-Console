package odin4

import lua "vendor:lua/5.4"
import "core:fmt"

// Lua API

// Clear screen with selected color
l_cls :: proc "c" (L: ^lua.State) -> i32 {
	color := lua.tointeger(L, 1);

	packed_color := u8(color & 0x03);
	fill_byte := (packed_color << 6) | (packed_color << 4) | (packed_color << 2) | packed_color

	for i in 0..<VRAM_SIZE {
		console.ram[VRAM_ADDR + i] = fill_byte
	}

	return 0;
}

// Change color palette
l_set_palette :: proc "c" (L: ^lua.State) -> i32 {
	id := lua.tointeger(L, 1);
	if (id == 0) {console.palette = Blueprint_Palette;}
	if (id == 1) {console.palette = Gameboy_Palette;}
	if (id == 2) {console.palette = Luminous_Palette;}
	if (id == 3) {console.palette = Grayscale_Palette;}
	return 0;
}

// Draw pixel
draw_pixel :: proc "c" (x,y: i32, color: u8) {
	// Bound Check
	if (x >= 0 && x < WIDTH && y >= 0 && y < HEIGHT) {
		idx := (y * WIDTH) + x;
		shift := u32(6 - (idx & 3) * 2);
		b := &console.ram[VRAM_ADDR + (idx >> 2)];
		b^ = (b^ & ~(u8(0b11) << shift)) | ((color & 0b11) << shift);
	}
}

l_pset :: proc "c" (L: ^lua.State) -> i32 {
	x 		:= i32(lua.tointeger(L, 1));
	y 		:= i32(lua.tointeger(L, 2));
	color := u8(lua.tointeger(L, 3));

	draw_pixel(x,y,color);

	return 0;
}

// Draw rect
l_rect :: proc "c" (L: ^lua.State) -> i32 {
	x0 		:= i32(lua.tointeger(L, 1));
	y0 		:= i32(lua.tointeger(L, 2));
	x1 		:= i32(lua.tointeger(L, 3));
	y1 		:= i32(lua.tointeger(L, 4));
	color := u8(lua.tointeger(L, 5));

	for x in x0..=x1 {
		for y in y0..=y1 {
			// draw only the edges
			if (y == y0 || y == y1 || x == x0 || x == x1) {
				// screen bound check
				if (x >= 0 && x < WIDTH && y >= 0 && y < HEIGHT) {
					draw_pixel(x, y, color)
				}
			}
		}
	}

	return 0;
}

l_rectfill :: proc "c" (L: ^lua.State) -> i32 {
	x0 		:= i32(lua.tointeger(L, 1));
	y0 		:= i32(lua.tointeger(L, 2));
	x1 		:= i32(lua.tointeger(L, 3));
	y1 		:= i32(lua.tointeger(L, 4));
	color := u8(lua.tointeger(L, 5));

	for x in x0..=x1 {
		for y in y0..=y1 {
			// screen bound check
			if (x >= 0 && x < WIDTH && y >= 0 && y < HEIGHT) {
				draw_pixel(x, y, color)
			}
		}
	}

	return 0;
}

// Draw sprite
draw_sprite :: proc "c" (sprite_id: u8, x,y:i32, flip_x, flip_y: b32) {
	// If sprite id isn't correct don't draw
	if (sprite_id < 0 || sprite_id > SPRITE_COUNT) {return}

	// the sprite uses 16bytes
	sprite_addr := SPRITES_ADDR + u32(sprite_id * 16);

	for row in 0..<8 {
		actual_row := flip_y ? (7-row) : row;

		row_byte0 := console.ram[sprite_addr + u32(actual_row * 2)];
		row_byte1 := console.ram[sprite_addr + u32(actual_row * 2) + 1];

		target_y := y + i32(row);

		for sx in 0..<8 {
			actual_sx := flip_x ? (7-sx) : sx;

			b_data := (actual_sx < 4) ? row_byte0 : row_byte1;
			shift := u32(6 - (u8(actual_sx & 3) * 2));
			pixel := (b_data >> shift) & 0b11;

			// if pixel color is 0 ignore
			if (pixel != 0) {
				idx := (target_y * WIDTH) + (x+i32(sx));

				// screen bounds check to prevent out-of-bounds crashes
				if (x + i32(sx) >= 0 && x + i32(sx) < WIDTH && target_y >= 0 && target_y < HEIGHT) {
					vram_shift := u32(6 - (idx & 3) * 2)
					b := &console.ram[VRAM_ADDR + (idx >> 2)];
					b^ = (b^ & ~(u8(0b11) << vram_shift)) | ((pixel & 0b11) << vram_shift);
				}
			}
		}
	}
}

l_spr :: proc "c" (L: ^lua.State) -> i32 {
	sprite_id := u8(lua.tointeger(L, 1));
	x 			  := i32(lua.tointeger(L, 2));
	y 		    := i32(lua.tointeger(L, 3));
	flip_x    := lua.toboolean(L, 4);
	flip_y    := lua.toboolean(L, 5);

	draw_sprite(sprite_id,x,y,flip_x,flip_y);

	return 0;
}

l_map :: proc "c" (L: ^lua.State) -> i32 {
	cell_x          := lua.tointeger(L, 1); // start x pos on the tilemap
	cell_y          := lua.tointeger(L, 2); // start y pos on the tilemap
	screen_x 				:= lua.tointeger(L, 3); // start x pos on the screen
	screen_y 			  := lua.tointeger(L, 4); // start y pos on the screen
	width_in_cells  := lua.tointeger(L, 5); // how many tiles to draw from cell_x
	height_in_cells := lua.tointeger(L, 6); // how many tiles to draw from cell_y

	// Check if in range
	if (cell_x < 0 || cell_y < 0 || cell_x + width_in_cells > 40 ||cell_y + height_in_cells > 25) {return 0}

	// sy: start y, sx: start x (for the tile)
	for sy in cell_y..<(cell_y+height_in_cells) {
		for sx in cell_x..<(cell_x+width_in_cells) {
			tile_idx := TILEMAP_ADDR + ((sy * 40) + sx);
			tile_id := console.ram[tile_idx]

			x := i32(screen_x + ((sx - cell_x) * 8));
			y := i32(screen_y + ((sy - cell_y) * 8));

			draw_sprite(tile_id, x, y, false, false);
		}
	}

	return 0;
}

// returns frame counter value 0-255
l_frame_count :: proc "c" (L: ^lua.State) -> i32 {
	frames := console.ram[FRAME_COUNTER_REG_ADDR];
	lua.pushinteger(L, lua.Integer(frames));
	return 1;
}

// Check if button pressed
l_btn :: proc "c" (L: ^lua.State) -> i32 {
	id := lua.tointeger(L, 1);

	// Safety check: ensure id is between 0 and 5 so Odin doesn't crash
	if (id < 0 || id > 5) {
		lua.pushboolean(L, false);
		return 1;
	}

	input_byte := console.ram[INPUT_REG_ADDR];

	is_pressed := (input_byte & (u8(1) << u8(id))) != 0;

	lua.pushboolean(L, b32(is_pressed));
	return 1;
}

// audio
l_sfx_ch1 :: proc "c" (L: ^lua.State) -> i32 {
	console.ch1.frequency = u16(lua.tointeger(L, 1));
	console.ch1.volume 		= u8(lua.tointeger(L, 2));
	console.ch1.duration  = u16(lua.tointeger(L, 3));
	console.ch1.slide 		= i8(lua.tointeger(L, 4));
	console.ch1.duty 			= u8(lua.tointeger(L, 5));
	console.ch1.phase 		= 0;

	return 0;
}

l_sfx_ch2 :: proc "c" (L: ^lua.State) -> i32 {
	console.ch2.frequency = u16(lua.tointeger(L, 1));
	console.ch2.volume 		= u8(lua.tointeger(L, 2));
	console.ch2.duration  = u16(lua.tointeger(L, 3));
	console.ch2.phase 		= 0;

	return 0;
}

l_sfx_stop :: proc "c" (L: ^lua.State) -> i32 {
	channel := lua.tointeger(L, 1);

	if (channel == 1) {
		console.ch1.volume = 0;
		console.ch1.duration = 0;
	}
	else if (channel == 2) {
		console.ch2.volume = 0;
		console.ch2.duration = 0;
	}

	return 0;
}

// Check sprite flag
l_check_flag :: proc "c" (L: ^lua.State) -> i32 {
	spr_id := lua.tointeger(L, 1);
	flag   := u8(lua.tointeger(L, 2));

	if ((spr_id < 0 || spr_id > 127) || (flag < 0 || flag > 7)) {return 0;}

	val := console.ram[FLAGS_ADDR + spr_id] >> flag & 0b1;
	lua.pushinteger(L, lua.Integer(val));
	return 1;
}

// peek
l_peek :: proc "c" (L: ^lua.State) -> i32 {
	addr := lua.tointeger(L, 1);

	target_addr := USER_ADDR + addr;
	if (addr < 0 || target_addr >= len(console.ram)) {return 0}

	val := console.ram[target_addr];
	lua.pushinteger(L, lua.Integer(val));

	return 1;
}

// poke
l_poke :: proc "c" (L: ^lua.State) -> i32 {
	addr := lua.tointeger(L, 1);
	val  := lua.tointeger(L, 2);

	target_addr := USER_ADDR + addr;

	if (addr < 0 || val < 0 || val > 255 || target_addr >= len(console.ram)) {return 0}
	console.ram[target_addr] = u8(val);

	return 0;
}

// text (Draws text on the screen)
l_text :: proc "c" (L: ^lua.State) -> i32 {
	text 		:= string(lua.tostring(L, 1));
	start_x := i32(lua.tointeger(L, 2));
	start_y := i32(lua.tointeger(L, 3));
	color   := u8(lua.tointeger(L, 4)); // 0-3 from the palette

	current_x := start_x;
	current_y := start_y;

	for i in 0..<len(text) {
		char := text[i];

		// Handle lowercase characters by automatically converting to uppercase
		lookup_char := char;
		if (char >= 'a' && char <= 'z') {lookup_char = char - 32;}

		// Handle new lines
		if (char == '\n') {
			current_x = start_x;
			current_y += 6; // 5 pixel is the letter height and 1 pixel for the space
			continue
		}

		// Map ASCII to our FONT_TABLE index (Space is 32)
		font_index := int(lookup_char) - 32;

		if (font_index >= 0 && font_index < len(FONT_TABLE)) {
			glyph := FONT_TABLE[font_index];

			// Render the text
			for row in 0..<5 {
				row_data := glyph.rows[row];

				for col in 0..<3 {
					// Check if the bit is set from left to right
          bit_mask := u8(1 << uint(2 - col));
          if ((row_data & bit_mask) != 0) {
          	draw_pixel(current_x + i32(col), current_y + i32(row), color);
          }
				}
			}
		}
		// Advance cursor right by 4 pixels (3 width + 1 pixel character spacing)
		current_x += 4;
	}

	return 0;
}

l_get_width :: proc "c" (L: ^lua.State) -> i32 {
	lua.pushinteger(L, WIDTH);
	return 1;
}

l_get_height :: proc "c" (L: ^lua.State) -> i32 {
	lua.pushinteger(L, HEIGHT);
	return 1;
}

register_lua_bindings :: proc(L: ^lua.State) {
	lua.pushcfunction(L, l_cls);
	lua.setglobal(L, "cls");

	lua.pushcfunction(L, l_set_palette);
	lua.setglobal(L, "set_palette");

	lua.pushcfunction(L, l_pset);
	lua.setglobal(L, "pset");

	lua.pushcfunction(L, l_rect);
	lua.setglobal(L, "rect");

	lua.pushcfunction(L, l_rectfill);
	lua.setglobal(L, "rectfill");

	lua.pushcfunction(L, l_btn);
	lua.setglobal(L, "btn");

	lua.pushcfunction(L, l_spr);
	lua.setglobal(L, "spr");

	lua.pushcfunction(L, l_map);
	lua.setglobal(L, "map");

	lua.pushcfunction(L, l_frame_count);
	lua.setglobal(L, "frame_count");

	lua.pushcfunction(L, l_sfx_ch1);
	lua.setglobal(L, "sfx_ch1");

	lua.pushcfunction(L, l_sfx_ch2);
	lua.setglobal(L, "sfx_ch2");

	lua.pushcfunction(L, l_peek);
	lua.setglobal(L, "peek");

	lua.pushcfunction(L, l_poke);
	lua.setglobal(L, "poke");

	lua.pushcfunction(L, l_check_flag);
	lua.setglobal(L, "check_flag");

	lua.pushcfunction(L, l_text);
	lua.setglobal(L, "text");

	lua.pushcfunction(L, l_get_width);
	lua.setglobal(L, "get_width");

	lua.pushcfunction(L, l_get_height);
	lua.setglobal(L, "get_height");
}

call_lua_func :: proc(L: ^lua.State, name: cstring) {
	lua.getglobal(L, name);

	// Check if the function exists
	if (!lua.isfunction(L, -1)) {
		lua.pop(L, 1);
		return
	}

	// Call the funciton (0 arguments, 0 return values)
	if (lua.pcall(L, 0,0,0) != 0) {
		err := lua.tostring(L, -1);
		fmt.printf("Lua Runtime Error in '%s': %s\n", name, err);
    lua.pop(L, 1);
	}

}
