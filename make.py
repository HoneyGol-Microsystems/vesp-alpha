import argparse
import sys
import subprocess
import os
import logging
import shutil
from itertools import zip_longest
from pathlib import Path
import yaml
from scripts.recipeProcessor import RecipeProcessor

# from elftools.elf.elffile import ELFFile
# from elftools.elf import descriptions
# from elftools.common import exceptions as elfexceptions

_LOGGER = logging.getLogger(__name__)

RVTESTS_SOURCE = os.path.join("tests", "riscv-tests", "isa")
HWTESTS_DIR = os.path.join("tests", "hwtests")
RVTESTS_HEX_DIR = os.path.join("tests", "riscv-tests-hex")
RVTESTS_TOP_TEMPLATE = os.path.join("tests", "riscvTopTest.v")
BUILD_DIR = "build"
IVERILOG_OUTPUT = os.path.join(BUILD_DIR, "tmp.out")

ASSERT_FAIL_MSG = "ASSERT_FAIL"
ASSERT_SUCC_MSG = "ASSERT_SUCCESS"

def getRVExecsFromPath(sourcePath):

    execs = []

    # for fileName in os.listdir(sourcePath):

    #     filePath = os.path.join(sourcePath, fileName)
    #     if not os.path.isfile(filePath):
    #         continue

    #     with open(filePath, "rb") as file:
    #         try:
    #             elffile = ELFFile(file)
    #         except elfexceptions.ELFError as e:
    #             # Skip non-ELF files.
    #             continue
    #         else:
    #             architecture = elffile.get_machine_arch()
    #             eType = elffile.header["e_type"]
    #             if architecture != "RISC-V" or eType != "ET_EXEC":
    #                 # Skip non-RISC-V executables.
    #                 continue 

    #     # File passed all checks, add to list.
    #     execs.append(fileName)
    
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

def test(args):
    
    if "recipe" in args and args.recipe:
        print(args)
        print("custom recipe not implemented yet")
    else:
        path = Path("recipes")
        if not path.exists():
            print("No default recipe folder found. Exiting.")
            exit(1)
        recipes = [recipe for recipe in path.iterdir() if recipe.is_file() and (recipe.suffix == ".yaml" or recipe.suffix == ".yml")]
        _LOGGER.debug(f"Found recipes: {recipes}")

        failedRecipes = []

        for recipe in recipes:
            processor = RecipeProcessor(recipe)
            if not processor.process():
                failedRecipes.append(recipe)

        if len(failedRecipes) > 0:
            print("Finished with errors! Rerun with -v or -vv to get more information.")
        else:
            print("Finished successfully!")

        print("Details:")
        print(f"- count of test suites: {len(recipes)}")
        print(f"- # failed: {len(failedRecipes)}")
        print(f"- failed suites: {[str(recName) for recName in failedRecipes]}")

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
        "--recipe",
        help = "Manually specify a recipe (or directory with recipes) to run.",
        action = "store",
        type = Path,
    )

    # add custom source files definition

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
        action = "count",
        default = 0
    )

    args = parser.parse_args()

    if args.v == 1:
        logging.basicConfig(level = logging.INFO)
    elif args.v > 1:
        logging.basicConfig(level = logging.DEBUG)

    args.func(args)
    