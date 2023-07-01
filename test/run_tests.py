#! /usr/bin/env python3

"""A script to run vdelay tests."""

import argparse
import subprocess
import re
import multiprocessing
from typing import Optional


class Sim65Driver:
    """A class that knows how to execute tests using sim65.

    This is not just a function because we need to refer to the 'sim65_executable'
    and 'test_program' values while running a test. Also, we store the compiled
    'test_ouput_regexp' in the class scope.
    """

    # We accept either LF or CR/LF as end-of-line terminators.
    test_output_regexp = re.compile(b"([0-9]+) cycles\r?\n")

    def __init__(self, sim65_executable: str, test_program: str):
        self.sim65_executable = sim65_executable
        self.test_program = test_program

    def run_testcase(self, k: Optional[int]) -> int:
        """Run sim65 to execute the test program with an argument.

        The value 'k' will be passed to sim65 and forwarded to the
        executed 6502 test program as a 4-digit hexadecimal string using
        capital letters (this is important). If k is None, a "null test"
        will be executed with an argument of the form "0000N".
        """
        test_program_argument = "0000N" if k is None else "{:04X}".format(k)
        subprocess_args = [self.sim65_executable, "-c", self.test_program, test_program_argument]
        completed_process = subprocess.run(subprocess_args, capture_output=True)
        if completed_process.returncode != 0:
            raise RuntimeError("Unexpected returncode: {}.".format(completed_process.returncode))
        match = self.test_output_regexp.fullmatch(completed_process.stdout)
        if match is None:
            raise RuntimeError("Unexpected response: {!r}.".format(completed_process.stdout))
        return int(match.group(1))


def main() -> None:
    """Run the vdelay tests."""

    # Parse command-line arguments.

    parser = argparse.ArgumentParser("Test vdelay cycle-counts using sim65.")
    parser.add_argument("--min", type=int, default=0, help="minimum value to test")
    parser.add_argument("--max", type=int, default=65535, help="maximum value to test")
    parser.add_argument("--sim65-executable", type=str, default="sim65", help="path to the sim65 executable")
    parser.add_argument("--test-program", type=str, default="temp/test.bin", help="path to the 6502 program to be tested")

    args = parser.parse_args()

    # Prepare and run the tests.

    actual_testcases = list(range(args.min, args.max + 1))
    all_testcases = [None] + actual_testcases

    sim65_driver = Sim65Driver(args.sim65_executable, args.test_program)
    with multiprocessing.Pool() as pool:
        results = pool.map(sim65_driver.run_testcase, all_testcases)

    null_testcase_cycles = results[0]
    actual_testcases_cycles = results[1:]

    # Present the results in the same format as the original "test.py" program.

    print("----- NULL:", null_testcase_cycles)
    (last, last_diff) = (null_testcase_cycles, 0)
    for (testcase, cycles) in zip(actual_testcases, actual_testcases_cycles):
        diff = cycles - last
        if diff != last_diff:
            print("{:5d} {:04X}: {:d}".format(testcase, testcase, diff))
        (last, last_diff) = (cycles, diff)
    print("count:", len(actual_testcases_cycles))


if __name__ == "__main__":
    main()
