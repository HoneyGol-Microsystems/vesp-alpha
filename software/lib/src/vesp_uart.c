#include "vesp_uart.h"

volatile uint8_t * const UART_TX_DATA_PTR  = (volatile uint8_t *) 0xF0000010;
volatile uint8_t * const UART_RX_DATA_PTR  = (volatile uint8_t *) 0xF0000011;
volatile uint8_t * const UART_CONFIG_A_PTR = (volatile uint8_t *) 0xF0000012;
volatile uint8_t * const UART_CONFIG_B_PTR = (volatile uint8_t *) 0xF0000013;
volatile uint8_t * const UART_STATUS_A_PTR = (volatile uint8_t *) 0xF0000014;
volatile uint8_t * const UART_IF_REG_PTR   = (volatile uint8_t *) 0xF0000015;