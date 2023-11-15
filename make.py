#!/usr/bin/env python3

import argparse
import sys
import os
import logging
import shutil
import subprocess
from pathlib import Path
from scripts.recipeProcessor import RecipeProcessor

DEFAULT_RECIPE_PATH = "recipes"
DEFAULT_VIVADO_PATH = "build/vivado"

_LOGGER = logging.getLogger(__name__)

def test(args):
    
    recipes = []
    failedRecipes = []
    customSourcePath = None

    if "recipe" in args and args.recipe:
        if not args.recipe.exists():
            print("Specified recipe (or folder) does not exist.")
            return True
        if args.recipe.is_file():
            if args.recipe.suffix == ".yaml" or args.recipe.suffix == ".yml":
                recipes.append(args.recipe)
            else:
                print("Specified file is not YAML!")
                return True
        elif args.recipe.is_dir():
            recipes = [recipe for recipe in args.recipe.iterdir() if recipe.is_file() and (recipe.suffix == ".yaml" or recipe.suffix == ".yml")]    
        else:
            print("Specified path is neither file nor directory.")
            return True
        
        if "sources" in args and args.sources:
            if not args.sources.exists():
                _LOGGER.error("Specified source path does not exist.")
                return True
            else:
                customSourcePath = args.sources
    else:
        if "sources" in args and args.sources:
            _LOGGER.warning("You specified custom sources but not recipe path, ignoring")

        print("No recipe path specified, using default...")
        path = Path(DEFAULT_RECIPE_PATH)
        if not path.exists() or not path.is_dir():
            print("No default recipe folder found. Exiting.")
            return True
        recipes = [recipe for recipe in path.iterdir() if recipe.is_file() and (recipe.suffix == ".yaml" or recipe.suffix == ".yml")]
    
    _LOGGER.debug(f"Running recipes: {recipes}")

    for recipe in recipes:
        processor = RecipeProcessor(recipe, customSourcePath)
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

    return len(failedRecipes) > 0

def vivado(args):

    path : Path         = args.path
    no_overwrite : bool = args.no_overwrite
    gui : bool          = args.gui

    if path.exists() and not path.is_dir():
        print("Specified path is invalid!")
        return False

    if not no_overwrite:
        shutil.rmtree(str(path.resolve()))

    if not path.exists():
        path.mkdir(parents = True, exist_ok = True)

    # Creating build dir to store logs.
    Path("build").mkdir(exist_ok = True)

    if gui:
        vivadoMode = "gui"
    else:
        vivadoMode = "tcl"

    proc = subprocess.run(
        ["vivado", "-mode", vivadoMode, "-source", "vivado/create_project.tcl", "-log", "build/vivado.log", "-journal", "build/vivado.jou", "-tclargs", str(path.resolve()), "vesp"]
    )

    return proc.returncode == 0

if __name__ == "__main__":

    # Setting proper working directory (to script location).
    os.chdir(sys.path[0])

    parser = argparse.ArgumentParser(
        prog = "make.py",
        description = "Cross-platform project make script."
    )

    subparsers = parser.add_subparsers(
        help = "Action to do.",
        required = True,
        dest = "command"
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
    testParser.add_argument(
        "--sources",
        help = "Manually specify a sources to be used with manually specified recipe.",
        action = "store",
        type = Path
    )

    # ============= Vivado subcommand =============
    vivadoParser = subparsers.add_parser(
        "vivado",
        help = "Create a Vivado project."
    )
    vivadoParser.set_defaults(func = vivado)
    vivadoParser.add_argument(
        "--gui",
        help = "Open a GUI.",
        action = "store_true"
    )
    # We will actually "overwrite" the project either way but won't delete any existing files (logs, VCDs, etc.)
    vivadoParser.add_argument(
        "--no-overwrite",
        help = "Do not overwrite an existing project.",
        action = "store_true"
    )
    vivadoParser.add_argument(
        "--path",
        help = "Set a custom path for the project.",
        action = "store",
        type = Path,
        default = Path("build/vivado")
    )

    # ============= Convert subcommand =============
    # convertParser = subparsers.add_parser(
    #     "convert",
    #     help = "Convert different executable formats."
    # )
    # convertParser.set_defaults(func = convert)
    
    # convertParser.add_argument(
    #     "sourceDir",
    #     help = "Source directory."
    # )
    # convertParser.add_argument(
    #     "outputDir",
    #     help = "Output directory."
    # )    
    
    # convertParser.add_argument(
    #     "--iformat",
    #     help = "Input file format.",
    #     choices = ["binary"],
    #     required = True
    # )
    # convertParser.add_argument(
    #     "--oformat",
    #     help = "Output file format.",
    #     choices = ["hex"],
    #     required = True
    # )
    
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

    # Pass return code to system. Handy e.g. when evaluating the result in GitHub actions.
    if(args.func(args)):
        sys.exit(0)
    else:
        sys.exit(1)
    