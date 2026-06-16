# Kalle Paint - Controls and User Interface

Kalle Paint operates across three distinct modes to work around the limitations of the NES hardware. The user can cycle through these modes at any time by pressing the **Select** button.

## 1. Paint Mode

The program starts in Paint Mode. This is the primary mode for drawing on the canvas. The cursor visually reflects the currently selected brush size and paint color.

### Controls:
*   **D-Pad (Up/Down/Left/Right):** Move the cursor. Holding a direction will move the cursor repeatedly.
*   **Start:** Toggle brush size between small (1x1 paint pixel) and large (2x2 paint pixels).
*   **B Button:** Cycle through the 4 colors of the currently active subpalette (Color 0 -> 1 -> 2 -> 3 -> 0).
*   **A Button:** Paint at the cursor's location using the selected color and brush size.
*   **Select:** Switch to Attribute Edit Mode.

*Note: The cursor becomes invisible if it is hovering over a pixel of the exact same color. To move long distances faster, switch to the large brush.*

---

## 2. Attribute Edit Mode

Because the NES groups color palettes into blocks, you cannot freely use any of the 13 colors on any single pixel. The screen is divided into a grid, and each square on that grid can only use one of four "subpalettes."

In this mode, the cursor changes into a large, blinking 16x16 pixel square that snaps to the NES attribute grid. 

### Controls:
*   **D-Pad (Up/Down/Left/Right):** Move the attribute cursor (snaps to 16x16 pixel quadrants).
*   **B Button:** Decrement the subpalette assigned to the highlighted square.
*   **A Button:** Increment the subpalette assigned to the highlighted square (Subpalette 0 <-> 1 <-> 2 <-> 3).
*   **Select:** Switch to Palette Edit Mode.

*Note: The first color (Color 0) of every subpalette is shared across the entire screen. Changing the subpalette of a square will have no visible effect on pixels drawn with that shared background color.*

---

## 3. Palette Edit Mode

This mode brings up a small black window at the bottom right corner of the screen, allowing you to edit the NES master colors assigned to the four subpalettes.

### User Interface Elements:
*   **`Pal`:** Indicates the number of the subpalette currently being edited (0-3).
*   **`C`:** Displays the NES color number of the selected color in hexadecimal (00-3F). The first digit roughly corresponds to brightness, and the second digit corresponds to hue.
*   **Colored Squares:** A visual preview of the four colors currently in the selected subpalette.
*   **Blinking Cursor:** Highlights exactly which of the four colors is currently being edited.

### Controls:
*   **D-Pad (Up/Down):** Move the cursor to select a different color within the current subpalette to edit.
*   **Start:** Cycle to the next subpalette (Subpalette 0 -> 1 -> 2 -> 3 -> 0).
*   **D-Pad (Left/Right):** Decrement/Increment the "ones" digit of the NES color number (changes hue).
*   **B / A Buttons:** Decrement/Increment the "sixteens" digit of the NES color number (changes brightness).
*   **Select:** Switch back to Paint Mode.

*Note: Because the top-most color in the list is shared across all subpalettes, editing it will change that background color everywhere on the screen simultaneously.*