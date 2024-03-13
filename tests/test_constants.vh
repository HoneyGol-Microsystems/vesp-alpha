`ifndef __FILE_TESTCONSTANTS_V
`define __FILE_TESTCONSTANTS_V

/* assertion values */
`define ASSERT_FAIL "ASSERT_FAIL"
`define ASSERT_SUCCESS "ASSERT_SUCCESS"
`define ASSERT_TIMEOUT "ASSERT_TIMEOUT"
`define ASSERT_DEBUG_STOP "ASSERT_DEBUG_STOP"

// test

// assertion macro
`define ASSERT(CONDITION, ERROR_MSG) if (!(CONDITION)) begin $display(ERROR_MSG); $display(`ASSERT_FAIL); $finish; end

`endif //__FILE_TESTCONSTANTS_V