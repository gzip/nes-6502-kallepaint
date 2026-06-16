# Completed: Control Scheme Overhaul

The control scheme was redesigned to move away from a clunky "sequential mode" architecture to a more modern "toggle and cycle" approach.

## 1. 4-Mode Architecture
Added a fourth internal mode to separate "Small Brush" and "Large Brush" into their own distinct states.
- **Mode 0**: Small Brush Paint
- **Mode 1**: Large Brush Paint
- **Mode 2**: Attribute Editor
- **Mode 3**: Palette Editor

## 2. Select Button: The Canvas Cycle
The **Select** button now exclusively cycles through the three primary canvas-interaction modes:
`Small Brush` &rarr; `Large Brush` &rarr; `Attribute Editor` &rarr; (Loop to Small Brush)

## 3. Start Button: Palette Toggle
The **Start** button was repurposed into a global Palette Editor toggle.
- **Enter**: Pressing **Start** in any drawing mode opens the Palette Editor.
- **Exit**: Pressing **Start** while in the Palette Editor returns you to your previous drawing mode.

## 4. Subpalette Selection (Internal Cycle)
Within the Palette Editor, the **Select** button now handles subpalette cycling (0-3), freeing up the **Start** button for its dedicated Exit function.

## 5. State Persistence (`prev_mode`)
Implemented a `prev_mode` variable in RAM to track the user's drawing state.
- **Benefit**: Closing the Palette Editor no longer resets the user to "Small Brush" mode; it restores whichever brush or editor they were using previously.
- **Benefit**: Correctly handles hiding/showing the appropriate cursors (paint cursor vs attribute cursor) during transitions, eliminating visual artifacts.
