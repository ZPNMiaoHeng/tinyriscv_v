#include <stdint.h>

#include "../../bsp/include/rvic.h"


void rvic_irq_enable(uint32_t id)
{
    RVIC_REG(RVIC_IE) |= 1 << id;
}

void rvic_irq_disable(uint32_t id)
{
    RVIC_REG(RVIC_IE) &= ~(1 << id);
}

void rvic_clear_irq_pending(uint32_t id)
{
    RVIC_REG(RVIC_IP) |= 1 << id;
}

void rvic_set_irq_prio_level(uint32_t id, uint8_t level)
{
    uint8_t reg;
    uint8_t index;

    reg = id >> 2;
    index = id % 4;

    RVIC_PRIO->prio[reg] &= ~(0xff << (index << 3));
    RVIC_PRIO->prio[reg] |= (level << (index << 3));
}
