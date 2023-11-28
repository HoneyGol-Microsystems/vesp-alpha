#include "vesp.h"

void delay_ms ( uint32_t ms )
{
    for ( uint32_t i = 0; i < ms * CPU_TICK_MS; i++ )
        __asm ( "nop" );
}

void delay_us ( uint32_t us )
{
    for ( uint32_t i = 0; i < us * CPU_TICK_US; i++ )
        __asm ( "nop" );
}