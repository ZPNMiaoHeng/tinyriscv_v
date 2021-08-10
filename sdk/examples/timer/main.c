#include <stdint.h>

#include "../../bsp/include/timer.h"
#include "../../bsp/include/utils.h"
#include "../../bsp/include/rvic.h"
#include "../../bsp/include/gpio.h"

static volatile uint32_t count;

int main()
{
    count = 0;

#ifdef SIMULATION
    timer0_set_div(50);
    timer0_set_value(100);    // 100us period
    timer0_clear_int_pending();
    timer0_set_int_enable(1);
    timer0_set_mode_auto_reload();
    rvic_set_irq_prio_level(0, 1);
    global_irq_enable();
    rvic_irq_enable(0);
    timer0_start(1);

    while (1) {
        if (count == 3) {
            timer0_start(0);
            // TODO: do something
            set_test_pass();
            break;
        }
    }

    return 0;
#else
    timer0_set_div(25);
    timer0_set_value(10000);    // 10ms period
    timer0_clear_int_pending();
    timer0_set_int_enable(1);
    timer0_set_mode_auto_reload();
    rvic_set_irq_prio_level(0, 1);
    global_irq_enable();
    rvic_irq_enable(0);
    timer0_start(1);

    gpio_output_enable(GPIO0);

    while (1) {
        // 500ms
        if (count == 50) {
            count = 0;
            gpio_data_toggle(GPIO0); // toggle led
        }
    }
#endif
}

void timer_irq_handler()
{
    count++;

    timer0_clear_int_pending();
    rvic_clear_irq_pending(0);
}
