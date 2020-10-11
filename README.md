# 6502 vdelay

A 6502 delay routine for delaying a number of cycles specified at runtime.

You might call this arbitrary delay, procedural delay, programmatic delay, variable delay, dial-a-delay etc.
 It might be handy in situations where you have a 6502 without effective timer hardware (e.g. Apple II, NES).

Uses ca65 ([cc65](https://cc65.github.io/)) assembly syntax.

Version 6

## Usage

* **vdelay.s** - normal version (61-65535 cycles, 96 bytes)
* **vdelay_short.s** - short version (56-255 cycles, 70 bytes)
* **vdelay_clockslide.s** - clockslide version (60-65535 cycles, 90 bytes)
* **vdelay_modify.s** - self modifying version (46-65535 cycles, 75 RAM or 27+52 RAM+ROM)
* **vdelay_extreme.s** - extreme version (40-65535 cycles, 826 bytes)

Assemble and include the source code in your project. It exports the **vdelay**
 subroutine, which you call with a 16-bit value for the number of cycles to delay.
 Low bits in **A**, high bits in **X**.

The minimum amount of delay is currently **63 cycles**.
 If the given parameter is less than that it will still delay that minimum number of cycles.
 The cycle count includes the jsr/rts of the subroutine call,
 though you will probably need to account for a few extra cycles to load A/X before calling.

This code must be placed in a 128-byte-aligned segment. Add **align=128** to your **CODE** segment CFG
 or add a **.segment** directive of your own to place it in a custom segment that is appropriately aligned.

The "short" version only permits delays only up to 255, with A as its parameter.
 Its minimum is lower, and the code is smaller.

The "clockslide" version uses a technique
 [suggested by Fiskbit](https://forums.nesdev.com/viewtopic.php?p=257562#p257562)
 which splits 2-byte instructions in half, and has an additional read at $EA
 (which is likely inconsequential). This reduces minimum and code size slightly.

The "self modifying" version places all or part of the code in RAM to lower the minimum.
 This is suitable for platforms where most code is run from RAM (Apple II, C64).
 For other platforms a "divided" option is provided that takes fewer bytes of RAM
 and places the rest in a separate ROM segment, though the RAM will have to be
 copied to where it is needed. (Also incorporates the clockslide technique.)

The "extreme" version has a lower minimum cycles, but is much larger, and requires 256-byte alignment.

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

This code should be 65C02 compatible, as it does not use instructions that have different timings from 6502.

The byte alignment requirements were chosen for ease of maintenance/use.
 If you remove the **.align** directive, it will still ensure correct branch timing with asserts,
 so if you are extremely cramped for space and willing to experiment with a few bytes of internal padding
 you might be able to get away with much smaller alignment.

The "extreme" version uses a large intro table and nopslide to achieve a 40 cycle minimum,
 at the expense of much greater code size. With some sacrifices (e.g. 255 maximum,
 or zero-page memory use for indirect jmp or avoiding pla, or a self-modifying jmp)
 it could get a few cycles lower, but I'll leave that adaptation for others.

If you need hard-coded delays of specific lengths (i.e. decided at compile-time, not run-time)
 you may find Bisqwit's *fixed-cycle delay code vending machine* useful:

* [https://bisqwit.iki.fi/utils/nesdelay.php](https://bisqwit.iki.fi/utils/nesdelay.php)

## History

* Version 1
  * vdelay - 78 cycles, 176 bytes.
* Version 2
  * vdelay - 64, 174.
* Version 3
  * vdelay - reduced alignment requirement.
  * vdelay_short - 57-255, 135.
  * vdelay_compact - 72, 144.
  * vdelay_extreme - 40, 896.
* Version 4
  * vdelay - 63, 113.
  * vdelay_short - 56, 80.
  * vdelay_compact - obsoleted.
  * vdelay_extreme - 40, 837.
* Version 5
  * vdelay - 63, 98.
  * vdelay_short - 56, 71.
  * vdelay_extreme - 40, 827.
* Version 6
  * vdelay - 61, 96.
  * vdelay_short - 56, 70.
  * vdelay_clockslide - 60, 90.
  * vdelay_modify - 46, 74/27+52.
  * vdelay_extreme - 40, 826.

## License

This library may be used, reused, and modified for any purpose, commercial or non-commercial.
 If distributing source code, do not remove the attribution to its original author,
 and document any modifications with attribution to their new author as well.

Attribution in released binaries or documentation is appreciated but not required.

If you'd like to support this project or its author, please visit:
 [Patreon](https://www.patreon.com/rainwarrior)
