#include <stdint.h>

#include "../../bsp/include/gpio.h"
#include "../../bsp/include/utils.h"
#include "../../bsp/include/pinmux.h"

int main()
{
    // IO10用作GPIO10
    pinmux_set_io10_func(IO10_GPIO10);
    // IO12用作GPIO12
    pinmux_set_io12_func(IO12_GPIO12);
    // IO14用作GPIO14
    pinmux_set_io14_func(IO14_GPIO14);
    // IO15用作GPIO15
    pinmux_set_io15_func(IO15_GPIO15);

    // 输出模式
    gpio_set_mode(GPIO10, GPIO_MODE_OUTPUT);
    gpio_set_mode(GPIO12, GPIO_MODE_OUTPUT);
    gpio_set_mode(GPIO14, GPIO_MODE_OUTPUT);
    gpio_set_mode(GPIO15, GPIO_MODE_OUTPUT);

    while (1) {
        // 逐个点亮
        gpio_set_output_data(GPIO12, 0);
        busy_wait(500000);
        gpio_set_output_data(GPIO10, 0);
        busy_wait(500000);
        gpio_set_output_data(GPIO15, 0);
        busy_wait(500000);
        gpio_set_output_data(GPIO14, 0);
        busy_wait(500000);
        // 全灭
        gpio_set_output_data(GPIO12, 1);
        gpio_set_output_data(GPIO10, 1);
        gpio_set_output_data(GPIO15, 1);
        gpio_set_output_data(GPIO14, 1);
        busy_wait(500000);
    }
}
