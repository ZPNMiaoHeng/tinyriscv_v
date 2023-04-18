#include <stdint.h>

#include "../../bsp/include/gpio.h"
#include "../../bsp/include/utils.h"
#include "../../bsp/include/rvic.h"
#include "../../bsp/include/pinmux.h"

int main()
{
    // IO12用作GPIO12
    pinmux_set_io12_func(IO12_GPIO12);
    // IO1用作GPIO1
    pinmux_set_io1_func(IO1_GPIO1);
    // gpio12输出模式
    gpio_set_mode(GPIO12, GPIO_MODE_OUTPUT);
    // gpio1输入模式
    gpio_set_mode(GPIO1, GPIO_MODE_INPUT);
    // gpio1双沿中断模式
    gpio_set_interrupt_mode(GPIO1, GPIO_INTR_DOUBLE_EDGE);
    // 使能RVIC中断
    rvic_irq_enable(RVIC_GPIO1_INT_ID);
    // gpio1中断优先级为1
    rvic_set_irq_prio_level(RVIC_GPIO1_INT_ID, 1);
    // 使能全局中断
    global_irq_enable();

    while (1);
}

// GPIO1中断处理函数
void gpio1_irq_handler()
{
    gpio_clear_intr_pending(GPIO1);
    rvic_clear_irq_pending(RVIC_GPIO1_INT_ID);

    // 如果GPIO1输入高
    if (gpio_get_input_data(GPIO1))
        gpio_set_output_data(GPIO12, 1);  // GPIO12输出高
    // 如果GPIO1输入低
    else
        gpio_set_output_data(GPIO12, 0);  // GPIO12输出低
}
