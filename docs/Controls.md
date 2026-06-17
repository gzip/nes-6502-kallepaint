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

**Impact Box**: A 16x16 dashed frame follows the cursor, snapping to the attribute grid. This indicates the area that will be automatically updated to your selected subpalette when you paint.

### Controls:
*   **D-Pad (Up/Down/Left/Right):** Move the cursor. 
    *   **Delayed Auto Shift (DAS):** A short delay exists on the first press to allow for single-pixel precision taps.
    *   **Context-Sensitive Speed:** Holding a direction will move the cursor repeatedly. The cursor moves significantly faster while navigating and slows down to a "precision gear" while the **A** button is held for drawing.
*   **B Button:** Cycle through the 4 colors of the currently active subpalette (Color 0 -> 1 -> 2 -> 3 -> 0).
*   **A Button:** Paint at the cursor's location. The surrounding 16x16 area is automatically updated to the active subpalette.
*   **Select:** Cycle the mode (Small Brush &rarr; Large Brush &rarr; Attribute Editor).
*   **Start:** Open the **Palette Editor**.

*Note: Visual speeds are normalized across all modes. Whether you are in Small Brush, Large Brush, or Attribute mode, the cursor will traverse the screen at the same visual rate.*

---

## 2. Attribute Edit Mode

Because the NES groups color palettes into blocks, you cannot freely use any of the 13 colors on any single pixel. The screen is divided into a grid, and each square on that grid can only use one of four "subpalettes."

In this mode, the cursor changes into a large, blinking 16x16 pixel square that snaps to the NES attribute grid. 

### Controls:
*   **D-Pad (Up/Down/Left/Right):** Move the attribute cursor (snaps to 16x16 pixel quadrants).
*   **B Button:** Cycle to the next subpalette (0 -> 1 -> 2 -> 3 -> 0).
*   **A Button:** "Stamp" the assigned subpalette to the highlighted 16x16 square.
*   **Select:** Switch back to Paint Mode (Small Brush).
*   **Start:** Open the **Palette Editor**.

*Note: The cursor flashes with the color of the selected subpalette. This provides a visual preview of the attribute you are about to apply.*

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
*   **Start:** Exit the editor and return to Paint Mode. Your active brush and subpalette will be updated to match your selection in the editor.

*Note: The Palette Editor is now the primary way to choose your drawing color and subpalette for the modernized paint workflow.*