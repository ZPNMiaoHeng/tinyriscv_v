#ifndef _MACHINE_TIMER_H_
#define _MACHINE_TIMER_H_

#define MTIMER_BASE   (0xA0000000)
#define MTIMER_CTRL   (MTIMER_BASE + (0x00))
#define MTIMER_CMP    (MTIMER_BASE + (0x04))
#define MTIMER_COUNT  (MTIMER_BASE + (0x08))

#define MTIMER_REG(addr) (*((volatile uint32_t *)addr))

void machine_timer_set_cmp_val(uint32_t val);
void machine_timer_enable(uint8_t en);
void machine_timer_irq_enable(uint8_t en);
void machine_timer_clear_irq_pending();

#endif
