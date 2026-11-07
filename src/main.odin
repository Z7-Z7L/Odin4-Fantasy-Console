package odin4

import "core:strings"
import rl "vendor:raylib"
import "core:fmt"
import "core:os"
import lua "vendor:lua/5.4"

state: ^lua.State;

ResizeAndCenterScreen :: proc(scaler: i32) {
	rl.SetWindowSize(WIDTH * scaler, HEIGHT * scaler);

	rl.SetWindowPosition(
		(rl.GetMonitorWidth(rl.GetCurrentMonitor()) - rl.GetScreenWidth()) / 2,
		(rl.GetMonitorHeight(rl.GetCurrentMonitor()) - rl.GetScreenHeight()) / 2
	);
}
screen_scaler: i32 = 6;

main :: proc() {
	// Dropped .cart file
 	cart_path: string;
  if (len(os.args) > 1) {
  	arg := os.args[1]
   	if (strings.has_suffix(arg, ".cart")) {
    	cart_path = arg;
    }
  }

  // If no valid .cart was provided, exit immediately with a helpful message
  if (cart_path == "") {
    fmt.println("Error: Please provide a valid .cart file (or drag and drop one onto the .exe).");
    return;
  }

  // Initialization
  rl.InitWindow(WIDTH * screen_scaler, HEIGHT * screen_scaler, "Odin4 Fantasy Console");
  rl.SetTargetFPS(FPS);

  rl.InitAudioDevice();

  audio_stream := rl.LoadAudioStream(11025, 16, 1);
  rl.PlayAudioStream(audio_stream)
  defer rl.StopAudioStream(audio_stream);
  defer rl.UnloadAudioStream(audio_stream);
  defer rl.CloseAudioDevice();

  state = lua.L_newstate();
  if (state == nil) {
  	fmt.println("Failed to init lua state!")
   	return
  }
  defer lua.close(state);

  // Open standard Lua libraries (math, string, table, etc.)
  lua.L_openlibs(state);
  register_lua_bindings(state);

  // Make it take the dropped .cart file
  LoadCartridge(cart_path);

  ConsoleInit();

  for (!rl.WindowShouldClose()) {
    // Update
    dt := rl.GetFrameTime();
    ConsoleUpdate(audio_stream);

    // Scale the screen
    if (rl.IsKeyPressed(.ONE) && screen_scaler > 1) {
    	screen_scaler -= 1;
     ResizeAndCenterScreen(screen_scaler);
    }
    if (rl.IsKeyPressed(.TWO)) {
    	screen_scaler += 1;
     	ResizeAndCenterScreen(screen_scaler);
    }

    // Draw
    rl.BeginDrawing();
      rl.ClearBackground(rl.BLACK);

      ConsoleDraw();

    rl.EndDrawing();

  }

  // Close the window
  rl.CloseWindow();
}
