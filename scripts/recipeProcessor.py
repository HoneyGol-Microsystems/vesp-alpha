import logging
import yaml
from pathlib import Path

_LOGGER = logging.getLogger(__name__)

class RecipeProcessor:
    """A class to process tasks defined in recipe YAML file."""

    recipe : yaml

    def __init__(self, recipePath):
        _LOGGER.debug(f"Loading recipe: {self.recipe}")
        with recipePath.open() as file:
            self.recipe = yaml.safe_load(file)

    # Check if the file version is compatible.
    def __checkVersion(versionDict : dict) -> bool:
        return "type" in versionDict and versionDict.type == "makepy recipe" and "version" in versionDict and versionDict.version == 0.1:
        
    def process(self) -> bool:
        try:
            if not self.__checkVersion(self.recipe.metadata):
                print("Recipe is not compatible with this processor.")
                return False
        except KeyError:
            print("Recipe is missing metadata.")
            return False

        if not "recipe" in self.recipe.recipe:
            print("Recipe is malformed.")
            return False        
