.global _start
.global main
.section .startup
_start:
    li sp, 0xEFFFFFFF # init to stack start
    j main