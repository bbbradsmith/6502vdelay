# 6502 vdelay

A 6502 delay routine for delaying a number of cycles specified at runtime.

You might call this arbitrary delay, procedural delay, programmatic delay,
 variable delay, etc. It might be handy in situations where you have a 6502
 without effective dimer hardware (e.g. Apple II, NES).

Uses ca65 ([cc65](https://cc65.github.io/)) assembly syntax.

Version 1

## Usage

* **vdelay.s** - source code

Assemble and include the source code in your project. It exports the **vdelay**
subroutine, which you call with a 16-bit value for the number of cycles to
delay. Low bits in **A**, high bits in **X**.

The mimnimum amount of delay is currently **78 cycles**. If the given parameter
is less than that it will still delay that minimum number of cycles.

## Tests

Place **cc65** in **test/cc65** and create a **test/temp** folder.

Run **test/compile.bat** to build the test binaries.

The [python3](https://www.python.org/) program **test/test.py** will use **sim65** to simulate the program
 with all possible parameters and logs the cycle count of each.
 (This takes a few minutes.)
 Once finished it will analyze the log to verify the measured cycles is correct.

The NES ROM compiled to **test/temp/test_nes.nes** can be used to test the code
 in an NES debugging emulator. 

## License

This library may be used, reused, and modified for any purpose, commercial or non-commercial.
 If distributing source code, do not remove the attribution to its original author,
 and document any modifications with attribution to their new author as well.

Attribution in released binaries or documentation is appreciated but not required.

If you'd like to support this project or its author, please visit:
 [Patreon](https://www.patreon.com/rainwarrior)
