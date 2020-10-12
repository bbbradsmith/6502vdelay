; vdelay (short clockslide version)
; Brad Smith, 2020
; https://github.com/bbbradsmith/6502vdelay

.export vdelay
; delays for A cycles, minimum: 51 (includes jsr)
;   A = cycles to delay
;   A/X/Y clobbered

VDELAY_MINIMUM = 51

; assert to make sure branches do not page-cross
.macro BRPAGE instruction_, label_
	instruction_ label_
	.assert >(label_) = >*, error, "Page crossed!"
.endmacro

.align 128 ; this code has no branches after 128 bytes

vdelay: ;                                +6 = 6 (jsr)
	sec                                ; +2 = 8
	sbc #VDELAY_MINIMUM                ; +2 = 10
	BRPAGE bcc, vdelay_toolow          ; +2 = 12
	tax                                ; +2 = 14
	lda #>(vdelay_clockslide-1)        ; +2 = 16
	pha                                ; +3 = 19
	txa                                ; +2 = 21
	and #7                             ; +2 = 23
	eor #$FF                           ; +2 = 25
	adc #<(vdelay_clockslide+7-1)      ; +2 = 27
	pha                                ; +3 = 30
	rts                                ; +6 = 36

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

vdelay_low_rest:                       ; +2 = 38
	txa                                ; +2 = 40
	and #$F8                           ; +2 = 42
	BRPAGE beq, vdelay_low_none        ; +2 = 44
	sec                                ; +2 = 46
	: ; 8 cycles each iteration
		sbc #8          ; +2 = 2
		BRPAGE bcs, *+2 ; +3 = 5 (branch always)
		BRPAGE bne, :-  ; +3 = 8         -1 = 45 (on last iteration)
vdelay_low_none:                       ; +3 = 45 (from branch)
	rts                                ; +6 = 51

vdelay_toolow:                         ; +3 = 13 (from branch)
	ldy #4                             ; +2 = 15
	: ; 7 cycle loop                    +28 = 43
		nop
		dey
		BRPAGE bne, :-                 ; -1 = 42 (on last iteration)
	BRPAGE beq, *+2                    ; +3 = 45
	rts                                ; +6 = 51
