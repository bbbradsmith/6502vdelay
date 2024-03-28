; vdelay (short version)
;
; Authors:
; - Eric Anderson
; - Joel Yliluoma
; - Brad Smith
; - Fiskbit
;
; Version 10
; https://github.com/bbbradsmith/6502vdelay

.export vdelay
; delays for A cycles, minimum: 27 (includes jsr)
;   A = cycles to delay
;   A clobbered

VDELAY_MINIMUM = 27

; assert to make sure branches do not page-cross
.macro BRPAGE instruction_, label_
    instruction_ label_
    .assert >(label_) = >*, error, "Page crossed!"
.endmacro

.align 32

vdelay:                                ; +6 = 6 (jsr)
    sec                                ; +2 = 8
    sbc #VDELAY_MINIMUM+4              ; +2 = 10
    BRPAGE bcc, vdelay_low             ; +2 = 12
    ; 5-cycle coundown loop + 5 paths   +19 = 31 (end >= 31)
@L:        sbc #5
    BRPAGE bcs, @L  ;  6 6 6 6 6  FB FC FD FE FF
           adc #3   ;  2 2 2 2 2  FE FF 00 01 02
    BRPAGE bcc, @4  ;  3 3 2 2 2  FE FF 00 01 02
           lsr      ;  - - 2 2 2  -- -- 00 00 01
    BRPAGE beq, @5  ;  - - 3 3 2  -- -- 00 00 01
@4:        lsr      ;  2 2 - - 2  7F 7F -- -- 00
@5: BRPAGE bcs, @6  ;  2 3 2 3 3  7F 7F 00 00 00
@6:        rts      ;  6 6 6 6 6

; 27-30 cycles handled separately
vdelay_low:                            ; +1 = 13 (bcc)
    adc #3                             ; +2 = 15
    BRPAGE bcc, @0  ;  3 2 2 2  <0 00 01 02
    BRPAGE beq, @0  ;  - 3 2 2  -- 00 01 02
           lsr      ;  - - 2 2  -- -- 00 01
@0: BRPAGE bne, @1  ;  3 2 2 3  <0 00 00 01
@1: rts                                ; +6 = 27 (end < 31)
