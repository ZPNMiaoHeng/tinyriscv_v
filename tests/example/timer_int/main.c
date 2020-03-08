#include <stdint.h>


// Timer regs
#define TIMER_BASE   (0x10000000)
#define TIMER_CTRL   (TIMER_BASE + (0x00))
#define TIMER_COUNT  (TIMER_BASE + (0x04))
#define TIMER_VALUE  (TIMER_BASE + (0x08))

#define TIMER_REG(addr) (*((volatile uint32_t *)addr))


static uint32_t ms_count;


static void set_test_pass()
{
    asm("li x27, 0x01");
}

static void set_test_fail()
{
    asm("li x27, 0x00");
}


int main()
{
    ms_count = 0;

    TIMER_REG(TIMER_VALUE) = 500;     // 10us period
    TIMER_REG(TIMER_CTRL) = 0x07;     // enable interrupt and start timer

    while (1) {
        if (ms_count == 5) {
            TIMER_REG(TIMER_CTRL) = 0x00;
            ms_count = 0;
            // TODO: do something
            set_test_pass();
            break;
        }
    }

    return 0;
}

void TIMER_IRQHandler()
{
    TIMER_REG(TIMER_CTRL) = 0x07; // clear int pending

    ms_count++;
}
