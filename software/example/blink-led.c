#include <vesp.h>

int main ( void )
{
    GPIODIR_A = 0x00;
    GPIODIR_B = 0x00;

    while ( 1 )
    {
        delay_ms ( 1000 );
        GPIOWR_A = ~GPIOWR_A;
        GPIOWR_B = ~GPIOWR_B;
    }

    return 0;
}