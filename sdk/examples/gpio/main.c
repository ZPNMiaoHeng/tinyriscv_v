#include <stdint.h>

#include "../../bsp/include/gpio.h"
#include "../../bsp/include/utils.h"


int main()
{
    gpio_output_enable(GPIO0);       // gpio0输出模式
    gpio_input_enable(GPIO1);        // gpio1输入模式

    while (1) {
        // 如果GPIO1输入高
        if (gpio_get_data(GPIO1))
            gpio_set_data(GPIO0, 1);  // GPIO0输出高
        // 如果GPIO1输入低
        else
            gpio_set_data(GPIO0, 0);  // GPIO0输出低
    }
}
