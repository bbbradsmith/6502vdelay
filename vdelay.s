; vdelay
; Brad Smith, 2020
; https://github.com/bbbradsmith/6502vdelay

.export vdelay
; delays for X:A cycles, minimum: 63 (includes jsr)
;   A = low bits of cycles to delay
;   X = high bits of cycles to delay
;   A/X/Y clobbered

VDELAY_MINIMUM = 63
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
	cpx #0                             ; +2 = 8
	BRPAGE bne, vdelay_full            ; +2 = 10
	sec                                ; +2 = 12
	sbc #VDELAY_MINIMUM                ; +2 = 14
	BRPAGE bcc, vdelay_toolow          ; +2 = 16

vdelay_low:                            ;           29 (full path)
	pha                                ; +3 = 19 / 32 (low only / full path)
	and #7                             ; +2 = 21 / 34
	tay                                ; +2 = 23 / 36
	lda vdelay_low_jump_msb, Y         ; +4 = 27 / 40
	pha                                ; +3 = 30 / 43
	lda vdelay_low_jump_lsb, Y         ; +4 = 34 / 47
	pha                                ; +3 = 37 / 50
	rts                                ; +6 = 43 / 56

vdelay_low_rest:                       ; +5 = 48 / 61 (returning from jump table)
	pla                                ; +4 = 52 / 65
	and #$F8                           ; +2 = 54 / 67
	BRPAGE beq, vdelay_low_none        ; +2 = 56 / 69
	: ; 8 cycles each iteration
		sbc #8          ; +2 = 2
		BRPAGE bcs, *+2 ; +3 = 5 (branch always)
		BRPAGE bne, :-  ; +3 = 8         -1 = 55 / 68 (on last iteration)
	nop                                ; +2 = 57 / 70
vdelay_low_none:                       ; +3 = 57 / 70 (from branch)
	rts                                ; +6 = 63 / 76

vdelay_toolow:                         ; +3 = 17 (from branch)
	ldy #7                             ; +2 = 19
	: ; 5 cycle loop                    +35 = 54
		dey
		BRPAGE bne, :-                 ; -1 = 53 (on last iteration)
	nop                                ; +2 = 55
	nop                                ; +2 = 57
	rts                                ; +6 = 63

vdelay_full:                           ; +3 = 11
	sec                                ; +2 = 13
	sbc #VDELAY_FULL_OVERHEAD          ; +2 = 15
	tay                                ; +2 = 17
	txa                                ; +2 = 19
	sbc #0                             ; +2 = 21
	BRPAGE beq, vdelay_high_none       ; +2 = 23
	: ; 256 cycles each iteration
		ldx #49            ; +2 = 2
		: ; 5 cycle loop   +245 = 247
			dex
			BRPAGE bne, :- ; -1 = 246
		BRPAGE beq, *+2    ; +3 = 249
		sec                ; +2 = 251
		sbc #1             ; +2 = 253
		BRPAGE bne, :--    ; +3 = 256    -1 = 22 (on last iteration)
	nop                                ; +2 = 24
vdelay_high_none:                      ; +3 = 24 (from branch)
	.assert (*-vdelay_low_jump_lsb)<128, error, "Last branch does not fit alignment?"
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
vdelay_low1: jmp *+3
	jmp vdelay_low_rest
