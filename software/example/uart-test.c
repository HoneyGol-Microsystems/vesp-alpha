#include <vesp.h>

int main ( void )
{
    // configuration
    UART_CONFIG_A = 0xB6; // 1011 0110
    UART_CONFIG_B = 0x34; // 0011 0100

    while ( 1 )
    {
        if ( ! ( UART_STATUS_A & 0x40 ) )
        {
            UART_TX_DATA = UART_RX_DATA;
        }
    }
    delay_us ( 10 );

    return 0;
}