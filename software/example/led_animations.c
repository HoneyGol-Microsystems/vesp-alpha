#include <vesp.h>

#define DIR_RIGHT 0
#define DIR_LEFT 1

inline uint16_t rol16 ( uint16_t x ) {
    return ( x << 1 ) | ( x >> 15 );
}

inline uint16_t ror16 ( uint16_t x ) {
    return ( x >> 1 ) | ( x << 15 );
}

void write_all_leds(uint16_t all_leds) {
    GPIOWR_A = (all_leds & 0xFF);
    GPIOWR_B = (all_leds >> 8) & 0xFF;
}

void anim_shift(int dir, int count) {

    uint16_t all_leds = dir == DIR_LEFT ? 0x0001 : 0x8000;

    for(int i = 0; i < count; i++) {
        write_all_leds(all_leds);
        delay_ms(100);
        all_leds = dir == DIR_LEFT ? rol16(all_leds) : ror16(all_leds);
    }
}

void anim_blink(int count) {

    uint16_t all_leds = 0xFFFF;

    for(int i = 0; i < count; i++) {
        write_all_leds(all_leds);
        delay_ms(1000);
        all_leds = ~all_leds;
    }
}

void anim_middle_boink(int count) {

    GPIOWR_A = 0x80;
    GPIOWR_B = 0x01;

    for(int counter = 0; counter < count; counter++) {
        for(int i = 0; i < 7; i++) {
            GPIOWR_A >>= 1;
            GPIOWR_B <<= 1;
            delay_ms(50);
        }

        for(int i = 0; i < 7; i++) {
            GPIOWR_A <<= 1;
            GPIOWR_B >>= 1;
            delay_ms(50);
        }
    }
}

void anim_breathe(int count) {

    int fade_in = 1;

    for(int counter = 0; counter < count; counter++) {
        for(int off_time = 0; off_time <= 10; off_time++) {
            for(int writes = 0; writes < 10; writes++) {
                write_all_leds(0xFFFF);
                delay_ms(fade_in ? 10 - off_time : off_time);
                write_all_leds(0x0000);
                delay_ms(fade_in ? off_time : 10 - off_time);
            }
        }
        fade_in = !fade_in;
    }

}

void main(void) {

    GPIOWR_A  = 0x1;
    GPIOWR_B  = 0x1;

    GPIODIR_A = 0xFF;
    GPIODIR_B = 0xFF;

    while(1) {
        anim_shift(DIR_LEFT, 32);
        anim_shift(DIR_RIGHT, 32);
        anim_blink(4);
        anim_middle_boink(4);
        anim_breathe(4);
    }
}