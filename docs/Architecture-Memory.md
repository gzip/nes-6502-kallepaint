# Architecture: Memory Mapping & Shadow VRAM

The Nintendo Entertainment System (NES) has very strict limitations regarding Video RAM (VRAM). The CPU cannot reliably write to VRAM while the Picture Processing Unit (PPU) is actively drawing the screen. To circumvent this and allow the application logic to update the canvas at any time, Kalle Paint implements a "Shadow VRAM" architecture within the CPU's limited internal RAM.

## NES RAM Constraints

The NES CPU only has **2KB (2048 bytes)** of internal Work RAM available, mapped from `$0000` to `$07FF`. Kalle Paint must fit its entire state—including variables, buffers, and the shadow copy of the screen—within this tight space.

## Memory Map

Based on `paint.asm`, the core RAM layout is organized as follows:

### Zero Page (`$0000` - `$00FF`)
The Zero Page is the fastest RAM to access on the 6502. Kalle Paint uses it for the most critical variables and the VRAM update queue.

*   `$00` - `$0F`: **`vram_buf_hi`** (VRAM buffer - High byte of target addresses, `0` acts as a terminator)
*   `$10` - `$1F`: **`vram_buf_lo`** (VRAM buffer - Low byte of target addresses)
*   `$20` - `$2F`: **`vram_buf_val`** (VRAM buffer - The actual tile/color data to write)
*   `$40` - `$41`: **`vram_offset`** (Calculated 16-bit offset into the Name/Attribute table, 0 - `$3FF`)
*   `$42` - `$43`: **`vram_copy_addr`** (Absolute 16-bit address pointing into `vram_copy` in RAM)
*   `$44`: **`mode`** (Current application mode: Paint, Attr Edit, Pal Edit)
*   `$48`: **`vram_buf_pos`** (Index tracking how many items are currently in the VRAM buffer)
*   `$53`: **`active_subpalette`** (The subpalette currently used by the paint brush for auto-attribute stamping)

*Note: The VRAM buffer is exactly 16 entries long. This limits the program to updating a maximum of 16 bytes of graphics per frame (1/60th of a second).*

### Work RAM (`$0100` - `$07FF`)

*   `$0100` - `$01FF`: **Stack** (Hardware defined)
*   `$0200` - `$02FF`: **Sprite DMA Buffer** (Common NES pattern: this page is copied directly to Object Attribute Memory (OAM) every frame for sprite rendering).
*   `$0300` - `$06FF`: **`vram_copy`** (The Shadow VRAM)

## The Shadow VRAM (`vram_copy`)

`vram_copy` is exactly `$0400` (1024) bytes long, perfectly matching the size of one NES Name Table (which includes the tile map and the attribute table). 

Because it must be exactly 1024 bytes, and it is located starting at `$0300`, it takes up exactly half of the NES's total available RAM.

**Why does it start exactly at `$0300`?**
The code defines `vram_copy equ $0300`. A comment explicitly notes `must be at $xx00`. This is a deliberate 6502 assembly optimization. By starting exactly on a page boundary (where the low byte of the address is `00`), calculating addresses inside the shadow RAM becomes much faster.

### Address Translation (Screen Coordinates to RAM)

When you press the 'A' button to paint, the program needs to find out what tile is currently there so it can modify it. It cannot read the PPU VRAM, so it reads `vram_copy`.

To translate a cursor position (`cursor_x`, `cursor_y`) to a RAM address, `paint.asm` performs the following steps (visible in the calculation leading up to `get_vram_copy_addr`):

1.  **Calculate Offset (`vram_offset`):** It takes the bit-shifted X and Y coordinates and interleaves them to calculate the exact offset (0 to `$3FF`) that this tile occupies within a standard NES Name Table. 
2.  **Calculate Absolute Address (`vram_copy_addr`):** It runs the `get_vram_copy_addr` subroutine. 
    *   It takes the low byte of `vram_offset` and stores it directly as the low byte of `vram_copy_addr`.
    *   It takes the high byte of `vram_offset` (which will be `00`, `01`, `02`, or `03`), adds it to the high byte of the `vram_copy` base address (`03`), and stores it as the high byte of `vram_copy_addr`.

Because `vram_copy` starts at `$0300`, the math is extremely cheap: the address is simply `$0300 + vram_offset`.

Once the tile value is read from `(vram_copy_addr)`, modified, and written back, the routine calls `to_vram_buf`. This takes the same `vram_offset`, adds the real PPU Name Table base address (usually `$2000`), and pushes that final destination address plus the new tile value into the 16-byte VRAM buffer queue (`vram_buf_hi`, `vram_buf_lo`, `vram_buf_val`) so the NMI routine will blast it to the real screen on the next frame.