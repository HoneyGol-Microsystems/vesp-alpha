.global _start
_start:
    # li x1, 0
    lw x1, 0(x0)
L:
    addi x1, x1, 1
    beq x0, x0, L

.section .data
some_data:
    .word 0x0
    .word 0x1
    .word 0x2
    .word 0x3
    .word 0x4
    .word 0x5