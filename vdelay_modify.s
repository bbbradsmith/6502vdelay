; vdelay (self-modifying version)
;
; Authors:
; - Brad Smith
; - Fiskbit
;
; Version 8
; https://github.com/bbbradsmith/6502vdelay

.export vdelay
; delays for X:A cycles, minimum: 35 (includes jsr)
;   A = low bits of cycles to delay
;   X = high bits of cycles to delay
;   A/X clobbered

VDELAY_MINIMUM = 35
VDELAY_FULL_OVERHEAD = 51

; assert to make sure branches do not page-cross
.macro BRPAGE instruction_, label_
    instruction_ label_
    .assert >(label_) = >*, error, "Page crossed!"
.endmacro

.align 64

.segment "RAMCODE"

vdelay:                                ; +6 = 6 (jsr)
    cpx #0                             ; +2 = 8 (sets carry)
    BRPAGE bne, vdelay_full            ; +2 = 10
    sbc #VDELAY_MINIMUM                ; +2 = 12
    BRPAGE bcc, vdelay_toolow          ; +2 = 14
vdelay_low:
    : ; 5 cycle countdown + 1 extra loop (carry is set on entry, clear on exit)
        sbc #5                         ; +2 = 16 (counting last time only)
        BRPAGE bcs, :-                 ; +2 = 18 (counting last time only)
    eor #$FF                           ; +2 = 20 (clears minus flag, A=0,1,2,3,4)
    sta vdelay_modify+1                ; +4 = 24
vdelay_modify:
    BRPAGE bpl, vdelay_clockslide      ; +3 = 27 (branch always)

; This "clockslide" overlaps instructions so that each byte adds one cycle to the tally.
; 0-4 cycles + 2 cycles of overhead (A clobbered)
vdelay_clockslide:                     ; +2 = 29
    .byte $A9           ; 0     LDA #$A9 (+2)
    .byte $A9           ; 1     LDA #$A9 (+2)
    .byte $A9           ; 0,2   LDA #$90 (+2)
    .byte $90           ; 1,3   BCC *+2+$18 (+3, carry guaranteed clear)
    .byte $18           ; 0,2,4 CLC (+2)
    .assert >(vdelay_clockslide) = >(vdelay_clockslide+4), error, "Clockslide crosses page."
    .assert >(*+$18) = >*, error, "Clockslide branch page crossed!"
    .assert (*+$18) = vdelay_clockslide_branch, error, "Clockslide branch misplaced!"
    rts                                ; +6 = 35 (end)

vdelay_full:                           ; +3 = 11 (carry is set)
    sbc #VDELAY_FULL_OVERHEAD          ; +2 = 13
    pha                                ; +3 = 16
    txa                                ; +2 = 18
    sbc #0                             ; +2 = 20
    BRPAGE beq, vdelay_high_none       ; +2 = 22
    : ; 256 cycles each iteration
        ldx #50            ; +2 = 2
        : ; 5 cycle loop   +250 = 252
            dex
            BRPAGE bne, :- ; -1 = 251
        sbc #1             ; +2 = 253 (carry always set)
        BRPAGE bne, :--    ; +3 = 256    -1 = 21 (on last iteration)
    nop                                ; +2 = 23
vdelay_high_none:                      ; +3 = 23 (from branch)
    pla                                ; +4 = 27
    jmp vdelay_low                     ; +3 = 30
    ;                                -14+35 = 51 (full end)

    nop ; padding
vdelay_clockslide_branch: ; exactly 24 bytes past the clockslide branch
    rts                                ; +6 = 35 (end)

vdelay_toolow:                         ; +3 = 15 (from branch)
    php                                ; +3 = 18
    plp                                ; +4 = 22
    php                                ; +3 = 25
    plp                                ; +4 = 29
    rts                                ; +6 = 35 (end)
