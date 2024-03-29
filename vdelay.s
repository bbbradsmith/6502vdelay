; vdelay
;
; Authors:
; - Brad Smith
; - Fiskbit
; - Eric Anderson
; - Joel Yliluoma
; - George Foot
; - Sidney Cadot
;
; Version 11
; https://github.com/bbbradsmith/6502vdelay

.export vdelay
; delays for X:A cycles, minimum: 29 (includes jsr)
;   A = low bits of cycles to delay
;   X = high bits of cycles to delay
;   A/X clobbered (X=0)

VDELAY_MINIMUM = 29
VDELAY_FULL_OVERHEAD = 34

; assert to make sure branches do not page-cross
.macro BRPAGE instruction_, label_
    instruction_ label_
    .assert >(label_) = >*, error, "Page crossed!"
.endmacro

.align 64

vdelay:                                ; +6 = 6 (jsr)
    cpx #0                             ; +2 = 8 (sets carry)
    BRPAGE bne, vdelay_full            ; +2 = 10
    sbc #VDELAY_MINIMUM+4              ; +2 = 12
    BRPAGE bcc, vdelay_low             ; +2 = 14
vdelay_full_return:
    ; 5-cycle countdown loop + 5 paths  +19 = 33 (carry is set on entry)
@L:        sbc #5
    BRPAGE bcs, @L  ;  6 6 6 6 6  FB FC FD FE FF
           adc #3   ;  2 2 2 2 2  FE FF 00 01 02
    BRPAGE bcc, @4  ;  3 3 2 2 2  FE FF 00 01 02
           lsr      ;  - - 2 2 2  -- -- 00 00 01
    BRPAGE beq, @5  ;  - - 3 3 2  -- -- 00 00 01
@4:        lsr      ;  2 2 - - 2  7F 7F -- -- 00
@5: BRPAGE bcs, @6  ;  2 3 2 3 3  7F 7F 00 00 00
@6:        rts      ;  6 6 6 6 6                 (end >= 33)

; 256+ cycles
vdelay_full:                           ; +3 = 11 (from: bne vdelay_full)
@C: ; 5-cycle countdown until A underflows (carry is set on entry)
    sbc #5          ;  2
    BRPAGE bcs, @C  ;  3 (2 on underflow)
    ; decrement X before resuming countdown
    sbc #(6 - 1)    ;  2 (subtracting 6, but carry is clear: adjust by -1)
    dex             ;  2 (note: carry is now set, A >= $FB before sbc)
    BRPAGE bne, @C  ;  3 (2 when finished)
    ; adjust for overhead before returning to the entry routine:
    ;   bne @C not taken when X is 0     -1 = 10
    ;   vdelay_full_return sequence     +19 = 29
    sbc #VDELAY_FULL_OVERHEAD          ; +2 = 31
    BRPAGE bcs, vdelay_full_return     ; +3 = 34 (end >= 34)
    ; (note: carry is set, A >= $F5 before sbc)

; 29-32 cycles handled separately
vdelay_low:                            ; +1 = 15 (bcc)
    adc #3                             ; +2 = 17
    BRPAGE bcc, @0  ;  3 2 2 2  <0 00 01 02
    BRPAGE beq, @0  ;  - 3 2 2  -- 00 01 02
           lsr      ;  - - 2 2  -- -- 00 01
@0: BRPAGE bne, @1  ;  3 2 2 3  <0 00 00 01
@1: rts                                ; +6 = 29 (end < 33)
