#ifndef __VESP_GPIO_H
#define __VESP_GPIO_H

/* GPIO addresses */
volatile uint8_t * const GPIOWR_A_PTR  = (volatile uint8_t *) 0xF0000000;
volatile uint8_t * const GPIODIR_A_PTR = (volatile uint8_t *) 0xF0000001;
volatile uint8_t * const GPIORD_A_PTR  = (volatile uint8_t *) 0xF0000002;
volatile uint8_t * const GPIOWR_B_PTR  = (volatile uint8_t *) 0xF0000003;
volatile uint8_t * const GPIODIR_B_PTR = (volatile uint8_t *) 0xF0000004;
volatile uint8_t * const GPIORD_B_PTR  = (volatile uint8_t *) 0xF0000005;

/* GPIO address placeholders */
#define GPIOWR_A  *GPIOWR_A_PTR
#define GPIODIR_A *GPIODIR_A_PTR
#define GPIORD_A  *GPIORD_A_PTR
#define GPIOWR_B  *GPIOWR_B_PTR
#define GPIODIR_B *GPIODIR_B_PTR
#define GPIORD_B  *GPIORD_B_PTR

#endif // __VESP_GPIO_H