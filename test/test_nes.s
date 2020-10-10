; NES ROM test of vdelay
; Brad Smith, 2020
; https://github.com/bbbradsmith/6502vdelay
;
; Use dpad to select a 4-digit delay parameter. Press A to execute.
; Execution doesn't do anything visual, it just runs the delay subroutine.
; You should use a debugger to count the cycles (or otherwise debug it).
;
; Put read breakpoints on DEBUG_START or DEBUG_END to easily find the function
; when it is called.

START_VALUE = 63
DISPLAY = $2000 + (10 * 32) + 10

; two read addresses that can be checked in a debugger to find the delay code
DEBUG_START = $FE
DEBUG_END   = $FF

.import vdelay

.segment "ZEROPAGE"

param: .res 4
select: .res 1
pad: .res 1
pad_last: .res 1
pad_new: .res 1
temp: .res 1

.segment "CODE"

.macro PPU_LATCH addr_
	bit $2002
	lda #>(addr_)
	sta $2006
	lda #<(addr_)
	sta $2006
.endmacro

nmi:
irq:
	rti

vblank:
	bit $2002
	:
		bit $2002
		bpl :-
	rts

PAD_A      = $01
PAD_B      = $02
PAD_SELECT = $04
PAD_START  = $08
PAD_U      = $10
PAD_D      = $20
PAD_L      = $40
PAD_R      = $80

gamepad_poll:
	lda #1
	sta $4016
	lda #0
	sta $4016
	ldx #8
	:
		pha
		lda $4016
		and #%00000011
		cmp #%00000001
		pla
		ror
		dex
		bne :-
	sta pad
	rts

reset:
	sei
	lda #0
	sta $2000
	sta $2001
	sta $4015
	cld
	jsr vblank
	jsr vblank
	; blank nametables
	PPU_LATCH $2000
	ldy #16
	ldx #0
	lda #0
	:
		sta $2007
		inx
		bne :-
		dey
		bne :-
	; palette
	PPU_LATCH $3F00
	ldx #8
	:
		lda #$0F
		sta $2007
		lda #$00
		sta $2007
		lda #$10
		sta $2007
		lda #$30
		sta $2007
		dex
		bne :-
	; setup variables
	lda #0
	sta param+0
	sta param+1
	sta pad
	sta pad_last
	lda #3
	sta select
	lda #((START_VALUE & $F0) >> 4)
	sta param+2
	lda #((START_VALUE & $0F) >> 0)
	sta param+3
loop:
	jsr vblank
	; hex parameter (4 digits)
	PPU_LATCH DISPLAY
	.repeat 4, I
		lda param+I
		clc
		adc #$A0
		sta $2007
	.endrepeat
	; select indicator (clear)
	PPU_LATCH DISPLAY+32
	lda #0
	sta $2007
	sta $2007
	sta $2007
	sta $2007
	; select indicator (set)
	lda select
	clc
	adc #<(DISPLAY+32)
	tax
	lda #0
	adc #>(DISPLAY+32)
	sta $2006
	stx $2006
	lda #$B8
	sta $2007
	; render on, reset scroll
	lda #%00001010
	sta $2001
	lda #0
	sta $2005
	sta $2005
wait: ; wait for pad press
	lda pad
	sta pad_last
	jsr gamepad_poll
	lda pad_last
	eor pad
	and pad
	sta pad_new
	beq wait
	; respond to press
	lda pad
	and #PAD_L
	beq :+
		lda select
		sec
		sbc #1
		and #3
		sta select
		jmp loop
	:
	lda pad
	and #PAD_R
	beq :+
		lda select
		clc
		adc #1
		and #3
		sta select
		jmp loop
	:
	lda pad
	and #PAD_U
	beq :+
		ldx select
		inc param, X
		lda param, X
		and #$0F
		sta param, X
		jmp loop
	:
	lda pad
	and #PAD_D
	beq :+
		ldx select
		dec param, X
		lda param, X
		and #$0F
		sta param, X
		jmp loop
	:
	lda pad
	and #PAD_A
	beq :+
		lda param+0
		asl
		asl
		asl
		asl
		sta temp
		lda param+1
		ora temp
		tax
		lda param+2
		asl
		asl
		asl
		asl
		sta temp
		lda param+3
		ora temp
		; X:A = parameter
		bit DEBUG_START
		jsr vdelay
		bit DEBUG_END
	:
	jmp loop

.segment "HEADER"
INES_MAPPER = 0 ; 0 = NROM
INES_MIRROR = 1 ; 0 = horizontal mirroring, 1 = vertical mirroring
INES_SRAM   = 0 ; 1 = battery backed SRAM at $6000-7FFF
.byte 'N', 'E', 'S', $1A
.byte $01 ; 16k PRG chunk count
.byte $01 ; 8k CHR chunk count
.byte INES_MIRROR | (INES_SRAM << 1) | ((INES_MAPPER & $f) << 4)
.byte (INES_MAPPER & %11110000)
.byte $0, $0, $0, $0, $0, $0, $0, $0 ; padding

.segment "TILES"
.incbin "test_nes.chr"
.incbin "test_nes.chr"

.segment "VECTORS"
.word nmi
.word reset
.word irq
