#include <vesp.h>

int main ( void )
{
    // configuration
    UART_CONFIG_A = 0xB4; // 1011 0100
    UART_CONFIG_B = 0x30; // 0011 0000

    while ( 1 )
    {
        UART_TX_DATA = 0x41;
        delay_ms ( 1000 );
    }

    return 0;
}