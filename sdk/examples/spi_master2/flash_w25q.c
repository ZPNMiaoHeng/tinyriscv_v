#include <stdint.h>

#include "../../bsp/include/spi.h"
#include "../../bsp/include/rvic.h"
#include "../../bsp/include/utils.h"
#include "flash_w25q.h"


void flash_w25q_init(uint16_t clk_div)
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

uint8_t flash_w25q_read_reg(uint8_t cmd)
{
    uint8_t data;

    spi0_set_ss_level(0);
    spi0_master_write_bytes(&cmd, 1);
    spi0_master_read_bytes(&data, 1);
    spi0_set_ss_level(1);

    return data;
}

uint8_t flash_w25q_write_reg(uint8_t cmd, uint8_t data)
{
    spi0_set_ss_level(0);
    spi0_master_write_bytes(&cmd, 1);
    spi0_master_write_bytes(&data, 1);
    spi0_set_ss_level(1);
}

uint8_t flash_w25q_send_cmd(uint8_t cmd)
{
    spi0_set_ss_level(0);
    spi0_master_write_bytes(&cmd, 1);
    spi0_set_ss_level(1);
}

void flash_w25q_volatile_status_reg_write_enable()
{
    flash_w25q_send_cmd(CMD_WRITE_ENABLE_FOR_VOL_STATUS_REG);
}

// 读flash ID
w25q_id_t flash_w25q_read_id()
{
    w25q_id_t id;
    uint8_t cmd;
    uint8_t data[2];
    uint8_t addr[3];

    cmd = CMD_READ_ID;
    addr[0] = 0x0;
    addr[1] = 0x0;
    addr[2] = 0x0;

    spi0_set_ss_level(0);
    spi0_master_write_bytes(&cmd, 1);
    spi0_master_write_bytes(addr, 3);
    spi0_master_read_bytes(data, 2);
    spi0_set_ss_level(1);

    id.manf_id = data[0];
    id.device_id = data[1];

    return id;
}

void flash_w25q_enable_qspi(uint8_t en)
{
    uint8_t data;

    flash_w25q_volatile_status_reg_write_enable();
    data = flash_w25q_read_reg(CMD_READ_STATUS_REG2);
    if (en)
        data |= 1 << 1;
    else
        data &= ~(1 << 1);
    flash_w25q_write_reg(CMD_WRITE_STATUS_REG2, data);
}

w25q_id_t flash_w25q_read_id_quad()
{
    w25q_id_t id;
    uint8_t cmd;
    uint8_t data[2];
    uint8_t addr[3];

    cmd = CMD_READ_ID_QUAD;
    addr[0] = 0x0;
    addr[1] = 0x0;
    addr[2] = 0x0;

    spi0_set_ss_level(0);
    spi0_master_write_bytes(&cmd, 1);
    spi0_set_spi_mode(SPI_MODE_QUAD);
    spi0_master_write_bytes(addr, 3);
    spi0_master_read_bytes(data, 2);
    spi0_master_read_bytes(data, 2);
    spi0_set_ss_level(1);

    id.manf_id = data[0];
    id.device_id = data[1];

    return id;
}
