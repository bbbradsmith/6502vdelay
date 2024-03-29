REM temporary output directory
SET OUTDIR=temp\

REM full test
SET /A COUNT = 65536

@REM abbreviated test
@REM SET /A COUNT = 1000

REM Set up and clean temp directory

IF NOT EXIST %OUTDIR% md %OUTDIR%
del %OUTDIR%* /Q


REM Test code

cc65\bin\ca65 -o %OUTDIR%vdelay.o -g ..\vdelay.s
@IF ERRORLEVEL 1 GOTO error

cc65\bin\ca65 -o %OUTDIR%vdelay_short.o -g ..\vdelay_short.s
@IF ERRORLEVEL 1 GOTO error

cc65\bin\ca65 -o %OUTDIR%test.o -g test.s
@IF ERRORLEVEL 1 GOTO error

cc65\bin\ca65 -o %OUTDIR%test_nes.o -g test_nes.s
@IF ERRORLEVEL 1 GOTO error

cc65\bin\cc65 -o %OUTDIR%test.c.s -T -O -g test.c
@IF ERRORLEVEL 1 GOTO error

cc65\bin\ca65 -o %OUTDIR%test.c.o -g %OUTDIR%test.c.s
@IF ERRORLEVEL 1 GOTO error

REM 6502 simulation

cc65\bin\ld65 -o %OUTDIR%test.bin -C test.cfg -m %OUTDIR%test.map %OUTDIR%vdelay.o %OUTDIR%test.o %OUTDIR%test.c.o sim6502.lib
@IF ERRORLEVEL 1 GOTO error

cc65\bin\ld65 -o %OUTDIR%test_short.bin -C test.cfg -m %OUTDIR%test_short.map %OUTDIR%vdelay_short.o %OUTDIR%test.o %OUTDIR%test.c.o sim6502.lib
@IF ERRORLEVEL 1 GOTO error

REM 65C02 simulation

cc65\bin\ld65 -o %OUTDIR%testc.bin -C test.cfg -m %OUTDIR%testc.map %OUTDIR%vdelay.o %OUTDIR%test.o %OUTDIR%test.c.o sim65C02.lib
@IF ERRORLEVEL 1 GOTO error

cc65\bin\ld65 -o %OUTDIR%testc_short.bin -C test.cfg -m %OUTDIR%testc_short.map %OUTDIR%vdelay_short.o %OUTDIR%test.o %OUTDIR%test.c.o sim65C02.lib
@IF ERRORLEVEL 1 GOTO error

REM NES demo

cc65\bin\ld65 -o %OUTDIR%test_nes.nes -C test_nes.cfg --dbgfile %OUTDIR%test_nes.dbg -m %OUTDIR%test_nes.map %OUTDIR%vdelay.o %OUTDIR%test_nes.o
@IF ERRORLEVEL 1 GOTO error

cc65\bin\ld65 -o %OUTDIR%test_short_nes.nes -C test_nes.cfg --dbgfile %OUTDIR%test_short_nes.dbg -m %OUTDIR%test_short_nes.map %OUTDIR%vdelay_short.o %OUTDIR%test_nes.o
@IF ERRORLEVEL 1 GOTO error

@echo.
@echo.
@echo Build successful! Creating test batches...
@echo.
@echo.

test.py bat %OUTDIR%test_short 256
test.py bat %OUTDIR%test %COUNT%
test.py bat %OUTDIR%testc_short 256
test.py bat %OUTDIR%testc %COUNT%

@echo.
@echo.
@echo Running tests...
@echo.
@echo.

test.py run %OUTDIR%test_short
test.py run %OUTDIR%test
test.py run %OUTDIR%testc_short
test.py run %OUTDIR%testc

@echo.
@echo.
@echo Test logs...
@echo.
@echo.

test.py log %OUTDIR%test_short
test.py log %OUTDIR%test
test.py log %OUTDIR%testc_short
test.py log %OUTDIR%testc

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
