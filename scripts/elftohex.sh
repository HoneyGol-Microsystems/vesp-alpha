#!/bin/bash

# check if all necessary arguments were passed
if [[ $# -ne 2 ]]; then
    echo "usage: $0 PATH_TO_ELF_FILES DEST_FOR_HEX_FILES"
    exit 1
fi

elfSrcPath=$1
hexDestPath=$2
elfFiles=$(scanelf -E ET_EXEC -BF %F "$elfSrcPath") # get all elf files with ET_EXEC format

for f in $elfFiles; do
    fNoExt=$(basename "$f") # get file name without path
    elf2hex --bit-width 32 --input "$f" --output "$hexDestPath/$fNoExt.hex" # convert elf file to .hex format
done