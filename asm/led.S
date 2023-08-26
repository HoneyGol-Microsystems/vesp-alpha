.global _start
_start:
    li x1, 0
L:
    addi x1, x1, 1
    beq x0, x0, L