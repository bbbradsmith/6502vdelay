; vdelay (short version)
;
; Authors:
; - Fiskbit
; - Brad Smith
;
; Version 7
; https://github.com/bbbradsmith/6502vdelay

.export vdelay
; delays for A cycles, minimum: 46 (includes jsr)
;   A = cycles to delay
;   A/X clobbered

VDELAY_MINIMUM = 46

; assert to make sure branches do not page-cross
.macro BRPAGE instruction_, label_
    instruction_ label_
    .assert >(label_) = >*, error, "Page crossed!"
.endmacro

.align 64

vdelay:                                ; +6 = 6 (jsr)
    sec                                ; +2 = 8
    sbc #VDELAY_MINIMUM                ; +2 = 10
    BRPAGE bcc, vdelay_toolow          ; +2 = 12
    : ; 5 cycle countdown + 1 extra loop (carry is set on entry, clear on exit)
        sbc #5                         ; +2 = 14 (counting last time only)
        BRPAGE bcs, :-                 ; +2 = 16 (counting last time only)
    tax                                ; +2 = 18
    lda #>(vdelay_clockslide-1)        ; +2 = 20
    pha                                ; +3 = 23
    txa                                ; +2 = 25
    eor #$FF                           ; +2 = 27
    adc #<(vdelay_clockslide-1)        ; +2 = 29
    pha                                ; +3 = 32
    rts                                ; +6 = 38 (to clockslide)

; This "clockslide" overlaps instructions so that each byte adds one cycle to the tally.
; 0-4 cycles + 2 cycles of overhead (A clobbered)
vdelay_clockslide:                     ; +2 = 40
    .byte $A9           ; 0     LDA #$A9 (+2)
    .byte $A9           ; 1     LDA #$A9 (+2)
    .byte $A9           ; 0,2   LDA #$90 (+2)
    .byte $90           ; 1,3   BCC *+2+$0A (+3, carry guaranteed clear)
    .byte $0A           ; 0,2,4 ASL (+2)
    .assert >(vdelay_clockslide-1) = >(vdelay_clockslide+4-1), error, "Clockslide crosses page."
    .assert >(*+$0A) = >*, error, "Clockslide branch page crossed!"
    .assert (*+$0A) = vdelay_clockslide_branch, error, "Clockslide branch misplaced!"
    rts                                ; +6 = 46 (end)

vdelay_toolow:                         ; +3 = 13 (from branch)
    ldx #3                             ; +2 = 15
    : ; 8 cycle loop                   ;+24 = 39
        jmp *+3
        dex
        bne :-                         ; -1 = 38 (on last iteration)
    nop                                ; +2 = 40
vdelay_clockslide_branch: ; exactly 10 bytes past the clockslide branch
    rts                                ; +6 = 46 (end)
