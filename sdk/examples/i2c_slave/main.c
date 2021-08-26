#include <stdint.h>

#include "../../bsp/include/uart.h"
#include "../../bsp/include/i2c.h"
#include "../../bsp/include/xprintf.h"
#include "../../bsp/include/utils.h"
#include "../../bsp/include/rvic.h"


#define SLAVE_ADDR   (0xAA)

typedef enum {
    OP_NONE = 0,
    OP_READ,
    OP_WRITE,
} op_e;

static volatile op_e op;

int main()
{
    uart0_init(uart0_putc);

    i2c0_set_mode(I2C_MODE_SLAVE);
    i2c0_slave_set_address(SLAVE_ADDR);
    i2c0_slave_set_ready(1);
    i2c0_set_interrupt_enable(1);

    rvic_set_irq_prio_level(RVIC_INT_ID_4, 1);
    rvic_irq_enable(RVIC_INT_ID_4);
    global_irq_enable();

    i2c0_start();

    op = OP_NONE;

    while (1) {
        if (op == OP_READ) {
            xprintf("op read addr = 0x%x\n", i2c0_slave_get_op_address());
            i2c0_slave_set_rsp_data(0x12345678);
            i2c0_slave_set_ready(1);
            op = OP_NONE;
        } else if (op == OP_WRITE) {
            xprintf("op write addr = 0x%x\n", i2c0_slave_get_op_address());
            xprintf("op write data = 0x%x\n", i2c0_slave_get_op_data());
            i2c0_slave_set_ready(1);
            op = OP_NONE;
        }
    }
}

void i2c0_irq_handler()
{
    if (i2c0_slave_op_read())
        op = OP_READ;
    else
        op = OP_WRITE;

    i2c0_clear_irq_pending();
    rvic_clear_irq_pending(RVIC_INT_ID_4);
}
