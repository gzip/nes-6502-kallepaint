# Architecture: NMI Render Pipeline & VRAM Buffer

On the NES, writing to Video RAM (VRAM) is restricted. Performing writes while the Picture Processing Unit (PPU) is rendering the screen results in "visual garbage" or crashes. To ensure clean updates, Kalle Paint uses an **asynchronous render pipeline** that queues updates in RAM and executes them during the **Vertical Blank (VBlank)** interval—a tiny window of roughly 2200 CPU cycles that occurs 60 times a second between frames.

## 1. The Main Loop Synchronization

The main application logic and the hardware rendering are kept in sync via a simple flag called `runmain`.

*   **Wait:** The `mainloop` starts by checking `runmain` (`bit runmain`). If the bit isn't set, it loops indefinitely.
*   **Process:** Once the NMI routine sets the flag, the `mainloop` clears it (`lsr runmain`) and processes one frame of input and drawing.
*   **Repeat:** This ensures the CPU logic never "outruns" the TV's refresh rate.

## 2. The VRAM Buffer Queue

Because the VBlank window is so short, the CPU cannot perform complex calculations during that time. Instead, the `mainloop` prepares a "to-do list" in the **Zero Page** (the fastest RAM).

The buffer consists of three 16-byte arrays:
*   `vram_buf_hi`: Target PPU address (high byte). A `0` here acts as a terminator.
*   `vram_buf_lo`: Target PPU address (low byte).
*   `vram_buf_val`: The 8-bit value (tile index or color) to write.

### How Updates are Queued
1.  **Frame Start:** Every frame, `vram_buf_pos` is reset to `0`.
2.  **Cursor Update:** The system always puts a mandatory update at index `0` to handle the blinking cursor's color in the PPU palette RAM (`$3Fxx`).
3.  **Drawing Updates:** If a user paints or changes an attribute, the code calls `to_vram_buf`. This routine:
    *   Increments `vram_buf_pos`.
    *   Calculates the PPU destination address (Offset + `$2000`).
    *   Stores the high/low address and the value in the next available buffer slot.
4.  **Termination:** At the end of the loop, a `0` is written to `vram_buf_hi + vram_buf_pos + 1`. This tells the NMI routine where to stop.

## 3. The NMI Routine (The "Blast")

The **Non-Maskable Interrupt (NMI)** is a hardware interrupt triggered by the PPU the moment VBlank begins. It immediately pauses the main loop and runs the high-priority rendering code.

### Step-by-Step Execution:
1.  **OAM DMA:** It first triggers a Sprite DMA. This hardware feature automatically copies 256 bytes of sprite data from CPU RAM (`$0200-$02FF`) to the PPU's internal sprite memory. This is why the cursor moves smoothly.
2.  **Buffer Flush:** It iterates through the VRAM buffer. For each entry:
    *   It writes the high and low address bytes to the PPU register `$2006` (`ppu_addr`).
    *   It writes the value to the PPU register `$2007` (`ppu_data`).
    *   It stops as soon as it reads a `0` for the high address byte.
3.  **Buffer Reset:** It clears the first byte of the buffer (`vram_buf_hi[0] = 0`) to prevent stale data from being written if the next frame has no updates.
4.  **PPU State Restore:** Because the VRAM writes change the PPU's internal address pointer, the NMI routine must reset the scroll (`ppu_scroll`) and the base address. If it didn't, the entire screen would jitter or disappear.
5.  **Signal Main Loop:** Finally, it sets the `runmain` flag, telling the CPU that the hardware is ready for the next frame of logic.

## Summary of Constraints
This architecture limits Kalle Paint to **16 VRAM updates per frame**. This is why the program uses a 1x1 or 2x2 brush; a much larger brush would exceed the 16-byte limit and could cause the "blast" to bleed out of the VBlank window, resulting in screen flickering or graphical glitches.