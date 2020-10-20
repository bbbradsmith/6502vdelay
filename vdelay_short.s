; vdelay (short version)
;
; Authors:
; - Ejona
; - Fiskbit
; - Brad Smith
;
; Version 8
; https://github.com/bbbradsmith/6502vdelay

.export vdelay
; delays for A cycles, minimum: 38 (includes jsr)
;   A = cycles to delay
;   A clobbered

VDELAY_MINIMUM = 38

; assert to make sure branches do not page-cross
.macro BRPAGE instruction_, label_
    instruction_ label_
    .assert >(label_) = >*, error, "Page crossed!"
.endmacro

.align 32

vdelay:                                ; +6 = 6 (jsr)
    sec                                ; +2 = 8
    sbc #VDELAY_MINIMUM                ; +2 = 10
    BRPAGE bcc, vdelay_toolow          ; +2 = 12
    BRPAGE bcs, vdelay_low             ; +3 = 15 (branch taken)
vdelay_toolow:
    lda #0                             ; +2
vdelay_low:
    lsr                                ; +2 = 17
    BRPAGE bcs, vdelay_2s              ; +2 = 19 (1 extra if bit 1 set)
vdelay_2s:
    lsr                                ; +2 = 21
    BRPAGE bcc, vdelay_4s              ; +3 = 24 (2 extra if bit 2 set)
    BRPAGE bcs, vdelay_4s              ; +3 (branch always)
vdelay_4s:
    lsr                                ; +2 = 26
    BRPAGE bcs, vdelay_wait4           ; +2 = 28 (4 extra if bit 3 set)
vdelay_8s:
    sec                                ; +2 = 30
vdelay_loop8:                          ;         (8 extra per loop, countdown)
    BRPAGE bne, vdelay_wait8           ; +2 = 32
    rts                                ; +6 = 38 (end)
vdelay_wait4:
    BRPAGE bcs, vdelay_8s              ; +3 (branch always)
vdelay_wait8:
    sbc #1                             ; +2
    BRPAGE bcs, vdelay_loop8           ; +3 (branch always)
