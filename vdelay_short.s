; vdelay (short version)
;
; Authors:
; - Eric Anderson
; - Fiskbit
; - Brad Smith
;
; Version 9
; https://github.com/bbbradsmith/6502vdelay

.export vdelay
; delays for A cycles, minimum: 34 (includes jsr)
;   A = cycles to delay
;   A clobbered (A=0)

VDELAY_MINIMUM = 34

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
    lsr                                ; +2 = 14
    BRPAGE bcs, vdelay_2s              ; +2 = 16 (1 extra if bit 1 set)
vdelay_2s:
    lsr                                ; +2 = 18
vdelay_toolow_resume:
    BRPAGE bcc, vdelay_4s              ; +3 = 21 (2 extra if bit 2 set)
    BRPAGE bcs, vdelay_4s              ; +3 (branch always)
vdelay_4s:
    lsr                                ; +2 = 23
    BRPAGE bcc, vdelay_8s              ; +3 = 26
    clc                                ; +2 (-1 bcc not taken)
    BRPAGE bcc, vdelay_8s              ; +3 (+2+3-1 = 4 extra if bit 4 set)
vdelay_8s:                             ; (8 extra per loop, countdown)
    BRPAGE bne, vdelay_wait8_clc       ; +2 = 28 (+1 if braching)
    rts                                ; +6 = 34 (end)
vdelay_wait8_clc:
    sbc #0                             ; +2 (carry is clear, subtract 1 less)
    BRPAGE bcs, vdelay_loop8           ; +3 (branch always, A>=0)
vdelay_wait8_sec:
    sbc #1                             ; +2 (carry is set, sutract 1)
    BRPAGE bcs, vdelay_loop8           ; +3 (branch always, A>=0)
vdelay_loop8:
    BRPAGE bne, vdelay_wait8_sec       ; +3 (-1 if ending = 28)
    rts                                ; +6 = 34 (end)

vdelay_toolow:
    lda #0                             ; +2 = 15
    BRPAGE bcc, vdelay_toolow_resume   ; +3 = 18 (branch always)
