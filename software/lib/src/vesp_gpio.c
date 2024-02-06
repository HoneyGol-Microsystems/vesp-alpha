#include "vesp_gpio.h"

volatile uint8_t * const GPIOWR_A_PTR  = (volatile uint8_t *) 0xF0000000;
volatile uint8_t * const GPIODIR_A_PTR = (volatile uint8_t *) 0xF0000001;
volatile uint8_t * const GPIORD_A_PTR  = (volatile uint8_t *) 0xF0000002;
volatile uint8_t * const GPIOWR_B_PTR  = (volatile uint8_t *) 0xF0000003;
volatile uint8_t * const GPIODIR_B_PTR = (volatile uint8_t *) 0xF0000004;
volatile uint8_t * const GPIORD_B_PTR  = (volatile uint8_t *) 0xF0000005;