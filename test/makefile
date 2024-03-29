CC65 ?= cc65/bin/cc65
CA65 ?= cc65/bin/ca65
LD65 ?= cc65/bin/ld65
SIM65 ?= cc65/bin/sim65

# multiprocess count, 0 for maximum
PROCESSES ?= 4

# test count can be abbreviated
COUNT ?= 65535
#COUNT ?= 999

.PHONY : default sim6502 sim65c02 bin nes full clean

OBJ = temp/test.o temp/test.c.o

# 6502 tests and NES ROM
default: nes sim6502

# test 6502 only
sim6502: bin
	./make_tests.py --sim65-executable $(SIM65) --test-program temp/test_short.bin --max 255 --processes $(PROCESSES)
	./make_tests.py --sim65-executable $(SIM65) --test-program temp/test.bin --max $(COUNT) --processes $(PROCESSES)

# test 65c02 only
sim65c02: bin
	./make_tests.py --sim65-executable $(SIM65) --test-program temp/testc_short.bin --max 255 --processes $(PROCESSES)
	./make_tests.py --sim65-executable $(SIM65) --test-program temp/testc.bin --max $(COUNT) --processes $(PROCESSES)

# create test binaries only
bin: temp/test.bin temp/test_short.bin temp/testc.bin temp/testc_short.bin

# NES ROM
nes: temp/test_nes.nes

# all tests and binaries
full: default sim65c02


temp/test.bin: temp/vdelay.o $(OBJ)
	$(LD65) -C test.cfg -m temp/test.map $^ sim6502.lib -o $@

temp/testc.bin: temp/vdelay.o $(OBJ)
	$(LD65) -C test.cfg -m temp/test.map $^ sim65c02.lib -o $@

temp/test_short.bin: temp/vdelay_short.o $(OBJ)
	$(LD65) -C test.cfg -m temp/test.map $^ sim6502.lib -o $@

temp/testc_short.bin: temp/vdelay_short.o $(OBJ)
	$(LD65) -C test.cfg -m temp/test.map $^ sim65c02.lib -o $@

temp/test_nes.nes: temp/test_nes.o temp/vdelay.o
	$(LD65) -C test_nes.cfg --dbgfile temp/test_nes.dbg -m temp/test_nes.map temp\vdelay.o temp\test_nes.o -o $@


temp/vdelay.o: ../vdelay.s
	$(CA65) -l temp/vdelay.lst -g $< -o $@

temp/vdelay_short.o: ../vdelay_short.s
	$(CA65) -l temp/vdelay_short.lst -g $< -o $@

temp/test_nes.o: test_nes.s
	$(CA65) -g $< -o $@


temp/test.o: test.s
	$(CA65) -g $< -o $@

temp/test.c.o: temp/test.c.s
	$(CA65) -g $< -o $@

temp/test.c.s: test.c
	$(CC65) -T -O -g $< -o $@


clean:
	$(RM) temp/*
