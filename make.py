import argparse
import sys
import os
import logging
from pathlib import Path
from scripts.recipeProcessor import RecipeProcessor

_LOGGER = logging.getLogger(__name__)

def test(args):
    
    recipes = []
    failedRecipes = []

    if "recipe" in args and args.recipe:
        if not args.recipe.exists():
            print("Specified recipe (or folder) does not exist.")
            exit(1)

        if args.recipe.is_file():
            if args.recipe.suffix == ".yaml" or args.recipe.suffix == ".yml":
                recipes.append(args.recipe)
            else:
                print("Specified file is not YAML!")
                exit(1)
        elif args.recipe.is_dir():
            recipes = [recipe for recipe in args.recipe.iterdir() if recipe.is_file() and (recipe.suffix == ".yaml" or recipe.suffix == ".yml")]    
        else:
            print("Specified path is neither file nor directory.")
            exit(1)
    else:
        path = Path("recipes")
        if not path.exists() or not path.is_dir():
            print("No default recipe folder found. Exiting.")
            exit(1)
        recipes = [recipe for recipe in path.iterdir() if recipe.is_file() and (recipe.suffix == ".yaml" or recipe.suffix == ".yml")]
    
    _LOGGER.debug(f"Running recipes: {recipes}")

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

    args.func(args)
    