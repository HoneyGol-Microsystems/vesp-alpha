#ifndef __VESP_TIMERS_H
#define __VESP_TIMERS_H

#include <stdint.h>

/////////////////////////////////////////////////////////
// MILLIS TIMER
/////////////////////////////////////////////////////////

/// Timer  value.
extern volatile const uint32_t * const TMR_MILLIS_VAL_PTR;

/// Pointerless access to the value.
#define TMR_MILLIS_VAL (*TMR_MILLIS_VAL_PTR)

/// Convenience Arduino-like function to get milliseconds elapsed since start.
uint32_t millis();

#endif // __VESP_TIMERS_H