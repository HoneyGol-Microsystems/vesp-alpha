#include "vesp_timers.h"

volatile const uint32_t * const TMR_MILLIS_VAL_PTR = (volatile uint32_t *) 0xF0000020;

uint32_t millis() {
    return TMR_MILLIS_VAL;
}