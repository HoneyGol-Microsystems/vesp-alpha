import argparse
import subprocess
import sys
import pathlib
import itertools

# Copied from https://docs.python.org/3/library/itertools.html
def grouper(iterable, n, fillvalue=None):
    """Collect data into fixed-length chunks or blocks"""
    # grouper('ABCDEFG', 3, 'x') --> ABC DEF Gxx
    args = [iter(iterable)] * n
    return itertools.zip_longest(*args, fillvalue=fillvalue)

# Inspired by https://github.com/sifive/elf2hex/blob/master/freedom-bin2hex.py
def bin2hex(bitWidth: int, inPath: pathlib.Path, outPath: pathlib.Path):
    byteWidth = bitWidth // 8

    with inPath.open("rb") as infile, outPath.open("w") as outfile:
        for row in grouper(infile.read(), byteWidth, fillvalue=0):
            # Reverse because in Verilog most-significant bit of vectors is first.
            hex_row = ''.join('{:02x}'.format(b) for b in reversed(row))
            outfile.write(hex_row + '\n')

def convert(srcPath: pathlib.Path, destPath: pathlib.Path, splitMem: bool):
    # Get all elf files with ET_EXEC format (path is raw string)
    elfFilesRawPaths = subprocess.check_output(
        [
            "scanelf",
            "-E", "ET_EXEC",
            "-BF", "%F", str(srcPath)
        ],
        stderr = subprocess.STDOUT
    ).decode("ascii").rsplit()

    if not elfFilesRawPaths:
        raise SystemExit("No ELF files found in '{srcPath}'.")

    # Convert raw string paths to pathlib.Path
    elfFilesPaths = [pathlib.Path(rawElf) for rawElf in elfFilesRawPaths]

    # Create list of elf files to remove at the end
    toRemove: list[pathlib.Path] = []
    
    for elfPath in elfFilesPaths:
        if splitMem:
            # Create paths for the .text and .data elf files
            dataSectionElfPath = pathlib.Path(elfPath.stem + "_data")
            textSectionElfPath = pathlib.Path(elfPath.stem + "_text")
            # Remove them at the end
            toRemove.append(dataSectionElfPath)
            toRemove.append(textSectionElfPath)

            # Separate .data
            subprocess.run(
                [
                    "riscv64-unknown-elf-objcopy",
                    "-O", "elf32-littleriscv",
                    "--only-section=.data",
                    elfPath,
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
                    elfPath,
                    str(textSectionElfPath)
                ],
                stdout = sys.stdout,
                stderr = subprocess.STDOUT
            )

            # Create .hex files from the elf
            convertElfToHex(dataSectionElfPath, destPath)
            convertElfToHex(textSectionElfPath, destPath)
        else:
            # Create .hex files from the elf
            convertElfToHex(elfPath, destPath)

    # Remove the elf files
    for path in toRemove:
        path.unlink()

def convertElfToHex(elfPath: pathlib.Path, destPath: pathlib.Path):
    # Convert file from elf format to .bin
    tmpBinPath = pathlib.Path("tmp.bin")
    ret = subprocess.run(
        [
            "riscv64-unknown-elf-objcopy",
            "-Obinary",
            str(elfPath),
            str(tmpBinPath)
        ],
        stdout = sys.stdout,
        stderr = subprocess.STDOUT
    )

    if ret.returncode != 0:
        print(f"Warning: '{elfPath.name}' can't be converted (possibly malformed?).")
        # Delete temporary .bin file
        tmpBinPath.unlink()
        return

    # Create destination directory if it doesn't exist yet
    destPath.mkdir(parents=True, exist_ok=True)

    # Convert temporary .bin to .hex format
    bin2hex(32, tmpBinPath, destPath.joinpath(elfPath.name).with_suffix(".mem"))

    # Delete temporary .bin file
    tmpBinPath.unlink()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog = "elftohex.py",
        description = "Converts ELF files to .hex format."
    )

    parser.add_argument(
        "-s", "--src-path",
        help = "Specify a path to an ELF file or the source directory with ELF files.",
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

    convert(args.src_path, args.dest_dir, args.mem_arch == "harvard")