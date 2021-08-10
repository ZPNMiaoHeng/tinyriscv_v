#include <stdint.h>

#include "../include/uart.h"
#include "../include/xprintf.h"


// send one char to uart
void uart0_putc(uint8_t c)
{
    while (UART0_REG(UART_STATUS_REG_OFFSET) & (1 << UART_STATUS_TXFULL_BIT));

    UART0_REG(UART_TXDATA_REG_OFFSET) = c;
}

// Block, get one char from uart.
uint8_t uart0_getc()
{
    while ((UART0_REG(UART_STATUS_REG_OFFSET) & (1 << UART_STATUS_RXEMPTY_BIT)));

    return (UART0_REG(UART_RXDATA_REG_OFFSET) & 0xff);
}

// 115200bps, 8 N 1
void uart0_init(putc put)
{
    // enable tx and rx
    UART0_REG(UART_CTRL_REG_OFFSET) |= 0x3;

    xdev_out(put);
}
