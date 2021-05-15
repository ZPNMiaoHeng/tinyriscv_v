#include <stdint.h>

#include "../../bsp/include/gpio.h"
#include "../../bsp/include/utils.h"

void gpio_output_enable(uint8_t gpio)
{
    GPIO_REG(GPIO_CTRL) &= ~(0x3 << (gpio << 1));
    GPIO_REG(GPIO_CTRL) |= GPIO_OUTPUT << (gpio << 1);
}

void gpio_input_enable(uint8_t gpio)
{
    GPIO_REG(GPIO_CTRL) &= ~(0x3 << (gpio << 1));
    GPIO_REG(GPIO_CTRL) |= GPIO_INPUT << (gpio << 1);
}

uint8_t gpio_get_data(uint8_t gpio)
{
    if (GPIO_REG(GPIO_DATA) & (1 << gpio))
        return 1;
    else
        return 0;
}

void gpio_set_data(uint8_t gpio, uint8_t data)
{
    if (data)
        GPIO_REG(GPIO_DATA) |= 1 << gpio;
    else
        GPIO_REG(GPIO_DATA) &= ~(1 << gpio);
}

void gpio_data_toggle(uint8_t gpio)
{
    GPIO_REG(GPIO_DATA) ^= 1 << gpio;
}
