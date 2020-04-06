#include <stdint.h>


// GPIO regs
#define GPIO_BASE      (0x40000000)
#define GPIO_DATA      (GPIO_BASE + (0x04))


#define GPIO_REG(addr) (*((volatile uint32_t *)addr))


#define MS(ms) (ms * 50000)


#define read_csr(reg) ({ unsigned long __tmp; \
  asm volatile ("csrr %0, " #reg : "=r"(__tmp)); \
  __tmp; })



static void delay_ms(uint32_t ms)
{
    uint64_t tmp;
    uint64_t cycle;

    tmp = read_csr(cycle);
    tmp += (uint64_t)(read_csr(cycleh)) << 32;

    do {
        cycle = read_csr(cycle);
        cycle += (uint64_t)(read_csr(cycleh)) << 32;
    } while (cycle < tmp + MS(ms));
}



int main()
{
    while (1) {
        GPIO_REG(GPIO_DATA) ^= 0x1;
        delay_ms(500);
    }
}
