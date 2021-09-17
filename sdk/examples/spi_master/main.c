#include <stdint.h>

#include "../../bsp/include/uart.h"
#include "../../bsp/include/spi.h"
#include "../../bsp/include/xprintf.h"
#include "../../bsp/include/utils.h"
#include "../../bsp/include/rvic.h"
#include "../../bsp/include/pinmux.h"
#include "../../bsp/include/sim_ctrl.h"
#include "flash_n25q.h"


#define BUFFER_SIZE   (64)

uint8_t program_data[BUFFER_SIZE];
uint8_t read_data[BUFFER_SIZE];


int main()
{
    uint16_t i;
    n25q_id_t id;

    pinmux_set_io0_func(IO0_UART0_TX);
    pinmux_set_io3_func(IO3_UART0_RX);
    pinmux_set_io10_func(IO10_SPI_CLK);
    pinmux_set_io11_func(IO11_SPI_SS);
    pinmux_set_io12_func(IO12_SPI_DQ0);
    pinmux_set_io13_func(IO13_SPI_DQ1);
    pinmux_set_io14_func(IO14_SPI_DQ2);
    pinmux_set_io15_func(IO15_SPI_DQ3);

    uart0_init(uart0_putc);
    flash_n25q_init(5);

    xprintf("read ID through standard SPI mode\n");
    id = flash_n25q_read_id();
    xprintf("manf id = 0x%2x\n", id.manf_id);
    xprintf("mem type = 0x%2x\n", id.mem_type);
    xprintf("mem cap = 0x%2x\n", id.mem_cap);

    // 初始化要编程的数据
    for (i = 0; i < BUFFER_SIZE; i++)
        program_data[i] = i;

    xprintf("start erase subsector...\n");
    // 擦除第0个子扇区
    flash_n25q_subsector_erase(0x00);
    xprintf("start program page...\n");
    xprintf("program data: \n");
    // 打印读出来的数据
    for (i = 0; i < BUFFER_SIZE; i++)
        xprintf("0x%x\n", program_data[i]);
    // 编程第1页
    flash_n25q_page_program(program_data, BUFFER_SIZE, 0x01);
    xprintf("start read page...\n");
    // 读第1页
    flash_n25q_read_data(read_data, BUFFER_SIZE, N25Q_PAGE_TO_ADDR(1));
    xprintf("read data: \n");
    // 打印读出来的数据
    for (i = 0; i < BUFFER_SIZE; i++)
        xprintf("0x%x\n", read_data[i]);

    // 使能N25Q QSPI模式
    flash_n25q_enable_quad_mode(1);
    // 使能SPI控制器QSPI模式
    spi0_set_spi_mode(SPI_MODE_QUAD);
    xprintf("read ID through QUAD SPI mode\n");
    id = flash_n25q_multi_io_read_id();
    xprintf("manf id = 0x%2x\n", id.manf_id);
    xprintf("mem type = 0x%2x\n", id.mem_type);
    xprintf("mem cap = 0x%2x\n", id.mem_cap);
    // 失能N25Q QSPI模式
    flash_n25q_enable_quad_mode(0);

/*
    flash_n25q_set_dummy_clock_cycles(DUMMY_CNT_4_4_4 << 1);
    flash_n25q_enable_quad_mode(1);
    spi0_set_spi_mode(SPI_MODE_QUAD);
    flash_n25q_quad_fast_read(N25Q_PAGE_TO_ADDR(1), read_data, BUFFER_SIZE);
    xprintf("fast read data: \n");
    for (i = 0; i < BUFFER_SIZE; i++)
        xprintf("0x%x\n", read_data[i]);

    flash_n25q_enable_quad_mode(0);
*/
    while (1);
}
