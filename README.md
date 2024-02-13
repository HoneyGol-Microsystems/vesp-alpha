# <img src="img/vesp_logo_export.svg" alt="VESP logo"  height="150"/>

*VESP: "VEřejný Studentský Procesor" (public students' processor)*

The VESP is a RV32I processor with M-mode support and integrated peripherals.

The VESP is a result of student initiative to create a RISC-V compatible processor that will serve as a learning tool for students interested in modern computer architectures.

## Links
This README contains basic information about project building. More information is covered in the documentation in the `docs` folder:

### Development and testing
- [Generic development guides](docs/development.md)
- [Compiling and deploying software](docs/software.md)
- [Notes about testing](docs/testing.md)
- [Creating `make.py` recipes](docs/recipes.md)

### Memory subsystem and peripherals
- [Memory subsystem](docs/memory_maps.md)
- [GPIO](docs/gpio.md)
- [System uptime timer](docs/millis_timer.md)

*UART and its documentation is available in the `uart` branch. More adjustments to the peripheral will be made, so it is not merged yet.*

## The main script (`make.py`)
This script is used mainly for launching tests and interfacing with Vivado design suite.

### Setup
To use the script, install all required dependencies and add them to path.

1. RISC-V toolchain
2. Python version >=3.10 (older versions not officially supported)
3. Vivado Design Suite
4. iverilog (optinal for legacy tests support)

### Usage

Launch this script directly:
```sh
./make.py
```

or using Python
```sh
python3 make.py
```

### Testing
All tests can be launched using
```sh
./make.py test
```
This command will run all tests (using all the *recipes* in the `recipes` directory) on current version of the CPU located in the repository.

Test routines are defined using a *recipe*, which is a custom YAML-based file describing all steps that should be performed and how are test results interpreted (how to recognize success or failure). A tutorial on creating a recipe is located in [docs/recipes.md](docs/recipes.md). 

To run specific recipe, use the `--recipe` switch. You can also pass custom sources to be used with the recipe instead default ones (which are specified in the recipe) using `--sources`. For example, if you want to run a single official RISC-V test, use the `rvtest.yaml` recipe and specify your desired hex file like this:
```sh
./make.py test --recipe recipes/rvtest.yaml --sources tests/riscv-tests-hex/rv32ui-p-add.hex
```

Of course, only files compatible with the selected recipe will work. Trying to run hex files using Hardware Test (hwtest.yaml) recipe will obviously not work. See list below for currently available recipes:
- `rvtest.yaml`: This recipe runs pre-compiled official RISC-V tests in simulation using Vivado.
- `hwtest.yaml`: This recipe runs custom Verilog-based tests mainly used to test separate components.

### Creating a Vivado project
To simply create a Vivado project in the default directory (`build/vivado`), use: 

```sh
./make.py vivado
```

To specify a custom directory path, use `--path`. If any project already exists in the default (or specified) path, it will be opened. Otherwise, a new one will be created. You can force script to overwrite an existing project using `--clean`.

By default, a project will be created and Vivado will stay in Tcl mode. To launch the GUI, use the `--gui` switch:
```sh
./make.py vivado --gui
```

### Cleaning
You can remove all generated content using:
```sh
./make.py clean
```

## License
All files in this repository, if not stated otherwise, are licensed under the GNU GENERAL PUBLIC LICENSE, version 3. The full license text is available in the `LICENSE` file.

© 2024 Ondrej Golasowski, Jan Medek