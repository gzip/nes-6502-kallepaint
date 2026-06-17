# Plan: SNES Mouse Support

## 1. Input Routine (RAM & Logic)
*   **RAM**: Add `mouse_dx`, `mouse_dy`, `mouse_btn`, and `mouse_sig`.
*   **Read**: Modify the `$4016` read loop to clock 32 times instead of 8. 
*   **Parse**: Extract Left/Right clicks, the device signature (bits 12-15 = `0001` for mouse), and the 7-bit signed `dX`/`dY` velocities (bits 16-31).

## 2. Cursor Movement
*   **Logic**: Bypass the D-Pad delay logic. Add `mouse_dx` to `cursor_x` and `mouse_dy` to `cursor_y` every frame.
*   **Bounds**: Clamp `cursor_x` (0-63) and `cursor_y` (0-55) to prevent wrapping.
*   **Scaling**: Because the NES canvas is very small (64x56 "pixels"), implement a simple bit-shift divider to reduce mouse sensitivity, preventing the cursor from flying off the screen.

## 3. Button Mapping
*   **Blend Inputs**: Map Left Click to the `pad_a` bit and Right Click to the `pad_b` bit.
*   **Integration**: Merge these mapped clicks into the existing `pad_status` variable. This allows the core `paint_mode` and `attr_editor` routines to function completely unmodified.
*   *(Note: The user will still need a standard controller on Port 1 or 2 to press Start/Select, unless we implement double-click or chorded click macros later).*

## 4. Hardware Safety
*   Ensure the standard 8-read controller loop still works for standard gamepads by checking the 4-bit signature before applying mouse-specific logic.