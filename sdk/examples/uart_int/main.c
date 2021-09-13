#include <stdint.h>

#include "../../bsp/include/uart.h"
#include "../../bsp/include/xprintf.h"
#include "../../bsp/include/rvic.h"
#include "../../bsp/include/utils.h"
#include "../../bsp/include/pinmux.h"


#define UART_TXB	(80)


static volatile struct {
	uint16_t	tri, twi, tct;
	uint8_t tbuf[UART_TXB];
} fifo;

static void uart_putc(uint8_t c)
{
	uint16_t i;

	if (fifo.tct >= UART_TXB)
        return;

	i = fifo.twi;
	fifo.tbuf[i] = c;
	fifo.twi = ++i % UART_TXB;

    global_irq_disable();
	fifo.tct++;
    // 使能TX FIFO空中断
    UART0_REG(UART_CTRL_REG_OFFSET) |= 1 << UART_CTRL_TX_FIFO_EMPTY_INT_EN_BIT;
    global_irq_enable();
}

int main()
{
    pinmux_set_io0_func(IO0_UART0_TX);
    pinmux_set_io3_func(IO3_UART0_RX);

    uart0_init(uart_putc);
    rvic_irq_enable(1);
    rvic_set_irq_prio_level(1, 1);
    // 使能RX FIFO非空中断
    UART0_REG(UART_CTRL_REG_OFFSET) |= 1 << UART_CTRL_RX_FIFO_NOT_EMPTY_INT_EN_BIT;
    global_irq_enable();
    fifo.tri = 0; fifo.twi = 0; fifo.tct = 0;

    xprintf("uart interrupt test\n");
    while (1);
}

void uart0_irq_handler()
{
    uint16_t i, count, index;
    uint8_t data;

    // 如果RX FIFO非空
    while (!(UART0_REG(UART_STATUS_REG_OFFSET) & (1 << UART_STATUS_RXEMPTY_BIT))) {
        data = UART0_REG(UART_RXDATA_REG_OFFSET);
        UART0_REG(UART_TXDATA_REG_OFFSET) = data;
    }
    // 如果TX FIFO为空
    if ((UART0_REG(UART_STATUS_REG_OFFSET) & (1 << UART_STATUS_TXEMPTY_BIT)) &&
        (fifo.tct > 0)) {

        count = fifo.tct;
        if (count > 8)
            count = 8;
        for (index = 0; index < count; index++) {
            fifo.tct--;
            i = fifo.tri;
            UART0_REG(UART_TXDATA_REG_OFFSET) = fifo.tbuf[i];
            fifo.tri = ++i % UART_TXB;
        }
        if (fifo.tct == 0)
            UART0_REG(UART_CTRL_REG_OFFSET) &= ~(1 << UART_CTRL_TX_FIFO_EMPTY_INT_EN_BIT);
    }
    rvic_clear_irq_pending(1);
}
