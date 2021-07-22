#ifndef _RVIC_H_
#define _RVIC_H_

#define RVIC_BASE    (0xD0000000)
#define RVIC_IE      (RVIC_BASE + (0x00))
#define RVIC_IP      (RVIC_BASE + (0x04))
#define RVIC_PRIO0   (RVIC_BASE + (0x08))
#define RVIC_PRIO1   (RVIC_BASE + (0x0C))
#define RVIC_PRIO2   (RVIC_BASE + (0x10))
#define RVIC_PRIO3   (RVIC_BASE + (0x14))
#define RVIC_PRIO4   (RVIC_BASE + (0x18))
#define RVIC_PRIO5   (RVIC_BASE + (0x1C))
#define RVIC_PRIO6   (RVIC_BASE + (0x20))
#define RVIC_PRIO7   (RVIC_BASE + (0x24))
#define RVIC_ID      (RVIC_BASE + (0x28))

#define RVIC_REG(addr) (*((volatile uint32_t *)addr))

typedef struct {
    volatile uint32_t prio[8];
} rvic_prio_t;

#define RVIC_PRIO  ((rvic_prio_t *)0xD0000008)

void rvic_irq_enable(uint32_t id);
void rvic_irq_disable(uint32_t id);
void rvic_clear_irq_pending(uint32_t id);
void rvic_set_irq_prio_level(uint32_t id, uint8_t level);

#endif
