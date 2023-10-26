import argparse
import subprocess
import sys
import pathlib
import elftohex

LINKER_SCRIPT_PATH = pathlib.Path(__file__).resolve().parent.parent.joinpath("firmware/mem.ld")

def compile(srcPath: pathlib.Path, destPath: pathlib.Path, memArch: str):
    # Get all .S files
    asmFilesPaths: list[pathlib.Path] = []
    if srcPath.suffix == ".S":  # If only one file was passed
        asmFilesPaths.append(srcPath)
    else:
        asmFilesPaths = list(srcPath.glob("*.S"))

    for asmPath in asmFilesPaths:
        # Compile source file
        elfPath = pathlib.Path(asmPath.stem)
        ret = subprocess.run(
            [
                "riscv64-unknown-elf-gcc",
                "-Wall",
                "-pedantic",
                "-static",
                "-fvisibility=hidden",
                "-nostartfiles",
                "-march=rv32i",
                "-mabi=ilp32",
                "-std=c11", "-O2",
                "-nostdlib",
                "-T", str(LINKER_SCRIPT_PATH),
                str(asmPath),
                "-o", elfPath.name
            ],
            stdout = sys.stdout,
            stderr = subprocess.STDOUT
        )

        if ret.returncode != 0:
            raise SystemExit("Compilation error.")
        
        # Convert the elf to .hex
        elftohex.convert(elfPath, destPath, memArch == "harvard")
        # Remove the elf
        elfPath.unlink()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog = "asmtohex.py",
        description = "Compiles RISC-V assembly source code and converts the elf to .hex."
    )

    parser.add_argument(
        "-s", "--src-path",
        help = "Specify a path to .asm file or the source directory with .asm files.",
        action = "store",
        type = pathlib.Path,
        required = True
    )

    parser.add_argument(
        "-d", "--dest-dir",
        help = "Specify a destination directory for the .hex files.",
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

    compile(args.src_path, args.dest_dir, args.mem_arch)