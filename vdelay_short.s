; vdelay (short version)
;
; Authors:
; - Eric Anderson
; - Fiskbit
; - Brad Smith
;
; Version 8
; https://github.com/bbbradsmith/6502vdelay

.export vdelay
; delays for A cycles, minimum: 35 (includes jsr)
;   A = cycles to delay
;   A clobbered (A=0)

VDELAY_MINIMUM = 35

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
    BRPAGE bcs, vdelay_wait4           ; +2 = 25 (4 extra if bit 3 set)
vdelay_8s:
    sec                                ; +2 = 27
vdelay_loop8:                          ;         (8 extra per loop, countdown)
    BRPAGE bne, vdelay_wait8           ; +2 = 29
    rts                                ; +6 = 35 (end)

vdelay_toolow:
    lda #0                             ; +2
    BRPAGE bcc, vdelay_toolow_resume   ; +3 (branch always)
vdelay_wait4:
    BRPAGE bcs, vdelay_8s              ; +3 (branch always)
vdelay_wait8:
    sbc #1                             ; +2
    BRPAGE bcs, vdelay_loop8           ; +3 (branch always)
