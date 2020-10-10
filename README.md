# 6502 vdelay

A 6502 delay routine for delaying a number of cycles specified at runtime.

You might call this arbitrary delay, procedural delay, programmatic delay, variable delay, dial-a-delay etc.
 It might be handy in situations where you have a 6502 without effective timer hardware (e.g. Apple II, NES).

Uses ca65 ([cc65](https://cc65.github.io/)) assembly syntax.

Version 3

## Usage

* **vdelay.s** - source code (64-65535 cycles, 174 bytes)
* **vdelay_short.s** - short version (57-255 cycles, 135 bytes)
* **vdelay_compact.s** - compact version (72-65535 cycles, 144 bytes)

Assemble and include the source code in your project. It exports the **vdelay**
 subroutine, which you call with a 16-bit value for the number of cycles to delay.
 Low bits in **A**, high bits in **X**.

The minimum amount of delay is currently **64 cycles**.
 If the given parameter is less than that it will still delay that minimum number of cycles.

This code must be placed in a 128-byte-aligned segment. Add **align=128** to your **CODE** segment CFG
 or add a **.segment** directive of your own to place it in a custom segment that is appropriately aligned.

The "short" version only permits 57-255 cycle delays, and only takes **A** as its
 parameter.

The "compact" version has a higher minimum of 72 cycles, but is slightly smaller at 144 bytes.

## Tests

Place **cc65** in **test/cc65** and create a **test/temp** folder.

Run **test/compile.bat** to build the test binaries.

The [python3](https://www.python.org/) program **test/test.py** will use **sim65** to simulate the program
 with all possible parameters and logs the cycle count of each.
 (This takes a few minutes.)
 Once finished it will analyze the log to verify the measured cycles is correct.

The NES ROM compiled to **test/temp/test_nes.nes** can be used to test the code
 in an NES debugging emulator.

## Algorithm and Notes

This routine is built around a loop that takes 8 cycles to subtract 8 from a number.
 Before entering this loop, the number is rounded down to the nearest 8, and a jump table is used
 to select one of 8 routines to make up the difference with a suitable delay. Before doing that,
 we have subtract the cycle overhead that it takes to prepare to enter the table/loop.
 This overhead is what causes the routine to have a minimum.

The 128-byte alignment requirement was chosen for ease of maintenance/use.
 If you remove the **.align** directive, it will still ensure correct branch timing with asserts,
 so if you are extremely cramped for space and willing to experiment with a few bytes of internal padding
 you might be able to get away with much smaller alignment.

## History

* Version 1
** vdelay - 78 cycles, 176 bytes.
* Version 2
** vdelay - 64 cycles, 174 bytes.
* Version 3
** vdelay - reduced alignment requirement.
** vdelay_short - 57-255, 135.
** vdelay_compact - 72, 144.

## License

This library may be used, reused, and modified for any purpose, commercial or non-commercial.
 If distributing source code, do not remove the attribution to its original author,
 and document any modifications with attribution to their new author as well.

Attribution in released binaries or documentation is appreciated but not required.

If you'd like to support this project or its author, please visit:
 [Patreon](https://www.patreon.com/rainwarrior)
