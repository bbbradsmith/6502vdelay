; vdelay
; Brad Smith, 2020
; https://github.com/bbbradsmith/6502vdelay

.export vdelay
; delays for A:X cycles, minimum: 64 (includes jsr)
;   A = low bits of cycles to delay
;   X = high bits of cycles to delay
;   A/X/Y clobbered

; NOTE:
; with an "intro" jump table of 512 bytes, and a large amount of nopslide code
; we could lower the minimum delay to 40 cycles, but this seemed too cumbersome
; to be worthwhile. It would look something like this:
; vdelay:
;     cpx #0
;     bne vdelay_full
;     tay
;     lda vdelay_short_jump + 256, Y
;     pha
;     lda vdelay_short_jump + 0, Y
;     pha
;     rts
; (the above is 38 cycles including jsr and the rts following the rts-jump)

VDELAY_MINIMUM = 64
VDELAY_FULL_OVERHEAD = 77

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
	cpx #0                             ; +2 = 8
	bne vdelay_full                    ; +2 = 10
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
	sec                                ; +2 = 39 / 52
	rts                                ; +6 = 45 / 58

vdelay_low_rest:                       ;+10 = 55 / 68 (returning from jump table)
	; A = remaining cycles to burn, truncated to nearest 8
	; Z flag matches A
	BRPAGE beq, vdelay_low_none        ; +2 = 57 / 70
	: ; 8 cycles each iteration
		sbc #8         ;  +2 = 2
		NOP3           ;  +3 = 5
		BRPAGE bne, :- ;  +3 = 8         -1 = 56 / 69 (on last iteration)
	nop                                ; +2 = 58 / 71
vdelay_low_none:                       ; +3 = 58 / 71 (from branch)
	rts                                ; +6 = 64 / 77

vdelay_toolow:                         ; +3 = 17 (
	jsr vdelay_24                      ;+24 = 41
	jsr vdelay_12                      ;+12 = 53
	NOP3                               ; +3 = 56
	nop                                ; +2 = 58
	rts                                ; +6 = 64

vdelay_full:                           ; +3 = 11
	sec                                ; +2 = 13
	sbc #VDELAY_FULL_OVERHEAD          ; +2 = 15
	tay                                ; +2 = 17
	txa                                ; +2 = 19
	sbc #0                             ; +2 = 21
	BRPAGE beq, vdelay_high_none       ; +2 = 23
	: ; 256 cycles each iteration
		pha            ;  +3 = 3
		tya            ;  +2 = 5
		pha            ;  +3 = 8
		ldx #0         ;  +2 = 10
		lda #(256-29)  ;  +2 = 12
		jsr vdelay
		pla            ;  +4 = 16
		tay            ;  +2 = 18
		pla            ;  +4 = 22
		sec            ;  +2 = 24
		sbc #1         ;  +2 = 26
		BRPAGE bne, :- ;  +3 = 29        -1 = 22 (on last iteration)
		nop                            ; +2 = 24
vdelay_high_none:                      ; +3 = 24 (from branch)
	tya                                ; +2 = 26
	jmp vdelay_low                     ; +3 = 29

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
vdelay_24: jsr vdelay_12
vdelay_12: rts
