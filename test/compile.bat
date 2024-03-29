REM full test
SET /A count = 65536

@REM abbreviated test
@REM SET /A count = 1000

REM Clean temp directory

@del temp\* /Q


REM Test code

cc65\bin\ca65 -o temp\vdelay.o -g ..\vdelay.s
@IF ERRORLEVEL 1 GOTO error

cc65\bin\ca65 -o temp\vdelay_short.o -g ..\vdelay_short.s
@IF ERRORLEVEL 1 GOTO error

cc65\bin\ca65 -o temp\test.o -g test.s
@IF ERRORLEVEL 1 GOTO error

cc65\bin\ca65 -o temp\test_nes.o -g test_nes.s
@IF ERRORLEVEL 1 GOTO error

cc65\bin\cc65 -o temp\test.c.s -T -O -g test.c
@IF ERRORLEVEL 1 GOTO error

cc65\bin\ca65 -o temp\test.c.o -g temp\test.c.s
@IF ERRORLEVEL 1 GOTO error

REM 6502 simulation

cc65\bin\ld65 -o temp\test.bin -C test.cfg -m temp\test.map temp\vdelay.o temp\test.o temp\test.c.o sim6502.lib
@IF ERRORLEVEL 1 GOTO error

cc65\bin\ld65 -o temp\test_short.bin -C test.cfg -m temp\test_short.map temp\vdelay_short.o temp\test.o temp\test.c.o sim6502.lib
@IF ERRORLEVEL 1 GOTO error

REM 65C02 simulation

cc65\bin\ld65 -o temp\testc.bin -C test.cfg -m temp\testc.map temp\vdelay.o temp\test.o temp\test.c.o sim65C02.lib
@IF ERRORLEVEL 1 GOTO error

cc65\bin\ld65 -o temp\testc_short.bin -C test.cfg -m temp\testc_short.map temp\vdelay_short.o temp\test.o temp\test.c.o sim65C02.lib
@IF ERRORLEVEL 1 GOTO error

REM NES demo

cc65\bin\ld65 -o temp\test_nes.nes -C test_nes.cfg --dbgfile temp\test_nes.dbg -m temp\test_nes.map temp\vdelay.o temp\test_nes.o
@IF ERRORLEVEL 1 GOTO error

@echo.
@echo.
@echo Build successful! Creating test batches...
@echo.
@echo.

test.py bat test_short 256
test.py bat test %count%
test.py bat testc_short 256
test.py bat testc %count%

@echo.
@echo.
@echo Running tests...
@echo.
@echo.

test.py run test_short
test.py run test
test.py run testc_short
test.py run testc

@echo.
@echo.
@echo Test logs...
@echo.
@echo.

test.py log test_short
test.py log test
test.py log testc_short
test.py log testc

@echo.
@echo.
@echo Tests complete. Check results above.
@echo.
@pause
@GOTO end

:error
@echo.
@echo.
@echo Build error!
@echo.
@pause
:end
