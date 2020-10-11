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
	BRPAGE bcs, @upper
	NOP3
	sec
	sbc #'0'
	rts
@upper:
	nop
	sec
	sbc #('A'-10)
	rts

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
	iny
	lda (ptr1), Y
	jsr conhex
	ora tmp2
	sta tmp2
	iny
	lda (ptr1), Y
	jsr conhex
	asl
	asl
	asl
	asl
	sta tmp1
	iny
	lda (ptr1), Y
	jsr conhex
	ora tmp1
	ldx tmp2
	; X:A = argument
	jmp vdelay

.segment "RAMCODE"
; empty placeholder
