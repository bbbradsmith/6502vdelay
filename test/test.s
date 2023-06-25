.include "zeropage.inc"
.import vdelay

.export _test

.macro BRPAGE instruction_, label_
	instruction_ label_
	.assert >(label_) = >*, error, "Page crossed!"
.endmacro

.macro NOP3
	jmp *+3
.endmacro

.align 256

conhex: ; convert 0123456789ABCDEF ASCII to hex in consistent cycle count
	cmp #'A'
	BRPAGE bcs, @upper ; +2 (unbranched)
	NOP3               ; +3
	sec                ; +2
	sbc #'0'           ; +2
	rts                ; +6 = 15
@upper:                ; +3 (branched)
	nop                ; +2
	sec                ; +2
	sbc #('A'-10)      ; +2
	rts                ; +6 = 15

incptr1: ; increment the pointer instead of INY to prevent page crossings
	inc ptr1+0
	BRPAGE beq, :+ ; +2 (unbranched)
	    nop        ; +2
	    nop        ; +2
	    NOP3       ; +3
	    rts        ; +6 = 15
	:              ; +3 (branched)
	    inc ptr1+1 ; +6
	    rts        ; +6 = 15
	;

_test: ; decode arguments in a consistent cycle count, run vdelay
	; ptr1 = argv[1]
	sta ptr1+0
	stx ptr1+1
	; decode hex into arguments
	ldy #0
	lda (ptr1), Y
	jsr conhex
	asl
	asl
	asl
	asl
	sta tmp2
	jsr incptr1
	lda (ptr1), Y
	jsr conhex
	ora tmp2
	sta tmp2
	jsr incptr1
	lda (ptr1), Y
	jsr conhex
	asl
	asl
	asl
	asl
	sta tmp1
	jsr incptr1
	lda (ptr1), Y
	jsr conhex
	ora tmp1
	ldx tmp2
	; 5th digit nonzero indicates null test (no vdelay call)
	jsr incptr1
	pha
	lda (ptr1), Y
	BRPAGE beq, :+ ; +2 (unbranched)
	    NOP3       ; +3
	    pla        ; +4
	    rts        ; +6 = 15
	:              ; +3 (branched)
	nop            ; +2
	pla            ; +4
	jsr vdelay ; X:A = argument
	rts      ; +6 = 15

.segment "RAMCODE"
; empty placeholder
