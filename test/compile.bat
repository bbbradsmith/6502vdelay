@del temp\vdelay.o
@del temp\test.c.s
@del temp\test.c.o
@del temp\test.o
@del temp\test.bin
@del temp\test.map
@del temp\test_nes.o
@del temp\test_nes.map
@del temp\test_nes.dbg
@del temp\test_nes.nes

REM if you wish to test alternative versions, uncomment them to replace vdelay.s

cc65\bin\ca65 -o temp\vdelay.o -g ..\vdelay.s
@IF ERRORLEVEL 1 GOTO error

REM cc65\bin\ca65 -o temp\vdelay.o -g ..\vdelay_short.s
@IF ERRORLEVEL 1 GOTO error

REM cc65\bin\ca65 -o temp\vdelay.o -g ..\vdelay_extreme.s
@IF ERRORLEVEL 1 GOTO error

REM cc65\bin\ca65 -o temp\vdelay.o -g ..\vdelay_clockslide.s
@IF ERRORLEVEL 1 GOTO error

REM cc65\bin\ca65 -o temp\vdelay.o -g ..\vdelay_modify.s
@IF ERRORLEVEL 1 GOTO error

cc65\bin\ca65 -o temp\test.o -g test.s
@IF ERRORLEVEL 1 GOTO error

cc65\bin\ca65 -o temp\test_nes.o -g test_nes.s
@IF ERRORLEVEL 1 GOTO error

cc65\bin\cc65 -o temp\test.c.s -T -O -g test.c
@IF ERRORLEVEL 1 GOTO error

cc65\bin\ca65 -o temp\test.c.o -g temp\test.c.s
@IF ERRORLEVEL 1 GOTO error

cc65\bin\ld65 -o temp\test.bin -C test.cfg -m temp\test.map temp\vdelay.o temp\test.o temp\test.c.o sim6502.lib
@IF ERRORLEVEL 1 GOTO error

REM cc65\bin\ld65 -o temp\test.bin -C test.cfg -m temp\test.map temp\vdelay.o temp\test.o temp\test.c.o sim65C02.lib
@IF ERRORLEVEL 1 GOTO error

cc65\bin\ld65 -o temp\test_nes.nes -C test_nes.cfg --dbgfile temp\test_nes.dbg -m temp\test_nes.map temp\vdelay.o temp\test_nes.o
@IF ERRORLEVEL 1 GOTO error

@echo.
@echo.
@echo Build successful!
@pause
@GOTO end
:error
@echo.
@echo.
@echo Build error!
@pause
:end
