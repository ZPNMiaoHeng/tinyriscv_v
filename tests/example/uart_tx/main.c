#include <stdint.h>

#include "xprintf.h"

// UART0 regs
#define UART0_BASE      (0x30000000)
#define UART0_CTRL      (UART0_BASE + (0x00))
#define UART0_STATUS    (UART0_BASE + (0x04))
#define UART0_BAUD      (UART0_BASE + (0x08))
#define UART0_TXDATA    (UART0_BASE + (0x0c))

#define UART0_REG(addr) (*((volatile uint32_t *)addr))



static void uart_putc(uint8_t d)
{
    while (UART0_REG(UART0_STATUS) & 0x1);
    UART0_REG(UART0_TXDATA) = d;
}


int main()
{
    UART0_REG(UART0_CTRL) = 0x1;

    xdev_out(uart_putc);

    xprintf("%d hello world\n", 1);

    while (1);
}
