#include <stdint.h>

#include "../../bsp/include/uart.h"
#include "../../bsp/include/spi.h"
#include "../../bsp/include/xprintf.h"
#include "../../bsp/include/utils.h"
#include "../../bsp/include/rvic.h"
#include "../../bsp/include/pinmux.h"
#include "../../bsp/include/sim_ctrl.h"
#include "flash_w25q.h"



int main()
{
    w25q_id_t id;

    pinmux_set_io0_func(IO0_UART0_TX);
    pinmux_set_io3_func(IO3_UART0_RX);

    pinmux_set_io6_func(IO6_SPI_CLK);
    pinmux_set_io8_func(IO8_SPI_SS);
    pinmux_set_io1_func(IO1_SPI_DQ0);
    pinmux_set_io2_func(IO2_SPI_DQ1);
    pinmux_set_io4_func(IO4_SPI_DQ2);
    pinmux_set_io5_func(IO5_SPI_DQ3);

    uart0_init(uart0_putc);
    flash_w25q_init(5);

    xprintf("read id:\n");
    id = flash_w25q_read_id();
    xprintf("manf id = 0x%2x\n", id.manf_id);
    xprintf("device id = 0x%2x\n", id.device_id);

    flash_w25q_enable_qspi(1);
    xprintf("quad read id:\n");
    id = flash_w25q_read_id_quad();
    xprintf("manf id = 0x%2x\n", id.manf_id);
    xprintf("device id = 0x%2x\n", id.device_id);
    flash_w25q_enable_qspi(0);

    while (1);
}
