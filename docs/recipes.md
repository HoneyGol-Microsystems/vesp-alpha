# Creating custom recipes
A *recipe* is a custom YAML-based file which describes how to run a test procedure and how to interpret results. Recipes are processed using `recipeProcessor.py` script.

## Structure
### Basic structure
Every recipe begins with a header:
```yaml
metadata:
  type: "makepy recipe"
  version: 0.1
```
For now, the version is always the same.

Then, a recipe description follows, which consists of four keys:
```yaml
recipe:
  name: "My strict test"                # (mandatory) A name for the test.
  comment: "This test is very strict."  # A comment for the test.
  sources:                              # Default source list specification.
    - path: "example/path/to/file.hex"
  steps:                                # (mandatory) Array of test steps. See "steps" section.
    - step1: ...
    - step2: ...
```

A test routine always perform all steps described in `steps` on every file specified in `sources`. If no sources are specified, steps will be perfomed only once.

If you want to specify a default source files to be used in test routine, you can specify a files or even directories in the `sources` key. To specify a file, simply pass a path to the file. To specify a directory, pass a path and a type of files to search in the directory using `type`.

Example:
```yaml
sources:
  - path: "path/to/my/file.dat"     # First file.
  - path: "path/to/my/file2.dat"    # Second file.
  - path: "path/to/directory"       # A directory from which only files of a type "hex" will be used.
    type: "hex"                     
```


For now, specifying a type is mandatory. Available types are:
- `hex`: will return only files with ".hex" suffix,
- `verilog`: will return only files with ".v" suffix.

### Steps
Steps are descriptions of how to run a test. There are several types of steps currently supported.

Each string in each type of steps can be replaced with a supported placeholder. For now, there is only one placeholder: `mpysource`. This placeholder contains a path to file from a source list which is currently processed. If there is no source list, this placeholder is empty and should not be used.

#### `make_directory`
This step will create a directory at a given path.
Example:
```yaml
- make_directory:
    name: "path/to/directory"
```

#### `find_and_replace`
This step will find all occurences of a given string in a source file, replaces them with another given string and outputs result to a specified destination file.
Example:
```yaml
- find_and_replace:
    source_file: "my/source/file.v"
    dest_file: "build/tmp.v"
    find: "PUT_HERE"
    replace: "\"build/tmp.hex\""
```

#### `run`
This step will run an executable with (optionally) specified parameters and optionally checks the return code and whether the output contains or does not contain specified strings. The step can also kill the executable if a specific string defined using `kill_on` key is found.
Example:
```yaml
- run:
    executable: "iverilog"
    params:
        - "build/tmp.v"
        - "-obuild/tmp.out"
        - "-Irtl/components"
    assert:
        return_code: 0
        output:
            not_contains:
                - "ERROR"
            contains:
                - "SUCCESS"
    kill_on: "please kill me"
```

#### `copy`
This step will copy file (or a directory structure) from source to destination. For directories, a `recursive: true` must be specified.
Example:
```yaml
- copy:
    source: mpysource       # This is an example of using a placeholder instead of an absolute path.
    dest: "build/tmp.hex"
    recursive: false
```
## Examples
Examples of complete recipes can be found in the `recipes` folder.