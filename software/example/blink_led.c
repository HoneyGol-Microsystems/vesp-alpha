#include <vesp.h>

int main ( void )
{
    GPIODIR_A = 0xFF;
    GPIODIR_B = 0xFF;

    while ( 1 )
    {
        delay_ms ( 1000 );
        GPIOWR_A = ~GPIOWR_A;
        GPIOWR_B = ~GPIOWR_B;
    }

    return 0;
}