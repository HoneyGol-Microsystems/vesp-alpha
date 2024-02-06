#ifndef __VESP_UART_H
#define __VESP_UART_H

#include <stdint.h>

/* GPIO addresses */
extern volatile uint8_t * const UART_TX_DATA_PTR;
extern volatile uint8_t * const UART_RX_DATA_PTR;
extern volatile uint8_t * const UART_CONFIG_A_PTR;
extern volatile uint8_t * const UART_CONFIG_B_PTR;
extern volatile uint8_t * const UART_STATUS_A_PTR;
extern volatile uint8_t * const UART_IF_REG_PTR;

/* GPIO address placeholders */
#define UART_TX_DATA  *UART_TX_DATA_PTR
#define UART_RX_DATA  *UART_RX_DATA_PTR
#define UART_CONFIG_A *UART_CONFIG_A_PTR
#define UART_CONFIG_B *UART_CONFIG_B_PTR
#define UART_STATUS_A *UART_STATUS_A_PTR
#define UART_IF_REG   *UART_IF_REG_PTR

#endif // __VESP_UART_H