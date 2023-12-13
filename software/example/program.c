#include <vesp.h>

int main ( void )
{
    GPIODIR_A &= 0xFF;
    GPIODIR_B &= 0xFF;

    uint8_t a = GPIORD_A;
    uint8_t b = GPIORD_B;

    __asm ( "nop" );
    __asm ( "nop" );

    GPIODIR_A |= 0x00;
    GPIODIR_B |= 0x00;

    // write some data to pins
    GPIOWR_A |= a + 1;
    GPIOWR_B |= b + 1;

    __asm ( ".word 0x1" );

    return 0;
}