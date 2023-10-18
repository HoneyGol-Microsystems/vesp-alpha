/* set the output target format and architecture */
OUTPUT_FORMAT("elf32-littleriscv", "elf32-littleriscv", "elf32-littleriscv")
OUTPUT_ARCH(riscv)

/* define entry point of the first piece of code to be executed */
ENTRY(_start)

/* define the memory sections */
MEMORY
{
    /* section 'CODE' can be read and executed, starts at address ORIGIN and is LENGTH bytes long */
    CODE(rx): ORIGIN = 0x00000000, LENGTH = 2K

    /* section 'DATA' can be read, written and executed, starts at address ORIGIN and is LENGTH bytes long */
    DATA(rwx): ORIGIN = 0x00000000, LENGTH = 2K
}

/* define the placement of the sections */
SECTIONS
{
    .text :
    {
        *(.startup) /* put here the .startup section of all of the input files (there's only one in startup.S) */
        *(.text) /* put here the .text section of all of the input files */
    } > CODE /* VMA (virtual memory address) and LMA (load memory address) are the same */

    .data :
    {
        *(.data) /* put here the .data section of all of the input files */
    } > DATA AT> CODE /* VMA is the ORIGIN address of DATA, but LMA is a address inside CODE (after all it's segments) */
}