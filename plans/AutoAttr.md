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

## 4. Automatic Attribute Logic
Modify `paint_mode` to automatically update the attribute table when painting.
- **Trigger**: Call `jsr auto_update_attribute` within the `update_tile` routine.
- **Subroutine**: `auto_update_attribute` calculates the attribute offset, bit position, masks the old quadrant bits, and applies the `active_subpalette`.

## 5. WYSIWYG Cursor Preview
The paint cursor currently previews the color based on the *existing* attribute table. This is misleading now that the attribute will change upon clicking.
- **Change**: Update the cursor color calculation in `paint_mode_2`.
- **Logic**: Use `active_subpalette` to calculate the color index in `user_palette` (Index = `active_subpalette * 4 + paint_color`).
- **Benefit**: The user sees the exact final color they are about to paint.

## 6. 16x16 Attribute Impact Indicator
Since painting now affects an entire 16x16 area, the user needs to know exactly which area is being targeted.
- **Change**: Re-enable and repurpose the attribute editor's corner sprites (#1-#4) during Paint Mode.
- **Logic**: 
    - These sprites will follow the cursor but "snap" to the 16x16 grid.
    - Snap Logic: `Indicator_X = (cursor_x & %00111100) * 4`, `Indicator_Y = ((cursor_y & %00111100) * 4) + 8`.
- **Result**: A dashed/corner frame will always show the "impact zone" of the auto-attribute feature.

## 7. Modernized Attribute Editor
The Attribute Editor (manual mode) currently cycles through subpalettes. This is inconsistent with the new workflow.
- **Change**: Modify `attr_editor` to use the `active_subpalette` for stamping.
- **Logic**: Replace the bit-flipping logic with a call to `auto_update_attribute`.
- **Benefit**: Both Paint mode (automatic) and Attribute mode (manual) now use the same source of truth for subpalettes.

## Expected User Experience
1. User enters Palette Editor (Start).
2. User selects Subpalette 2, Color 3.
3. User exits Palette Editor (Start).
4. **Visual**: The brush is now Color 3, and a 16x16 frame appears on the grid, snapping to attribute boundaries.
5. User paints on the canvas (A).
6. **Result**: The tile is updated to Color 3, and the area within the 16x16 frame is automatically switched to Subpalette 2.
