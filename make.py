#!/usr/bin/env python3

import argparse
import sys
import os
import logging
import shutil
from pathlib import Path
from scripts.recipeProcessor import RecipeProcessor

DEFAULT_RECIPE_PATH = "recipes"
TO_CLEAN : list[Path] = [Path("build")]

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

def clean(args):
    for item in TO_CLEAN:
        if (item.exists()):
            if (item.is_dir()):
                shutil.rmtree(str(item.resolve()))
            else:
                item.unlink()
    
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

    # add custom source files definition

    # ============= Clean subcommand =============
    cleanParser = subparsers.add_parser(
        "clean",
        help = "Remove all generated content."
    )
    cleanParser.set_defaults(func = clean)

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

    subcommandReturnCode = args.func(args)
    sys.exit(subcommandReturnCode) # Pass return code to system. Handy e.g. when evaluating the result in GitHub actions.
    