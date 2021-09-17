#include <stdint.h>

#include "../../bsp/include/spi.h"
#include "../../bsp/include/rvic.h"
#include "../../bsp/include/utils.h"
#include "flash_n25q.h"

/* N25Q064特点:
 * 1.总共64Mb大小，即8MB
 * 2.总共128个扇区，每个扇区大小为64KB
 * 3.总共2048个子扇区，每个子扇区大小为4KB
 * 4.总共37768页，每页大小为256B
 * 5.擦除的最小单位是子扇区，编程(写)的最小单位是页，读的最小单位是字节
 */


void flash_n25q_init(uint16_t clk_div)
{
    spi0_set_clk_div(clk_div);
    spi0_set_role_mode(SPI_ROLE_MODE_MASTER);
    spi0_set_spi_mode(SPI_MODE_STANDARD);
    spi0_set_cp_mode(SPI_CPOL_0_CPHA_0);
    spi0_set_msb_first();
    spi0_master_set_ss_delay(1);
    spi0_set_ss_level(1);
    spi0_set_ss_ctrl_by_sw(1);
    spi0_set_enable(1);
}

// 写使能
// 擦除或者编程操作之前必须先发送写使能命令
void flash_n25q_write_enable(uint8_t en)
{
    uint8_t cmd;

    if (en)
        cmd = CMD_WRITE_ENABLE;
    else
        cmd = CMD_WRITE_DISABLE;

    spi0_set_ss_level(0);
    spi0_master_write_bytes(&cmd, 1);
    spi0_set_ss_level(1);
}

// 读寄存器
uint8_t flash_n25q_read_reg(uint8_t cmd)
{
    uint8_t data;

    spi0_set_ss_level(0);
    spi0_master_write_bytes(&cmd, 1);
    spi0_master_read_bytes(&data, 1);
    spi0_set_ss_level(1);

    return data;
}

// 写寄存器
void flash_n25q_write_reg(uint8_t cmd, uint8_t data)
{
    spi0_set_ss_level(0);
    spi0_master_write_bytes(&cmd, 1);
    spi0_master_write_bytes(&data, 1);
    spi0_set_ss_level(1);
}

// 读状态寄存器
uint8_t flash_n25q_read_status_reg()
{
    uint8_t data;

    data = flash_n25q_read_reg(CMD_READ_STATUS_REG);

    return data;
}

// 是否正在擦除或者编程
uint8_t flash_n25q_is_busy()
{
    if (flash_n25q_read_status_reg() & 0x1)
        return 1;
    else
        return 0;
}

// 读数据
// addr: 0, 1, 2, ...
void flash_n25q_read_data(uint8_t data[], uint32_t len, uint32_t addr)
{
    uint8_t cmd;
    uint8_t tran_addr[3];

    cmd = CMD_READ;
    tran_addr[0] = (addr >> 16) & 0xff;
    tran_addr[1] = (addr >> 8)  & 0xff;
    tran_addr[2] = (addr >> 0)  & 0xff;

    spi0_set_ss_level(0);
    spi0_master_write_bytes(&cmd, 1);
    spi0_master_write_bytes(tran_addr, 3);
    spi0_master_read_bytes(data, len);
    spi0_set_ss_level(1);
}

static void sector_erase(uint8_t cmd, uint32_t addr)
{
    uint8_t tran_addr[3];

    flash_n25q_write_enable(1);

    tran_addr[0] = (addr >> 16) & 0xff;
    tran_addr[1] = (addr >> 8)  & 0xff;
    tran_addr[2] = (addr >> 0)  & 0xff;

    spi0_set_ss_level(0);
    spi0_master_write_bytes(&cmd, 1);
    spi0_master_write_bytes(tran_addr, 3);
    spi0_set_ss_level(1);

    while (flash_n25q_is_busy());

    flash_n25q_write_enable(0);
}

// 子扇区擦除
// subsector，第几个子扇区: 0 ~ N
void flash_n25q_subsector_erase(uint32_t subsector)
{
    sector_erase(CMD_SUBSECTOR_ERASE, N25Q_SUBSECTOR_TO_ADDR(subsector));
}

// 扇区擦除
// sector，第几个扇区: 0 ~ N
void flash_n25q_sector_erase(uint32_t sector)
{
    sector_erase(CMD_SECTOR_ERASE, N25Q_SECTOR_TO_ADDR(sector));
}

// 页编程
// page，第几页: 0 ~ N
void flash_n25q_page_program(uint8_t data[], uint32_t len, uint32_t page)
{
    uint8_t tran_addr[3];
    uint8_t cmd;
    uint32_t addr;

    flash_n25q_write_enable(1);

    addr = N25Q_PAGE_TO_ADDR(page);
    tran_addr[0] = (addr >> 16) & 0xff;
    tran_addr[1] = (addr >> 8)  & 0xff;
    tran_addr[2] = (addr >> 0)  & 0xff;

    cmd = CMD_PAGE_PROGRAM;

    spi0_set_ss_level(0);
    spi0_master_write_bytes(&cmd, 1);
    spi0_master_write_bytes(tran_addr, 3);
    spi0_master_write_bytes(data, len);
    spi0_set_ss_level(1);

    while (flash_n25q_is_busy());

    flash_n25q_write_enable(0);
}

// 读增强型易失配置寄存器
uint8_t flash_n25q_read_enhanced_volatile_conf_reg()
{
    uint8_t data;

    data = flash_n25q_read_reg(CMD_READ_ENHANCED_VOL_CONF_REG);

    return data;
}

// 读非易失配置寄存器
uint8_t flash_n25q_read_nonvolatile_conf_reg()
{
    uint8_t data;

    data = flash_n25q_read_reg(CMD_READ_NONVOL_CONF_REG);

    return data;
}

// 写增强型易失配置寄存器
void flash_n25q_write_enhanced_volatile_conf_reg(uint8_t data)
{
    flash_n25q_write_reg(CMD_WRITE_ENHANCED_VOL_CONF_REG, data);
}

// 使能QUAD SPI模式
void flash_n25q_enable_quad_mode(uint8_t en)
{
    uint8_t data;

    flash_n25q_write_enable(1);

    data = flash_n25q_read_enhanced_volatile_conf_reg();
    if (en) {
        data &= ~(1 << 7);
        data |= 1 << 6;
    } else {
        data |= 0x3 << 6;
    }
    flash_n25q_write_enhanced_volatile_conf_reg(data);

    flash_n25q_write_enable(0);
}

// 设置n25q dummy cycles
void flash_n25q_set_dummy_clock_cycles(uint8_t num)
{
    uint8_t data;

    data = flash_n25q_read_reg(CMD_READ_VOL_CONF_REG);
    data &= ~(0xf << 4);
    data |= num << 4;
    flash_n25q_write_reg(CMD_WRITE_VOL_CONF_REG, data);
}

void flash_n25q_quad_fast_read(uint32_t addr, uint8_t data[], uint32_t len)
{
    uint8_t tran_addr[3];
    uint8_t cmd, i;

    cmd = CMD_4_4_4_FAST_READ;

    tran_addr[0] = (addr >> 16) & 0xff;
    tran_addr[1] = (addr >> 8)  & 0xff;
    tran_addr[2] = (addr >> 0)  & 0xff;

    spi0_set_ss_level(0);
    spi0_master_write_bytes(&cmd, 1);
    spi0_master_write_bytes(tran_addr, 3);
    for (i = 0; i < DUMMY_CNT_4_4_4; i++)
        spi0_master_read_bytes(data, 1);
    spi0_reset_rxfifo();
    spi0_master_read_bytes(data, len);
    spi0_set_ss_level(1);
}

// 标准SPI模式读flash ID
n25q_id_t flash_n25q_read_id()
{
    n25q_id_t id;
    uint8_t cmd;
    uint8_t data[3];

    cmd = CMD_READ_ID;

    spi0_set_ss_level(0);
    spi0_master_write_bytes(&cmd, 1);
    spi0_master_read_bytes(data, 3);
    spi0_set_ss_level(1);

    id.manf_id = data[0];
    id.mem_type = data[1];
    id.mem_cap = data[2];

    return id;
}

// DUAL/QUAD SPI模式读flash ID
n25q_id_t flash_n25q_multi_io_read_id()
{
    n25q_id_t id;
    uint8_t cmd;
    uint8_t data[3];

    cmd = CMD_MULTI_IO_READ_ID;

    spi0_set_ss_level(0);
    spi0_master_write_bytes(&cmd, 1);
    spi0_master_read_bytes(data, 3);
    spi0_set_ss_level(1);

    id.manf_id = data[0];
    id.mem_type = data[1];
    id.mem_cap = data[2];

    return id;
}
