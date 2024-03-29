CC65 ?= cc65/bin/cc65
CA65 ?= cc65/bin/ca65
LD65 ?= cc65/bin/ld65
SIM65 ?= cc65/bin/sim65
MKDIR ?= mkdir -p
OUTDIR ?= temp

# multiprocess count, 0 for maximum
PROCESSES ?= 4

# test count can be abbreviated
COUNT ?= 65535
#COUNT ?= 999

.PHONY : default sim6502 sim65c02 bin nes clean

# NES ROM, 6502 tests, 65C02 tests (everything)
default: nes sim6502 sim65c02

# test 6502 only
sim6502: bin
	./make_tests.py --sim65-executable $(SIM65) --test-program $(OUTDIR)/test_short.bin --max 255 --processes $(PROCESSES)
	./make_tests.py --sim65-executable $(SIM65) --test-program $(OUTDIR)/test.bin --max $(COUNT) --processes $(PROCESSES)

# test 65c02 only
sim65c02: bin
	./make_tests.py --sim65-executable $(SIM65) --test-program $(OUTDIR)/testc_short.bin --max 255 --processes $(PROCESSES)
	./make_tests.py --sim65-executable $(SIM65) --test-program $(OUTDIR)/testc.bin --max $(COUNT) --processes $(PROCESSES)

# create test binaries only
bin: $(OUTDIR)/test.bin $(OUTDIR)/test_short.bin $(OUTDIR)/testc.bin $(OUTDIR)/testc_short.bin

# NES ROM
nes: $(OUTDIR)/test_nes.nes $(OUTDIR)/test_short_nes.nes


OBJ = $(OUTDIR)/test.o $(OUTDIR)/test.c.o

$(OUTDIR)/test.bin: $(OUTDIR)/vdelay.o $(OBJ)
	$(LD65) -C test.cfg -m $(OUTDIR)/test.map $^ sim6502.lib -o $@

$(OUTDIR)/testc.bin: $(OUTDIR)/vdelay.o $(OBJ)
	$(LD65) -C test.cfg -m $(OUTDIR)/test.map $^ sim65c02.lib -o $@

$(OUTDIR)/test_short.bin: $(OUTDIR)/vdelay_short.o $(OBJ)
	$(LD65) -C test.cfg -m $(OUTDIR)/test.map $^ sim6502.lib -o $@

$(OUTDIR)/testc_short.bin: $(OUTDIR)/vdelay_short.o $(OBJ)
	$(LD65) -C test.cfg -m $(OUTDIR)/test.map $^ sim65c02.lib -o $@

$(OUTDIR)/test_nes.nes: $(OUTDIR)/test_nes.o $(OUTDIR)/vdelay.o
	$(LD65) -C test_nes.cfg --dbgfile $(OUTDIR)/test_nes.dbg -m $(OUTDIR)/test_nes.map $(OUTDIR)/vdelay.o $(OUTDIR)/test_nes.o -o $@

$(OUTDIR)/test_short_nes.nes: $(OUTDIR)/test_nes.o $(OUTDIR)/vdelay_short.o
	$(LD65) -C test_nes.cfg --dbgfile $(OUTDIR)/test_short_nes.dbg -m $(OUTDIR)/test_short_nes.map $(OUTDIR)/vdelay_short.o $(OUTDIR)/test_nes.o -o $@



$(OUTDIR)/vdelay.o: ../vdelay.s | $(OUTDIR)/
	$(CA65) -l $(OUTDIR)/vdelay.lst -g $< -o $@

$(OUTDIR)/vdelay_short.o: ../vdelay_short.s | $(OUTDIR)/
	$(CA65) -l $(OUTDIR)/vdelay_short.lst -g $< -o $@

$(OUTDIR)/test_nes.o: test_nes.s  | $(OUTDIR)/
	$(CA65) -g $< -o $@

$(OUTDIR)/test.o: test.s | $(OUTDIR)/
	$(CA65) -g $< -o $@

$(OUTDIR)/test.c.o: $(OUTDIR)/test.c.s | $(OUTDIR)/
	$(CA65) -g $< -o $@

$(OUTDIR)/test.c.s: test.c  | $(OUTDIR)/
	$(CC65) -T -O -g $< -o $@


$(OUTDIR)/:
	$(MKDIR) $@

clean:
	$(RM) $(OUTDIR)/*
