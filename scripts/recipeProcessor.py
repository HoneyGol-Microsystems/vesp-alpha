import logging
import yaml
from pathlib import Path

_LOGGER = logging.getLogger(__name__)

class MissingRequiredKey(Exception):
    pass

class RecipeProcessingFailed(Exception):
    pass

class RecipeProcessor:
    """
    A class to process tasks defined in recipe YAML file.
    """

    recipe : yaml

    def __init__(self, recipePath):
        _LOGGER.debug(f"Loading recipe: {recipePath}")
        with recipePath.open() as file:
            self.recipe = yaml.safe_load(file)

    # Creates a directory.
    # Returns true if successful.
    # Throws MissingRequiredKey if there is directory name missing (or not string).
    def stepMakeDirectory(self, stepData) -> bool:
        
        dirName = stepData
        if type(dirName) != str:
            raise MissingRequiredKey

        _LOGGER.debug(f"Creating directory '{stepData}'")
        Path(stepData).mkdir(exist_ok = True)
        
        return True

    def stepRun(self, stepData) -> bool:

        try:
            execName      = stepData["executable"]
            params        = stepData["params"]
            assertConds   = stepData["assert"]
        except KeyError:
            _LOGGER.error("Missing required key found during elaboration of run step. Halting.")
            return False

        _LOGGER.debug(f"Running executable '{execName}'")
        # ret = subprocess.run(
        #     ["iverilog", os.path.join(HWTESTS_DIR, testName), "-o" + IVERILOG_OUTPUT],
        #     stdout = sys.stdout,
        #     stderr = subprocess.STDOUT
        # )

    stepParsers : dict = {
        "make_directory" : stepMakeDirectory,
        "run" : stepRun
    }

    # Check if the file version is compatible.
    def __checkVersion(self, metadata) -> bool:
        return "type" in metadata and metadata["type"] == "makepy recipe" and "version" in metadata and metadata["version"] == 0.1
    
    # Process the recipe.
    # Returns true when all actions in the recipe succeeded, otherwise false.
    # Throws RecipeProcessingFailed exception if there is a syntax error in the recipe.
    def process(self) -> bool:
        try:
            if not self.__checkVersion(self.recipe["metadata"]):
                _LOGGER.error("Recipe is not compatible with this processor.")
                return False
        except (KeyError, TypeError) as e:
            _LOGGER.error("Recipe is missing metadata.")
            return False

        # Load required keys.
        try:
            self.name = self.recipe["recipe"]["name"]
            self.steps = self.recipe["recipe"]["steps"]
        except KeyError:
            _LOGGER.error("Recipe does not contain required keys.")
            return False
        
        # Load optional keys.
        try:
            self.comment = self.recipe["comment"]
        except KeyError:
            self.comment = "N/A"
        
        try:
            self.printLogs = self.recipe["print_logs"]
        except KeyError:
            self.printLogs = "error"
        
        print(f"Running recipe {self.name}...")
        _LOGGER.debug(f"Recipe comment: {self.comment}")

        for step in self.steps:
            try:
                stepName = list(step.keys())[0]
                if not self.stepParsers[stepName](self, step[stepName]):
                    _LOGGER.info(f"Step {stepName} failed, returning false.")
                    return False
            except KeyError:
                _LOGGER.error(f"Unsupported step '{stepName}', halting.")
                raise RecipeProcessingFailed
        
        _LOGGER.info("All steps succeeded.")
        return True
