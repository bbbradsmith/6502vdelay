; vdelay
;
; Authors:
; - Ejona
; - Brad Smith
; - Fiskbit
;
; Version 8
; https://github.com/bbbradsmith/6502vdelay

.export vdelay
; delays for X:A cycles, minimum: 48 (includes jsr)
;   A = low bits of cycles to delay
;   X = high bits of cycles to delay
;   A/X clobbered

VDELAY_MINIMUM = 40
VDELAY_FULL_OVERHEAD = 55

; assert to make sure branches do not page-cross
.macro BRPAGE instruction_, label_
    instruction_ label_
    .assert >(label_) = >*, error, "Page crossed!"
.endmacro

.align 64

vdelay:                                ; +6 = 6 (jsr)
    cpx #0                             ; +2 = 8 (sets carry)
    BRPAGE bne, vdelay_full            ; +2 = 10
    sbc #VDELAY_MINIMUM                ; +2 = 12
    BRPAGE bcc, vdelay_toolow          ; +2 = 14
    BRPAGE bcs, vdelay_low             ; +3 = 17 (branch taken)
vdelay_toolow:
    lda #0                             ; +2
vdelay_low:
    lsr                                ; +2 = 19
    BRPAGE bcs, vdelay_2s              ; +2 = 21 (1 extra if bit 1 set)
vdelay_2s:
    lsr                                ; +2 = 23
    BRPAGE bcc, vdelay_4s              ; +3 = 26 (2 extra if bit 2 set)
    BRPAGE bcs, vdelay_4s              ; +3 (branch always)
vdelay_4s:
    lsr                                ; +2 = 28
    BRPAGE bcs, vdelay_wait4           ; +2 = 30 (4 extra if bit 3 set)
vdelay_8s:
    sec                                ; +2 = 32
vdelay_loop8:                          ;         (8 extra per loop, countdown)
    BRPAGE bne, vdelay_wait8           ; +2 = 34
    rts                                ; +6 = 40 (end)

vdelay_wait4:
    BRPAGE bcs, vdelay_8s              ; +3 (branch always)
vdelay_wait8:
    sbc #1                             ; +2
    BRPAGE bcs, vdelay_loop8           ; +3 (branch always)

vdelay_full:                           ; +3 = 11
    sec                                ; +2 = 13
    sbc #VDELAY_FULL_OVERHEAD          ; +2 = 15
    pha                                ; +3 = 18
    txa                                ; +2 = 20
    sbc #0                             ; +2 = 22
    BRPAGE beq, vdelay_high_none       ; +2 = 24
    : ; 256 cycles each iteration
        ldx #50            ; +2 = 2
        : ; 5 cycle loop   +250 = 252
            dex
            BRPAGE bne, :- ; -1 = 251
        sbc #1             ; +2 = 253 (carry always set)
        BRPAGE bne, :--    ; +3 = 256    -1 = 23 (on last iteration)
    nop                                ; +2 = 25
vdelay_high_none:                      ; +3 = 25 (from branch)
    pla                                ; +4 = 29
    jmp vdelay_low                     ; +3 = 32
    ;                                -17+40 = 55 (full end)
