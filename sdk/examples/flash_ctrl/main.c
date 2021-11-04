#include <stdint.h>

#include "../../bsp/include/uart.h"
#include "../../bsp/include/xprintf.h"
#include "../../bsp/include/pinmux.h"
#include "../../bsp/include/flash_ctrl.h"


#define DATA_BUF_LEN    (32)

// bytes = DATA_BUF_LEN * 4
#define DATA_BYTES      (DATA_BUF_LEN << 2)

static uint32_t write_data_buf[DATA_BUF_LEN];
static uint32_t read_data_buf[DATA_BUF_LEN];


int main()
{
    uint32_t i;

    // UART引脚配置
    pinmux_set_io0_func(IO0_UART0_TX);
    pinmux_set_io3_func(IO3_UART0_RX);
    // UART初始化
    uart_init(UART0, uart0_putc);

    flash_ctrl_init();

    // 擦除0子扇区
    if (!flash_ctrl_sector_erase(0))
        xprintf("erase failed...\n");

    // 构造编程数据
    for (i = 0; i < DATA_BUF_LEN; i++)
        write_data_buf[i] = i;

    // 编程第0页
    if (!flash_ctrl_page_program(0, write_data_buf, DATA_BYTES))
        xprintf("program failed...\n");

    // 读0x0地址开始的数据
    flash_ctrl_read(0, read_data_buf, DATA_BYTES);

    flash_ctrl_deinit();

    // 打印读到的数据
    for (i = 0; i < DATA_BUF_LEN; i++)
        xprintf("0x%x\n", read_data_buf[i]);

/************************** QSPI测试 **************************/

    flash_ctrl_init();

    // QSPI初始化
    flash_ctrl_qspi_init();

    // 读0x0地址开始的数据
    flash_ctrl_read(0, read_data_buf, DATA_BYTES);

    flash_ctrl_deinit();

    xprintf("\nquad spi test, read data:\n");
    // 打印读到的数据
    for (i = 0; i < DATA_BUF_LEN; i++)
        xprintf("0x%x\n", read_data_buf[i]);

    while (1);
}
