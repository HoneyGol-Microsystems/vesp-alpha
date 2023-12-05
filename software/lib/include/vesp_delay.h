#ifndef __VESP_DELAY_H
#define __VESP_DELAY_H

/* frequency is 50 MHz, period 20ns */
#define CPU_TICK_MS 50000
#define CPU_TICK_US 50

void delay_ms ( uint32_t ms );
void delay_us ( uint32_t us );

#endif // __VESP_DELAY_H