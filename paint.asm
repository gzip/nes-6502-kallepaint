; Kalle Paint (NES, ASM6)

; --- Constants -----------------------------------------------------------------------------------

; Note: "VRAM buffer" = what to update in VRAM on next VBlank.

; RAM
vram_buf_hi   equ $00    ; VRAM buffer - high bytes of addresses (16 bytes)
vram_buf_lo   equ $10    ; VRAM buffer - low bytes of addresses (16 bytes)
vram_buf_val  equ $20    ; VRAM buffer - values (16 bytes)
user_palette     equ $30    ; user palette (16 bytes; each $00-$3f; offsets 4/8/12 are unused)
vram_offset    equ $40    ; offset to name/attr table 0 and vram_copy (2 bytes, low first; 0-$3ff)
vram_copy_addr equ $42    ; address in vram_copy (2 bytes, low first; vram_copy...vram_copy+$3ff)
mode        equ $44    ; program mode: 0=sm brush, 1=lg brush, 2=attr edit, 3=pal edit
runmain     equ $45    ; run main loop? (flag; only MSB is important)
pad_status   equ $46    ; first joypad status (bits: A, B, select, start, up, down, left, right)
prev_pad_status equ $47    ; first joypad status on previous frame
vram_count    equ $48    ; number of entries in VRAM buffer (0-16)
temp        equ $49    ; temporary
delay_left   equ $4a    ; cursor move delay left (paint mode)
brush_size   equ $4b    ; cursor type (paint mode; 0=small, 1=big)
paint_color  equ $4c    ; paint color (paint mode; 0-3)
cursor_x     equ $4d    ; cursor X position (paint/attribute edit mode; 0-63)
cursor_y     equ $4e    ; cursor Y position (paint/attribute edit mode; 0-55)
blink_timer  equ $4f    ; cursor blink timer (attribute/palette editor)
pal_edit_cursor_pos equ $50    ; cursor position (palette editor; 0-3)
pal_edit_subpal equ $51    ; selected subpalette (palette editor; 0-3)
prev_mode   equ $52    ; previous mode (to return to after palette editor)
active_subpalette equ $53 ; currently active subpalette (1-3)
vram_ready  equ $54    ; VRAM buffer ready flag (1 = ready for NMI)
cursor_color_dirty equ $55 ; cursor color needs VRAM update (paint mode)
sprite_data     equ $0200  ; $100 bytes (see init_sprite_data for layout)
vram_copy    equ $0300  ; $400 bytes (copy of name/attribute table 0; must be at $xx00)
; END RAM

; memory-mapped registers; see https://wiki.nesdev.org/w/index.php/PPU_registers
ppu_ctrl     equ $2000
ppu_mask     equ $2001
ppu_status   equ $2002
oam_addr     equ $2003
ppu_scroll   equ $2005
ppu_addr     equ $2006
ppu_data     equ $2007
dmcfreq     equ $4010
oam_dma      equ $4014
sndchn      equ $4015
joypad1     equ $4016
joypad2     equ $4017

; joypad bitmasks
pad_a       equ 1<<7                     ; A
pad_b       equ 1<<6                     ; B
pad_select      equ 1<<5                     ; select
pad_start      equ 1<<4                     ; start
pad_up       equ 1<<3                     ; up
pad_down       equ 1<<2                     ; down
pad_left       equ 1<<1                     ; left
pad_right       equ 1<<0                     ; right

; default user palette
def_bg_color  equ $0f  ; background (all subpalettes)
def_color_0a  equ $15  ; reds
def_color_0b  equ $25
def_color_0c  equ $35
def_color_1a  equ $18  ; yellows
def_color_1b  equ $28
def_color_1c  equ $38
def_color_2a  equ $1b  ; greens
def_color_2b  equ $2b
def_color_2c  equ $3b
def_color_3a  equ $12  ; blues
def_color_3b  equ $22
def_color_3c  equ $32

; user interface colors
pal_edit_bg_color  equ $0f  ; palette editor background (black)
pal_edit_txt_color equ $30  ; palette editor text (white)
blinkcol1   equ $00  ; blinking cursor 1
blinkcol2   equ $10  ; blinking cursor 2 (gray)

; sprite tile indexes (note: hexadecimal digits "0"-"F" must start at $00)
small_cursor_tile equ $10  ; small paint cursor
large_cursor_tile  equ $11  ; large paint cursor
attr_cursor_tile equ $12  ; corner of attribute cursor
dotted_corner_tile equ $17 ; dotted corner for auto-attr indicator
cover_tile   equ $13  ; cover (palette editor)
pal_tile_1    equ $14  ; left  half of "Pal" (palette editor)
pal_tile_2    equ $15  ; right half of "Pal" (palette editor)
color_ind_tile  equ $16  ; color indicator (palette editor)

; misc
blink_rate   equ 4      ; attribute/palette editor cursor blink rate (0=fastest, 7=slowest)
brush_delay  equ 2      ; paint cursor move repeat delay (frames)
v_scroll     equ 0      ; PPU vertical scroll value (VRAM $2000 is at the top of visible area)

; --- iNES header ---------------------------------------------------------------------------------

            ; see https://wiki.nesdev.org/w/index.php/INES
            base $0000
            db "NES", $1a            ; file id
            db 1, 1                  ; 16 KiB PRG ROM, 8 KiB CHR ROM
            db %00000001, %00000000  ; NROM mapper, vertical name table mirroring
            pad $0010, $00           ; unused

; --- Start of PRG ROM ----------------------------------------------------------------------------

            ; only use last 2 KiB of CPU address space
            base $c000
            pad $f800, $ff

; --- Initialization and main loop ----------------------------------------------------------------

macro wait_vblank
            bit ppu_status  ; wait until next VBlank starts
-           bit ppu_status
            bpl -
endm

reset       ; initialize the NES; see https://wiki.nesdev.org/w/index.php/Init_code
            sei             ; ignore IRQs
            cld             ; disable decimal mode
            ldx #%01000000
            stx joypad2     ; disable APU frame IRQ
            ldx #$ff
            txs             ; initialize stack pointer
            inx
            stx ppu_ctrl     ; disable NMI
            stx ppu_mask     ; disable rendering
            stx dmcfreq     ; disable DMC IRQs
            stx sndchn      ; disable sound channels

            wait_vblank

            lda #$00             ; clear zero page and vram_copy
            tax
-           sta $00,x
            sta vram_copy,x
            sta vram_copy+$100,x
            sta vram_copy+$200,x
            sta vram_copy+$300,x
            inx
            bne -

            ldx #(16-1)        ; init user palette
-           lda init_palette,x
            sta user_palette,x
            dex
            bpl -

            ldx #(24*4-1)      ; init sprite data
-           lda init_sprite_data,x
            sta sprite_data,x
            dex
            bpl -

            ldx #(1*4)       ; show impact box sprites (#1-#4)
            ldy #4
-           lda init_sprite_data,x
            sta sprite_data,x
            inx
            inx
            inx
            inx
            dey
            bne -

            ldx #(5*4)       ; hide remaining sprites (#5-#63)
            ldy #59
            jsr hide_sprites  ; X = first byte index, Y = count

            lda #30         ; init misc vars
            sta cursor_x
            lda #26
            sta cursor_y
            lda #0
            sta mode
            sta brush_size
            lda #1
            sta paint_color
            sta active_subpalette
            sta cursor_color_dirty

            wait_vblank

            lda #$3f           ; init PPU palette
            sta ppu_addr
            ldx #$00
            stx ppu_addr
-           lda init_palette,x
            sta ppu_data
            inx
            cpx #32
            bne -

            lda #$20     ; clear name/attribute table 0 ($400 bytes)
            sta ppu_addr
            lda #$00
            sta ppu_addr
            ldy #4
--          tax
-           sta ppu_data
            inx
            bne -
            dey
            bne --

            bit ppu_status  ; reset ppu_addr/ppu_scroll latch
            lda #$00       ; reset PPU address and set scroll
            sta ppu_addr
            sta ppu_addr
            sta ppu_scroll
            lda #v_scroll
            sta ppu_scroll

            wait_vblank

            lda #%10001000  ; NMI, 8*8-px sprites, pattern table 0 for BG and 1 for sprites,
            sta ppu_ctrl     ; 1-byte VRAM address auto-increment, name table 0

            lda #%00011110  ; show BG & sprites on entire screen,
            sta ppu_mask     ; don't use R/G/B de-emphasis or grayscale mode

mainloop    bit runmain      ; the main loop
            bpl mainloop     ; wait until NMI routine has run
            lsr runmain      ; clear flag to prevent main loop from running until after next NMI

            lda #0
            sta vram_ready
            sta vram_count

            lda pad_status    ; store previous joypad status
            sta prev_pad_status

            ldx #$01        ; read first joypad
            stx pad_status   ; initialize; set LSB of variable to detect end of loop
            stx joypad1
            dex
            stx joypad1
-           clc             ; read 8 buttons; each one = OR of two LSBs
            lda joypad1
            and #%00000011
            beq +
            sec
+           rol pad_status
            bcc -

            lda #$3f             ; tell NMI routine to update blinking cursor in VRAM
            sta vram_buf_hi+0
            lda #(4*4+3)
            sta vram_buf_lo+0
            ldx #blinkcol1
            lda blink_timer
            and #(1<<blink_rate)
            beq +
            ldx #blinkcol2
+           stx vram_buf_val+0
            lda #1               ; we have one entry (blinking cursor)
            sta vram_count

            inc blink_timer  ; advance timer
            jsr jump_engine  ; run code for the program mode we're in

            lda #1               ; signal that buffer is ready for NMI
            sta vram_ready

            jmp mainloop

init_palette ; initial palette
            ; background (also the initial user palette)
            db def_bg_color, def_color_0a, def_color_0b, def_color_0c
            db def_bg_color, def_color_1a, def_color_1b, def_color_1c
            db def_bg_color, def_color_2a, def_color_2b, def_color_2c
            db def_bg_color, def_color_3a, def_color_3b, def_color_3c
            ; sprites
            ; 2nd color in all subpalettes: palette editor background
            ; 3rd color in all subpalettes: selected colors in palette editor
            ; 4th color in 1st subpalette : all cursors
            ; 4th color in 2nd subpalette : palette editor text
            db def_bg_color, pal_edit_bg_color, def_bg_color,  def_color_0a
            db def_bg_color, pal_edit_bg_color, def_color_0a, pal_edit_txt_color
            db def_bg_color, pal_edit_bg_color, def_color_0b,         $00
            db def_bg_color, pal_edit_bg_color, def_color_0c,         $00

init_sprite_data ; initial sprite data (Y, tile, attributes, X for each sprite)
            ; paint mode
            db    $ff, small_cursor_tile, %00000001,    0  ; #0:  cursor
            ; attribute editor / paint impact indicator
            db    $ff, attr_cursor_tile, %00000000,    0  ; #1:  cursor top left
            db    $ff, attr_cursor_tile, %01000000,    0  ; #2:  cursor top right
            db    $ff, attr_cursor_tile, %10000000,    0  ; #3:  cursor bottom left
            db    $ff, attr_cursor_tile, %11000000,    0  ; #4:  cursor bottom right
            ; palette editor
            db    $ff,  large_cursor_tile, %00000000, 29*8  ; #5:  cursor
            db 22*8-1,    pal_tile_1, %00000001, 28*8  ; #6:  left  half of "Pal"
            db 22*8-1,    pal_tile_2, %00000001, 29*8  ; #7:  right half of "Pal"
            db 22*8-1,         $00, %00000001, 30*8  ; #8:  subpalette number
            db 23*8-1,         $0c, %00000001, 28*8  ; #9:  "C"
            db 23*8-1,         $00, %00000001, 29*8  ; #10: color number - 16s
            db 23*8-1,         $00, %00000001, 30*8  ; #11: color number - ones
            db 24*8-1,  color_ind_tile, %00000000, 29*8  ; #12: color 0
            db 25*8-1,  color_ind_tile, %00000001, 29*8  ; #13: color 1
            db 26*8-1,  color_ind_tile, %00000010, 29*8  ; #14: color 2
            db 27*8-1,  color_ind_tile, %00000011, 29*8  ; #15: color 3
            db 24*8-1,   cover_tile, %00000001, 28*8  ; #16: cover (to left  of color 0)
            db 24*8-1,   cover_tile, %00000001, 30*8  ; #17: cover (to right of color 0)
            db 25*8-1,   cover_tile, %00000001, 28*8  ; #18: cover (to left  of color 1)
            db 25*8-1,   cover_tile, %00000001, 30*8  ; #19: cover (to right of color 1)
            db 26*8-1,   cover_tile, %00000001, 28*8  ; #20: cover (to left  of color 2)
            db 26*8-1,   cover_tile, %00000001, 30*8  ; #21: cover (to right of color 2)
            db 27*8-1,   cover_tile, %00000001, 28*8  ; #22: cover (to left  of color 3)
            db 27*8-1,   cover_tile, %00000001, 30*8  ; #23: cover (to right of color 3)

jump_engine  ldx mode           ; jump engine (run one sub depending on program mode)
            lda jump_table_hi,x  ; note: don't inline this sub
            pha                ; push target address minus one, high byte first
            lda jump_table_lo,x
            pha
            rts                ; pull address, low byte first; jump to that address plus one

jump_table_hi dh paint_mode-1, paint_mode-1, attr_editor-1, pal_editor-1  ; jump table - high bytes
jump_table_lo dl paint_mode-1, paint_mode-1, attr_editor-1, pal_editor-1  ; jump table - low bytes

; --- Paint mode (code label prefix "pm") ---------------------------------------------------------

paint_mode   lda prev_pad_status  ; select/B/start logic
            and #(pad_select|pad_b|pad_start)
            bne pm_arrows     ; if any pressed on previous frame, ignore them all

            lda pad_status    ; if start pressed, switch to palette editor
            and #pad_start
            beq +
            lda mode          ; save current mode
            sta prev_mode
            lda #3           ; mode 3 = palette editor
            sta mode
            lda #$ff         ; hide paint cursor sprite
            sta sprite_data+0+0
            ldx #(1*4)       ; hide impact box sprites (#1-#4)
            ldy #4
            jsr hide_sprites
            ldx #(5*4)       ; show palette editor sprites (#5-#23)
-           lda init_sprite_data,x
            sta sprite_data,x
            inx
            inx
            inx
            inx
            cpx #(24*4)
            bne -
            rts              ; return to main loop

+           lda pad_status    ; if select pressed, switch to next mode
            and #pad_select
            beq +
            lda mode          ; check if we are in small or large brush mode
            beq ++            ; if small (0), go to large (1)

            ; we are in large brush mode (1), switch to attribute editor (2)
            lda #2           ; mode 2 = attribute editor
            sta mode
            lda #$ff         ; hide paint cursor sprite
            sta sprite_data+0+0
            lda #%00111100   ; make cursor coordinates a multiple of four
            and cursor_x
            sta cursor_x
            lda #%00111100
            and cursor_y
            sta cursor_y
            rts              ; return to main loop

++          lda #1           ; mode 1 = large brush
            sta mode
            sta brush_size
            lsr cursor_x      ; make coordinates even for large brush
            asl cursor_x
            lsr cursor_y
            asl cursor_y
            rts

+           lda pad_status    ; if B pressed, increment paint color (0-3)
            and #pad_b
            beq pm_arrows
            ldx paint_color
            inx
            txa
            and #%00000011
            sta paint_color
            lda #1
            sta cursor_color_dirty

pm_arrows    lda pad_status    ; arrow logic
            and #(pad_up|pad_down|pad_left|pad_right)
            bne +
            sta delay_left    ; if none pressed, clear cursor move delay
            beq paint_mode_2   ; unconditional; ends with rts
+           lda delay_left    ; else if delay > 0, decrement it and exit
            beq +
            dec delay_left
            bpl paint_mode_2   ; unconditional; ends with rts

+           lda pad_status    ; check horizontal arrows
            lsr a
            bcs +
            lsr a
            bcs ++
            bcc pm_check_vert  ; unconditional
+           lda cursor_x      ; right
            sec
            adc brush_size
            bpl +++          ; unconditional
++          lda cursor_x      ; left
            clc
            sbc brush_size
+++         and #%00111111   ; store horizontal position
            sta cursor_x

pm_check_vert lda pad_status    ; check vertical arrows
            lsr a
            lsr a
            lsr a
            bcs +
            lsr a
            bcs ++
            bcc pm_arrow_end   ; unconditional
+           lda cursor_y      ; down
            sec
            adc brush_size
            cmp #56
            bne +++
            lda #0
            beq +++          ; unconditional
++          lda cursor_y      ; up
            clc
            sbc brush_size
            bpl +++
            lda #56
            clc
            sbc brush_size
+++         sta cursor_y      ; store vertical position

pm_arrow_end  lda #brush_delay  ; reinit cursor move delay
            sta delay_left

paint_mode_2  ; paint mode, part 2

            ; update cursor sprite
            lda cursor_x        ; X pos
            asl a
            asl a
            sta sprite_data+0+3
            lda cursor_y        ; Y pos
            asl a
            asl a
            sec
            sbc #1             ; screen-relative (line 0 = nametable line 0)
            sta sprite_data+0+0
            ldx brush_size      ; tile
            lda cursortiles,x
            sta sprite_data+0+1

            ; update impact box sprites (#1-#4)
            lda #dotted_corner_tile
            sta sprite_data+1*4+1
            sta sprite_data+2*4+1
            sta sprite_data+3*4+1
            sta sprite_data+4*4+1

            lda cursor_x
            and #%11111100
            asl a
            asl a
            sta sprite_data+4+3 ; #1 X
            sta sprite_data+3*4+3 ; #3 X
            adc #8             ; carry is always clear
            sta sprite_data+2*4+3 ; #2 X
            sta sprite_data+4*4+3 ; #4 X
            
            lda cursor_y
            and #%11111100
            asl a
            asl a
            sec
            sbc #1             ; screen-relative (line 0 = nametable line 0)
            sta sprite_data+4+0 ; #1 Y
            sta sprite_data+2*4+0 ; #2 Y
            adc #8             ; carry is always clear
            sta sprite_data+3*4+0 ; #3 Y
            sta sprite_data+4*4+0 ; #4 Y

            lda cursor_color_dirty
            beq ++
            ldx paint_color       ; color 0 is common to all subpalettes
            beq +
            lda active_subpalette
            asl a
            asl a
            ora paint_color
            tax
+           lda user_palette,x        ; cursor color -> A
            pha                  ; append to VRAM buffer
            ldx vram_count
            cpx #16
            bcs +
            lda #$3f
            sta vram_buf_hi,x
            lda #$17             ; palette 1 color 3
            sta vram_buf_lo,x
            pla
            sta vram_buf_val,x
            inc vram_count
            lda #0
            sta cursor_color_dirty
            jmp ++
+           pla
++          lda pad_status  ; if A not pressed, we are done
            and #pad_a
            beq rts_label

            ; edit one byte (tile) in vram_copy and tell NMI routine to update it to VRAM

            ; compute offset to vram_copy and VRAM $2000;
            ; bits: cursor_y = 00ABCDEF, cursor_x = 00abcdef,
            ; -> vram_offset = 000000AB CDEabcde
            lda cursor_y
            lsr a           ; A = 00ABCDE (Tile Y)
            sta temp
            lsr a
            lsr a
            lsr a           ; A = 000000AB
            sta vram_offset+1
            lda temp
            and #%00000111  ; A = 00000CDE
            asl a
            asl a
            asl a
            asl a
            asl a           ; A = CDE00000
            sta temp
            lda cursor_x
            lsr a           ; A = 00abcde
            ora temp
            sta vram_offset+0 ; vram_offset+0 = CDEabcde

            jsr get_vram_copy_addr  ; get vram_copy_addr
            lda brush_size
            beq +

            ldx paint_color    ; large brush -> replace entire byte (tile) with a solid color
            lda solid_tiles,x
            jmp update_tile

+           ; small brush -> replace a bit pair (pixel) within the original byte
            ldy #0               ; original byte -> stack
            lda (vram_copy_addr),y
            pha
            lda cursor_x          ; pixel position within tile (0-3) -> X
            lsr a
            lda cursor_y
            rol a
            and #%00000011
            tax
            lda pixel_masks,x     ; AND mask for clearing a bit pair -> temp
            eor #%11111111
            sta temp
            ldy paint_color       ; OR mask for changing a cleared bit pair -> X
            lda solid_tiles,y
            and pixel_masks,x
            tax
            pla                  ; pull original byte, clear bit pair and change it
            and temp
            stx temp
            ora temp

update_tile  ldy #0               ; update byte in vram_copy
            sta (vram_copy_addr),y
            jsr to_vram_buf        ; tell NMI routine to update A to VRAM
            jsr auto_update_attribute ; update attribute for the current 16x16 area
rts_label    rts                  ; return to main loop

cursortiles db small_cursor_tile, large_cursor_tile                     ; brush size -> cursor tile
solid_tiles  db %00000000, %01010101, %10101010, %11111111  ; tiles of solid color 0-3
pixel_masks  db %11000000, %00110000, %00001100, %00000011  ; bitmasks for pixels within tile index

; --- Attribute editor (code label prefix "ae") ---------------------------------------------------

attr_editor  lda prev_pad_status  ; surgical debounce for mode-switching buttons
            and #(pad_start|pad_select)
            bne ae_arrows

            lda pad_status      ; if start pressed, switch to palette editor
            and #pad_start
            beq +
            lda mode          ; save current mode
            sta prev_mode
            lda #3           ; mode 3 = palette editor
            sta mode
            ldx #(1*4)       ; hide attribute editor sprites (#1-#4)
            ldy #4
            jsr hide_sprites    ; X = first byte index, Y = count
            ldx #(5*4)       ; show palette editor sprites (#5-#23)
-           lda init_sprite_data,x
            sta sprite_data,x
            inx
            inx
            inx
            inx
            cpx #(24*4)
            bne -
            rts              ; return to main loop

+           lda pad_status      ; if select pressed, switch back to paint mode (small brush)
            and #pad_select
            beq ae_arrows
            ldx #(1*4)         ; re-init impact box sprites (#1-#4)
            ldy #4
-           lda init_sprite_data,x
            sta sprite_data,x
            inx
            inx
            inx
            inx
            dey
            bne -
            lda #0             ; mode 0 = small brush
            sta mode
            sta brush_size
            lda init_sprite_data+0+0  ; show paint cursor sprite
            sta sprite_data+0+0
            rts                ; return to main loop

ae_arrows    lda pad_status    ; arrow logic
            and #(pad_up|pad_down|pad_left|pad_right)
            bne +
            sta delay_left    ; if none pressed, clear cursor move delay
            beq ae_check_stamp
+           lda delay_left    ; else if delay > 0, decrement it and exit
            beq +
            dec delay_left
            bpl ae_check_stamp
+           lda pad_status    ; check horizontal arrows
            lsr a
            bcs +
            lsr a
            bcs ++
            bcc ae_check_vert  ; unconditional
+           lda cursor_x      ; right
            adc #(4-1)       ; carry is always set
            bcc +++          ; unconditional
++          lda cursor_x      ; left
            sbc #4           ; carry is always set
+++         and #%00111111   ; store horizontal position
            sta cursor_x
ae_check_vert lda pad_status    ; check vertical arrows
            lsr a
            lsr a
            lsr a
            bcs +
            lsr a
            bcs ++
            bcc ae_arrow_end  ; unconditional
+           lda cursor_y      ; down
            adc #(4-1)       ; carry is always set
            cmp #56
            bne +++
            lda #0
            beq +++          ; unconditional
++          lda cursor_y      ; up
            sbc #4           ; carry is always set
            bpl +++
            lda #(56-4)
+++         sta cursor_y      ; store vertical position

ae_arrow_end lda #brush_delay  ; reinit cursor move delay
            sta delay_left

ae_check_stamp lda pad_status   ; if A/B pressed, stamp the active subpalette
            and #(pad_a|pad_b)
            beq attr_editor_2
            jsr auto_update_attribute

attr_editor_2 lda #attr_cursor_tile
            sta sprite_data+1*4+1
            sta sprite_data+2*4+1
            sta sprite_data+3*4+1
            sta sprite_data+4*4+1
            lda cursor_x        ; update cursor sprite X
            asl a
            asl a
            sta sprite_data+4+3
            sta sprite_data+3*4+3
            adc #8             ; carry is always clear
            sta sprite_data+2*4+3
            sta sprite_data+4*4+3
            lda cursor_y        ; update cursor sprite Y
            asl a
            asl a
            sec
            sbc #1             ; screen-relative (line 0 = nametable line 0)
            sta sprite_data+4+0
            sta sprite_data+2*4+0
            clc
            adc #8             ; ensure perfect 8-pixel alignment
            sta sprite_data+3*4+0
            sta sprite_data+4*4+0
            rts                ; return to main loop

bp_change_masks  db %00000001, %00000011  ; bit pair change masks (LSB or both LSB and MSB of each)
            db %00000100, %00001100
            db %00010000, %00110000
            db %01000000, %11000000

; --- Subroutines used by both paint mode and attribute editor ------------------------------------

attr_bit_pos  lda cursor_y     ; position within attribute byte -> X (0/2/4/6)
            and #%00000100  ; bits: cursor_y = 00ABCDEF, cursor_x = 00abcdef -> X = 00000Dd0
            lsr a
            tax
            lda cursor_x
            and #%00000100
            cmp #%00000100  ; bit -> carry
            txa
            adc #0
            asl a
            tax
            rts

attr_vram_offset lda #%00000011  ; get VRAM offset for attribute byte, fall through to next sub
            sta vram_offset+1  ; bits: cursor_y = 00ABCDEF, cursor_x = 00abcdef
            lda cursor_y     ; -> vram_offset = $3c0 + 00ABCabc = 00000011 11ABCabc
            and #%00111000
            sta temp
            lda cursor_x
            lsr a
            lsr a
            lsr a
            ora temp
            ora #%11000000
            sta vram_offset+0  ; fall through to next sub

get_vram_copy_addr lda vram_offset+0     ; get address within vram_copy
            sta vram_copy_addr+0  ; vram_copy + vram_offset -> vram_copy_addr (vram_copy must be at $xx00)
            lda #>vram_copy
            clc
            adc vram_offset+1
            sta vram_copy_addr+1
            rts

to_vram_buf   pha               ; tell NMI routine to write A to VRAM $2000 + vram_offset
            ldx vram_count
            cpx #16
            bcs +
            lda #$20
            ora vram_offset+1
            sta vram_buf_hi,x
            lda vram_offset+0
            sta vram_buf_lo,x
            pla
            sta vram_buf_val,x
            inc vram_count
            rts
+           pla
            rts

auto_update_attribute
            jsr attr_vram_offset      ; sets vram_offset and vram_copy_addr
            jsr attr_bit_pos          ; returns 0/2/4/6 in X
            
            inx                       ; X = 1/3/5/7 for 2-bit mask
            lda bp_change_masks,x
            eor #%11111111            ; invert to clear bits
            sta temp
            
            ldy #0
            lda (vram_copy_addr),y    ; get current attribute byte from vram_copy
            and temp                  ; clear the target quadrant bits
            sta temp
            
            dex                       ; X = 0/2/4/6 for shifting
            lda active_subpalette     ; get subpalette (0-3)
            and #%00000011            ; safety
            cpx #0
            beq +
-           asl a
            asl a                     ; active_subpalette is bits 1-0, shift by 2 each iteration
            dex
            dex
            bne -
+           ora temp                  ; combine with other quadrants
            
            ldy #0
            sta (vram_copy_addr),y    ; update vram_copy
            jsr to_vram_buf           ; queue VRAM update (uses vram_offset set by attr_vram_offset)
            rts

; --- Palette editor (code label prefix "pe") -----------------------------------------------------

pal_editor   lda prev_pad_status  ; if any button pressed on previous frame, ignore all
            beq +
            jmp pal_editor_2
+           lda pad_status
            lsr a
            bcc +
            jmp pe_inc_1s      ; right
+           lsr a
            bcc +
            jmp pe_dec_1s      ; left
+           lsr a
            bcc +
            jmp pe_down       ; down
+           lsr a
            bcc +
            jmp pe_up         ; up
+           lsr a
            bcc +
            jmp pe_exit       ; start
+           lsr a
            bcc +
            jmp pe_inc_subpal  ; select
+           lda pad_status
            and #pad_b
            beq +
            jmp pe_dec_16s     ; B
+           lda pad_status
            and #pad_a
            beq +
            jmp pe_inc_16s     ; A
+           jmp pal_editor_2

pe_exit     lda pal_edit_cursor_pos
            sta paint_color
            lda pal_edit_subpal
            sta active_subpalette
            lda #1
            sta cursor_color_dirty
            ldx #(5*4)       ; exit palette editor (switch to previous mode)
            ldy #19          ; hide palette editor sprites (#5-#23)
            jsr hide_sprites  ; X = first byte index, Y = count
            lda prev_mode
            sta mode         ; restore program mode
            cmp #2           ; if we were in paint mode (0 or 1)
            bcs +
            lda init_sprite_data+0+0  ; show paint cursor sprite
            sta sprite_data+0+0
            ldx #(1*4)       ; show impact box sprites (#1-#4)
            ldy #4
-           lda init_sprite_data,x
            sta sprite_data,x
            inx
            inx
            inx
            inx
            dey
            bne -
            rts
+           ; we were in attribute editor (2)
            ldx #(1*4)
-           lda init_sprite_data,x
            sta sprite_data,x
            inx
            inx
            inx
            inx
            cpx #(5*4)
            bne -
            rts              ; return to main loop

pe_inc_subpal lda pal_edit_subpal  ; increment subpalette (0 -> 1 -> 2 -> 3 -> 0)
            adc #0           ; carry is always set
            and #%00000011
            sta pal_edit_subpal
            bpl pal_editor_2   ; unconditional

pe_down      ldx pal_edit_cursor_pos  ; move down
            inx
            bpl pe_store_pos   ; unconditional
pe_up        ldx pal_edit_cursor_pos  ; move up
            dex
pe_store_pos  txa              ; store cursor pos
            and #%00000011
            sta pal_edit_cursor_pos
            tax
            bpl pal_editor_2   ; unconditional

pe_inc_1s     jsr user_pal_offset  ; increment ones
            ldy user_palette,x
            iny
            bpl pe_store_1s    ; unconditional
pe_dec_1s     jsr user_pal_offset  ; decrement ones
            ldy user_palette,x
            dey
pe_store_1s   tya              ; store ones
            and #%00001111
            sta temp
            lda user_palette,x
            and #%00110000
            ora temp
            sta user_palette,x
            bpl pal_editor_2   ; unconditional

pe_inc_16s    jsr user_pal_offset  ; increment sixteens
            lda user_palette,x
            clc
            adc #$10
            bpl pe_store_16s   ; unconditional
pe_dec_16s    jsr user_pal_offset  ; decrement sixteens
            lda user_palette,x
            sec
            sbc #$10
pe_store_16s  and #%00111111   ; store sixteens
            sta user_palette,x
            bpl pal_editor_2   ; unconditional

pal_editor_2  lda pal_edit_subpal    ; palette editor, part 2
            sta sprite_data+8*4+1  ; update tile of selected subpalette
            lda pal_edit_cursor_pos    ; update cursor Y position
            asl a
            asl a
            asl a
            adc #(24*8-1)      ; carry is always clear
            sta sprite_data+5*4+0
            jsr user_pal_offset    ; update sixteens tile of color number
            lda user_palette,x
            lsr a
            lsr a
            lsr a
            lsr a
            sta sprite_data+10*4+1
            lda user_palette,x       ; update ones tile of color number
            and #%00001111
            sta sprite_data+11*4+1

            ; tell NMI routine to update 5 VRAM bytes
            jsr user_pal_offset
            pha
            ldx vram_count
            cpx #11             ; room for 5?
            bcs +
            lda #$3f            ; selected color -> background palette
            sta vram_buf_hi,x
            pla
            sta vram_buf_lo,x
            tay
            lda user_palette,y
            sta vram_buf_val,x
            inx
            lda #$3f            ; 1st color of all subpalettes
            sta vram_buf_hi,x
            lda #(4*4+2)
            sta vram_buf_lo,x
            lda user_palette+0
            sta vram_buf_val,x
            inx
            lda pal_edit_subpal     ; subpalette offset in user palette -> Y
            asl a
            asl a
            tay
            lda #$3f            ; 2nd color of selected subpalette
            sta vram_buf_hi,x
            lda #(5*4+2)
            sta vram_buf_lo,x
            lda user_palette+1,y
            sta vram_buf_val,x
            inx
            lda #$3f            ; 3rd color of selected subpalette
            sta vram_buf_hi,x
            lda #(6*4+2)
            sta vram_buf_lo,x
            lda user_palette+2,y
            sta vram_buf_val,x
            inx
            lda #$3f            ; 4th color of selected subpalette
            sta vram_buf_hi,x
            lda #(7*4+2)
            sta vram_buf_lo,x
            lda user_palette+3,y
            sta vram_buf_val,x
            inx
            stx vram_count
            rts
+           pla
            rts

user_pal_offset lda pal_edit_cursor_pos  ; offset to user palette (user_palette or VRAM $3f00-$3f0f) -> A, X
            beq +            ; if 1st color of any subpal, zero
            lda pal_edit_subpal  ; else, subpalette * 4 + cursor pos
            asl a
            asl a
            ora pal_edit_cursor_pos
+           tax
            rts

; --- Subroutines used by many parts of the program -----------------------------------------------

hide_sprites lda #$ff       ; hide some sprites (X = first index on sprite page, Y = count)
-           sta sprite_data,x
            inx
            inx
            inx
            inx
            dey
            bne -
            rts

; --- Interrupt routines --------------------------------------------------------------------------

nmi         pha            ; push A, X, Y
            txa
            pha
            tya
            pha
            bit ppu_status  ; reset ppu_addr/ppu_scroll latch
            lda #$00       ; do OAM DMA
            sta oam_addr
            lda #>sprite_data
            sta oam_dma

            lda vram_ready    ; only update VRAM if main loop says it's ready
            beq skip_vram

            ldx vram_count    ; update VRAM from buffer
            beq nmi_done_vram
nmi_loop    dex
            lda vram_buf_hi,x
            sta ppu_addr
            lda vram_buf_lo,x
            sta ppu_addr
            lda vram_buf_val,x
            sta ppu_data
            txa
            bne nmi_loop

nmi_done_vram lda #0
            sta vram_count    ; reset count
            sta vram_ready   ; reset ready flag

skip_vram   ; PROPER SCROLL RESET
            lda #%10001000    ; NMI enabled, Nametable 0
            sta ppu_ctrl
            bit ppu_status    ; reset latch
            lda #$00
            sta ppu_scroll    ; horizontal scroll = 0
            lda #v_scroll
            sta ppu_scroll    ; vertical scroll
            
            sec               ; set flag to let main loop run once
            ror runmain
            pla               ; pull Y, X, A
            tay
            pla
            tax
            pla

irq         rti

; --- Interrupt vectors ---------------------------------------------------------------------------

            pad $fffa, $ff
            dw nmi, reset, irq  ; note: IRQ unused
            pad $10000, $ff

; --- CHR ROM -------------------------------------------------------------------------------------

            base $0000
            incbin "chr-background.bin"  ; 256 tiles (4 KiB)
            pad $1000, $ff
            incbin "chr-sprites.bin"     ; 256 tiles (4 KiB)
            pad $2000, $ff
