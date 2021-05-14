#include <stdint.h>

#include "../../bsp/include/machine_timer.h"
#include "../../bsp/include/utils.h"

void machine_timer_set_cmp_val(uint32_t val)
{
    MTIMER_REG(MTIMER_CMP) = val;
}

void machine_timer_enable(uint8_t en)
{
    if (en)
        MTIMER_REG(MTIMER_CTRL) |= 1;
    else
        MTIMER_REG(MTIMER_CTRL) &= ~1;
}

void machine_timer_irq_enable(uint8_t en)
{
    if (en)
        mtime_irq_enable();
    else
        mtime_irq_disable();
}

void machine_timer_clear_irq_pending()
{
    MTIMER_REG(MTIMER_CTRL) |= 1 << 1;
}
