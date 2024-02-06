#include "vesp_delay.h"

// The tick count is divided by 3, because the for loop is compiled into 3 instructions.

void delay_ms ( uint32_t ms )
{
    for ( uint32_t i = 0; i < ms * (CPU_TICK_MS / 3); i++ )
        __asm ( "nop" );
}

void delay_us ( uint32_t us )
{
    for ( uint32_t i = 0; i < us * (CPU_TICK_US / 3); i++ )
        __asm ( "nop" );
}