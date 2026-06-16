# Kalle Paint - Controls and User Interface

Kalle Paint operates across four distinct modes to work around the limitations of the NES hardware. The user can switch between drawing and editing modes using the **Select** and **Start** buttons.

## The Mode Cycle (Select Button)
Pressing **Select** cycles through the three primary canvas-related modes:
1.  **Paint Mode (Small Brush)**: Standard 1x1 drawing.
2.  **Paint Mode (Large Brush)**: 2x2 block drawing.
3.  **Attribute Edit Mode**: Change subpalettes for 16x16 quadrants.

*(Pressing Select in Attribute Mode returns you to Small Brush Paint Mode).*

---

## The Palette Editor (Start Button)
Pressing **Start** in any of the above modes will open the **Palette Editor**. Pressing **Start** again while inside the editor will return you to **Small Brush Paint Mode**.

---

## 1. Paint Modes (Small & Large Brush)

These modes are used for drawing on the canvas. The cursor visually reflects the currently selected brush size and paint color.

### Controls:
*   **D-Pad (Up/Down/Left/Right):** Move the cursor. Holding a direction will move the cursor repeatedly.
*   **B Button:** Cycle through the 4 colors of the currently active subpalette (Color 0 -> 1 -> 2 -> 3 -> 0).
*   **A Button:** Paint at the cursor's location using the selected color and brush size.
*   **Select:** Cycle the mode (Small Brush &rarr; Large Brush &rarr; Attribute Editor).
*   **Start:** Open the **Palette Editor**.

*Note: The cursor becomes invisible if it is hovering over a pixel of the exact same color. To move long distances faster, switch to the Large Brush mode via Select.*

---

## 2. Attribute Edit Mode

Because the NES groups color palettes into blocks, you cannot freely use any of the 13 colors on any single pixel. The screen is divided into a grid, and each square on that grid can only use one of four "subpalettes."

In this mode, the cursor changes into a large, blinking 16x16 pixel square that snaps to the NES attribute grid. 

### Controls:
*   **D-Pad (Up/Down/Left/Right):** Move the attribute cursor (snaps to 16x16 pixel quadrants).
*   **B Button:** Decrement the subpalette assigned to the highlighted square.
*   **A Button:** Increment the subpalette assigned to the highlighted square (Subpalette 0 <-> 1 <-> 2 <-> 3).
*   **Select:** Switch back to Paint Mode (Small Brush).
*   **Start:** Open the **Palette Editor**.

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
*   **Select:** Cycle to the next subpalette (Subpalette 0 -> 1 -> 2 -> 3 -> 0).
*   **D-Pad (Left/Right):** Decrement/Increment the "ones" digit of the NES color number (changes hue).
*   **B / A Buttons:** Decrement/Increment the "sixteens" digit of the NES color number (changes brightness).
*   **Start:** Exit the editor and return to Paint Mode (Small Brush).

*Note: Because the top-most color in the list is shared across all subpalettes, editing it will change that background color everywhere on the screen simultaneously.*