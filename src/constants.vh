`ifndef __FILE_CONSTANTS_V
`define __FILE_CONSTANTS_V

/* RISC-V ISA constants */
`define XLEN 32       // width of an integer register (in bits)
`define IALIGN 32     // instruction-address alignment constraint (in bits)
`define ILEN 1*`IALIGN // length of an instruction (in bits) - it's always a multiple of IALIGN

/* other constants */
`define REG_CNT 32 // number of registers in a register file
`define INSTR_MEM_WORD_CNT 512 // number of words in instruction memory
`define DATA_MEM_WORD_CNT 512 // number of words in data memory
`define RAM_WORD_CNT `INSTR_MEM_WORD_CNT + `DATA_MEM_WORD_CNT // number of words in RAM

/* assertion values */
`define ASSERT_FAIL "ASSERT_FAIL"
`define ASSERT_SUCCESS "ASSERT_SUCCESS"
`define ASSERT_TIMEOUT "ASSERT_TIMEOUT"
`define ASSERT_DEBUG_STOP "ASSERT_DEBUG_STOP"

`endif // __FILE_CONSTANTS_V