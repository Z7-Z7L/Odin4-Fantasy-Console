package odin4

import "core:strings"
import rl "vendor:raylib"
import "core:fmt"
import lua "vendor:lua/5.4"
import "core:os"
import "core:math/rand"

/* ---- Font ----*/
// Defines a 3x5 bitmap glyph
Font_3x5 :: struct {
  rows: [5]u8, // 3 bits per row (left to right)
}

// Compact ASCII font table starting from space (ASCII 32) up to 'Z' (ASCII 90)
FONT_TABLE := [?]Font_3x5{
  // 32: ' ' (Space)
  { rows = { 0b000, 0b000, 0b000, 0b000, 0b000 } },
  // 33: '!'
  { rows = { 0b010, 0b010, 0b010, 0b000, 0b010 } },
  // 34: '"'
  { rows = { 0b101, 0b101, 0b000, 0b000, 0b000 } },
  // 35: '#'
  { rows = { 0b101, 0b111, 0b101, 0b111, 0b101 } },
  // 36: '$'
  { rows = { 0b010, 0b111, 0b010, 0b111, 0b010 } },
  // 37: '%'
  { rows = { 0b101, 0b010, 0b100, 0b010, 0b101 } },
  // 38: '&'
  { rows = { 0b010, 0b101, 0b010, 0b101, 0b010 } },
  // 39: '''
  { rows = { 0b010, 0b010, 0b000, 0b000, 0b000 } },
  // 40: '('
  { rows = { 0b010, 0b100, 0b100, 0b100, 0b010 } },
  // 41: ')'
  { rows = { 0b010, 0b001, 0b001, 0b001, 0b010 } },
  // 42: '*'
  { rows = { 0b000, 0b101, 0b010, 0b101, 0b000 } },
  // 43: '+'
  { rows = { 0b000, 0b010, 0b111, 0b010, 0b000 } },
  // 44: ','
  { rows = { 0b000, 0b000, 0b000, 0b010, 0b100 } },
  // 45: '-' (Hyphen/Dash)
  { rows = { 0b000, 0b000, 0b111, 0b000, 0b000 } },
  // 46: '.'
  { rows = { 0b000, 0b000, 0b000, 0b000, 0b010 } },
  // 47: '/'
  { rows = { 0b001, 0b010, 0b010, 0b100, 0b100 } },

  // 48-57: Numbers '0' to '9'
  { rows = { 0b111, 0b101, 0b101, 0b101, 0b111 } }, // '0'
  { rows = { 0b010, 0b110, 0b010, 0b010, 0b111 } }, // '1'
  { rows = { 0b111, 0b001, 0b111, 0b100, 0b111 } }, // '2'
  { rows = { 0b111, 0b001, 0b011, 0b001, 0b111 } }, // '3'
  { rows = { 0b101, 0b101, 0b111, 0b001, 0b001 } }, // '4'
  { rows = { 0b111, 0b100, 0b111, 0b001, 0b111 } }, // '5'
  { rows = { 0b111, 0b100, 0b111, 0b101, 0b111 } }, // '6'
  { rows = { 0b111, 0b001, 0b010, 0b010, 0b010 } }, // '7'
  { rows = { 0b111, 0b101, 0b111, 0b101, 0b111 } }, // '8'
  { rows = { 0b111, 0b101, 0b111, 0b001, 0b111 } }, // '9'

  // 58: ':'
  { rows = { 0b000, 0b010, 0b000, 0b010, 0b000 } },
  // 59: ';'
  { rows = { 0b000, 0b010, 0b000, 0b010, 0b100 } },
  // 60: '<'
  { rows = { 0b001, 0b010, 0b100, 0b010, 0b001 } },
  // 61: '='
  { rows = { 0b000, 0b111, 0b000, 0b111, 0b000 } },
  // 62: '>'
  { rows = { 0b100, 0b010, 0b001, 0b010, 0b100 } },
  // 63: '?'
  { rows = { 0b111, 0b001, 0b010, 0b000, 0b010 } },
  // 64: '@'
  { rows = { 0b111, 0b101, 0b111, 0b100, 0b111 } },

  // 65-90: Uppercase Letters 'A' to 'Z'
  { rows = { 0b010, 0b101, 0b111, 0b101, 0b101 } }, // A
  { rows = { 0b110, 0b101, 0b110, 0b101, 0b110 } }, // B
  { rows = { 0b011, 0b100, 0b100, 0b100, 0b011 } }, // C
  { rows = { 0b110, 0b101, 0b101, 0b101, 0b110 } }, // D
  { rows = { 0b111, 0b100, 0b110, 0b100, 0b111 } }, // E
  { rows = { 0b111, 0b100, 0b110, 0b100, 0b100 } }, // F
  { rows = { 0b011, 0b100, 0b101, 0b101, 0b011 } }, // G
  { rows = { 0b101, 0b101, 0b111, 0b101, 0b101 } }, // H
  { rows = { 0b111, 0b010, 0b010, 0b010, 0b111 } }, // I
  { rows = { 0b001, 0b001, 0b001, 0b101, 0b010 } }, // J
  { rows = { 0b101, 0b110, 0b100, 0b110, 0b101 } }, // K
  { rows = { 0b100, 0b100, 0b100, 0b100, 0b111 } }, // L
  { rows = { 0b101, 0b111, 0b101, 0b101, 0b101 } }, // M
  { rows = { 0b101, 0b111, 0b111, 0b101, 0b101 } }, // N
  { rows = { 0b010, 0b101, 0b101, 0b101, 0b010 } }, // O
  { rows = { 0b110, 0b101, 0b110, 0b100, 0b100 } }, // P
  { rows = { 0b010, 0b101, 0b101, 0b110, 0b011 } }, // Q
  { rows = { 0b110, 0b101, 0b110, 0b101, 0b101 } }, // R
  { rows = { 0b011, 0b100, 0b010, 0b001, 0b110 } }, // S
  { rows = { 0b111, 0b010, 0b010, 0b010, 0b010 } }, // T
  { rows = { 0b101, 0b101, 0b101, 0b101, 0b111 } }, // U
  { rows = { 0b101, 0b101, 0b101, 0b010, 0b010 } }, // V
  { rows = { 0b101, 0b101, 0b101, 0b111, 0b101 } }, // W
  { rows = { 0b101, 0b101, 0b010, 0b101, 0b101 } }, // X
  { rows = { 0b101, 0b101, 0b010, 0b010, 0b010 } }, // Y
  { rows = { 0b111, 0b001, 0b010, 0b100, 0b111 } }, // Z
}

/* ---- Palettes ---- */
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

/* ---- Specs ---- */
WIDTH, HEIGHT :: 128, 128
FPS :: 60

/* ---- Region size ---- */
RAM_SIZE   :: 16 * 1024 // 16KB
VRAM_SIZE  :: (WIDTH * HEIGHT) / 4 // 2bpp, each byte holds 4 pixels

SPRITE_W, SPRITE_H :: 8,8
SPRITE_COUNT 			 :: 128

// 8x8=64pixels per sprite * 128 sprites count / 4 2bpp 4 pixels per byte
SPRITES_SIZE 			 		 :: ((SPRITE_W*SPRITE_H)*SPRITE_COUNT) / 4
FLAGS_SIZE         		 :: SPRITE_COUNT // Sprite flags, 1 byte per sprite
TILEMAP_SIZE       		 :: 40*25 //40:width, 25:height , Stores sprite id to draw it

// Hardware regs
INPUT_REG_SIZE     		 :: 1 // Player input in one byte
FRAME_COUNTER_REG_SIZE :: 1 // System frame tick

// Channel 1: Pulse Wave (Melodies & Tonal SFX)
CH1_FREQ_REG_SIZE  		 :: 1 // Pitch / Frequency value
CH1_VOL_DUTY_REG_SIZE  :: 1 // Volume and Waveform Shape.
CH1_DURATION_REG_SIZE  :: 1 // Sound Length in frames
CH1_SLIDE_REG_SIZE  	 :: 1 // Pitch Slide

// Channel 2: Noise Wave (Percussion & Explosions)
CH2_FREQ_REG_SIZE 		:: 1 // Noise Clock / Timbre
CH2_VOL_REG_SIZE  		:: 1 // Volume. (0 - 15)
CH2_DURATION_REG_SIZE :: 1 // Sound Length in frames

/* ---- Region address ---- */
VRAM_ADDR    			     :: 0x0000
SPRITES_ADDR 			     :: VRAM_ADDR + VRAM_SIZE
FLAGS_ADDR   			     :: SPRITES_ADDR + SPRITES_SIZE
TILEMAP_ADDR 			     :: FLAGS_ADDR + FLAGS_SIZE

// Input & Frame Counter
INPUT_REG_ADDR    		 :: TILEMAP_ADDR + TILEMAP_SIZE
FRAME_COUNTER_REG_ADDR :: INPUT_REG_ADDR + INPUT_REG_SIZE

// Channel 1
CH1_FREQ_REG_ADDR      :: FRAME_COUNTER_REG_ADDR + FRAME_COUNTER_REG_SIZE
CH1_VOL_DUTY_REG_ADDR  :: CH1_FREQ_REG_ADDR + CH1_FREQ_REG_SIZE
CH1_DURATION_REG_ADDR  :: CH1_VOL_DUTY_REG_ADDR + CH1_VOL_DUTY_REG_SIZE
CH1_SLIDE_REG_ADDR     :: CH1_DURATION_REG_ADDR + CH1_DURATION_REG_SIZE

// Channel 2
CH2_FREQ_REG_ADDR  		 :: CH1_SLIDE_REG_ADDR + CH1_SLIDE_REG_SIZE
CH2_VOL_REG_ADDR   		 :: CH2_FREQ_REG_ADDR + CH2_FREQ_REG_SIZE
CH2_DURATION_REG_ADDR  :: CH2_VOL_REG_ADDR + CH2_VOL_REG_SIZE

// User RAM & Lua Global Variables
USER_ADDR              :: CH2_DURATION_REG_ADDR + CH2_DURATION_REG_SIZE

// Channel 1: Lead Melody & SFX (Includes Duty Cycle & Pitch Slide)
Channel_1 :: struct {
	frequency: u16,
	volume:    u8,
	duration:  u16,
	slide: 		 i8, // for pitch bends (jumps, lasers
	duty: 		 u8,  // for square wave timbre flavor (0 to 3)

	// Internal tracker for audio generation math
	phase: 		 f32,
}

// Channel 2: Percussion / Harmony (Noise or simpler square)
Channel_2 :: struct {
  frequency: u16,
  volume:    u8,
  duration:  u16,

  // Internal tracker
  phase:     f32,
}

console: struct {
	ram: [RAM_SIZE]u8,
	palette: [4]rl.Color,
	ch1: Channel_1,
	ch2: Channel_2,
}

ConsoleInit :: proc() {
	// Default color palette
	console.palette = Blueprint_Palette;

	call_lua_func(state, "_init");
}

ConsoleUpdate :: proc(audio_stream: rl.AudioStream) {
	// Inputs
	if (rl.IsKeyDown(.RIGHT)) {console.ram[INPUT_REG_ADDR] |=(1 << 0)}
	else {console.ram[INPUT_REG_ADDR] &~=(1 << 0)}

	if (rl.IsKeyDown(.LEFT)) {console.ram[INPUT_REG_ADDR] |=(1 << 1)}
	else {console.ram[INPUT_REG_ADDR] &~=(1 << 1)}

	if (rl.IsKeyDown(.UP)) {console.ram[INPUT_REG_ADDR] |=(1 << 2)}
	else {console.ram[INPUT_REG_ADDR] &~=(1 << 2)}

	if (rl.IsKeyDown(.DOWN)) {console.ram[INPUT_REG_ADDR] |=(1 << 3)}
	else {console.ram[INPUT_REG_ADDR] &~=(1 << 3)}

	// A
	if (rl.IsKeyDown(.Z)) {console.ram[INPUT_REG_ADDR] |=(1 << 4)}
	else {console.ram[INPUT_REG_ADDR] &~=(1 << 4)}

	// B
	if (rl.IsKeyDown(.X)) {console.ram[INPUT_REG_ADDR] |=(1 << 5)}
	else {console.ram[INPUT_REG_ADDR] &~=(1 << 5)}

	// Increment frame counter every frame (automatically wraps from 255 to 0)
	console.ram[FRAME_COUNTER_REG_ADDR] += 1;

	// Audio
	if (console.ch1.duration > 0) {
		console.ch1.duration -= 1;

		// Apply pitch slide per frame (e.g., rising or falling pitch)
    // We cast frequency to i32 to handle positive/negative slides safely
    new_freq := i32(console.ch1.frequency) + i32(console.ch1.slide);
    console.ch1.frequency = u16(clamp(new_freq, 20, 20000)); // Keep within safe limits

    if (console.ch1.duration == 0) {
      console.ch1.volume = 0; // Cut off sound when time's up
    }
	}

	if (console.ch2.duration > 0) {
    console.ch2.duration -= 1;
    if (console.ch2.duration == 0) {console.ch2.volume = 0;}
	}

	if (rl.IsAudioStreamProcessed(audio_stream)) {
		samples: [512]f32;
		sample_rate :: 11025.0;

		for i in 0..<512 {
			mixed_sample: f32;

			// Channel 1: Square wave
			if (console.ch1.volume > 0 && console.ch1.duration > 0) {
				freq := f32(max(console.ch1.frequency, 1));
				period := sample_rate / freq;

				// Duty cycle determines the width of the square wave (default to 50% or map from console.ch1.duty)
        duty_ratio: f32 = 0.5;
        if (console.ch1.duty == 1) 			{duty_ratio = 0.125}
        else if (console.ch1.duty == 2) {duty_ratio = 0.25}
        else if (console.ch1.duty == 3) {duty_ratio = 0.75}

        // Generate square wave sample (+amplitude or -amplitude)
        sq_sample: f32 = 0.0;
        if (console.ch1.phase < period * duty_ratio) {sq_sample = 0.15}// Positive half
        else {sq_sample = -0.15} // Negative half

        // Scale by volume (0 to 15 mapped to 0.0 to 1.0)
        vol_scale := f32(console.ch1.volume) / 15.0;
        mixed_sample += sq_sample * vol_scale;

        // Advance phase forward
        console.ch1.phase += 1.0;
        if (console.ch1.phase >= period) {console.ch1.phase = 0.0}
			}

			// --- CHANNEL 2: Noise Wave (Simple Pseudo-Random Percussion) ---
      if (console.ch2.volume > 0 && console.ch2.duration > 0) {
      	// Generate white noise static for explosions/drums
      	// A simple pseudo-random generator or tick counter can flip between -1 and 1
        noise_sample: f32 = (rand.float32() * 0.3) - 0.15;

        vol_scale := f32(console.ch2.volume) / 15.0;
        mixed_sample += noise_sample * vol_scale;
      }

      // Store the final mixed sample into our buffer
      samples[i] = mixed_sample;
		}

		// Push the filled buffer to Raylib so it plays out of the speakers!
    rl.UpdateAudioStream(audio_stream, &samples[0], 512);
	}

	call_lua_func(state, "_update");
}

ConsoleDraw :: proc() {
	call_lua_func(state, "_draw");

	// Draw VRAM
	for y in 0..<i32(HEIGHT) {
		for x in 0..<i32(WIDTH) {
			pixel_idx := (y * WIDTH) + x;
			byte_idx 	:= pixel_idx / 4;
			vram_byte := console.ram[VRAM_ADDR + byte_idx]

			pixels := [4]u8 {
				(vram_byte >> 6) & 0b11,
				(vram_byte >> 4) & 0b11,
				(vram_byte >> 2) & 0b11,
				 vram_byte & 0b11,
			}

			color := pixels[pixel_idx % 4];

			rl.DrawRectangle(x * screen_scaler, y * screen_scaler, screen_scaler,screen_scaler, console.palette[color]);
		}
	}
}

// Load .cart file
LoadCartridge :: proc(path: string) {
  data, ok := os.read_entire_file_from_filename(path);
  defer delete(data);

  if (!ok) {
  	fmt.println("Failed to open lua script!");
   	return
  }

  /*
  	split the .cart data to 4 sections:
   		0: sprites data (u8)
     	1: sprite flags data (u8)
      2: tilemap data (u8)
      3: lua script data (string)
  */

  // lines := strings.split_lines_n(strings.clone_from_bytes(data), 4);

  FLAGS_OFFSET   :: SPRITES_SIZE
	TILEMAP_OFFSET :: SPRITES_SIZE + FLAGS_SIZE
	SCRIPT_OFFSET  :: SPRITES_SIZE + FLAGS_SIZE + TILEMAP_SIZE

  if len(data) < SCRIPT_OFFSET {
    fmt.println("Error: Cartridge too small!");
    return
  }

  copy(console.ram[SPRITES_ADDR:], data[:FLAGS_OFFSET]);
  copy(console.ram[FLAGS_ADDR:],   data[FLAGS_OFFSET:TILEMAP_OFFSET]);
  copy(console.ram[TILEMAP_ADDR:], data[TILEMAP_OFFSET:SCRIPT_OFFSET]);

  lua_script := strings.clone_to_cstring(string(data[SCRIPT_OFFSET:]));
  defer delete (lua_script);

  // Load cartridge code
  if lua.L_dostring(state, lua_script) != 0 {
      err_msg := lua.tostring(state, -1)
      fmt.printf("Lua Error: %s\n", err_msg)
      lua.pop(state, 1)
  }
}
