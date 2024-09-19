#!/bin/bash

# Set the source file and output file
SOURCE="strings.asm"
OUTPUT="strings"

# Check if NASM is installed
if ! command -v nasm &> /dev/null
then
    echo "nasm could not be found, please install it using your package manager (e.g., sudo apt install nasm)"
    exit 1
fi

# Check if ld is installed
if ! command -v ld &> /dev/null
then
    echo "ld could not be found, please install it using your package manager (e.g., sudo apt install binutils)"
    exit 1
fi

# Assemble the assembly code using NASM
echo "Assembling $SOURCE..."
nasm -f elf32 -o ${OUTPUT}.o $SOURCE
if [ $? -ne 0 ]; then
    echo "Assembly failed."
    exit 1
fi

# Link the object file to create an executable
echo "Linking $OUTPUT..."
ld -m elf_i386 -o $OUTPUT ${OUTPUT}.o
if [ $? -ne 0 ]; then
    echo "Linking failed."
    exit 1
fi

# Clean up the object file
rm ${OUTPUT}.o

# Make the output file executable
chmod +x $OUTPUT

echo "Build completed successfully. You can run the program using ./$OUTPUT <filename>"
echo "Example ./$OUTPUT $OUTPUT"
./$OUTPUT $OUTPUT
