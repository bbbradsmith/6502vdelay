# 6502 vdelay simulation test
# Brad Smith, 2020
# https://github.com/bbbradsmith/6502vdelay
#
# This will test every input value of vdelay.
# It generates a batch file with 65537 command lines to run sim65.
# It redirects the cycle count output to a log file.
# The log file is then parsed and compared.
# For each line, it compares the current cycle count against the previous,
# and will output whenever the difference between successive lines changes.
#
# For a successful output, you should see:
#   1. An output for the null test (the baseline cycle time of the program).
#   2. An output for test 0 with the minimum delay.
#   3. An output for test 1 with a difference of 0.
#   4. An output for 1 test past your minimum delay with a difference of 1.
#   5. A final count of 65536 tests if not aborted early.
# This indicates that up to the minimum, all inputs give the same delay (0),
# and after the minimum it increases by 1 cycle for each test.
#
# You can press CTRL+C while the batch file is running to stop the test run,
# which will analyze the partially generated log.

import os
import subprocess

skip_run = False # True to test a partial log already generated

bat = "temp\\test.bat"
log = "temp\\test.log"
run = "cc65\\bin\\sim65 -c temp\\test.bin"

try:
    os.remove(bat)
except:
    pass

if not skip_run:
    try:
        os.remove(log)
    except:
        pass

s = "%s 0000N >> %s\n" % (run,log) # null test
for i in range(0,65536):
    cline = "%s %04X >> %s\n" % (run,i,log)
    s += cline
f = open(bat,"wt")
f.write(s)
f.close()

if not skip_run:
    subprocess.call(bat)

logged = open(log,"rt").readlines()

ls = logged[0].split()
last = int(ls[0])
last_diff = 0
print("----- NULL: %d" % last)

count = 0
for i in range(1,len(logged)):
    ls = logged[i].split()
    if len(ls) == 2:
        count += 1
        cycles = int(ls[0])
        diff = cycles - last
        if diff != last_diff:
            print("%5d %04X: %d" % (i-1,i-1,diff))
        last = cycles
        last_diff = diff
print("count: %d" % count)
