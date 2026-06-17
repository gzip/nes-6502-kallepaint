# Plan: Help Screen Overlay

## Goal
Implement a non-destructive Help Screen overlay that appears when the user enters **Palette Mode**. This provides a quick reference for the control scheme without obscuring or destroying the current drawing canvas.

## Technical Strategy: Nametable Swapping
The NES supports two nametables (for NROM). 
*   **Nametable 0 ($2000):** Reserved for the Drawing Canvas.
*   **Nametable 1 ($2400):** Reserved for the Help Screen.

### 1. Initialization
During the `reset` phase, we will clear Nametable 1 and populate it with the help text strings. This only happens once on boot.

### 2. Mode Transition
*   **Entering Palette Mode:**
    *   Set `ppu_ctrl` to point to **Nametable 1** ($2400).
    *   Set `ppu_ctrl` to use **Pattern Table 1** for the background. This allows the help screen to use the font tiles stored alongside the sprites, as the "Virtual Bitmap" tiles in Pattern Table 0 are completely full.
*   **Exiting Palette Mode:**
    *   Restore `ppu_ctrl` to point to **Nametable 0** ($2000).
    *   Restore `ppu_ctrl` to use **Pattern Table 0** for the background (restoring the drawing canvas).
*   The Palette Editor UI (which is entirely sprite-based) will remain visible on top of the Help Screen as it already uses Pattern Table 1 for sprites.

### 3. NMI Synchronization
The `nmi` routine must be updated to ensure that when it resets the `ppu_ctrl` at the end of the VBlank period, it uses the bit corresponding to the *currently active* mode's nametable.

---

## Proposed Text & Layout
The help text will be positioned in the top-left quadrant of Nametable 1 (to avoid clashing with the Palette Editor UI in the bottom-right).

**Proposed Layout (Center-Left):**

```text
       CONTROLS
       --------
D-PAD  - NAVIGATE
SELECT - DRAWING MODE
START  - PALETTE MODE
A      - DRAW *
B      - CYCLE COLOR *

* IN PALETTE MODE:
  A/B CYCLE BRIGHTNESS
```

## Implementation Notes
*   **Tile Indices:** To be provided after manual CHR editing.
*   **Attributes:** The Help Screen will use a dedicated attribute block on Nametable 1 to ensure the text is high-contrast (e.g., White on Black).
*   **Preservation:** Because the Drawing Canvas logic only writes to Nametable 0 (and its shadow-RAM), the canvas remains completely intact while the Help Screen is visible.
