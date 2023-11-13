import logging
import yaml
import subprocess
import shutil
import re
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

    recipe : dict
    PLACEHOLDER_CURRENT_SOURCE = r"\bmpysource\b"
    PLACEHOLDER_CURRENT_SOURCE_STEM = r"\bmpysourcestem\b"

    def __init__(self, recipePath, customSourcePath : Path):
        _LOGGER.debug(f"Loading recipe: {recipePath}")
        self.fileName = str(recipePath)
        with recipePath.open() as file:
            try:
                self.recipe = yaml.safe_load(file)
            except yaml.error.YAMLError as e:
                _LOGGER.error("Failed to parse YAML structure of the recipe. Check for YAML format related errors - indentation etc. Check the log below, it should tell you which lines caused the error.")
                raise e # Reraise to provide more information.
        
        self.customSourcePath = customSourcePath

    # Creates a directory.
    # Returns true if successful.
    # Throws MissingRequiredKey if there is directory name missing (or not string).
    def stepMakeDirectory(self, stepData) -> bool:
        
        _LOGGER.info("Starting make directory step...")

        try:
            dirName = stepData["name"]
        except KeyError:
            _LOGGER.error("Directory name missing.")
            raise MissingRequiredKey

        if type(dirName) != str:
            _LOGGER.error("Directory name is not a string.")
            raise MissingRequiredKey

        _LOGGER.debug(f"Creating directory '{dirName}'")
        Path(dirName).mkdir(exist_ok = True)
        
        _LOGGER.info("Step passed.")
        return True

    def stepRun(self, stepData) -> bool:

        _LOGGER.info("Starting run step...")

        if stepData == None:
            _LOGGER.error("Run step empty.")
            return False

        try:
            execName             = stepData["executable"]
        except KeyError:
            _LOGGER.error("Missing required key found during elaboration of run step. Halting.")
            return False
        
        try:
            params = stepData["params"]
        except KeyError:
            params = []

        try:
            assertReturnCode = stepData["assert"]["return_code"] 
        except KeyError:
            assertReturnCode = None
        _LOGGER.debug(f"Assert return code: {assertReturnCode}")

        try:
            assertOutputNotCont = stepData["assert"]["output"]["not_contains"]
        except KeyError:
            assertOutputNotCont = []
        _LOGGER.debug(f"Assert output notcont: {assertOutputNotCont}")
        
        try:
            assertOutputCont    = stepData["assert"]["output"]["contains"]
        except KeyError:
            assertOutputCont    = []
        _LOGGER.debug(f"Assert output cont: {assertOutputCont}")


        _LOGGER.debug(f"Elaborated params: {params}")
        
        execWithParams = [execName, *params]
        _LOGGER.debug(f"Running: '{execWithParams}'")

        # stderr is set to stdout to merge and pipe these two.
        pipes = subprocess.Popen(
            execWithParams,
            stdout = subprocess.PIPE,
            stderr = subprocess.STDOUT,
            bufsize = 1,
            text = True
        )

        _LOGGER.info("Program's output follows:")

        output : str = ""

        if pipes.stdout is not None:
            for line in pipes.stdout:
                _LOGGER.info(f"{execName}: %s", line.strip('"\n"'))
                output += line
        
        # Required to get return code.
        pipes.wait()

        _LOGGER.info("Program's execution finished.")

        # There needs to be != None, because if the return code is 0, simple 'if assertReturnCode' will obviously evaluate to false.
        if assertReturnCode != None:
            if pipes.returncode != assertReturnCode:
                _LOGGER.info(f"Assertion for return code failed. Expected {assertReturnCode} got {pipes.returncode}")
                return False
            
        if type(assertOutputCont) == list:
            for outCont in assertOutputCont:
                if not outCont in (output):
                    _LOGGER.info(f"Assertion failed for program output condition: '{outCont}' not found in output.")
                    return False
        
        if type(assertOutputNotCont) == list:
            for outCont in assertOutputNotCont:
                if outCont in (output):
                    _LOGGER.info(f"Assertion failed for program output condition: '{outCont}' was found in output.")
                    return False
        
        _LOGGER.info("Step passed.")
        return True

    # Finds and replace specified string in a specified file, then writes result into a specified file.
    def stepFindReplace(self, stepData) -> bool:
        
        _LOGGER.info("Starting make directory step...")

        try:
            sourceFilePath = Path(stepData["source_file"])
            destFilePath   = Path(stepData["dest_file"])
            findStr    = stepData["find"]
            replaceStr = stepData["replace"]
        except KeyError:
            _LOGGER.error("Missing required key found during elaboration of find and replace step. Halting.")
            return False
        
        if not sourceFilePath.exists():
            _LOGGER.error("Source file for find and replace not exists!")
            return False
        
        if destFilePath.exists():
            _LOGGER.info("Destination file already exists, will be overwritten.")
        
        _LOGGER.debug(f"Loading source file '{sourceFilePath}'...")
        sourceText = sourceFilePath.read_text()
        
        _LOGGER.debug(f"Replacing '{findStr}' with '{replaceStr}'.")
        destText   = sourceText.replace(findStr, replaceStr)

        _LOGGER.debug(f"Writing to dest file '{destFilePath}'...")
        destFilePath.write_text(destText)

        _LOGGER.info("Step passed.")
        return True

    def stepCopy(self, stepData) -> bool:

        _LOGGER.info("Starting step copy...")

        try:
            sourcePath = Path(stepData["source"])
            destPath   = Path(stepData["dest"])
        except KeyError:
            _LOGGER.error("Missing required key found during elaboration of find and copy step. Halting.")
            return False
        
        if not sourcePath.exists():
            _LOGGER.error("Source does not exist!")
            return False

        # Directories will be copied using copytree which creates whole structure automatically => caring only about files.
        if not destPath.exists() and not sourcePath.is_dir():
            _LOGGER.info("Dest path not exists, trying to create it...")
            # If destination ends with "/" it means it should be a directory, otherwise it is a file name and we will create dir structure only to the penultimate element.
            # We use stepData instead destPath, because pathlib does not preserve trailing slashes.
            try:
                if stepData["dest"].endswith("/"):
                    destPath.mkdir(exist_ok = True, parents = True)
                else:
                    destPath.parents[0].mkdir(exist_ok = True, parents = True)
            except FileExistsError:
                _LOGGER.error("Dest path contains an existing file, can't create required directory structure.")
                return False

        _LOGGER.debug(f"Will copy {sourcePath} to {destPath}")

        try:
            recursive = stepData["recursive"]
            if type(recursive) != bool:
                _LOGGER.error("'Recursive' parameter is not boolean. Halting.")
                return False
        except KeyError:
            recursive = False

        if sourcePath.is_dir() and not recursive:
            _LOGGER.error("Source is a directory but 'recursive' mode not enabled.")
            return False

        if sourcePath.is_file() and recursive:
            _LOGGER.warning("Recursive parameter specified but source is a file.")

        # Copying directory. We will create full path as necessary.
        if sourcePath.is_dir():
            shutil.copytree(str(sourcePath), str(destPath), dirs_exist_ok = True)
        elif sourcePath.is_file():
            shutil.copy2(str(sourcePath), str(destPath))
        else:
            _LOGGER.error("Source path is neither a file nor directory.")
            return False

        _LOGGER.info("Step passed.")
        return True

    stepParsers : dict = {
        "make_directory" : stepMakeDirectory,
        "run" : stepRun,
        "find_and_replace" : stepFindReplace,
        "copy" : stepCopy
    }

    # Check if the file version is compatible.
    def __checkVersion(self, metadata) -> bool:
        return "type" in metadata and metadata["type"] == "makepy recipe" and "version" in metadata and metadata["version"] == 0.1
    
    # Elaborate all steps in recipe.
    # Throws RecipeProcessingFailed exception if there is a syntax error in the recipe.
    def __elaborateSteps(self, steps) -> bool:
        for step in steps:
            try:
                stepName = list(step.keys())[0]
                # Merge step's parameters with current source from list (if specified).
                if not self.stepParsers[stepName](self, step[stepName]):
                    _LOGGER.info(f"Step '{stepName}' failed, returning false.")
                    return False
            except KeyError:
                _LOGGER.error(f"Unsupported step '{stepName}', halting.")
                raise RecipeProcessingFailed
        
        return True

    def __validateType(self, file : Path, fileType : str) -> bool:
        if fileType == "verilog":
            return file.suffix == ".v"
        elif fileType == "hex":
            return file.suffix == ".hex"
        else:
            return False

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
            self.comment = self.recipe["recipe"]["comment"]
        except KeyError:
            self.comment = "N/A"
        
        try:
            self.printLogs = self.recipe["recipe"]["print_logs"]
        except KeyError:
            self.printLogs = "error"
        
        if self.customSourcePath:
            if self.customSourcePath.is_dir():
                self.sources = [file for file in self.customSourcePath.iterdir() if file.is_file()]
            elif self.customSourcePath.is_file():
                self.sources = [self.customSourcePath]
            else:
                _LOGGER.error("Custom source path not file nor directory.")
                return False
        else:
            try:
                for source in self.recipe["recipe"]["sources"]:
                    srcPath = Path(source["path"])
                    if srcPath.is_dir():
                        self.sources = [file for file in srcPath.iterdir() if file.is_file() and self.__validateType(file, source["type"])]
                    else:
                        self.sources = [srcPath]
                _LOGGER.debug(f"Loaded sources: {self.sources}")
            except KeyError:
                self.sources = [ None ]
                _LOGGER.debug(f"No sources specified, inserted dummy one: {self.sources}")

        # Running the recipe.
        print(f"📜 Running recipe '{self.name}' ({self.fileName})...")
        _LOGGER.debug(f"Recipe comment: {self.comment}")

        for source in self.sources:


            if source != None:
                
                # Replacing source file placeholders with real paths.
                replacedStepsString : str = yaml.safe_dump(self.steps)
                replacedStepsString       = re.sub(self.PLACEHOLDER_CURRENT_SOURCE, rf"{str(source.resolve())}",  replacedStepsString)
                replacedStepsString       = re.sub(self.PLACEHOLDER_CURRENT_SOURCE_STEM, rf"{str(source.stem)}", replacedStepsString)
                
                replacedSteps : dict      = yaml.safe_load(replacedStepsString)
                print(f"📜📄 Running steps for source file '{source}'")
            else:
                replacedSteps = self.steps

            if not self.__elaborateSteps(replacedSteps):
                if source != None:
                    print(f"📜❌ File '{source}' failed")
                else:
                    print("📜❌ Failed!")
                return False
            
            if source != None:
                print(f"📜✅ File '{source}' passed")
            
        print(f"✅ Recipe '{self.name}' passed successfully.")
        return True
        

