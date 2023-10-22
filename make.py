#!/usr/bin/env python3

import argparse
import sys
import subprocess
import os
import logging
import shutil
from itertools import zip_longest

from elftools.elf.elffile import ELFFile
from elftools.elf import descriptions
from elftools.common import exceptions as elfexceptions

RVTESTS_SOURCE = os.path.join("tests", "riscv-tests", "isa")
HWTESTS_DIR = os.path.join("tests", "hwtests")
RVTESTS_HEX_DIR = os.path.join("tests", "riscv-tests-hex")
RVTESTS_TOP_TEMPLATE = os.path.join("tests", "riscvTopTest.v")
BUILD_DIR = "build"
IVERILOG_OUTPUT = os.path.join(BUILD_DIR, "tmp.out")

ASSERT_FAIL_MSG = "ASSERT_FAIL"
ASSERT_SUCC_MSG = "ASSERT_SUCCESS"

def printSeparator():
    print("======================================")

def prepareTesting():    
    logging.debug("Creating temp directory...")
    os.makedirs(BUILD_DIR, exist_ok = True)

def rvtest():

    prepareTesting()

    PREPROCESSED_TOP_PATH = os.path.join(BUILD_DIR, "tmp.v")

    testfiles = [file for file in os.listdir(RVTESTS_HEX_DIR) if file.endswith(".hex")]
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
        ["iverilog", PREPROCESSED_TOP_PATH, "-o" + IVERILOG_OUTPUT, "-Irtl/components"],
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
        shutil.copy2(os.path.join(RVTESTS_HEX_DIR, testName), os.path.join(BUILD_DIR, "tmp.hex"))
        
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

def getRVExecsFromPath(sourcePath):

    execs = []

    for fileName in os.listdir(sourcePath):

        filePath = os.path.join(sourcePath, fileName)
        if not os.path.isfile(filePath):
            continue

        with open(filePath, "rb") as file:
            try:
                elffile = ELFFile(file)
            except elfexceptions.ELFError as e:
                # Skip non-ELF files.
                continue
            else:
                architecture = elffile.get_machine_arch()
                eType = elffile.header["e_type"]
                if architecture != "RISC-V" or eType != "ET_EXEC":
                    # Skip non-RISC-V executables.
                    continue 

        # File passed all checks, add to list.
        execs.append(fileName)
    
    return execs
    
# Copied from https://docs.python.org/3/library/itertools.html
def grouper(iterable, n, fillvalue=None):
    """Collect data into fixed-length chunks or blocks"""
    # grouper('ABCDEFG', 3, 'x') --> ABC DEF Gxx
    args = [iter(iterable)] * n
    return zip_longest(*args, fillvalue=fillvalue)

# Inspired by https://github.com/sifive/elf2hex/blob/master/freedom-bin2hex.py
def bin2hex(bit_width, inPath, outPath):
    byte_width = bit_width // 8

    infile = open(inPath, "rb")
    outfile = open(outPath, "w")

    for row in grouper(infile.read(), byte_width, fillvalue=0):
        # Reverse because in Verilog most-significant bit of vectors is first.
        hex_row = ''.join('{:02x}'.format(b) for b in reversed(row))
        outfile.write(hex_row + '\n')

    infile.close()
    outfile.close()

def convert(args):
    sourcePath = os.path.normpath(args.sourceDir)
    outputPath = os.path.normpath(args.outputDir)
                        
    if args.iformat == "binary" and args.oformat == "hex":
        sourceFiles = getRVExecsFromPath(sourcePath)
        
        for fileName in sourceFiles:

            tempObjFilePath = os.path.join(BUILD_DIR, "temp.obj")

            ret = subprocess.run(
                ["riscv64-unknown-elf-objcopy", os.path.join(sourcePath, fileName), "-Obinary", tempObjFilePath],
                stdout = sys.stdout,
                stderr = subprocess.STDOUT
            )

            if ret.returncode != 0:
                print(f"Warning: '{fileName}' can't be converted (possibly malformed?).")
                continue
                
            bin2hex(32, tempObjFilePath, os.path.join(outputPath, fileName + ".hex"))
            print(f"Converted '{fileName}' to hex.")

TEST_SUITES = {
    "official": rvtest,
    "hardware": hwtest
}

def test(args):

    if "suite" in args and args.suite:
        for testName in args.suite:
            TEST_SUITES[testName]()
    else:
        for name,func in TEST_SUITES.items():
            func()

if __name__ == "__main__":

    # Setting proper working directory (to script location).
    os.chdir(sys.path[0])

    parser = argparse.ArgumentParser(
        prog = "make.py",
        description = "Cross-platform project make script."
    )

    subparsers = parser.add_subparsers(
        help = "Action to do.",
        required = True
    )

    # ============= Test subcommand =============
    testParser = subparsers.add_parser(
        "test",
        help = "Run tests."
    )
    testParser.set_defaults(func = test)
    testParser.add_argument(
        "--suite",
        help = "Manually specify test suites to run.",
        choices = list(TEST_SUITES.keys()),
        action = "append"
    )

    # ============= Convert subcommand =============
    convertParser = subparsers.add_parser(
        "convert",
        help = "Convert different executable formats."
    )
    convertParser.set_defaults(func = convert)
    
    convertParser.add_argument(
        "sourceDir",
        help = "Source directory."
    )
    convertParser.add_argument(
        "outputDir",
        help = "Output directory."
    )    
    
    convertParser.add_argument(
        "--iformat",
        help = "Input file format.",
        choices = ["binary"],
        required = True
    )
    convertParser.add_argument(
        "--oformat",
        help = "Output file format.",
        choices = ["hex"],
        required = True
    )
    
    # ============= Other arguments =============
    parser.add_argument(
        "-v",
        help = "Print debug data.",
        action = "store_true"
    )

    args = parser.parse_args()

    if args.v:
        logging.basicConfig(level = logging.DEBUG)

    args.func(args)
    