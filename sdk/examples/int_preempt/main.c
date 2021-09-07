#include <stdint.h>

#include "../../bsp/include/timer.h"
#include "../../bsp/include/utils.h"
#include "../../bsp/include/rvic.h"
#include "../../bsp/include/gpio.h"
#include "../../bsp/include/uart.h"
#include "../../bsp/include/xprintf.h"

static volatile uint32_t count;

int main()
{
    count = 0;

    uart0_init(uart0_putc);

    timer0_set_div(25);
    timer0_set_value(10000);    // 10ms period
    timer0_clear_int_pending();
    timer0_set_int_enable(1);
    timer0_set_mode_ontshot();
    // timer0中断优先级为1
    rvic_set_irq_prio_level(0, 1);
    global_irq_enable();
    rvic_irq_enable(0);
    timer0_start(1);

    // gpio0输出模式
    gpio_set_mode(GPIO0, GPIO_MODE_OUTPUT);
    // gpio1输入模式
    gpio_set_mode(GPIO1, GPIO_MODE_INPUT);
    // gpio1双沿中断
    gpio_set_interrupt_mode(GPIO1, GPIO_INTR_DOUBLE_EDGE);
    rvic_irq_enable(3);
    // gpio1中断优先级为2
    rvic_set_irq_prio_level(3, 2);

    while (1) {
        if (count == 3) {
            gpio_set_output_toggle(GPIO0); // toggle led
            busy_wait(500 * 1000);
        }
    }
}

void timer0_irq_handler()
{
    timer0_clear_int_pending();
    rvic_clear_irq_pending(0);

    xprintf("timer0 isr\n");
    // GPIO0对应LED为灭
    gpio_set_output_data(GPIO0, 1);

    while (count != 3);
}

void gpio1_irq_handler()
{
    gpio_clear_intr_pending(GPIO1);
    rvic_clear_irq_pending(3);

    xprintf("gpio1 isr\n");
    count++;
}
