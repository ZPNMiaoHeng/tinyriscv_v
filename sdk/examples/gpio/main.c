#include <stdint.h>

#include "../../bsp/include/gpio.h"
#include "../../bsp/include/utils.h"
#include "../../bsp/include/rvic.h"

int main()
{
    gpio_set_mode(GPIO0, GPIO_MODE_OUTPUT);       // gpio0输出模式
    gpio_set_mode(GPIO1, GPIO_MODE_INPUT);        // gpio1输入模式
    gpio_set_interrupt_mode(GPIO1, GPIO_INTR_DOUBLE_EDGE);
    rvic_irq_enable(3);
    rvic_set_irq_prio_level(3, 1);
    global_irq_enable();

    while (1);
}

void gpio1_irq_handler()
{
    gpio_clear_intr_pending(GPIO1);
    rvic_clear_irq_pending(3);

    // 如果GPIO1输入高
    if (gpio_get_input_data(GPIO1))
        gpio_set_output_data(GPIO0, 1);  // GPIO0输出高
    // 如果GPIO1输入低
    else
        gpio_set_output_data(GPIO0, 0);  // GPIO0输出低
}
