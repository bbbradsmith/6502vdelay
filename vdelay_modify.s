; vdelay (self modifying version)
; Brad Smith, 2020
; https://github.com/bbbradsmith/6502vdelay

.export vdelay
; delays for X:A cycles, minimum: 46 (includes jsr)
;   A = low bits of cycles to delay
;   X = high bits of cycles to delay
;   A/X/Y clobbered, reads $EA

; DIVIDED
; 0 = code all in RAMCODE (RAM)
; 1 = code divided into RAMCODE (RAM) and CODE (ROM) sections
DIVIDED = 0

VDELAY_MINIMUM = 46
VDELAY_FULL_OVERHEAD = 61 + (DIVIDED * 3)

; assert to make sure branches do not page-cross
.macro BRPAGE instruction_, label_
	instruction_ label_
	.assert >(label_) = >*, error, "Page crossed!"
.endmacro

.segment "RAMCODE"

.if DIVIDED = 0
	.align 128
.else
	.align 32
.endif

vdelay: ;                                +6 = 6 (jsr)
	cpx #0                             ; +2 = 8 (sets carry)
	BRPAGE bne, vdelay_full_jmp        ; +2 = 10
	sbc #VDELAY_MINIMUM                ; +2 = 12
	BRPAGE bcc, vdelay_toolow_jmp      ; +2 = 14

vdelay_low:                            ;           29 (full path)
	tay                                ; +2 = 16 / 31
	and #7                             ; +2 = 18 / 33
	eor #$FF                           ; +2 = 20 / 35
	adc #<(vdelay_clockslide+7)        ; +2 = 22 / 37
	sta vdelay_dispatch+1              ; +4 = 26 / 41 (modifies JMP)
vdelay_dispatch:
	jmp vdelay_clockslide              ; +3 = 29 / 44

.if DIVIDED = 0

vdelay_full_jmp = vdelay_full
vdelay_toolow_jmp = vdelay_toolow

.else ; DIVIDED = 3

vdelay_full_jmp:
	jmp vdelay_full
vdelay_toolow_jmp:
	jmp vdelay_toolow
.segment "CODE"
.align 64

.endif

; "clockslide" technique, delays 2 + 0-7 cycles
vdelay_clockslide:
	.byte $C9 ; CMP #$C9 (+2)
	.byte $C9 ; CMP #$C9
	.byte $C9 ; CMP #$C9
	.byte $C9 ; CMP #$C9
	.byte $C9 ; CMP #$C9
	.byte $C9 ; CMP #$C9
	.byte $C5 ; CMP $EA (+3, reads zero-page)
	.byte $EA ; NOP (+2)
	.assert >(*-1) = >(vdelay_clockslide), error, "Clockslide page crossing!"

	;                                    +2 = 31 / 46 ( from clockslide)
	sec                                ; +2 = 33 / 48
	tya                                ; +2 = 35 / 50
	and #$F8                           ; +2 = 37 / 52
	BRPAGE beq, vdelay_low_none        ; +2 = 39 / 54
	: ; 8 cycles each iteration
		sbc #8          ; +2 = 2
		BRPAGE bcs, *+2 ; +3 = 5 (branch always)
		BRPAGE bne, :-  ; +3 = 8         -1 = 38 / 53 (on last iteration)
	nop                                ; +2 = 40 / 55
vdelay_low_none:                       ; +3 = 40 / 55 (from branch)
	rts                                ; +6 = 46 / 61

vdelay_toolow:
.if DIVIDED = 0
	;                                    +3 = 15 (from branch)
	ldy #4                             ; +2 = 17
	: ; 5 cycle loop                    +20 = 37
		dey
		BRPAGE bne, :-                 ; -1 = 36 (on last iteration)
	nop                                ; +2 = 38
	nop                                ; +2 = 40
	rts                                ; +6 = 46
.else
	;                                    +3 = 18 (from branch)
	ldy #3                             ; +2 = 20
	: ; 7 cycle loop                    +21 = 41
		dey
		nop
		BRPAGE bne, :-                 ; -1 = 40 (on last iteration)
	rts                                ; +6 = 46
.endif

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
