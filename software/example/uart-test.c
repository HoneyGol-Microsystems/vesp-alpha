#include <vesp.h>

int main ( void )
{
    // configuration
    UART_CONFIG_A = 0xB4; // 1011 0100
    UART_CONFIG_B = 0x60; // 1011 0000

    // tx data
    UART_TX_DATA = 0xAB;
    UART_TX_DATA = 0xCD;
    UART_TX_DATA = 0xEF;

    while ( 1 );

    return 0;
}