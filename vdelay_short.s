; vdelay (short version)
; Brad Smith, 2020
; https://github.com/bbbradsmith/6502vdelay

.export vdelay
; delays for A cycles, minimum: 57 (includes jsr)
;   A = cycles to delay
;   A/X/Y clobbered

VDELAY_MINIMUM = 57

; assert to make sure branches do not page-cross
.macro BRPAGE instruction_, label_
	instruction_ label_
	.assert >(label_) = >*, error, "Page crossed!"
.endmacro

; 3 cycle "nop" that does not alter flags
.macro NOP3
	jmp *+3
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
.assert >* = >vdelay_low_jump_lsb, error, "Jump table page crossed!"
vdelay_low_jump_msb:
	.byte >(vdelay_low0-1)
	.byte >(vdelay_low1-1)
	.byte >(vdelay_low2-1)
	.byte >(vdelay_low3-1)
	.byte >(vdelay_low4-1)
	.byte >(vdelay_low5-1)
	.byte >(vdelay_low6-1)
	.byte >(vdelay_low7-1)
.assert >* = >vdelay_low_jump_msb, error, "Jump table page crossed!"

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
	sec                                ; +2 = 34
	rts                                ; +6 = 40

vdelay_low_rest:                       ; +8 = 48
	; A = remaining cycles to burn, truncated to nearest 8
	; Z flag matches A
	BRPAGE beq, vdelay_low_none        ; +2 = 50
	: ; 8 cycles each iteration
		sbc #8         ;  +2 = 2
		NOP3           ;  +3 = 5
		BRPAGE bne, :- ;  +3 = 8         -1 = 49 (on last iteration)
	nop                                ; +2 = 51
vdelay_low_none:                       ; +3 = 51 (from branch)
	rts                                ; +6 = 57

vdelay_toolow:                         ; +3 = 13 (from branch)
	.assert (*-vdelay_low_jump_lsb)<128, error, "Last branch does not fit alignment?"
	jsr vdelay_24                      ;+24 = 37
	jsr vdelay_12                      ;+12 = 49
	nop                                ; +2 = 51
	rts                                ; +6 = 57

; each of these is 8 cycles + 0-7 cycles
; carry is set on entry, and Z is set to A on return
; their job is to get the remaining delay cycles to a multiple of 8,
; and adjust A to compensate
vdelay_low0:
	txa                       ; +2
	; no sbc                  ; -2
	NOP3
	jmp vdelay_low_rest       ; +3
vdelay_low1:
	txa                       ; +2
	sbc #1                    ; +2
	nop
	jmp vdelay_low_rest       ; +3
vdelay_low2:
	txa
	sbc #2
	NOP3
	jmp vdelay_low_rest
vdelay_low3:
	txa
	sbc #3
	nop
	nop
	jmp vdelay_low_rest
vdelay_low4:
	txa
	sbc #4
	nop
	NOP3
	jmp vdelay_low_rest
vdelay_low5:
	txa
	sbc #5
	NOP3
	NOP3
	jmp vdelay_low_rest
vdelay_low6:
	txa
	sbc #6
	nop
	nop
	NOP3
	jmp vdelay_low_rest
vdelay_low7:
	txa
	sbc #7
	nop
	NOP3
	NOP3
	jmp vdelay_low_rest

; a few compact delays
vdelay_24: jsr vdelay_12
vdelay_12: rts
