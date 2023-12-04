import os
import pathlib

with pathlib.Path("software/firmware_data.hex").open("w") as f:
    for i in range(1024):
        f.write(os.urandom(4).hex() + "\n")