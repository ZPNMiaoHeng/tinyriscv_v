#include <stdint.h>

#include "../include/timer.h"


void timer0_start(uint8_t en)
{
    if (en)
        TIMER0_REG(TIMER_CTRL_REG_OFFSET) |= 1 << TIMER_CTRL_EN_BIT;
    else
        TIMER0_REG(TIMER_CTRL_REG_OFFSET) &= ~(1 << TIMER_CTRL_EN_BIT);
}

void timer0_set_value(uint32_t val)
{
    TIMER0_REG(TIMER_VALUE_REG_OFFSET) = val;
}

void timer0_set_int_enable(uint8_t en)
{
    if (en)
        TIMER0_REG(TIMER_CTRL_REG_OFFSET) |= 1 << TIMER_CTRL_INT_EN_BIT;
    else
        TIMER0_REG(TIMER_CTRL_REG_OFFSET) &= ~(1 << TIMER_CTRL_INT_EN_BIT);
}

void timer0_clear_int_pending()
{
    TIMER0_REG(TIMER_CTRL_REG_OFFSET) |= 1 << TIMER_CTRL_INT_PENDING_BIT;
}

uint8_t timer0_get_int_pending()
{
    if (TIMER0_REG(TIMER_CTRL_REG_OFFSET) & (1 << TIMER_CTRL_INT_PENDING_BIT))
        return 1;
    else
        return 0;
}

uint32_t timer0_get_current_count()
{
    return TIMER0_REG(TIMER_COUNT_REG_OFFSET);
}

void timer0_set_mode_auto_reload()
{
    TIMER0_REG(TIMER_CTRL_REG_OFFSET) |= 1 << TIMER_CTRL_MODE_BIT;
}

void timer0_set_mode_ontshot()
{
    TIMER0_REG(TIMER_CTRL_REG_OFFSET) &= ~(1 << TIMER_CTRL_MODE_BIT);
}

void timer0_set_div(uint32_t div)
{
    TIMER0_REG(TIMER_CTRL_REG_OFFSET) &= ~(TIMER_CTRL_CLK_DIV_MASK << TIMER_CTRL_CLK_DIV_OFFSET);
    TIMER0_REG(TIMER_CTRL_REG_OFFSET) |= div << TIMER_CTRL_CLK_DIV_OFFSET;
}
