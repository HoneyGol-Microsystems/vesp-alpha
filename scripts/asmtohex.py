import argparse
import subprocess
import sys
import pathlib
import elftohex

LINKER_SCRIPT_PATH = pathlib.Path(__file__).resolve().parent.parent.joinpath("sw/mem.ld")

def compile(srcPath: pathlib.Path, destPath: pathlib.Path, memArch: str):
    # Check what memory architecture was specified
    memHarvard = (memArch == "harvard")
    # Get all .S files
    asmFilesPaths: list[pathlib.Path] = []
    if srcPath.suffix == ".S":  # If only one file was passed
        asmFilesPaths.append(srcPath)
    else:
        asmFilesPaths = list(srcPath.glob("*.S"))

    for fPath in asmFilesPaths:
        # Compile source file
        ret = subprocess.run(
            [
                "riscv64-unknown-elf-gcc",
                "-Wall",
                "-pedantic",
                "-static",
                "-fvisibility=hidden",
                "-nostdlib",
                "-nostartfiles",
                "-march=rv32i",
                "-mabi=ilp32",
                "-T", str(LINKER_SCRIPT_PATH),
                str(fPath),
                "-o", fPath.stem
            ],
            stdout = sys.stdout,
            stderr = subprocess.STDOUT
        )

        # Create list of elf files to remove at the end
        toRemove: list[pathlib.Path] = []
        toRemove.append(pathlib.Path(fPath.stem))  # Add compiled elf

        # Create dest directory if it doesn't exist yet
        destPath.mkdir(parents=True, exist_ok=True)

        # Separate .text and .data according to the specified memory architecture
        if memHarvard:
            # Create paths for the .text and .data elf files
            dataSectionElfPath = pathlib.Path(fPath.stem + "_data")
            textSectionElfPath = pathlib.Path(fPath.stem + "_text")
            # Remove them at the end
            toRemove.append(dataSectionElfPath)
            toRemove.append(textSectionElfPath)

            # Separate .data
            subprocess.run(
                [
                    "riscv64-unknown-elf-objcopy",
                    "-O", "elf32-littleriscv",
                    "--only-section=.data",
                    fPath.stem,
                    str(dataSectionElfPath)
                ],
                stdout = sys.stdout,
                stderr = subprocess.STDOUT
            )
            # Separate .text
            subprocess.run(
                [
                    "riscv64-unknown-elf-objcopy",
                    "-O", "elf32-littleriscv",
                    "--only-section=.text",
                    fPath.stem,
                    str(textSectionElfPath)
                ],
                stdout = sys.stdout,
                stderr = subprocess.STDOUT
            )

            # Create .hex files from the elf
            elftohex.convert(dataSectionElfPath, destPath)
            elftohex.convert(textSectionElfPath, destPath)
        else:
            # Create .hex files from the elf
            elftohex.convert(fPath.stem, destPath)
        
        # Remove the elf files
        for fPath in toRemove:
            fPath.unlink()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog = "asmtohex.py",
        description = "Compiles RISC-V assembly source code and converts the elf to .hex."
    )

    parser.add_argument(
        "-s", "--src-path",
        help = "Specify the source path to the assembly source code files.",
        action = "store",
        type = pathlib.Path,
        required = True
    )

    parser.add_argument(
        "-d", "--dest-path",
        help = "Specify the destination path for the created .hex files.",
        action = "store",
        type = pathlib.Path,
        required = True
    )

    parser.add_argument(
        "-m", "--mem-arch",
        help = "Specify memory architecture.",
        action = "store",
        choices = ["harvard", "von-neumann"],
        required = True
    )

    args = parser.parse_args()

    compile(args.src_path, args.dest_path, args.mem_arch)