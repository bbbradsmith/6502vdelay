; vdelay
;
; Authors:
; - Brad Smith
; - Fiskbit
;
; Version 7
; https://github.com/bbbradsmith/6502vdelay

.export vdelay
; delays for X:A cycles, minimum: 48 (includes jsr)
;   A = low bits of cycles to delay
;   X = high bits of cycles to delay
;   A/X/Y clobbered

VDELAY_MINIMUM = 48
VDELAY_FULL_OVERHEAD = 63

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
vdelay_low:
    : ; 5 cycle countdown + 1 extra loop (carry is set on entry)
        sbc #5                         ; +2 = 16 (counting last time only)
        BRPAGE bcs, :-                 ; +2 = 18 (counting last time only)
    tax                                ; +2 = 20
    lda #>(vdelay_clockslide-1)        ; +2 = 22
    pha                                ; +3 = 25
    txa                                ; +2 = 27
    eor #$FF                           ; +2 = 29
    adc #<(vdelay_clockslide-1)        ; +2 = 31
    pha                                ; +3 = 34
    rts                                ; +6 = 40 (to clockslide)

; This "clockslide" overlaps instructions so that each byte adds one cycle to the tally.
; 0-4 cycles + 2 cycles of overhead (A clobbered)
vdelay_clockslide:                     ; +2 = 42
    .byte $A9           ; 0     LDA #$A9 (+2)
    .byte $A9           ; 1     LDA #$A9 (+2)
    .byte $A9           ; 0,2   LDA #$90 (+2)
    .byte $90           ; 1,3   BCC *+2+$0A (+3, carry guaranteed clear)
    .byte $0A           ; 0,2,4 ASL (+2)
    .assert >(vdelay_clockslide-1) = >(vdelay_clockslide+4-1), error, "Clockslide crosses page."
    .assert >(*+$0A) = >*, error, "Clockslide branch page crossed!"
    .assert (*+$0A) = vdelay_clockslide_branch, error, "Clockslide branch misplaced!"
    rts                                ; +6 = 48 (end)

vdelay_toolow:                         ; +3 = 15 (from branch)
    ldx #3                             ; +2 = 17
    : ; 8 cycle loop                   ;+24 = 41
        jmp *+3
        dex
        bne :-                         ; -1 = 40 (on last iteration)
    nop                                ; +2 = 42
vdelay_clockslide_branch: ; exactly 10 bytes from the clockslide branch
    rts                                ; +6 = 48 (end)

vdelay_full:                           ; +3 = 11
    sec                                ; +2 = 13
    sbc #VDELAY_FULL_OVERHEAD          ; +2 = 15
    tay                                ; +2 = 17
    txa                                ; +2 = 19
    sbc #0                             ; +2 = 21
    BRPAGE beq, vdelay_high_none       ; +2 = 23
    : ; 256 cycles each iteration
        ldx #50            ; +2 = 2
        : ; 5 cycle loop   +250 = 252
            dex
            BRPAGE bne, :- ; -1 = 251
        sbc #1             ; +2 = 253 (carry always set)
        BRPAGE bne, :--    ; +3 = 256    -1 = 22 (on last iteration)
    nop                                ; +2 = 24
vdelay_high_none:                      ; +3 = 24 (from branch)
    tya                                ; +2 = 26
    jmp vdelay_low                     ; +3 = 29
    ;                                -14+48 = 63 (full end)
