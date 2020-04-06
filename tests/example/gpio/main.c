#include <stdint.h>

#include "../include/gpio.h"
#include "../include/utils.h"


#define MS(ms) (ms * 50000)



static void delay_ms(uint32_t ms)
{
    uint64_t tmp;
    uint64_t cycle;

    tmp = read_csr(cycle);
    tmp += (uint64_t)(read_csr(cycleh)) << 32;

    do {
        cycle = read_csr(cycle);
        cycle += (uint64_t)(read_csr(cycleh)) << 32;
    } while (cycle < tmp + MS(ms));
}



int main()
{
    while (1) {
        GPIO_REG(GPIO_DATA) ^= 0x1;
        delay_ms(500);
    }
}
