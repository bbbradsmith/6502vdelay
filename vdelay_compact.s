; vdelay (compact version)
; Brad Smith, 2020
; https://github.com/bbbradsmith/6502vdelay

.export vdelay
; delays for X:A cycles, minimum: 72 (includes jsr)
;   A = low bits of cycles to delay
;   X = high bits of cycles to delay
;   A/X/Y clobbered

VDELAY_MINIMUM = 72

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
vdelay_jump_lsb:
	.repeat 16, I
		.byte <(.ident(.sprintf("vdelay%d",I))-1)
	.endrepeat
	.assert >(*-1) = >vdelay_jump_lsb, error, "Jump table page crossed!"
vdelay_jump_msb:
	.repeat 16, I
		.byte >(.ident(.sprintf("vdelay%d",I))-1)
	.endrepeat
	.assert >(*-1) = >vdelay_jump_msb, error, "Jump table page crossed!"

vdelay:                                ; +6 = 6 (jsr)
	sec                                ; +2 = 8
	sbc #VDELAY_MINIMUM                ; +2 = 10
	tay                                ; +2 = 12
	txa                                ; +2 = 14
	sbc #0                             ; +2 = 16
	BRPAGE bcc, vdelay_toolow          ; +2 = 18
	tax                                ; +2 = 20
	tya                                ; +2 = 22
	pha                                ; +3 = 25
	and #$0F                           ; +2 = 27
	tay                                ; +2 = 29
	lda vdelay_jump_msb, Y             ; +4 = 33
	pha                                ; +3 = 36
	lda vdelay_jump_lsb, Y             ; +4 = 40
	pha                                ; +3 = 43
	rts                                ; +6 = 49 (to jump table)

vdelay_rest:                           ; +4 = 54 (returning from jump table)
	pla                                ; +4 = 58
	and #$F0                           ; +2 = 60
	BRPAGE bne, vdelay_rest_a_nonzero  ; +2 = 62
	cpx #0                             ; +2 = 64
	BRPAGE bne, vdelay_rest_x_nonzero  ; +2 = 66
	rts                                ; +6 = 72
vdelay_rest_x_nonzero:                 ; +3 = 67 (branch)
    sec                                ; +2 = 69
    jmp vdelay_loop                    ; +3 = 72
vdelay_rest_a_nonzero:                 ; +3 = 63
    sec                                ; +2 = 65
    nop                                ; +4 = 69
    nop
    jmp vdelay_loop                    ; +3 = 72

; 16-cycle loop that subtracts 16 from X:A until 0
vdelay_loop:
	sbc #16                            ; +2 = 2
	BRPAGE beq, vdelay_loop_zero       ; +2 = 4
	BRPAGE bcs, vdelay_loop_no_borrow  ; +2 = 6
	dex                                ; +2 = 8
	sec                                ; +2 = 10
	NOP3                               ; +3 = 13
	jmp vdelay_loop                    ; +3 = 16
vdelay_loop_no_borrow:                 ; +3 = 7 (branch)
	nop                                ; +6 = 13
	nop
	nop
	jmp vdelay_loop                    ; +3 = 16
vdelay_loop_zero:                      ; +3 = 5 (branch)
	cpx #0                             ; +2 = 7
	BRPAGE beq, vdelay_loop_exit       ; +2 = 9
	nop                                ; +4 = 13
	nop
	jmp vdelay_loop                    ; +3 = 16
vdelay_loop_exit:                      ; +3 = 10 (branch)
	rts                                ; +6 = 16

vdelay_toolow:                         ; +3 = 19
	.assert (*-vdelay_jump_lsb)<128, error, "Last branch does not fit alignment?"
	nop                                ; +2 = 21
	jsr vdelay_toolow_18               ;+18 = 39
	jmp vdelay_toolow_36               ;+33 = 72
vdelay_toolow_36: ; 36 if jsr, 33 if jmp
	jsr vdelay_toolow_18
vdelay_toolow_18:
	nop
	nop
	nop
	rts

; each of theses is the given delay + 4 cycles
vdelay15: nop
vdelay13: nop
vdelay11: nop
vdelay9:  nop
vdelay7:  nop
vdelay5:  nop
vdelay3:  nop
vdelay1:  NOP3
          jmp vdelay_rest
vdelay14: nop
vdelay12: nop
vdelay10: nop
vdelay8:  nop
vdelay6:  nop
vdelay4:  nop
vdelay2:  nop
vdelay0:  nop
          jmp vdelay_rest
