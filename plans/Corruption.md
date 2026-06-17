# Bug Report: Systematic Screen Corruption ("Pink Squares")

## Description
When drawing rapidly on the canvas, systematic "pink square" artifacts appear at the top of the screen ($2000-$20xx range). These artifacts mirror the brush strokes but are shifted in position. 

**Crucially**: This corruption is visible on the real hardware/emulator screen but is **invisible** in both the Nametable Viewer and Sprite (OAM) Viewer.

## Potential Causes

### 1. PPU Address Corruption (The "Carry Leak")
The nametable offset calculation in `paint_mode_2` uses a sequence of `ror` instructions.
- **Mechanism**: `ror` rotates through the Carry flag. If the Carry flag is inadvertently set by preceding UI logic (like the impact box or WYSIWYG cursor math), the `ror` instruction injects a `1` into the high bits of the PPU address.
- **Result**: The drawing target shifts from the intended tile to the Attribute Table or Nametable 1.
- **Mirroring**: Due to vertical mirroring, Nametable 1 overwrites the top of Nametable 0, resulting in the "pink squares" at the top of the screen.

### 2. VBlank Overrun (Timing/Race Condition)
The increased cursor speed (`brush_delay = 2`) allows the main loop to run very frequently.
- **Mechanism**: If the CPU is still writing data to the VRAM buffer when the PPU begins rendering the visible frame, the PPU's internal address registers ($2006) are corrupted mid-scanline.
- **Result**: This causes transient screen tearing and garbage rendering that does not persist in PPU memory (explaining why viewers don't see it).

### 3. Buffer Terminator Race Condition
The `vram_ready` flag and the `$00` terminator are currently managed in a way that allows for a tiny "window of failure."
- **Mechanism**: If the NMI fires after the main loop has started writing to `vram_buf_hi+0` but *before* `vram_ready` is cleared, the NMI processes an inconsistent buffer.
- **Result**: Without a valid terminator, the NMI loop reads past the 16-byte limit into adjacent RAM, blasting random data into the PPU.

### 4. Uninitialized Drawing State
After code reverts, `active_subpalette` may be uninitialized (defaulting to 0).
- **Result**: The cursor "previews" the background color (palette 0) instead of the selected drawing color, contributing to the perception of erratic drawing behavior.

## Status: UNFIXED
The engine requires a robust, non-rotating address calculation and a synchronized, count-based VRAM pipeline to eliminate these systematic race conditions.
