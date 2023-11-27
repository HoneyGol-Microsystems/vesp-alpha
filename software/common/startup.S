.global _start
.global main # define symbol for main function
.section .startup # linker script knows to put this section first
_start:
    li sp, 0xEFFFFFFF # init to stack start
    j main