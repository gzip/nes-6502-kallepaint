# Kalle Paint Codebase Overview

This is a 6502 assembly paint program designed specifically for the Nintendo Entertainment System (NES). It targets the NROM mapper (the simplest NES mapper), using 16KB of Program ROM (PRG) and 8KB of Character ROM (CHR).

## Key Components

*   **Features**:
    *   **Canvas Size**: 64x56 "paint pixels" (halving the native NES resolution to 4x4 hardware pixel blocks).
    *   **Colors**: 13 simultaneous colors from the NES master palette.
    *   **Modernized Paint**: Automatic attribute stamping allows painting with any subpalette without manual mode switching.
    *   **Modes**: Paint, Attribute Editor, and Palette Editor.
*   **`paint.asm`**: This is the core engine. It contains the entire application logic written in 6502 assembly. Key features include:
    *   **Main Loop & Input**: Handles controller input and dictates the program flow across its three primary modes: Paint, Attribute Editor, and Palette Editor.
    *   **Shadow VRAM (`vram_copy`)**: Because reading directly from the NES Video RAM (VRAM) is slow and tricky, the program maintains a shadow copy of the screen (Name Table and Attribute Table) in the CPU's RAM.
    *   **NMI Routine**: The Non-Maskable Interrupt routine triggers 60 times a second (during VBlank). It reads a queue of pending graphics updates (a 16-entry VRAM buffer) and blasts those changes to the actual NES PPU.

*   **`chr-background-generate.py`**: This is a crucial piece of the puzzle. It dynamically generates the CHR (graphics) data for the background.
    *   **The "Virtual Bitmap" Trick**: The NES operates on 8x8 pixel tiles. To create a freehand paint program, Kalle Paint defines a "paint pixel" as a 4x4 hardware pixel block. An 8x8 hardware tile holds a 2x2 grid of these paint pixels. Since each paint pixel can be one of 4 colors, there are 4^4 = 256 possible combinations. This Python script generates exactly 256 tiles covering every possible combination, allowing the assembly code to just swap tile indices to create the illusion of drawing at the "paint pixel" level.

*   **`build.sh` / `build.bat`**: Simple build scripts. They first run the Python script(s) to generate the raw graphics binaries, and then use `asm6` to assemble `paint.asm` into a playable `.nes` ROM file.

## Timing and Responsiveness

The "feel" of Kalle Paint is dictated by a dynamic input processing system that balances fast navigation with surgical drawing precision:

*   **Synchronous Polling**: The `mainloop` is locked to the **NMI (Vertical Blank)** interrupt. The engine polls the controller exactly once per frame (60 times per second), ensuring zero input latency.
*   **Delayed Auto Shift (DAS)**: To prevent accidental "pixel jumping," the engine applies a 16-frame delay (1/4 second) on the first D-pad press. This makes it easy to tap a single direction for precise 1-pixel adjustments without triggering a runaway repeat.
*   **Context-Sensitive "Gears"**: The engine dynamically adjusts movement speed based on user intent:
    *   **Navigation Gear**: When moving the cursor freely, the cursor moves at a high repeat rate.
    *   **Precision Gear**: While the **A** button is held to draw, the movement speed automatically drops by half. This "aim-down-sights" mechanic provides the fine control needed for detailed pixel work.
*   **Normalized Visual Speed**: Movement is now scaled based on the current mode's step size (1, 2, or 4 units). This ensures that the cursor traverses the screen at the same visual speed regardless of whether you are using the small brush, large brush, or attribute editor.

## Operating Modes

1.  **Paint Mode**: Allows drawing with a 1x1 or 2x2 brush (using the "paint pixels" described above). When you draw, it calculates the new state of the 2x2 grid in that specific 8x8 tile, determines the new tile index (0-255), and queues an update to the shadow VRAM.
2.  **Attribute Editor**: Allows assigning subpalettes to 16x16 quadrants. The cursor in this mode flashes with the color of the selected subpalette, providing a visual preview. 
    *   **B Button**: Cycles the active subpalette.
    *   **A Button**: Stamps the selection to the grid.
3.  **Palette Editor**: Allows real-time modification of the 13 available on-screen colors.

In short, it's a very clever use of NES hardware limitations, utilizing procedural tile generation to simulate bitmap graphics on a tile-based console.