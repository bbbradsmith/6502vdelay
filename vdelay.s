; vdelay
; Brad Smith, 2020
; https://github.com/bbbradsmith/6502vdelay

.export vdelay
; delays for A:X cycles, minimum: 78 (includes jsr)
;   A = low bits of cycles to delay
;   X = high bits of cycles to delay
;   A/X/Y clobbered
;   stack descends up to 12 bytes

; NOTE:
; with an "intro" jump table of 512 bytes, and a large amount of nopslide code
; we could lower the minimum delay to 40 cycles, but this seemed too cumbersome
; to be worthwhile. It would look something like this:
; vdelay:
;     cpx #0
;     bne vdelay_long
;     tay
;     lda vdelay_short_jump + 256, Y
;     pha
;     lda vdelay_short_jump + 0, Y
;     pha
;     rts
; (the above is 38 cycles including jsr and the rts following the rts-jump)

; NOTE:
; could probably reduce VDELAY_MINIMUM by skipping the high portion for low-only

VDELAY_MINIMUM = 78

; assert to make sure branches do not page-cross
.macro BRPAGE instruction_, label_
	instruction_ label_
	.assert >(label_) = >*, error, "Page crossed!"
.endmacro

; 3 cycle "nop" that does not alter flags
.macro NOP3
	jmp *+3
.endmacro

.align 256

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
	; subtract overhead from target
	sec                                ; +2 = 8
	sbc #VDELAY_MINIMUM                ; +2 = 10
	tay                                ; +2 = 12
	txa                                ; +2 = 14
	sbc #0                             ; +2 = 16
	BRPAGE bcc, vdelay_toolow          ; +2 = 18 (branch)
	tax                                ; +2 = 20
	; Y = low-cycles (1 each)
	; X = high-cycles (256 each)
	tya                                ; +2 = 22
	BRPAGE bne, vdelay_low             ; +2 = 24 (branch)
	jsr vdelay_24                      ;+40 = 64
	jsr vdelay_12
	nop
	nop
	jmp vdelay_high                    ; +3 = 67

vdelay_low:                            ; +3 = 25 (bne)
	pha                                ; +3 = 28
	and #7                             ; +2 = 30
	tay                                ; +2 = 32
	lda vdelay_low_jump_msb, Y         ; +4 = 36
	pha                                ; +3 = 39
	lda vdelay_low_jump_lsb, Y         ; +4 = 43
	pha                                ; +3 = 46
	sec                                ; +2 = 48
	rts                                ; +6 = 54 (rts-jump)

vdelay_low_rest:                       ;+10 = 64 (returning from jump table)
	; A = remaining cycles to burn, truncated to nearest 8
	; Z flag matches A
	BRPAGE beq, vdelay_low_none        ; +2 = 66
	: ; 8 cycles each iteration
		sbc #8
		NOP3
		BRPAGE bne, :-                 ; -1 = 65 (on last iteration)
	nop                                ; +2 = 67
vdelay_low_none:                       ; +3 = 67 (+3 if from branch)

vdelay_high:                           ;    = 67 (from all paths)
	cpx #0                             ; +2 = 69
	BRPAGE beq, vdelay_end             ; +2 = 71
	: ; 256 cycles each iteration
		txa          ;  +2 = 2
		pha          ;  +3 = 5
		ldx #0       ;  +2 = 7
		lda #236     ;  +2 = 9
		jsr vdelay   ;+236 = 245
		pla          ;  +4 = 249
		tax          ;  +2 = 251
		dex          ;  +2 = 253
		BRPAGE bne, :-                 ; -1 = 70 (on last iteration)
		nop                            ; +2 = 72

vdelay_end:                            ;    = 72 (from all paths)
	rts                                ; +6 = 78

; if given delay < 78 then 
vdelay_toolow:                         ; +3 = 19
	jsr vdelay_48                      ;+53 = 72
	nop
	NOP3
	rts                                ; +6 = 78

; each of these is 10 cycles + 0-7 cycles
; carry is set on entry, and Z is set to A on return
; their job is to get the remaining delay cycles to a multiple of 8,
; and adjust A to compensate
vdelay_low0:
	pla                       ; +4
	; no sbc                  ; -2
	NOP3
	jmp vdelay_low_rest       ; +3
vdelay_low1:
	pla                       ; +4
	sbc #1                    ; +2
	nop
	jmp vdelay_low_rest       ; +3
vdelay_low2:
	pla
	sbc #2
	NOP3
	jmp vdelay_low_rest
vdelay_low3:
	pla
	sbc #3
	nop
	nop
	jmp vdelay_low_rest
vdelay_low4:
	pla
	sbc #4
	nop
	NOP3
	jmp vdelay_low_rest
vdelay_low5:
	pla
	sbc #5
	NOP3
	NOP3
	jmp vdelay_low_rest
vdelay_low6:
	pla
	sbc #6
	nop
	nop
	NOP3
	jmp vdelay_low_rest
vdelay_low7:
	pla
	sbc #7
	nop
	NOP3
	NOP3
	jmp vdelay_low_rest

; a few compact delays
vdelay_48: jsr vdelay_24
vdelay_24: jsr vdelay_12
vdelay_12: rts
