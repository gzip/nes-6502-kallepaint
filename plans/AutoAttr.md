# Plan: Auto-Attribute Drawing ("Modernized Paint")

The goal of this enhancement is to allow the user to select a color in the Palette Editor and immediately begin drawing with that exact color, without having to manually switch to the Attribute Editor to "stamp" the correct subpalette.

## 1. State Tracking (RAM)
We need to track which subpalette is currently "active" for the drawing brush.
- **Variable**: `active_subpalette equ $53`
- **Default Value**: `1` (as per user preference, ensuring the user starts with a non-zero palette).

## 2. Initialization
In the `reset` routine in `paint.asm`:
- Explicitly set `active_subpalette` to `#1`.

## 3. Palette Editor Synchronization
When exiting the Palette Editor via the `pe_exit` label:
- Update `paint_color` from `pal_edit_cursor_pos`.
- Update `active_subpalette` from `pal_edit_subpal`.

## 4. Automatic Attribute Stamping
Modify `paint_mode` to automatically update the attribute table when painting.
- After the `jsr to_vram_buf` call (or within the `update_tile` routine), add a call to a new subroutine: `jsr auto_update_attribute`.

## 5. Subroutine: `auto_update_attribute`
This routine will perform the bitwise manipulation necessary to change only the 2-bit subpalette selection for the current 16x16 quadrant.

**Logic**:
1.  **Calculate Offset**: Call existing `attr_vram_offset` to set `vram_offset` and `vram_copy_addr`.
2.  **Calculate Bit Position**: Call existing `attr_bit_pos` to get the shift amount (0, 2, 4, or 6) in `X`.
3.  **Fetch & Mask**: 
    - Load the attribute byte from `(vram_copy_addr)`.
    - Clear the target 2-bit quadrant using a mask derived from `bp_change_masks` or by dynamic shifting.
4.  **Set New Bits**: 
    - Take `active_subpalette`.
    - Shift it left by `X`.
    - `OR` it into the byte.
5.  **Write Back**: 
    - Store the modified byte back into `(vram_copy_addr)`.
    - Call `to_vram_buf` to queue the PPU update.

## Expected User Experience
1. User enters Palette Editor (Start).
2. User selects Subpalette 2, Color 3.
3. User exits Palette Editor (Start).
4. User paints on the canvas (A).
5. **Result**: The tile is updated to Color 3, and the surrounding 16x16 area is automatically switched to Subpalette 2.
