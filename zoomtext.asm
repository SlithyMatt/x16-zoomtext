.include "x16.inc"

.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

jmp start

doublechars: .byte 20,6C,7B,62,7C,E1,FF,FE,7E,7F,61,FC,E2,FB,EC,A0

DOUBLE_CHAR_MAP = $8000

topline:    .byte 0
bottomline: .byte 0

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
   ldx #0
@charloop:
   ldy #0
@lineloop:
   lda VERA_data0
   sta topline
   lda VERA_data0
   sta bottomline




rts
