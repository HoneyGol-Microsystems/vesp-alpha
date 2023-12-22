# Notes about testing
## Official test suite - handling success/failure
*This section is mainly meant as a documentation of the official tests' inner workings for our future reference, because there is none in the official repository.*

Official test suite always at the end of the test executes `ecall` instruction. This causes an exception, so the execution is redirected to the `trap_vector`, from where it branches to the `write_tohost`. In this routine, test number and result is written to a special memory-mapped register `tohost` (used by the Spike).

This gets interistingly more complicated when the exceptions themselves are tested. `ebreak` test causes a jump to `trap_vector` but from there it jumps to `mtvec_handler` (for M-mode tests). Every test may define its own `mtvec_handler`. For example, the `ebreak` test checks for the exception code in the `mcause` register in this routine and then the `ecall` is executed, again causing a redirection to the `trap_vector` and `write_tohost`.

To sum up, here are visualizations:

Normal program flow:
```
_start => reset_vector => (the test routines) => trap_vector => write_tohost
```

This is a flow of tests which test exceptions:
```
_start => reset_vector => (the test routines) => trap_vector => mtvec_handler => trap_vector => write_tohost
```

### Our modifications
Because for now there are no memory-mapped peripherals in our implementation, we can't use the `tohost` mechanism to check the status of the tests. To overcome this limitation, we detect success and failure using officially unused opcodes:
- 0x0 for failure,
- 0x1 for success.

We effectively disable the `write_tohost` routine altogether, because it is only called in the `trap_vector` when the exception is caused by the `ecall`. 

Using special opcodes instead of the `tohost` mechanism is fine for all other tests but not for the test where the `ecall` instruction itself is tested (rv32mi-p-scall). To detect a success in this test we abuse the `write_tohost` routine to signalize the result using the aforementioned 0x1 opcode. This can be done, because as it was mentioned, `write_tohost` is not used anywhere else in our modification of the test result handling.

## Creating testbenches
Testbenches must not contain Verilog's `$dumpfile` and `$dumpvars`, otherwise no VCD will be created by Vivado!