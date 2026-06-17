# Architecture: NMI Render Pipeline & VRAM Buffer

On the NES, writing to Video RAM (VRAM) is restricted. Performing writes while the Picture Processing Unit (PPU) is rendering the screen results in "visual garbage" or crashes. To ensure clean updates, Kalle Paint uses an **asynchronous render pipeline** that queues updates in RAM and executes them during the **Vertical Blank (VBlank)** interval—a tiny window of roughly 2200 CPU cycles that occurs 60 times a second between frames.

## 1. The Main Loop Synchronization

The main application logic and the hardware rendering are kept in sync via two flags: `runmain` and `vram_ready`.

*   **`runmain` (Timing):** The `mainloop` starts by checking `runmain` (`bit runmain`). If the bit isn't set, it loops indefinitely. Once the NMI routine sets the flag, the `mainloop` processes one frame of input and drawing.
*   **`vram_ready` (Safety):** To prevent race conditions, the main loop clears `vram_ready` while building the VRAM buffer. It only sets the flag after the buffer is fully terminated. The NMI routine will skip the "Blast" (Step 2 in section 3) if this flag is not set, preventing it from processing a half-finished buffer if the main loop takes too long.

This dual-flag system ensures the CPU logic never "outruns" the TV's refresh rate and never corrupts the PPU state during heavy logic calculations.

## 2. The VRAM Buffer Queue

Because the VBlank window is so short, the CPU cannot perform complex calculations during that time. Instead, the `mainloop` prepares a "to-do list" in the **Zero Page** (the fastest RAM).

The buffer consists of three 16-byte arrays:
*   `vram_buf_hi`: Target PPU address (high byte).
*   `vram_buf_lo`: Target PPU address (low byte).
*   `vram_buf_val`: The 8-bit value (tile index or color) to write.

An additional variable, `vram_count`, tracks the number of active entries in the queue.

### How Updates are Queued
1.  **Frame Start:** Every frame, `vram_count` is reset to `0`.
2.  **Cursor/Indicator Update:** The system always puts a mandatory update at index `0` to handle the blinking cursor (Paint mode) or flashing background indicator (Attribute mode) in the PPU palette RAM (`$3Fxx`).
3.  **Drawing Updates:** If a user paints or changes an attribute, the code calls `to_vram_buf`. This routine:
    *   Checks if `vram_count` has reached the limit of 16 entries.
    *   Calculates the PPU destination address (Offset + `$2000`).
    *   Stores the high/low address and the value in the next available buffer slot (`vram_buf_xx[vram_count]`).
    *   Increments `vram_count`.

## 3. The NMI Routine (The "Blast")

The **Non-Maskable Interrupt (NMI)** is a hardware interrupt triggered by the PPU the moment VBlank begins. It immediately pauses the main loop and runs the high-priority rendering code.

### Step-by-Step Execution:
1.  **OAM DMA:** It first triggers a Sprite DMA. This hardware feature automatically copies 256 bytes of sprite data from CPU RAM (`$0200-$02FF`) to the PPU's internal sprite memory. This is why the cursor moves smoothly.
2.  **Buffer Flush:** It reads `vram_count` and iterates backwards through the buffer. For each entry:
    *   It writes the high and low address bytes to the PPU register `$2006` (`ppu_addr`).
    *   It writes the value to the PPU register `$2007` (`ppu_data`).
3.  **Buffer Reset:** It clears `vram_count` and the `vram_ready` flag to signal that the rendering task is complete.
4.  **PPU State Restore:** Because the VRAM writes change the PPU's internal address pointer, the NMI routine must reset the scroll (`ppu_scroll`) and the base address. If it didn't, the entire screen would jitter or disappear.
5.  **Signal Main Loop:** Finally, it sets the `runmain` flag, telling the CPU that the hardware is ready for the next frame of logic.

## Summary of Constraints
This architecture limits Kalle Paint to **16 VRAM updates per frame**. This is why the program uses a 1x1 or 2x2 brush; a much larger brush would exceed the 16-byte limit and could cause the "blast" to bleed out of the VBlank window, resulting in screen flickering or graphical glitches.