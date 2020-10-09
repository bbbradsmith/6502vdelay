# 6502 vdelay simulation test
# Brad Smith, 2020
# https://github.com/bbbradsmith/6502vdelay
#
# This will test every input value of vdelay.
# It generates a batch file with 65536 command lines to run sim65.
# It redirects the cycle count output to a log file.
# The log file is then parsed and compared.
# For each line, it compares the current count against the previous,
# and will output whenever the difference between successive lines changes.
#
# For a successful output, you should see:
#   1. An output for test 0 with the baseline cycle time of the program.
#   2. An output for test 1 with a difference of 0.
#   3. An output for 1 test past your minimum delay with a difference of 1.
#   4. A final count of 65536 tests.
# This indicates that up to the minimum, all inputs give the same delay,
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

s = ""
for i in range(0,65536):
    cline = "%s %04X >> %s\n" % (run,i,log)
    s += cline
f = open(bat,"wt")
f.write(s)
f.close()

if not skip_run:
    subprocess.call(bat)

count = 0
last = 0
last_diff = 0
logged = open(log,"rt").readlines()
for i in range(0,len(logged)):
    ls = logged[i].split()
    if len(ls) == 2:
        count += 1
        cycles = int(ls[0])
        diff = cycles - last
        if diff != last_diff:
            print("%5d %04X: %d" % (i,i,diff))
        last = cycles
        last_diff = diff
print("count: %d" % count)
