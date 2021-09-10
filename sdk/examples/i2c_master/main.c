#include <stdint.h>

#include "../../bsp/include/uart.h"
#include "../../bsp/include/i2c.h"
#include "../../bsp/include/xprintf.h"
#include "../../bsp/include/utils.h"
#include "../../bsp/include/rvic.h"
#include "../../bsp/include/pinmux.h"


#define SLAVE_ADDR   (0xA0)

static volatile uint8_t i2c_done;

static void i2c_master_write(uint8_t addr, uint8_t data)
{
    i2c_done = 0;
    i2c0_master_set_write(1);
    i2c0_master_set_info(SLAVE_ADDR, addr, data);
    i2c0_start();

    while (!i2c_done);
}

static uint8_t i2c_master_read(uint8_t addr)
{
    i2c_done = 0;
    i2c0_master_set_write(0);
    i2c0_master_set_info(SLAVE_ADDR, addr, 0);
    i2c0_start();

    while (!i2c_done);

    return (i2c0_master_get_data());
}

int main()
{
    uint8_t data, i;

    uart0_init(uart0_putc);
    pinmux_set_io0_func(IO0_UART0_TX);
    pinmux_set_io3_func(IO3_UART0_RX);
    pinmux_set_io6_func(IO6_I2C0_SCL);
    pinmux_set_io8_func(IO8_I2C0_SDA);

    i2c0_set_clk(0x7D);     // 200KHZ
    i2c0_set_mode(I2C_MODE_MASTER);
    i2c0_set_interrupt_enable(1);

    rvic_set_irq_prio_level(RVIC_INT_ID_4, 1);
    rvic_irq_enable(RVIC_INT_ID_4);
    global_irq_enable();

    // 写
    for (i = 0; i < 10; i++) {
        i2c_master_write(i, i);
        xprintf("write[%d] = 0x%x\n", i, i);
        busy_wait(100 * 1000);
    }

    // 读
    for (i = 0; i < 10; i++) {
        data = i2c_master_read(i);
        xprintf("read[%d] = 0x%x\n", i, data);
    }

    while (1);
}

void i2c0_irq_handler()
{
    i2c_done = 1;

    i2c0_clear_irq_pending();
    rvic_clear_irq_pending(RVIC_INT_ID_4);
}
