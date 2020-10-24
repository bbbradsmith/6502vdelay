; vdelay (extreme version)
;
; Authors:
; - Eric Anderson
; - Brad Smith
; - Fiskbit
;
; Version 9
; https://github.com/bbbradsmith/6502vdelay

.export vdelay
; delays for X:A cycles, minimum: 31 (includes jsr)
;   A = low bits of cycles to delay
;   X = high bits of cycles to delay
;   A/X clobbered

DIVIDED = 0 ; 0 = all in RAM, 1 = some in RAM, most in ROM
VDELAY_MINIMUM = 31
VDELAY_FULL_OVERHEAD = 52

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

vdelay_clockslide:                     ; +2 = 25
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
    rts                                ; +6 = 31 (end)

.if DIVIDED <> 0
	.segment "RAMCODE"
	.align 16
.endif

vdelay:                                ; +6 = 6 (jsr)
    cpx #0                             ; +2 = 8
    bne vdelay_full                    ; +2 = 10
    cmp #VDELAY_MINIMUM                ; +2 = 12
    BRPAGE bcc, vdelay_toolow          ; +2 = 14
    eor #$FF                           ; +2 = 16
    sta vdelay_modify+1                ; +4 = 20
vdelay_modify:
    jmp vdelay_clockslide              ; +3 = 23

vdelay_toolow:                         ; +3 = 15 (from branch)
    sec                                ; +2 = 17
    jmp 20+6 + (vdelay_clockslide_end+2) - VDELAY_MINIMUM ; +3 = 20 (+6 rts)

vdelay_full:                           ; +3 = 11 (branch taken)
    jmp vdelay_full_jmp                ; +3 = 14

.if DIVIDED <> 0
	.segment "CODE"
	nop ; padding
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
.endif

vdelay_clockslide_branch: ; exactly 24=$18 bytes past the clockslide branch (10=$0A if DIVIDED)
    rts                                ; +6 = 27 (end)

vdelay_full_jmp:                       ;      14 (carry is set)
    sbc #VDELAY_FULL_OVERHEAD          ; +2 = 16
    pha                                ; +3 = 19
    txa                                ; +2 = 21
    sbc #0                             ; +2 = 23
    BRPAGE beq, vdelay_high_none       ; +2 = 25
    : ; 256 cycles each iteration
        ldx #50            ; +2 = 2
        : ; 5 cycle loop   +250 = 252
            dex
            BRPAGE bne, :- ; -1 = 251
        sbc #1             ; +2 = 253 (carry always set)
        BRPAGE bne, :--    ; +3 = 256    -1 = 24 (on last iteration)
    nop                                ; +2 = 26
vdelay_high_none:                      ; +3 = 26 (from branch)
    pla                                ; +4 = 30
; from vdelay_short.s:
    lsr                                ; +2 = 32
    BRPAGE bcs, vdelay_2s              ; +2 = 34 (1 extra if bit 1 set)
vdelay_2s:
    lsr                                ; +2 = 36
vdelay_toolow_resume:
    BRPAGE bcc, vdelay_4s              ; +3 = 39 (2 extra if bit 2 set)
    BRPAGE bcs, vdelay_4s              ; +3 (branch always)
vdelay_4s:
    lsr                                ; +2 = 41
    BRPAGE bcc, vdelay_8s              ; +3 = 44
    clc                                ; +2 (-1 bcc not taken)
    BRPAGE bcc, vdelay_8s              ; +3 (+2+3-1 = 4 extra if bit 4 set)
vdelay_8s:                             ; (8 extra per loop, countdown)
    BRPAGE bne, vdelay_wait8_clc       ; +2 = 46 (+1 if braching)
    rts                                ; +6 = 52 (end)
vdelay_wait8_clc:
    sbc #0                             ; +2 (carry is clear, subtract 1 less)
    BRPAGE bcs, vdelay_loop8           ; +3 (branch always, A>=0)
vdelay_wait8_sec:
    sbc #1                             ; +2 (carry is set, sutract 1)
    BRPAGE bcs, vdelay_loop8           ; +3 (branch always, A>=0)
vdelay_loop8:
    BRPAGE bne, vdelay_wait8_sec       ; +3 (-1 if ending = 28)
    rts                                ; +6 = 52 (end)
