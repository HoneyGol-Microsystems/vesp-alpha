import argparse
import sys
import subprocess
import os
import logging
import shutil


HWTESTS_DIR = os.path.join("tests", "hwtests")
RVTESTS_DIR = os.path.join("tests", "rvtests", "hex")
RVTESTS_TOP_TEMPLATE = os.path.join("tests", "rvtests", "topTest.v")
BUILD_DIR = "build"
IVERILOG_OUTPUT = os.path.join(BUILD_DIR, "tmp.out")

ASSERT_FAIL_MSG = "ASSERT_FAIL"
ASSERT_SUCC_MSG = "ASSERT_SUCCESS"

def printSeparator():
    print("======================================")

def prepareTesting():    
    logging.debug("Creating temp directory...")
    os.makedirs(BUILD_DIR, exist_ok = True)

def test():
    hwtest()
    rvtest()

def rvtest():

    prepareTesting()

    PREPROCESSED_TOP_PATH = os.path.join(BUILD_DIR, "tmp.v")

    testfiles = [file for file in os.listdir(RVTESTS_DIR) if file.endswith(".hex") and "rv32" in file]
    testfiles.sort()

    logging.debug(f"Found test files: {testfiles}")

    if not testfiles:
        print("No test files found. Terminating.")
        return

    successfulCount = 0

    print("Preprocessing top entity...")
    logging.debug(f"Opening top template at: {RVTESTS_TOP_TEMPLATE}")
    try:
        with open(RVTESTS_TOP_TEMPLATE) as template:
            templateText = template.read()
            logging.debug("Replacing test names...")
            templateText = templateText.replace("\"PATH_TO_HEX\"", "\"build/tmp.hex\"")
    except IOError:
        print("Couldn't open top entity template. Terminating.")
        return
    
    logging.debug("Writing preprocessed top...")

    try:
        with open(PREPROCESSED_TOP_PATH, 'w') as target:
            target.write(templateText)
    except IOError:
        print("Couldn't write preprocessed top. Terminating.")
        return

    print("Compiling top entity...")
    ret = subprocess.run(
        ["iverilog", PREPROCESSED_TOP_PATH, "-o" + IVERILOG_OUTPUT, "-Isrc/components"],
        stdout = sys.stdout,
        stderr = subprocess.STDOUT
    )

    if ret.returncode != 0:
        print("❌ Compilation error! Terminating.")
        printSeparator()
        return
    
    logging.debug("Preparations successful, running tests...")
    unsuccessfulTestNames = []
    
    for testId, testName in enumerate(testfiles):
        
        print(f"Begin test [{testId + 1}/{len(testfiles)}]: {testName}")
        logging.debug("Copying binary...")
        shutil.copy2(os.path.join(RVTESTS_DIR, testName), os.path.join(BUILD_DIR, "tmp.hex"))
        
        print("Running test...")
        output = subprocess.check_output(
            [IVERILOG_OUTPUT],
            stderr = subprocess.STDOUT
        )

        outputString = output.decode()

        print(outputString)

        if ASSERT_FAIL_MSG in outputString:
            print("❌ Test error!")
            printSeparator()
            unsuccessfulTestNames.append(testName)
            continue
        elif not ASSERT_SUCC_MSG in outputString:
            print("⚠️ Unknown error!")
            printSeparator()
            unsuccessfulTestNames.append(testName)
            continue
        else:
            print("✅ Success!")
            successfulCount += 1
            printSeparator()
        
    print("RISC-V official tests summary")
    print(f"Successful tests: {successfulCount}/{len(testfiles)}")        
    if successfulCount < len(testfiles):
        print("❌ There were some errors.")
        print("Unsuccessful tests: ", unsuccessfulTestNames)
    else:
        print("✅ All tests passed.")

def hwtest():

    prepareTesting()

    testfiles = [file for file in os.listdir(HWTESTS_DIR) if file.endswith(".v")]
    testfiles.sort()

    logging.debug(f"Found test files: {testfiles}")

    if not testfiles:
        print("No test files found. Terminating.")
        return

    successfulCount = 0
    unsuccessfulTestNames = []
    for testId, testName in enumerate(testfiles):

        print(f"Begin test [{testId + 1}/{len(testfiles)}]: {testName}")
        print("Compiling test...")

        ret = subprocess.run(
            ["iverilog", os.path.join(HWTESTS_DIR, testName), "-o" + IVERILOG_OUTPUT],
            stdout = sys.stdout,
            stderr = subprocess.STDOUT
        )

        if ret.returncode != 0:
            print("❌ Compilation error!")
            printSeparator()
            continue

        print("Running test...")
        output = subprocess.check_output(
            [IVERILOG_OUTPUT],
            stderr = subprocess.STDOUT
        )

        outputString = output.decode()

        print(outputString)

        if ASSERT_FAIL_MSG in outputString:
            print("❌ Test error!")
            printSeparator()
            unsuccessfulTestNames.append(testName)
            continue
        elif not ASSERT_SUCC_MSG in outputString:
            print("⚠️ Unknown error!")
            printSeparator()
            unsuccessfulTestNames.append(testName)
            continue
        else:
            print("✅ Success!")
            successfulCount += 1
            printSeparator()

    print("Hardware testing summary")
    print(f"Successful tests: {successfulCount}/{len(testfiles)}")
    if successfulCount < len(testfiles):
        print("There were some errors.")
        print("Unsuccessful tests: ", unsuccessfulTestNames)
    else:
        print("All tests passed.")

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
        choices = ["test", "rvtest", "hwtest"]
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
    elif args.command == "rvtest":
        rvtest()
    elif args.command == "hwtest":
        hwtest()

    