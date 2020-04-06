#include <stdint.h>

#include "../include/timer.h"
#include "../include/gpio.h"


static uint32_t count;


int main()
{
    count = 0;

    TIMER0_REG(TIMER0_VALUE) = 50000;   // 1ms period
    TIMER0_REG(TIMER0_CTRL) = 0x07;     // enable interrupt and start timer

    GPIO_REG(GPIO_DATA) = 0x1;

    while (1) {
        if (count >= 500) {
            count = 0;
            GPIO_REG(GPIO_DATA) ^= 0x1;
        }
    }

    return 0;
}

void TIMER0_IRQHandler()
{
    TIMER0_REG(TIMER0_CTRL) = 0x07; // clear int pending

    count++;
}
