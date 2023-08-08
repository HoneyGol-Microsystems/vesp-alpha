import argparse
import sys
import subprocess
import os
import logging


TESTS_DIR = "tests"
BUILD_DIR = "build"

def printSeparator():
    print("======================================")

def test():

    IVERILOG_OUTPUT = os.path.join(BUILD_DIR, "tmp.out")

    logging.debug("Creating temp directory...")
    os.makedirs(BUILD_DIR, exist_ok = True)

    testfiles = [file for file in os.listdir(TESTS_DIR) if file.endswith(".v")]
    testfiles.sort()

    logging.debug(f"Found test files: {testfiles}")

    if not testfiles:
        print("No test files found. Terminating.")
        return

    successfulCount = 0

    for testId, testName in enumerate(testfiles):

        print(f"Begin test [{testId + 1}/{len(testfiles)}]: {testName}")
        print("Compiling test...")

        ret = subprocess.run(
            ["iverilog", os.path.join(TESTS_DIR, testName), "-o" + IVERILOG_OUTPUT],
            stdout = sys.stdout,
            stderr = subprocess.STDOUT
        )

        if ret.returncode != 0:
            print("❌ Compilation error!")
            printSeparator()
            continue

        print("Running test...")

        ret = subprocess.run(
            [IVERILOG_OUTPUT],
            stdout = sys.stdout,
            stderr = subprocess.STDOUT
        )

        if ret.returncode != 0:
            print("❌ Test error!")
            printSeparator()
            continue

        print("✅ Success!")
        successfulCount += 1
        printSeparator()

    print("Testing summary")
    print(f"Successful tests: {successfulCount}/{len(testfiles)}")
    if successfulCount < len(testfiles):
        print("Conclusion: your code sucks 🤮")
    else:
        print("Conclusion: very well done 🎉")

if __name__ == "__main__":

    # Setting proper working directory (to script location).
    os.chdir(sys.path[0])

    parser = argparse.ArgumentParser(
        prog = "make.py",
        description = "Cross-platform project make script."
    )

    parser.add_argument(
        "command",
        help = "Action to do.",
        choices = ["test"]
    )

    parser.add_argument(
        "-v",
        help = "Print debug data.",
        action = "store_true"
    )

    args = parser.parse_args()

    if not args.command:
        print("No command specified.")
        sys.exit()
    
    if args.v:
        logging.basicConfig(level = logging.DEBUG)

    if args.command == "test":
        test()

    