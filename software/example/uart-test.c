#include <vesp.h>

int main ( void )
{
    UART_CONFIG_A = 0x14; // 0001 0100
    UART_CONFIG_B = 0x60; // 0110 0000
    UART_TX_DATA = 0xAB;
    UART_TX_DATA = 0xCD;
    UART_TX_DATA = 0xEF;

    while ( 1 );

    return 0;
}