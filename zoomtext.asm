.include "x16.inc"

.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

jmp start

zoomchars: .byte $20,$6C,$7B,$62,$7C,$E1,$FF,$FE,$7E,$7F,$61,$FC,$E2,$FB,$EC,$A0

ZOOM_CHAR_MAP = $8000

topline:    .byte 0
bottomline: .byte 0
zoom_idx:   .word 0
line_len:   .byte 0
line_str:   .res 40
welcome:    .byte "type something!"
quit:       .byte 17,0,21,0,9,0,20,0
goodbye:    .byte "bye!"
char_color: .byte 0

WELCOME_LEN = 15
GOODBYE_LEN = 4

start:
   ldx #0
@welcome_loop:
   phx
   lda welcome,x
   jsr CHROUT
   plx
   inx
   cpx #WELCOME_LEN
   bne @welcome_loop
   jsr zoom_println
   sec
   jsr PLOT
   dex
   dex
   dex
   clc
   jsr PLOT

   stz VERA_ctrl
   lda VERA_L1_tilebase
   and #$80
   asl
   rol
   ora #$10
   sta VERA_addr_bank
   lda VERA_L1_tilebase
   and #$7C
   asl
   sta VERA_addr_high
   stz VERA_addr_low
   lda #<ZOOM_CHAR_MAP
   sta ZP_PTR_1
   lda #>ZOOM_CHAR_MAP
   sta ZP_PTR_1+1
   ldx #0
@charloop:
   phx
   ldy #0
@lineloop:
   lda VERA_data0
   sta topline
   lda VERA_data0
   sta bottomline
   phy
   ldy #0
@shiftloop:
   stz zoom_idx
   asl topline
   rol zoom_idx
   asl topline
   rol zoom_idx
   asl bottomline
   rol zoom_idx
   asl bottomline
   rol zoom_idx
   ldx zoom_idx
   lda zoomchars,x
   sta (ZP_PTR_1),y
   iny
   cpy #4
   bne @shiftloop
   lda ZP_PTR_1
   clc
   adc #4
   sta ZP_PTR_1
   lda ZP_PTR_1+1
   adc #0
   sta ZP_PTR_1+1
   ply
   iny
   cpy #4
   bne @lineloop
   plx
   inx
   cpx #0
   bne @charloop

   ; zoomed char map populated

@read_line:
   stz line_len
@chrin_loop:
   jsr CHRIN
   inc line_len
   cmp #$0D
   bne @chrin_loop
   dec line_len
   asl line_len

   sec
   jsr PLOT
   ldy #0
   stz VERA_ctrl
   lda #$10
   sta VERA_addr_bank
   stx VERA_addr_high
   stz VERA_addr_low
   clc
   jsr PLOT

   lda line_len
   cmp #41
   bmi @vpeek_line
   lda #40
   sta line_len
@vpeek_line:
   ldx #0
@vpeek_loop:
   lda VERA_data0
   sta line_str,x
   inx
   cpx line_len
   bne @vpeek_loop

   lda line_len
   cmp #8
   bne @putc_line
   ldx #0
@check_quit:
   lda line_str,x
   cmp quit,x
   bne @putc_line
   inx
   inx
   cpx #8
   beq @goodbye
   bra @check_quit

@putc_line:
   ldy #0
@putc_loop:
   lda line_str,y
   iny
   ldx line_str,y
   iny
   phy
   jsr zoom_putc
   ply
   cpy line_len
   bne @putc_loop

   jsr zoom_println
   jmp @read_line

@goodbye:
   ldx #0
@goodbye_loop:
   phx
   lda goodbye,x
   jsr CHROUT
   plx
   inx
   cpx #GOODBYE_LEN
   bne @goodbye_loop
   lda #$0D
   jsr CHROUT

rts

zoom_putc:  ; A: character to put as zoomed character
            ; X: character color
   sta zoom_idx
   stz zoom_idx+1
   stx char_color
   asl zoom_idx
   rol zoom_idx+1
   asl zoom_idx
   rol zoom_idx+1
   asl zoom_idx
   rol zoom_idx+1
   asl zoom_idx
   rol zoom_idx+1
   lda #<ZOOM_CHAR_MAP
   clc
   adc zoom_idx
   sta ZP_PTR_1
   lda #>ZOOM_CHAR_MAP
   adc zoom_idx+1
   sta ZP_PTR_1+1
   sec
   jsr PLOT
   stz VERA_ctrl
   lda #$10
   sta VERA_addr_bank
   stx VERA_addr_high
   tya
   asl
   pha
   sta VERA_addr_low
   ldx #0
   ldy #0
@loop:
   lda (ZP_PTR_1),y
   sta VERA_data0
   lda char_color
   sta VERA_data0
   iny
   tya
   and #$03
   bne @loop
   inc VERA_addr_high
   pla
   sta VERA_addr_low
   pha
   inx
   cpx #4
   beq @next
   bra @loop
@next:
   pla ; clear stack
   sec
   jsr PLOT
   iny
   iny
   iny
   iny
   clc
   jsr PLOT
   rts

zoom_println:
   sec
   jsr PLOT
   inx
   inx
   inx
   inx
   cpx #57
   bmi @down
   phx
   jsr scroll_up
   plx
   dex
   dex
   dex
   dex
@down:
   ldy #0
   clc
   jsr PLOT
   rts

scroll_up:
   stz VERA_ctrl
   lda #$10
   sta VERA_addr_bank
   lda #$04
   sta VERA_addr_high
   stz VERA_addr_low
   lda #1
   sta VERA_ctrl
   lda #$10
   sta VERA_addr_bank
   stz VERA_addr_high
   stz VERA_addr_low
   ldx #56
   ldy #0
@copy_loop:
   lda VERA_data0
   sta VERA_data1
   dey
   bne @copy_loop
   ldy #0
   dex
   bne @copy_loop
   ldx #4
@clear_loop:
   lda #$20
   sta VERA_data1
   dey
   lda #$61
   sta VERA_data1
   dey
   bne @clear_loop
   ldy #0
   dex
   bne @clear_loop
   stz VERA_ctrl
   rts
