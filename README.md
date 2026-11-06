# Odin-4 Fantasy Console

A custom fantasy console built from scratch using the **Odin** programming language, featuring **Raylib** for rendering and **Lua 5.4** for game scripting.

## 🛠️ Technical Specifications

| Feature | Spec | Details |
| --- | --- | --- |
| **CPU / Scripting** | Lua 5.4 | Standardized at 60 FPS|
| **Display** | 80 × 64 pixels | Low-res retro canvas with a 2-bit color palette (4 colors) |
| **Memory** | 16 KB RAM | User-accessible memory space via custom `peek` and `poke` APIs |
| **Input** | 6 Buttons | **Arrows**, **Z** (Button A), **X** (Button B) |
| **Audio** | 2 Channels | Dedicated Pulse wave and Noise wave sound channels |
| **Sprites** | 128 Sprites | 8×8 pixel sprites with 8 metadata flags per sprite (1 byte) |
| **Tilemap** | 40 × 20 Grid | Built-in background tilemap support |

## 🎨 Built-in Editor Suite

Odin-4 includes custom-built companion tools tailored specifically for the console:

* **Sprite Editor:** Design and manage your 8×8 tiles and configure custom flags.
* **Tilemap Editor:** Paint levels and assemble backgrounds directly for the console's rendering pipeline.

## 🚀 Workflow: Exporting & Running Games

### 1. Exporting a Game

Package your project files into a standalone `.cart` file:

* Drag and drop your game folder directly onto **`Odin 4 Export Tool.exe`**.

### 2. Running a Game

Launch and play your compiled cartridges:

* Drag and drop the resulting **`.cart`** file into the Odin-4 console executable.

## 🎨 Color Palettes

Odin-4 supports dynamic 2-bit (4-color) palette switching via `set_palette(id)`. The console includes the following built-in themes:

| ID | Palette Name | Style / Vibe | Lospec Link |
| :---: | :--- | :--- | :--- |
| **0** | **RGR Blueprint 4** *(Default)* | Blueprint & Commodore 64 inspired | [View on Lospec](https://lospec.com/palette-list/rgr-blueprint4) |
| **1** | **Kirokaze Gameboy** | Classic handheld green-scale nostalgic aesthetic | [View on Lospec](https://lospec.com/palette-list/kirokaze-gameboy) |
| **2** | **Luminous** | High-contrast, vibrant cyberpunk glow | [View on Lospec](https://lospec.com/palette-list/luminous) |
| **3** | **2-Bit Grayscale** | Classic monochrome retro computing shade | [View on Lospec](https://lospec.com/palette-list/2-bit-grayscale) |
