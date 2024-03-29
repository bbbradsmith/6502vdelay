CC65 ?= cc65/bin/cc65
CA65 ?= cc65/bin/ca65
LD65 ?= cc65/bin/ld65
SIM65 ?= cc65/bin/sim65

.PHONY : default clean

OBJ = temp/vdelay.o temp/test.o temp/test.c.o

default: temp/test.bin
	./make_tests.py --sim65-executable $(SIM65) --test-program $<

temp/test.bin: $(OBJ)
	$(LD65) -C test.cfg -m temp/test.map $^ sim6502.lib -o $@

#temp/test.bin: $(OBJ)
#	$(LD65) -C test.cfg -m temp/test.map $^ sim65c02.lib -o $@

temp/vdelay.o: ../vdelay.s
	$(CA65) -l temp/vdelay.lst -g $< -o $@

#temp/vdelay.o: ../vdelay_short.s
#	$(CA65) -l temp/vdelay.lst -g $< -o $@

temp/test.o: test.s
	$(CA65) -g $< -o $@

temp/test.c.o: temp/test.c.s
	$(CA65) -g $< -o $@

temp/test.c.s: test.c
	$(CC65) -T -O -g $< -o $@

clean:
	$(RM) temp/test.bin $(OBJ) test.c.s
