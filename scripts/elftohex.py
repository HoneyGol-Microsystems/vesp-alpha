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

def convert(srcPath: pathlib.Path, destPath: pathlib.Path):
    # Get all elf files with ET_EXEC format (path is raw string)
    elfFilesRawPaths = subprocess.check_output(
        [
            "scanelf",
            "-E", "ET_EXEC",
            "-BF", "%F", str(srcPath)
        ],
        stderr = subprocess.STDOUT
    ).decode("ascii").rsplit()

    # Convert raw string paths to pathlib.Path
    elfFilesPaths = [pathlib.Path(rawElf) for rawElf in elfFilesRawPaths]

    for fPath in elfFilesPaths:
        # Convert file from elf format to .bin
        fTmpBinPath = pathlib.Path("tmp.bin")
        ret = subprocess.run(
            [
                "riscv64-unknown-elf-objcopy",
                "-Obinary",
                str(fPath),
                str(fTmpBinPath)
            ],
            stdout = sys.stdout,
            stderr = subprocess.STDOUT
        )

        if ret.returncode != 0:
            print(f"Warning: '{fPath.name}' can't be converted (possibly malformed?).")
            continue

        # Convert elf file to .hex format
        bin2hex(32, fTmpBinPath, destPath.joinpath(fPath.name).with_suffix(".hex"))

    # Delete temporary .bin file
    fTmpBinPath.unlink()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog = "elftohex.py",
        description = "Converts elf files to .hex format."
    )

    parser.add_argument(
        "-s", "--src-path",
        help = "Specify the source path to the elf files.",
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

    args = parser.parse_args()

    convert(args.src_path, args.dest_path)