; vdelay
; Brad Smith, 2020
; https://github.com/bbbradsmith/6502vdelay

.export vdelay
; delays for X:A cycles, minimum: 61 (includes jsr)
;   A = low bits of cycles to delay
;   X = high bits of cycles to delay
;   A/X/Y clobbered

VDELAY_MINIMUM = 61
VDELAY_FULL_OVERHEAD = 76

; assert to make sure branches do not page-cross
.macro BRPAGE instruction_, label_
	instruction_ label_
	.assert >(label_) = >*, error, "Page crossed!"
.endmacro

.align 128

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
	cpx #0                             ; +2 = 8 (sets carry)
	BRPAGE bne, vdelay_full            ; +2 = 10
	sbc #VDELAY_MINIMUM                ; +2 = 12
	BRPAGE bcc, vdelay_toolow          ; +2 = 14

vdelay_low:                            ;           29 (full path)
	pha                                ; +3 = 17 / 32 (low only / full path)
	and #7                             ; +2 = 19 / 34
	tay                                ; +2 = 21 / 36
	lda vdelay_low_jump_msb, Y         ; +4 = 25 / 40
	pha                                ; +3 = 28 / 43
	lda vdelay_low_jump_lsb, Y         ; +4 = 32 / 47
	pha                                ; +3 = 35 / 50
	rts                                ; +6 = 41 / 56

vdelay_low_rest:                       ; +5 = 46 / 61 (returning from jump table)
	pla                                ; +4 = 50 / 65
	and #$F8                           ; +2 = 52 / 67
	BRPAGE beq, vdelay_low_none        ; +2 = 54 / 69
	: ; 8 cycles each iteration
		sbc #8          ; +2 = 2
		BRPAGE bcs, *+2 ; +3 = 5 (branch always)
		BRPAGE bne, :-  ; +3 = 8         -1 = 53 / 68 (on last iteration)
	nop                                ; +2 = 55 / 70
vdelay_low_none:                       ; +3 = 55 / 70 (from branch)
	rts                                ; +6 = 61 / 76

vdelay_toolow:                         ; +3 = 15 (from branch)
	ldy #7                             ; +2 = 17
	: ; 5 cycle loop                    +35 = 52
		dey
		BRPAGE bne, :-                 ; -1 = 51 (on last iteration)
	nop                                ; +2 = 53
	nop                                ; +2 = 55
	rts                                ; +6 = 61

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
