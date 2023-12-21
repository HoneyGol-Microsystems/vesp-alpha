#include <vesp.h>

void write_all_leds(uint16_t all_leds) {
    GPIOWR_A = (all_leds & 0xFF);
    GPIOWR_B = (all_leds >> 8) & 0xFF;
}

void main() {
    
    GPIODIR_A = 0xFF;
    GPIODIR_B = 0xFF;

    while(1) {
        write_all_leds((uint16_t)millis());
    }
}