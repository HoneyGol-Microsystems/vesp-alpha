import logging
import yaml
import subprocess
import shutil
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
    PLACEHOLDER_CURRENT_SOURCE = "mpysource"

    def __init__(self, recipePath):
        _LOGGER.debug(f"Loading recipe: {recipePath}")
        self.fileName = str(recipePath)
        with recipePath.open() as file:
            try:
                self.recipe = yaml.safe_load(file)
            except yaml.parser.ParserError as e:
                _LOGGER.error("Failed to parse YAML structure of the recipe. Check for YAML format related errors - indentation etc. Check the log below, it should tell you which lines caused the error.")
                raise e # Reraise to provide more information.

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

        try:
            execName             = stepData["executable"]
            globalSource : Path  = stepData["global_source"]

        except KeyError:
            _LOGGER.error("Missing required key found during elaboration of run step. Halting.")
            return False
        
        params = []
        try:
            # Check if there is a source placeholder in params and replace accordingly.
            for par in stepData["params"]:
                if par == self.PLACEHOLDER_CURRENT_SOURCE:
                    if globalSource == None:
                        _LOGGER.warning(f"Using placeholder {self.PLACEHOLDER_CURRENT_SOURCE} even when no global sources are specified. Parameter ignored.")
                    else:
                        params.append(str(globalSource.resolve()))
                else:
                    params.append(par)
        except KeyError:
            pass

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

        pipes = subprocess.Popen(
            execWithParams,
            stdout = subprocess.PIPE,
            stderr = subprocess.PIPE
        )

        stdout, stderr = pipes.communicate()
        stdout = stdout.decode('utf-8')
        stderr = stderr.decode('utf-8')

        if stdout: _LOGGER.info(f"STDOUT: {stdout}")
        if stderr: _LOGGER.info(f"STDERR: {stderr}")

        # There needs to be != None, because if the return code is 0, simple 'if assertReturnCode' will obviously evaluate to false.
        if assertReturnCode != None:
            if pipes.returncode != assertReturnCode:
                _LOGGER.info(f"Assertion for return code failed. Expected {assertReturnCode} got {pipes.returncode}")
                return False
            
        if type(assertOutputCont) == list:
            for outCont in assertOutputCont:
                if not outCont in (stdout + stderr):
                    _LOGGER.info(f"Assertion failed for program output condition: '{outCont}' not found in output.")
                    return False
        
        if type(assertOutputNotCont) == list:
            for outCont in assertOutputNotCont:
                if outCont in (stdout + stderr):
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
    def __elaborateSteps(self, currentSource) -> bool:
        for step in self.steps:
            try:
                stepName = list(step.keys())[0]
                # Merge step's parameters with current source from list (if specified).
                stepParams = step[stepName] | {"global_source" : currentSource}
                if not self.stepParsers[stepName](self, stepParams):
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
        
        print(f"📜 Running recipe '{self.name}' ({self.fileName})...")
        _LOGGER.debug(f"Recipe comment: {self.comment}")

        for source in self.sources:

            if source != None:
                print(f"📜📄 Running steps for source file '{source}'")

            if not self.__elaborateSteps(source):
                if source != None:
                    print(f"📜❌ File '{source}' failed")
                else:
                    print("📜❌ Failed!")
                return False
            
            if source != None:
                print(f"📜✅ File '{source}' passed")
            
        print(f"✅ Recipe '{self.name}' passed successfully.")
        return True
        

