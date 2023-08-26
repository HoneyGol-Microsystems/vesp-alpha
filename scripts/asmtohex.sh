#!/bin/bash

# check if all necessary arguments were passed
if [[ $# -ne 2 ]]; then
    echo "usage: $0 PATH_TO_ASM_FILES DEST_FOR_HEX_FILES"
    exit 1
fi

asmSrcPath=$1
hexDestPath=$2
asmFiles=$(ls $asmSrcPath*.S)
scriptPath=$(dirname $0) # location of this script

for f in $asmFiles; do
   fNoExt=$(basename "$f" .S) # get file name without path and it's extension
   riscv64-unknown-elf-gcc -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -march=rv32i -mabi=ilp32 "$f" -o "$fNoExt" # compile source files

    mkdir -p "$hexDestPath"
    "$scriptPath/elftohex.sh" . "$hexDestPath" # run script to convert elf file to .hex format
    rm $fNoExt # remove elf file
done