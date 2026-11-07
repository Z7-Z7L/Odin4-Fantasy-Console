package editor

import "core:path/filepath"
import "core:math"
import rl "vendor:raylib"
import "core:fmt"
import "core:os"

Blueprint_Palette :: [4]rl.Color {
	{218, 236, 242, 255},
	{115, 180, 230, 255},
	{82, 131, 204, 255},
	{48, 81, 191, 255},
}
Gameboy_Palette 	:: [4]rl.Color {
	{51, 44, 80, 255},
	{70, 135, 143, 255},
	{148, 227, 68, 255},
	{226, 243, 228, 255},
}
Luminous_Palette 	:: [4]rl.Color {
	{163, 222, 124, 255},
	{161, 162, 127, 255},
	{158, 89, 113, 255},
	{80, 67, 89, 255},
}
Grayscale_Palette :: [4]rl.Color {
	{0, 0, 0, 255},
	{103, 103, 103, 255},
	{182, 182, 182, 255},
	{255, 255, 255, 255},
}

WIDTH, HEIGHT :: 80, 64
FPS :: 60

ResizeAndCenterScreen :: proc(scaler: i32) {
	rl.SetWindowSize(WIDTH * scaler, HEIGHT * scaler);

	rl.SetWindowPosition(
		(rl.GetMonitorWidth(rl.GetCurrentMonitor()) - rl.GetScreenWidth()) / 2,
		(rl.GetMonitorHeight(rl.GetCurrentMonitor()) - rl.GetScreenHeight()) / 2
	);
}
screen_scaler: i32 = 14;

SPRITE_COUNT  :: 128
SPRITES_SIZE  :: ((8*8)*SPRITE_COUNT) / 4
FLAGS_SIZE    :: SPRITE_COUNT // Sprite flags, 1 byte per sprite
TILEMAP_SIZE  :: 40*25 //40:width, 25:height , Stores sprite id to draw it

sprites: 			[SPRITES_SIZE]u8;
sprite_flags: [FLAGS_SIZE]u8;
tilemap: 			[TILEMAP_SIZE]u8;

EDITORS :: enum {
	Sprite,
	Tilemap,
}

main :: proc() {
	folder := os.args[1];

	if (!os.is_dir(folder)) {
		fmt.println("Not a folder:", folder);
		return
	}

	// assets.bin path
	assets_path := filepath.join({folder, "assets.bin"}, context.temp_allocator);

  // Initialization
  rl.InitWindow(WIDTH * screen_scaler, HEIGHT * screen_scaler, "Odin4 editor");
  rl.SetTargetFPS(FPS);

  // Load assets.bin file if there is one
  LoadAssets(assets_path);

  mouse_pos: rl.Vector2;

  camera: rl.Camera2D;
  camera.target = 0;
  camera.offset = 0
  camera.zoom = 1;

  save_btn := CreateBTN({71.5,1.5}, 7,3, "SAVE", rl.DARKBLUE, rl.RAYWHITE);
  sprite_btn := CreateBTN({1.5,1.5}, 7,3, "SPR", rl.SKYBLUE, rl.RAYWHITE);
  sprite_btn.selected = true;
  tilemap_btn := CreateBTN({10,1.5}, 7,3, "MAP", rl.BLUE, rl.RAYWHITE);

  current_editor: EDITORS = .Sprite;

  // 0-127
  selected_sprite: u8 = 0;
  prev_selected_sprite: u8 = 255;

  // 0-3
  selected_palette: u8 = 0;
  palette := Blueprint_Palette;

  next_palette_btn := CreateBTN({75,9}, 2,2, ">", rl.BLUE, rl.RAYWHITE);
  prev_palette_btn := CreateBTN({70,9}, 2,2, "<", rl.BLUE, rl.RAYWHITE);

  spr_flag_data: u8;

  // 0-5, each page hold 24 sprites
  spr_page: u8;

  next_sprpage_btn := CreateBTN({65,29}, 4,4, ">", rl.BLUE, rl.RAYWHITE);
  prev_sprpage_btn := CreateBTN({50,29}, 4,4, "<", rl.BLUE, rl.RAYWHITE);

  map_next_sprpage_btn := CreateBTN({63,35}, 2,2, ">", rl.BLUE, rl.RAYWHITE);
  map_prev_sprpage_btn := CreateBTN({52.7,35}, 2,2, "<", rl.BLUE, rl.RAYWHITE);

  // Flag buttons
  flag_btns: [8]BTN = {
	  CreateBTN({31, 9}, 3,3, "0",  {153,204,255,255}, {40,20,61,255}),
	  CreateBTN({35, 9}, 3,3, "1",  {153,153,255,255}, {40,20,61,255}),
	  CreateBTN({39, 9}, 3,3, "2",  {204,153,255,255}, {40,20,61,255}),
	  CreateBTN({43, 9}, 3,3, "3",  {255,153,255,255}, {40,20,61,255}),
	  CreateBTN({31, 13}, 3,3, "4", {204,229,255,255}, {40,20,61,255}),
	  CreateBTN({35, 13}, 3,3, "5", {204,204,255,255}, {40,20,61,255}),
	  CreateBTN({39, 13}, 3,3, "6", {229,204,255,255}, {40,20,61,255}),
	  CreateBTN({43, 13}, 3,3, "7", {255,204,255,255}, {40,20,61,255}),
  }

  // Sprite select buttons
  spr_sel_btns: [24]BTN;
  for &b, i in spr_sel_btns {
 		row := f32(i / 8);

  	pos: rl.Vector2 = {
	   	4 + (f32(i) - (row * 8)) * 9, // Increase X per col
	    35 + row * 9 // Increase Y per row
    };

    b = CreateBTN(pos, 8,8, "", {255,165,74,255}, {}, true);
  }

  // Sprite select buttons (TILEMAP)
  map_spr_sel_btns: [24]BTN;
  for &b, i in map_spr_sel_btns {
 		row := f32(i / 8);

  	pos: rl.Vector2 = {
	    3 + (f32(i) - (row * 8)) * 9, // Increase X per col
	    38 + row * 9 // Increase Y per row
    };

    b = CreateBTN(pos, 8,8, "", {255,165,74,255}, {}, true);
  }

  // 0-127
  map_selected_spr: u8;

  // 0-1, moves the tiles in the map to show the bottom 10 tiles
  map_row: u8;

  map_row_up   := CreateBTN({75.3,15}, 3,3, "/\\", rl.BLUE, rl.RAYWHITE);
  map_row_down := CreateBTN({75.3,20}, 3,3, "\\/", rl.BLUE, rl.RAYWHITE);

  // current pixel color 0-3
  current_color: u8;

  color_btns: [4]BTN = {
  	CreateBTN({54, 9},  3,3, "0", palette[0],  {40,20,61,255}),
  	CreateBTN({58, 9},  3,3, "1", palette[1],  {40,20,61,255}),
  	CreateBTN({54, 13},  3,3, "2", palette[2], {40,20,61,255}),
  	CreateBTN({58, 13},  3,3, "3", palette[3], {40,20,61,255}),
  }
  color_btns[0].selected = true;

  // Map tile buttons
  map_tile_btns: [40*15]BTN;
  for y in 0..<15 {
  	for x in 0..<40 {
   		idx := (y * 40) + x;
     	b := &map_tile_btns[idx];

      pos: rl.Vector2 = {
      	f32(x) * 1.84,
       	6 + (f32(y) * 1.84)
      };


      b^ = CreateBTN(pos, 1.84,1.84, "", {255,165,74,255}, {}, true);
   	}
  }

  for (!rl.WindowShouldClose()) {
    // Update
    dt := rl.GetFrameTime();

    // Change palette
    if (selected_palette == 0) {palette = Blueprint_Palette}
    if (selected_palette == 1) {palette = Gameboy_Palette}
    if (selected_palette == 2) {palette = Luminous_Palette}
    if (selected_palette == 3) {palette = Grayscale_Palette}

    // Mouse pos
    mouse_pos = rl.GetScreenToWorld2D(rl.GetMousePosition(),camera) / f32(screen_scaler);

    // Scale the screen
    if (rl.IsKeyPressed(.ONE) && screen_scaler > 1) {
    	screen_scaler -= 1;
     ResizeAndCenterScreen(screen_scaler);
    }
    if (rl.IsKeyPressed(.TWO)) {
    	screen_scaler += 1;
     	ResizeAndCenterScreen(screen_scaler);
    }

    // Update Bar Buttons
    UpdateBTN(&save_btn, mouse_pos);
    UpdateBTN(&sprite_btn, mouse_pos);
    UpdateBTN(&tilemap_btn, mouse_pos);

    // Buttons
    if (save_btn.state == .PRESSED) {SaveToAssets(assets_path)}
    if (sprite_btn.state == .PRESSED) {
    	current_editor = .Sprite;
    	sprite_btn.selected = true;
    	tilemap_btn.selected = false;
    }
    if (tilemap_btn.state == .PRESSED) {
    	current_editor = .Tilemap;
      tilemap_btn.selected = true;
    	sprite_btn.selected = false;
    }

    // Sprite editor
    if (current_editor == .Sprite) {
	   	UpdateBTN(&next_palette_btn, mouse_pos);
	    UpdateBTN(&prev_palette_btn, mouse_pos);
	    UpdateBTN(&next_sprpage_btn, mouse_pos);
	    UpdateBTN(&prev_sprpage_btn, mouse_pos);

			for &b, i in spr_sel_btns {
				UpdateBTN(&b, mouse_pos);

				if (b.state == .PRESSED) {
					// btn index with page
					idx_wp:u8 = u8(i) + u8(spr_page * 24);
					if (idx_wp < 128) {
						selected_sprite = idx_wp;
					}
				}
			}

			// Color buttons
			for &b, i in color_btns {
				UpdateBTN(&b, mouse_pos);
				b.color = palette[i];
			}

	    if (next_palette_btn.state == .PRESSED && selected_palette != 3) {selected_palette += 1}
			if (prev_palette_btn.state == .PRESSED && selected_palette != 0) {selected_palette -= 1}

   		if (next_sprpage_btn.state == .PRESSED && spr_page != 5) {spr_page += 1}
    	if (prev_sprpage_btn.state == .PRESSED && spr_page != 0) {spr_page -= 1}

      // SYNC Flags when selected sprite changes
      if (selected_sprite != prev_selected_sprite) {
      	spr_flag_data = sprite_flags[selected_sprite];

      	// update the buttons state
       	for &b, i in flag_btns {
        	f := spr_flag_data >> u8(i) & 0b1;
         	v := f == 1 ? true : false;
          b.selected = v;
        }

      	prev_selected_sprite = selected_sprite;
      }

     	// Flags
	    for &b, i in flag_btns {
	    	UpdateBTN(&b, mouse_pos);

	     	if(b.state == .PRESSED) {
	      	b.selected = !b.selected;
	      }

	      mask := u8(1) << u8(i);
	      spr_flag_data &= ~mask;
	      spr_flag_data |= u8(b.selected) << u8(i);
	    }

	    sprite_flags[selected_sprite] = spr_flag_data;

			// Color buttons
			for &b, i in color_btns {
				if (b.state == .PRESSED) {current_color = u8(i);}
				b.selected = (i == int(current_color));
			}

			// Drawing
			// pixel size is 2x2 so 2 of x and 2 of y = 1 pixel idx
			if (mouse_pos.x > 3 && mouse_pos.x < 27 && mouse_pos.y > 9 && mouse_pos.y < 33) {
				local_pos := mouse_pos - {3,9};
				pixel: rl.Vector2 = {
					math.floor(local_pos.x / 3),
					math.floor(local_pos.y / 3),
				};

				// Draw the color on the pixel
				if (rl.IsMouseButtonDown(.LEFT)) {
					idx := i32(pixel.y * 8) + i32(pixel.x);
					shift := u32(6 - (idx & 3) * 2);
					b := &sprites[(idx >> 2) + i32(selected_sprite * 16)];
					b^ = (b^ & ~(u8(0b11) << shift)) | ((current_color & 0b11) << shift);
				}
			}
    }
    else { // Tilemap editor
    	for &b, i in map_spr_sel_btns {
				UpdateBTN(&b, mouse_pos);

				if (b.state == .PRESSED) {
					// btn index with page
					idx_wp:u8 = u8(i) + u8(spr_page * 24);
					if (idx_wp < 128) {
						map_selected_spr = idx_wp;
					}
				}
			}

			UpdateBTN(&map_next_sprpage_btn, mouse_pos);
			UpdateBTN(&map_prev_sprpage_btn, mouse_pos);
			UpdateBTN(&map_row_up, mouse_pos);
			UpdateBTN(&map_row_down, mouse_pos);

	 		if (map_next_sprpage_btn.state == .PRESSED && spr_page != 5) {spr_page += 1}
	   	if (map_prev_sprpage_btn.state == .PRESSED && spr_page != 0) {spr_page -= 1}

			if (map_row_up.state == .PRESSED) {map_row = 0;}
			if (map_row_down.state == .PRESSED) {map_row = 1;}

			// Placing sprites on tilemap
			for &b, i in map_tile_btns {
				UpdateBTN(&b, mouse_pos);

				if (b.state == .DOWN) {
					idx := i + (int(map_row) * 400);
					fmt.println(idx);
					tilemap[idx] = map_selected_spr;
				}
			}

    }

    // Draw
    rl.BeginDrawing();
      rl.ClearBackground({0,76,153,255});
      rl.BeginMode2D(camera);
      	// Top Bar
       	rl.DrawRectangle(0, 0, 80*screen_scaler, 6*screen_scaler, {0,0,102,255});

       	// Draw Bar Buttons
      	DrawBTN(save_btn, rl.LIGHTGRAY);
      	DrawBTN(sprite_btn, rl.LIGHTGRAY);
      	DrawBTN(tilemap_btn, rl.LIGHTGRAY);

       	if (current_editor == .Sprite) {
	       	DrawBTN(next_palette_btn, rl.LIGHTGRAY);
			    DrawBTN(prev_palette_btn, rl.LIGHTGRAY);
	       	DrawBTN(next_sprpage_btn, rl.LIGHTGRAY);
	       	DrawBTN(prev_sprpage_btn, rl.LIGHTGRAY);

	       	// Draw selected sprite
	        sprite_base := int(selected_sprite) * 16;
	        pixel_size := screen_scaler * 3;
					DrawSprite(1, 3, sprite_base, f32(pixel_size), palette);

					// Draw sprites grid
					for row in 0..<3 {
						for col in 0..<8 {
							spr_idx := int(spr_page * 24) + (row * 8) + col;

							if (spr_idx < SPRITE_COUNT) {
								spr_base := spr_idx * 16;
								x_pos := 4 + (col * 9);
								y_pos := 35 + (row * 9);

								DrawSprite(i32(x_pos), i32(y_pos), spr_base, f32(screen_scaler), palette);
							}
						}
					}

					// Flag buttons
	       	for b in flag_btns {DrawBTN(b, rl.LIGHTGRAY);}

					// Color buttons
					for b in color_btns {DrawBTN(b, rl.LIGHTGRAY);}

	       	// Current palette number text
	        rl.DrawText(fmt.ctprint(selected_palette), 73*screen_scaler, 9*screen_scaler, 2*screen_scaler, rl.RAYWHITE)

					rl.DrawTextEx(rl.GetFontDefault(), "Palette",
						{70*f32(screen_scaler), 6.5*f32(screen_scaler)},
						2*f32(screen_scaler),2,rl.RAYWHITE
					);

					rl.DrawTextEx(rl.GetFontDefault(), "Flags",
						{36*f32(screen_scaler), 6.5*f32(screen_scaler)},
						2*f32(screen_scaler),2,rl.RAYWHITE
					);

					// Current sprite id text
					rl.DrawTextEx(rl.GetFontDefault(),
						fmt.caprint("sprite id:",selected_sprite),
						{1*f32(screen_scaler), 6.5*f32(screen_scaler)},
						2*f32(screen_scaler),2,rl.RAYWHITE
					);

					// Sprites text
					rl.DrawTextEx(rl.GetFontDefault(), "Sprites",
						{29*f32(screen_scaler), 28*f32(screen_scaler)},
						5*f32(screen_scaler),2,rl.RAYWHITE
					);

					rl.DrawTextEx(rl.GetFontDefault(),
						fmt.caprint("Page:", spr_page),
						{55.4*f32(screen_scaler), 29.7*f32(screen_scaler)},
						2.5*f32(screen_scaler),2,rl.RAYWHITE);

					for b in spr_sel_btns {
						if (b.state == .HOVER) {DrawBTN(b, rl.WHITE);}
					}

					// Colors text
					rl.DrawTextEx(rl.GetFontDefault(), "Colors",
						{54.2*f32(screen_scaler), 6.5*f32(screen_scaler)},
						2*f32(screen_scaler),2,rl.RAYWHITE
					);
        }
        else { // Tilemap editor
        	// tiles
         	for row in 0..<15 {
        		// if map_row = 1 then show shift the i by 10 rows to show the last 10 rows
          	target_row := row + (int(map_row) * 10);
           	if (target_row > 24) {break}

          	for col in 0..<40 {
           		i := (target_row * 40) + col;

             	tile := int(tilemap[i]);

              x_offset:i32 = i32(col) * 8;
              y_offset:i32 = 26 + (i32(row) * 8);

              DrawSprite(x_offset, y_offset, tile * 16, 0.23 * f32(screen_scaler), palette);
           	}
          }

          // Draw sprites grid
					for row in 0..<3 {
						for col in 0..<8 {
							spr_idx := int(spr_page * 24) + (row * 8) + col;

							if (spr_idx < SPRITE_COUNT) {
								spr_base := spr_idx * 16;
								x_pos := 3 + (col * 9);
								y_pos := 38 + (row * 9);

								DrawSprite(i32(x_pos), i32(y_pos), spr_base, f32(screen_scaler), palette);
							}
						}
					}

					// sprite buttons
					for b in map_spr_sel_btns {
						if (b.state == .HOVER) {DrawBTN(b, rl.WHITE);}
					}

					// Next, Prev page buttons
					DrawBTN(map_next_sprpage_btn, rl.LIGHTGRAY);
					DrawBTN(map_prev_sprpage_btn, rl.LIGHTGRAY);
					DrawBTN(map_row_up, rl.LIGHTGRAY);
					DrawBTN(map_row_down, rl.LIGHTGRAY);

					rl.DrawTextEx(rl.GetFontDefault(),
						fmt.caprint("Page:", spr_page),
						{55.4*f32(screen_scaler), 34.9*f32(screen_scaler)},
						2*f32(screen_scaler),2,rl.RAYWHITE);

					for b in map_tile_btns {if (b.state == .HOVER) {DrawBTN(b, rl.WHITE)};}

        }


      rl.EndMode2D();

    rl.EndDrawing();

  }

  // Close the window
  rl.CloseWindow();
}

DrawSprite :: proc(x_offset, y_offset: i32, sprite_base: int, pixel_size: f32, palette: [4]rl.Color) {
	for i in 0..<8 {
	 	row_byte0 := sprites[sprite_base + (i * 2)];
	 	row_byte1 := sprites[sprite_base + (i * 2) + 1];

   	y := i32(i) + y_offset;

    // First 4 pixels
    for b in 0..<4 {
   		shift := u8((3-b) * 2);
    	p_val := (row_byte0 >> shift) & 0b11;

     	px := i32(b) + x_offset;
      x_:f32 = f32(px) * pixel_size;
      y_:f32 = f32(y) * pixel_size;

      // rl.DrawRectangle(x_, y_, pixel_size, pixel_size, palette[p_val]);
      rl.DrawRectangleRec({f32(x_), f32(y_), pixel_size, pixel_size}, palette[p_val]);
    }

    // Last 4 pixels
    for b in 0..<4 {
   		shift := u8((3-b) * 2);
    	p_val := (row_byte1 >> shift) & 0b11;

     	px := 4 + i32(b) + x_offset;
      x_:f32 = f32(px) * pixel_size;
      y_:f32 = f32(y)* pixel_size;

      // rl.DrawRectangle(x_, y_, pixel_size, pixel_size, palette[p_val]);
      rl.DrawRectangleRec({f32(x_), f32(y_), pixel_size, pixel_size}, palette[p_val]);
    }
	}
}

BTN_STATE :: enum {
	None,
	PRESSED,
	HOVER,
	DOWN,
}

BTN :: struct {
	pos: rl.Vector2,
	hitbox: rl.Rectangle,
	text: cstring,
	state: BTN_STATE,

	color, text_color: rl.Color,

	selected: bool,
	outline: bool,
}

CreateBTN :: proc(pos: rl.Vector2, hitbox_width, hitbox_height: f32, text: cstring, color,text_color: rl.Color, outline: bool = false) -> BTN {
	btn: BTN;

  btn.pos = pos;
  btn.hitbox = {pos.x, pos.y, hitbox_width,hitbox_height};
  btn.text = text;
  btn.color = color;
  btn.text_color = text_color;
  btn.outline = outline;

	return btn;
}

UpdateBTN :: proc(btn: ^BTN, mouse_pos: rl.Vector2) {
	// Hover
	if (rl.CheckCollisionPointRec(mouse_pos, btn.hitbox)) {
		if (rl.IsMouseButtonPressed(.LEFT)) {btn.state = .PRESSED}
		else if (rl.IsMouseButtonDown(.LEFT)) {btn.state = .DOWN}
		else {btn.state = .HOVER}
	}
	else {btn.state = .None}
}

DrawBTN :: proc(btn: BTN, tint_color: rl.Color) {
	color: rl.Color;
	font_color: rl.Color;

	if (btn.state == .HOVER && !btn.selected) {
		color = rl.ColorTint(btn.color, tint_color);
	} else {color = btn.color}

	if (btn.state == .HOVER && !btn.selected) {
		font_color = rl.ColorTint(btn.text_color, tint_color);
	} else {font_color = btn.text_color}

	// if button selected swap the hitbox and text colors
	if (btn.selected) {color, font_color = font_color, color;}

	if (btn.outline) {
		rl.DrawRectangleLinesEx({
	    btn.pos.x * f32(screen_scaler),
	    btn.pos.y * f32(screen_scaler),
	    btn.hitbox.width * f32(screen_scaler),
	    btn.hitbox.height * f32(screen_scaler)
  	}, 5, color);
	}
	else {
	  rl.DrawRectangleRec({
	    btn.pos.x * f32(screen_scaler),
	    btn.pos.y * f32(screen_scaler),
	    btn.hitbox.width * f32(screen_scaler),
	    btn.hitbox.height * f32(screen_scaler)
	  }, color);
	}

  font_size := i32(screen_scaler) * 2;
  text_size := rl.MeasureText(btn.text, font_size);

  center_x := (btn.pos.x + btn.hitbox.width / 2) * f32(screen_scaler);
  center_y := (btn.pos.y + btn.hitbox.height / 2) * f32(screen_scaler);

  rl.DrawText(
    btn.text,
    i32(center_x) - text_size / 2,
    i32(center_y) - font_size / 2,
    font_size,
    font_color
  );

}

// Saves assets to assets.bin file
SaveToAssets :: proc(file_path: string) {
	out_data := make([]u8, len(sprites) + len(sprite_flags) + len(tilemap));
	defer delete(out_data);

	// copy assets onto outdata
	copy(out_data, sprites[:]);
	copy(out_data[SPRITES_SIZE:], sprite_flags[:]);
	copy(out_data[SPRITES_SIZE+FLAGS_SIZE:], tilemap[:]);

	ok := os.write_entire_file(file_path, out_data);
	if (!ok) {
		fmt.println("Failed to write assets!");
	}
}

LoadAssets :: proc(file_path: string) {
	data, ok := os.read_entire_file_from_filename(file_path);
	defer delete(data);

	// if there isn't assets don't load
	if (!ok) {return}

	if (len(data) < SPRITES_SIZE + FLAGS_SIZE + TILEMAP_SIZE) {
		fmt.println("Warning: assets.bin in incomplete!");
		return;
	}

	copy(sprites[:], data[:SPRITES_SIZE]);
	copy(sprite_flags[:], data[SPRITES_SIZE:SPRITES_SIZE + FLAGS_SIZE]);
	copy(tilemap[:], data[SPRITES_SIZE + FLAGS_SIZE: SPRITES_SIZE + FLAGS_SIZE + TILEMAP_SIZE]);

}
