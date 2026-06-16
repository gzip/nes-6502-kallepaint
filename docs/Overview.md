# Kalle Paint Codebase Overview

This is a 6502 assembly paint program designed specifically for the Nintendo Entertainment System (NES). It targets the NROM mapper (the simplest NES mapper), using 16KB of Program ROM (PRG) and 8KB of Character ROM (CHR).

## Key Components

*   **Features**:
    *   **Canvas Size**: 64x56 "paint pixels" (halving the native NES resolution to 4x4 hardware pixel blocks).
    *   **Colors**: 13 simultaneous colors from the NES master palette.
    *   **Modes**: Paint, Attribute Editor, and Palette Editor.
*   **`paint.asm`**: This is the core engine. It contains the entire application logic written in 6502 assembly. Key features include:
    *   **Main Loop & Input**: Handles controller input and dictates the program flow across its three primary modes: Paint, Attribute Editor, and Palette Editor.
    *   **Shadow VRAM (`vram_copy`)**: Because reading directly from the NES Video RAM (VRAM) is slow and tricky, the program maintains a shadow copy of the screen (Name Table and Attribute Table) in the CPU's RAM.
    *   **NMI Routine**: The Non-Maskable Interrupt routine triggers 60 times a second (during VBlank). It reads a queue of pending graphics updates (a 16-entry VRAM buffer) and blasts those changes to the actual NES PPU.

*   **`chr-background-generate.py`**: This is a crucial piece of the puzzle. It dynamically generates the CHR (graphics) data for the background.
    *   **The "Virtual Bitmap" Trick**: The NES operates on 8x8 pixel tiles. To create a freehand paint program, Kalle Paint defines a "paint pixel" as a 4x4 hardware pixel block. An 8x8 hardware tile holds a 2x2 grid of these paint pixels. Since each paint pixel can be one of 4 colors, there are 4^4 = 256 possible combinations. This Python script generates exactly 256 tiles covering every possible combination, allowing the assembly code to just swap tile indices to create the illusion of drawing at the "paint pixel" level.

*   **`build.sh` / `build.bat`**: Simple build scripts. They first run the Python script(s) to generate the raw graphics binaries, and then use `asm6` to assemble `paint.asm` into a playable `.nes` ROM file.

## Operating Modes

1.  **Paint Mode**: Allows drawing with a 1x1 or 2x2 brush (using the "paint pixels" described above). When you draw, it calculates the new state of the 2x2 grid in that specific 8x8 tile, determines the new tile index (0-255), and queues an update to the shadow VRAM.
2.  **Attribute Editor**: The NES groups color palettes in 32x32 pixel attribute blocks, which are subdivided into four 16x16 pixel quadrants. This mode changes your cursor into a 16x16 box that snaps to a 16x16 grid. It allows you to target and assign one of the four subpalettes to that specific 16x16 quadrant without affecting the rest of the 32x32 attribute block.
3.  **Palette Editor**: Allows real-time modification of the 13 available on-screen colors.

In short, it's a very clever use of NES hardware limitations, utilizing procedural tile generation to simulate bitmap graphics on a tile-based console.