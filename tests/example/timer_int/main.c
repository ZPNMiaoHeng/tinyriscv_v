#include <stdint.h>


// Timer0 regs
#define TIMER0_BASE   (0x20000000)
#define TIMER0_CTRL   (TIMER0_BASE + (0x00))
#define TIMER0_COUNT  (TIMER0_BASE + (0x04))
#define TIMER0_VALUE  (TIMER0_BASE + (0x08))

#define TIMER0_REG(addr) (*((volatile uint32_t *)addr))


static uint32_t count;


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
    count = 0;

    TIMER0_REG(TIMER0_VALUE) = 500;     // 10us period
    TIMER0_REG(TIMER0_CTRL) = 0x07;     // enable interrupt and start timer

    while (1) {
        if (count == 10) {
            TIMER0_REG(TIMER0_CTRL) = 0x00;
            count = 0;
            // TODO: do something
            set_test_pass();
            break;
        }
    }

    return 0;
}

void TIMER0_IRQHandler()
{
    TIMER0_REG(TIMER0_CTRL) = 0x07; // clear int pending

    count++;
}
