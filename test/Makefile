
.PHONY : default clean

OBJ = vdelay.o test.o test.c.o

default: test.bin
	./run_tests.py --test-program $<

test.bin: $(OBJ)
	ld65 -C test.cfg -m test.map $^ sim6502.lib -o $@

vdelay.o: ../vdelay.s
	ca65 -l vdelay.lst -g $< -o $@

test.o: test.s
	ca65 -g $< -o $@

test.c.o: test.c.s
	ca65 -g $< -o $@

test.c.s: test.c
	cc65 -T -O -g $< -o $@

clean :
	$(RM) test.bin $(OBJ) test.c.s

# ca65 -o temp/vdelay.o -g ../vdelay_short.s
# ca65 -g test_nes.s -o temp/test_nes.o
# 6502 simulation
# 65C02 simulation
#ld65 -o temp/test.bin -C test.cfg -m temp/test.map temp/vdelay.o temp/test.o temp/test.c.o sim65C02.lib
#ld65 -C test_nes.cfg --dbgfile temp/test_nes.dbg -m temp/test_nes.map temp/vdelay.o temp/test_nes.o -o temp/test_nes.nes
