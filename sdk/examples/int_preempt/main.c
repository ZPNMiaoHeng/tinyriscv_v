#include <stdint.h>

#include "../../bsp/include/timer.h"
#include "../../bsp/include/utils.h"
#include "../../bsp/include/rvic.h"
#include "../../bsp/include/gpio.h"
#include "../../bsp/include/uart.h"
#include "../../bsp/include/xprintf.h"
#include "../../bsp/include/pinmux.h"

static volatile uint32_t count;

int main()
{
    count = 0;

    pinmux_set_io0_func(IO0_UART0_TX);
    pinmux_set_io3_func(IO3_UART0_RX);

    uart0_init(uart0_putc);

    timer0_set_div(25);
    timer0_set_value(10000);    // 10ms period
    timer0_clear_int_pending();
    timer0_set_int_enable(1);
    timer0_set_mode_ontshot();
    // timer0中断优先级为1
    rvic_set_irq_prio_level(RVIC_INT_ID_0, 1);
    global_irq_enable();
    rvic_irq_enable(RVIC_INT_ID_0);
    timer0_start(1);

    // IO7用作GPIO7
    pinmux_set_io7_func(IO7_GPIO7);
    // IO9用作GPIO9
    pinmux_set_io9_func(IO9_GPIO9);
    // gpio7输出模式
    gpio_set_mode(GPIO7, GPIO_MODE_OUTPUT);
    // gpio9输入模式
    gpio_set_mode(GPIO9, GPIO_MODE_INPUT);
    // gpio9双沿中断
    gpio_set_interrupt_mode(GPIO9, GPIO_INTR_DOUBLE_EDGE);
    rvic_irq_enable(RVIC_INT_ID_9);
    // gpio9中断优先级为2
    rvic_set_irq_prio_level(RVIC_INT_ID_9, 2);

    while (1) {
        if (count == 3) {
            gpio_set_output_toggle(GPIO7); // toggle led
            busy_wait(500 * 1000);
        }
    }
}

void timer0_irq_handler()
{
    timer0_clear_int_pending();
    rvic_clear_irq_pending(0);

    xprintf("timer0 isr enter\n");
    // GPIO0对应LED为灭
    gpio_set_output_data(GPIO7, 1);

    while (count != 3);

    xprintf("timer0 isr exit\n");
}

void gpio9_irq_handler()
{
    gpio_clear_intr_pending(GPIO9);
    rvic_clear_irq_pending(RVIC_INT_ID_9);

    xprintf("gpio1 isr\n");
    count++;
}
