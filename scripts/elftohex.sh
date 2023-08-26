#!/bin/bash

if [[ $# -ne 2 ]]; then
    echo "usage: $0 PATH_TO_ELF_FILES DEST_FOR_HEX_FILES"
    exit 1
fi

elfSrcPath=$1
hexDestPath=$2
elfFiles=$(scanelf -E ET_EXEC -BF %F "$elfSrcPath")

for f in $elfFiles; do
    fName=$(basename "$f")
    elf2hex --bit-width 32 --input "$f" --output "$hexDestPath/$fName.hex"
done