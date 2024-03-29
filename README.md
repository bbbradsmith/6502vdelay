# 6502 vdelay

A 6502 delay routine for delaying a number of cycles specified at runtime.

You might call this arbitrary delay, procedural delay, programmatic delay, variable delay, dial-a-delay etc.
 It might be handy in situations where you have a 6502 without effective timer hardware (e.g. Apple II, NES).

Uses ca65 ([cc65](https://cc65.github.io/)) assembly syntax.

Authors:
* [Brad Smith](http://rainwarrior.ca)
* Fiskbit ([source](https://forums.nesdev.com/viewtopic.php?p=257651#p257651))
* [Eric Anderson](https://github.com/ejona86) ([source](http://forums.nesdev.com/viewtopic.php?p=258154#p258154))
* [Joel Yliluoma](https://bisqwit.iki.fi/) ([source](https://wiki.nesdev.com/w/index.php/Delay_code))
* [George Foot](https://github.com/gfoot) ([issue](https://github.com/bbbradsmith/6502vdelay/issues/6))
* [Sidney Cadot](https://github.com/sidneycadot) ([PR](https://github.com/bbbradsmith/6502vdelay/pull/4), [PR](https://github.com/bbbradsmith/6502vdelay/pull/5))

Version 11

## Usage

* **vdelay.s** - normal version (29-65535 cycles, 46 bytes)
* **vdelay_short.s** - short version (27-255 cycles, 30 bytes)

Assemble and include the source code in your project. It exports the **vdelay**
 subroutine, which you call with a 16-bit value for the number of cycles to delay.
 Low bits in **A**, high bits in **X**.

The minimum amount of delay is currently **29 cycles**.
 If the given parameter is less than that it will still delay that minimum number of cycles.
 The cycle count includes the JSR/RTS of the subroutine call,
 though you will probably need to account for a few extra cycles to load A/X before calling.

This code must be placed in a 64-byte-aligned segment. Add **align=64** to your **CODE** segment CFG
 or add a **.segment** directive of your own to place it in a custom segment that is appropriately aligned.

The **short** version only permits delays only up to 255, with **A** as its parameter.
 The minimum is slightly lower, and the code is smaller.
 Since X is ignored, there may be less calling overhead.

## Notes

This code should be 65C02 compatible, as it does not use instructions that have different timings from 6502.

The byte alignment requirements were chosen for ease of maintenance/use.
 If you remove the **.align** directive, it will still ensure correct branch timing with asserts,
 so if you are extremely cramped for space and willing to experiment with a few bytes of internal padding
 you might be able to get away with much smaller alignment.

If you need hard-coded delays of specific lengths (i.e. decided at compile-time, not run-time),
 or want to investigate other alternative, you may find these articles and tools written by Bisqwit useful:

* [NESDev Wiki: Fixed cycle delay](https://wiki.nesdev.com/w/index.php/Fixed_cycle_delay) (minimal-size fixed-cycle delays)
* [NESDev Wiki: Delay code](https://wiki.nesdev.com/w/index.php/Delay_code) (collection of variable-delay methods)
* [NES 6502 / RP2A03 / RP2A07 fixed-cycle delay code vending machine](https://bisqwit.iki.fi/utils/nesdelay.php)

## Tests

Place **cc65** in **test/cc65** and create a **test/temp** folder. **[python3](https://www.python.org/)** is also required.

Run **test/test.bat** to build and test the binaries. Alternatively, run **make** in the **test/** folder.

These will build test binaries, and an NES ROM, then will begin running tests of each. Full tests will typically take several minutes. A correct test will look something like this:

```
----- NULL: 1447
    0 0000: 29
    1 0001: 0
   30 001E: 1
count: 65536
```

Each line of the results shows:
* The input value in decimal
* The input value in hexadecimal
* The cycle difference between this test and the previous input (input-1, not the previous result line)

Any test where the difference was the same as the previous test is omitted, therefore we should see:
* 1 line for the NULL test, giving a baseline cycle count. (Any value is OK.)
* 1 line for input 0 showing the minimum delay value.
* 1 line for input 1 with a value of 0, indicating that the delay is always equal to the minimum whenever the input is less than it.
* 1 line for the minimum delay + 1 with a value of 1, indicating that once the minimum is reached, each test is 1 more cycle than the preceding one.
* A final count of 65536 (or 256 for the short test).

The NES ROM compiled to **test/temp/test_nes.nes** can be used to test the code in an NES debugging emulator.
 In FCEUX or Mesen emulators you can set a read breakpoint on $FE to quickly find the function entry,
 then step over it to count its cycles, or step into it for debugging.
 Use the gamepad to set the parameter (the default is set at 64 = $0040),
 and press A to run the test.

See **test/test.bat** or **test/makefile** for other run options.

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
  * vdelay_clockslide - 60, 89.
  * vdelay_modify - 44, 72/27+52.
  * vdelay_extreme - 40, 826.
  * vdelay_short - 56, 70.
  * vdelay_short_clockslide - 51, 48.
* Version 7
  * vdelay - 48, 62.
  * vdelay_clockslide - obsoleted: vdelay is now a clockslide technique.
  * vdelay_modify - 35, 54.
  * vdelay_extreme - obsoleted.
  * vdelay_short - 46, 36.
  * vdelay_short_clockslide - obsoleted.
  * vdelay_short_modify - 33, 28.
* Version 8
  * vdelay - 37, 55. Y not clobbered.
  * vdelay_modify - Y not clobbered.
  * vdelay_short - 35, 30. X not clobbered.
  * vdelay_short_modify - X not clobbered.
* Version 9
  * vdelay - 36, 62.
  * vdelay_short - 34, 37.
  * vdelay_extreme - 31, 297/23+283.
  * vdelay_short_extreme - 27, 254/16+240.
* Version 10
  * vdelay - 29, 55.
  * vdelay_modify - obsoleted.
  * vdelay_extreme - obsoleted.
  * vdelay_short - 27, 30.
  * vdelay_short_modify - obsoleted.
  * vdelay_short_extreme - obsoleted.
* Version 11
  * vdelay - 29, 46.
  * vdelay_short - 27, 30 - unchanged.

## License

This library may be used, reused, and modified for any purpose, commercial or non-commercial.
 If distributing source code, do not remove the attribution to its original authors,
 and document any modifications with attribution to their new author as well.

Attribution in released binaries or documentation is appreciated but not required.
