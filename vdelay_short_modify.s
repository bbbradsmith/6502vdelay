; vdelay (short self-modifying version)
;
; Authors:
; - Fiskbit
; - Brad Smith
;
; Version 8
; https://github.com/bbbradsmith/6502vdelay

.export vdelay
; delays for A cycles, minimum: 33 (includes jsr)
;   A = cycles to delay
;   A clobbered

VDELAY_MINIMUM = 33

; assert to make sure branches do not page-cross
.macro BRPAGE instruction_, label_
    instruction_ label_
    .assert >(label_) = >*, error, "Page crossed!"
.endmacro

.align 32

.segment "RAMCODE"

vdelay_clockslide_branch: ; exactly 22 bytes before the clockslide branch
    rts

vdelay:                                ; +6 = 6 (jsr)
    sec                                ; +2 = 8
    sbc #VDELAY_MINIMUM                ; +2 = 10
    BRPAGE bcc, vdelay_toolow          ; +2 = 12
    : ; 5 cycle countdown + 1 extra loop (carry is set on entry, clear on exit)
        sbc #5                         ; +2 = 14 (counting last time only)
        BRPAGE bcs, :-                 ; +2 = 16 (counting last time only)
    eor #$FF                           ; +2 = 18 (clears minus flag, A=0,1,2,3,4)
    sta vdelay_modify+1                ; +4 = 22
vdelay_modify:
    BRPAGE bpl, vdelay_clockslide      ; +3 = 25 (branch always)

; This "clockslide" overlaps instructions so that each byte adds one cycle to the tally.
; 0-4 cycles + 2 cycles of overhead (A clobbered)
vdelay_clockslide:                     ; +2 = 27
    .byte $A9           ; 0     LDA #$A9 (+2)
    .byte $A9           ; 1     LDA #$A9 (+2)
    .byte $A9           ; 0,2   LDA #$90 (+2)
    .byte $90           ; 1,3   BCC *+2+$EA-$100 (+3, carry guaranteed clear)
    .byte $EA           ; 0,2,4 NOP (+2)
    .assert >(vdelay_clockslide) = >(vdelay_clockslide+4), error, "Clockslide crosses page."
    .assert >(*+$EA-$100) = >*, error, "Clockslide branch page crossed!"
    .assert (*+$EA-$100) = vdelay_clockslide_branch, error, "Clockslide branch misplaced!"
    rts                                ; +6 = 33 (end)

vdelay_toolow:                         ; +3 = 13 (from branch)
    php                                ; +3 = 16
    plp                                ; +4 = 20
    php                                ; +3 = 23
    plp                                ; +4 = 27
    rts                                ; +6 = 33 (end)
