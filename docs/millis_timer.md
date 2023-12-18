# System Uptime Timer (millis_timer)
This peripheral counts elapsed milliseconds since last system reboot.

Its 32-bit value is mapped to memory (check memory map). It is read only and cannot be reset by software.

## Usage in C
There are two ways in which the timer can be read:
1) Read directly from memory mapped register: `TMR_MILLIS_VAL`.
2) Use `millis` convenience function.

## Precaution
Because the timer is 32-bit, it will overflow approximately after 49 days of uptime. It is not meant to be any precise counting mechanism, rather it is a convenient way to perform non-blocking waiting (instead of using delay) and possibly to implement a primitive cooperative multitasking.