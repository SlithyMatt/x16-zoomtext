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

start:
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
   lda #8
   jsr zoom_putc
   lda #5
   jsr zoom_putc
   lda #12
   jsr zoom_putc
   lda #12
   jsr zoom_putc
   lda #15
   jsr zoom_putc
   lda #$2C
   jsr zoom_putc
   jsr zoom_println
   lda #23
   jsr zoom_putc
   lda #15
   jsr zoom_putc
   lda #18
   jsr zoom_putc
   lda #12
   jsr zoom_putc
   lda #4
   jsr zoom_putc
   lda #$21
   jsr zoom_putc
   jsr zoom_println
rts

zoom_putc:  ; A: character to put as zoomed character
   sta zoom_idx
   stz zoom_idx+1
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
   lda #$20
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
   ldy #0
   clc
   jsr PLOT
   rts
