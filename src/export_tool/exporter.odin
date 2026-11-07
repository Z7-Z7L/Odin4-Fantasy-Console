package exporter

import "core:fmt"
import "core:os"
import "core:path/filepath"

MAX_CART_SIZE :: 32 * 1024 // 32 KB

ExportToCart :: proc(assets_path, lua_script_path, folder: string) {
	assets_data, assets_ok := os.read_entire_file_from_filename(assets_path);
	lua_script_data, lua_script_ok := os.read_entire_file_from_filename(lua_script_path);

	if (!assets_ok) {
		fmt.println("Failed to open assets data file!");
		return
	}

	if (!lua_script_ok) {
		fmt.println("Failed to open lua script file!");
		return
	}

	out_data := make([]u8, len(assets_data) + len(lua_script_data));
	defer delete(out_data);

	copy(out_data, assets_data);
	copy(out_data[len(assets_data):], lua_script_data);

	// Check cartridge size
	if (len(out_data) > MAX_CART_SIZE) {
  	fmt.printf("Cartridge too large! (%d KB / 32 KB)\n", len(out_data) / 1024);
    return
	}

	out_path := filepath.join({folder, "game.cart"}, context.temp_allocator);

	os.write_entire_file(out_path, out_data);

	// Export message
 	fmt.printf("Cartridge exported! (%d KB / 32 KB)\n", len(out_data) / 1024);
}

main :: proc() {
	folder := os.args[1];

	if (!os.is_dir(folder)) {
		fmt.println("Not a folder:", folder);
		return
	}

	lua_path 	  := filepath.join({folder, "main.lua"}, context.temp_allocator);
	assets_path := filepath.join({folder, "assets.bin"}, context.temp_allocator);

	ExportToCart(assets_path, lua_path, folder);

}
