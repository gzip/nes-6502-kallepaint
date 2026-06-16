# Architecture: The "Virtual Bitmap" & Procedural CHR Generation

The Nintendo Entertainment System natively does not support a bitmap rendering mode. Graphics are exclusively drawn using 8x8 pixel character tiles (CHR) locked to a rigid 32x30 grid on the screen. 

To create a freehand paint program, Kalle Paint has to simulate a bitmap. It achieves this using a clever combination of procedurally generated graphics data and bitwise math.

## The Concept

The program divides the standard 8x8 hardware tile into a 2x2 grid of "paint pixels", meaning each paint pixel is a 4x4 hardware pixel block. This approach essentially halves the native NES resolution in both directions to allow for manipulation at the "paint pixel" level (4x4 hardware pixels) within the constraints of the tile-based hardware.

The resulting canvas is **64x56 paint pixels** (256x224 hardware pixels). This fills most of the NES's 256x240 display, leaving a small 16-pixel high gutter at the bottom used for the Palette Editor UI. 

Since each of the four "paint pixels" inside a tile can be painted with one of 4 colors (from the active NES subpalette), there are exactly $4^4 = 256$ possible color combinations for any given tile. Coincidentally, the NES can hold exactly 256 background tiles in its 4KB CHR ROM pattern table.

If you generate every single one of these 256 combinations ahead of time, drawing a pixel on the screen becomes as simple as calculating the new color state of the 2x2 grid and swapping in the corresponding pre-generated tile.

## 1. Generating the CHR (`chr-background-generate.py`)

Instead of hand-drawing 256 tiles, the project uses a Python script to build the CHR ROM procedurally. 

The script iterates from index `0` to `255` (`0x00` to `0xFF`). The key to the entire architecture is that **the 8-bit tile index IS the color data.**

An 8-bit index can be represented as `AaBbCcDd`. The script uses these bits to define the color of the four quadrants:
*   `Aa` = Top-Left paint pixel
*   `Bb` = Top-Right paint pixel
*   `Cc` = Bottom-Left paint pixel
*   `Dd` = Bottom-Right paint pixel

*(Where the capital letter is the most-significant bit (plane 1), and the lowercase letter is the least-significant bit (plane 0) of the NES CHR format).*

For example, tile index `%11 00 00 00` (`$C0`) will be a tile where the top-left 4x4 block is filled with Color 3 (`%11`), and the other three quadrants are filled with Color 0 (`%00`).

## 2. Drawing on the Canvas (`paint.asm`)

When the user presses the 'A' button to paint with a small brush, the 6502 assembly code performs the following logic in `paint_mode_2`:

### Step A: Identify the Tile and Quadrant
First, it uses the cursor's screen coordinates to determine which tile is being modified, and retrieves the current tile index (a value from `0` to `255`) from the `vram_copy` shadow RAM.

Then, it calculates the specific sub-pixel position (0, 1, 2, or 3) within that tile based on the lowest bits of the X and Y coordinates:
```assembly
            lda cursor_x          ; pixel position within tile (0-3) -> X
            lsr a
            lda cursor_y
            rol a
            and #%00000011
            tax
```

### Step B: Bitwise Manipulation
Because the tile index perfectly encodes the colors of its four quadrants, updating a pixel means applying a bitmask to the tile index itself. 

The code defines two lookup tables:
```assembly
solid_tiles  db %00000000, %01010101, %10101010, %11111111  ; solid color 0-3
pixel_masks  db %11000000, %00110000, %00001100, %00000011  ; masks for quadrants
```

1. It takes the `pixel_masks` value for the current quadrant and inverts it (e.g., `%00111111` for quadrant 0).
2. It uses `AND` to clear out the old color data for that specific quadrant in the original tile index.
3. It takes the `solid_tiles` value matching the user's current paint color (0-3) and `AND`s it with the original `pixelmask` to isolate just the two bits needed.
4. Finally, it `OR`s these new bits back into the tile index.

### Step C: Update the Screen
This newly calculated 8-bit value is precisely the index of the pre-generated tile that shows the new combination of pixels. The code saves this new index back into `vram_copy` and adds it to the VRAM buffer queue, allowing the NMI routine to blast the new tile index to the NES screen on the next frame.