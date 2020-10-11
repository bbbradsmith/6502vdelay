; vdelay (short version)
; Brad Smith, 2020
; https://github.com/bbbradsmith/6502vdelay

.export vdelay
; delays for A cycles, minimum: 56 (includes jsr)
;   A = cycles to delay
;   A/X/Y clobbered

VDELAY_MINIMUM = 56

; assert to make sure branches do not page-cross
.macro BRPAGE instruction_, label_
	instruction_ label_
	.assert >(label_) = >*, error, "Page crossed!"
.endmacro

.align 128 ; this code has no branches after 128 bytes

; jump table
vdelay_low_jump_lsb:
	.byte <(vdelay_low0-1)
	.byte <(vdelay_low1-1)
	.byte <(vdelay_low2-1)
	.byte <(vdelay_low3-1)
	.byte <(vdelay_low4-1)
	.byte <(vdelay_low5-1)
	.byte <(vdelay_low6-1)
	.byte <(vdelay_low7-1)
.assert >(*-1) = >vdelay_low_jump_lsb, error, "Jump table page crossed!"
vdelay_low_jump_msb:
	.byte >(vdelay_low0-1)
	.byte >(vdelay_low1-1)
	.byte >(vdelay_low2-1)
	.byte >(vdelay_low3-1)
	.byte >(vdelay_low4-1)
	.byte >(vdelay_low5-1)
	.byte >(vdelay_low6-1)
	.byte >(vdelay_low7-1)
.assert >(*-1) = >vdelay_low_jump_msb, error, "Jump table page crossed!"

vdelay: ;                                +6 = 6 (jsr)
	sec                                ; +2 = 8
	sbc #VDELAY_MINIMUM                ; +2 = 10
	BRPAGE bcc, vdelay_toolow          ; +2 = 12
	tax                                ; +2 = 14
	and #7                             ; +2 = 16
	tay                                ; +2 = 18
	lda vdelay_low_jump_msb, Y         ; +4 = 22
	pha                                ; +3 = 25
	lda vdelay_low_jump_lsb, Y         ; +4 = 29
	pha                                ; +3 = 32
	rts                                ; +6 = 38

vdelay_low_rest:                       ; +5 = 43
	txa                                ; +2 = 45
	and #$F8                           ; +2 = 47
	BRPAGE beq, vdelay_low_none        ; +2 = 49
	: ; 8 cycles each iteration
		sbc #8          ; +2 = 2
		BRPAGE bcs, *+2 ; +3 = 5 (branch always)
		BRPAGE bne, :-  ; +3 = 8         -1 = 48 (on last iteration)
	nop                                ; +2 = 50
vdelay_low_none:                       ; +3 = 50 (from branch)
	rts                                ; +6 = 56

vdelay_toolow:                         ; +3 = 13 (from branch)
	ldy #4                             ; +2 = 15
	: ; 9 cycle loop                    +36 = 51
		nop
		nop
		dey
		BRPAGE bne, :-                 ; -1 = 50 (on last iteration)
	rts                                ; +6 = 56

; each of these is 5 cycles + 0-7 cycles
vdelay_low6: nop
vdelay_low4: nop
vdelay_low2: nop
vdelay_low0: nop
	jmp vdelay_low_rest
vdelay_low7: nop
vdelay_low5: nop
vdelay_low3: nop
vdelay_low1: BRPAGE bcs, *+2 ; (+3) branch always
	jmp vdelay_low_rest
