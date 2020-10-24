; vdelay (short extreme version)
;
; Authors:
; - Eric Anderson
; - Brad Smith
; - Fiskbit
;
; Version 9
; https://github.com/bbbradsmith/6502vdelay

.export vdelay
; delays for A cycles, minimum: 27 (includes jsr)
;   A = cycles to delay
;   A clobbered

DIVIDED = 0 ; 0 = all in RAM, 1 = some in RAM, most in ROM
VDELAY_MINIMUM = 27

; assert to make sure branches do not page-cross
.macro BRPAGE instruction_, label_
    instruction_ label_
    .assert >(label_) = >*, error, "Page crossed!"
.endmacro

.if DIVIDED <> 0
	.segment "CODE"
	CS_END = $0A ; ASL (+2, branch *+2+$0A)
.else
	.segment "RAMCODE"
	CS_END = $18 ; CLC (+2, branch *+2+$18)
.endif

.align 256

vdelay_clockslide:                     ; +2 = 21
    .repeat 256-VDELAY_MINIMUM-2
        .byte $A9 ; LDA #$A9 (+2)
    .endrepeat    ; LDA #$B0 (+2)
    .byte $B0     ; BCS *+2+$18 (+3, carry guaranteed set)
vdelay_clockslide_end:
    .byte CS_END  ; CLC/ASL (+2)
    .assert <vdelay_clockslide =  0, error, "Clockslide must begin on a page boundary."
    .assert >vdelay_clockslide = >vdelay_clockslide_end, error, "Clockslide crosses page."
    .assert >(*+CS_END) = >*, error, "Clockslide branch page crossed!"
    .assert (*+CS_END) = vdelay_clockslide_branch, error, "Clockslide branch misplaced!"
    rts                                ; +6 = 27 (end)

.if DIVIDED <> 0
	.segment "RAMCODE"
	.align 16
.endif

vdelay:                                ; +6 = 6 (jsr)
    cmp #VDELAY_MINIMUM                ; +2 = 8
    BRPAGE bcc, vdelay_toolow          ; +2 = 10
    eor #$FF                           ; +2 = 12
    sta vdelay_modify+1                ; +4 = 16
vdelay_modify:
    jmp vdelay_clockslide              ; +3 = 19

vdelay_toolow:                         ; +3 = 11 (from branch)
    sec                                ; +2 = 13
    jmp 16+6 + (vdelay_clockslide_end+2) - VDELAY_MINIMUM ; +3 = 16 (+6 rts)

.if DIVIDED <> 0
	.segment "CODE"
	nop ; padding
	nop
.endif

    nop ; padding
    nop
    nop
    nop
    nop
    nop
    nop
vdelay_clockslide_branch: ; exactly 24=$18 bytes past the clockslide branch (10=$0A if DIVIDED)
    rts                                ; +6 = 27 (end)
