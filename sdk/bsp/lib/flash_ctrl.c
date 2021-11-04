#include <stdint.h>

#include "../../bsp/include/flash_ctrl.h"
#include "../../bsp/include/utils.h"


void flash_ctrl_init()
{
    FLASH_CTRL_REG(FLASH_CTRL_CTRL_REG_OFFSET) |= 1 << FLASH_CTRL_CTRL_SW_CTRL_BIT;
}

void flash_ctrl_deinit()
{
    FLASH_CTRL_REG(FLASH_CTRL_CTRL_REG_OFFSET) &= ~(1 << FLASH_CTRL_CTRL_SW_CTRL_BIT);
}

// 初始化flash为QSPI模式
void flash_ctrl_qspi_init()
{
    FLASH_CTRL_REG(FLASH_CTRL_CTRL_REG_OFFSET) &= ~(FLASH_CTRL_CTRL_OP_MODE_MASK << FLASH_CTRL_CTRL_OP_MODE_OFFSET);
    FLASH_CTRL_REG(FLASH_CTRL_CTRL_REG_OFFSET) |= (FLASH_OP_INIT << FLASH_CTRL_CTRL_OP_MODE_OFFSET);

    FLASH_CTRL_REG(FLASH_CTRL_CTRL_REG_OFFSET) |=  1 << FLASH_CTRL_CTRL_START_BIT;
    while (FLASH_CTRL_REG(FLASH_CTRL_CTRL_REG_OFFSET) & (1 << FLASH_CTRL_CTRL_START_BIT));
}

static void flash_ctrl_program_init()
{
    FLASH_CTRL_REG(FLASH_CTRL_CTRL_REG_OFFSET) |= 1 << FLASH_CTRL_CTRL_PROGRAM_INIT_BIT;
}

static void flash_ctrl_program_deinit()
{
    FLASH_CTRL_REG(FLASH_CTRL_CTRL_REG_OFFSET) &= ~(1 << FLASH_CTRL_CTRL_PROGRAM_INIT_BIT);
}

// 读数据
void flash_ctrl_read(uint32_t start_addr, uint32_t *data, uint32_t len)
{
    uint32_t addr, i;

    FLASH_CTRL_REG(FLASH_CTRL_CTRL_REG_OFFSET) &= ~(FLASH_CTRL_CTRL_OP_MODE_MASK << FLASH_CTRL_CTRL_OP_MODE_OFFSET);
    FLASH_CTRL_REG(FLASH_CTRL_CTRL_REG_OFFSET) |= (FLASH_OP_READ << FLASH_CTRL_CTRL_OP_MODE_OFFSET);

    addr = start_addr;
    len = len >> 2;

    for (i = 0; i < len; i++) {
        FLASH_CTRL_REG(FLASH_CTRL_ADDR_REG_OFFSET) = addr & FLASH_CTRL_ADDR_RW_ADDRESS_MASK;
        FLASH_CTRL_REG(FLASH_CTRL_CTRL_REG_OFFSET) |=  1 << FLASH_CTRL_CTRL_START_BIT;
        while (FLASH_CTRL_REG(FLASH_CTRL_CTRL_REG_OFFSET) & (1 << FLASH_CTRL_CTRL_START_BIT));
        data[i] = FLASH_CTRL_REG(FLASH_CTRL_DATA_REG_OFFSET);
        addr += 4;
    }
}

// 以word为单位进行烧写，一次最多烧一个page(256个字节)
// 返回值，1：成功，0：失败
uint8_t flash_ctrl_page_program(uint32_t page_addr, uint32_t *data, uint32_t len)
{
    uint32_t i, index;
    uint32_t prog_len, remain_len;

    FLASH_CTRL_REG(FLASH_CTRL_CTRL_REG_OFFSET) &= ~(FLASH_CTRL_CTRL_OP_MODE_MASK << FLASH_CTRL_CTRL_OP_MODE_OFFSET);
    FLASH_CTRL_REG(FLASH_CTRL_CTRL_REG_OFFSET) |= (FLASH_OP_PROGRAM << FLASH_CTRL_CTRL_OP_MODE_OFFSET);

    FLASH_CTRL_REG(FLASH_CTRL_ADDR_REG_OFFSET) = page_addr & FLASH_CTRL_ADDR_RW_ADDRESS_MASK;

    if (len > 4)
        flash_ctrl_program_init();

    remain_len = len;
    index = 0;

    while (remain_len > 0) {
        // 一次最多烧32个byte
        if (remain_len > 32)
            prog_len = 32;
        else
            prog_len = remain_len;

        remain_len -= prog_len;
        // word的个数
        prog_len = prog_len >> 2;

        // 每次烧写一个word
        for (i = 0; i < prog_len; i++) {
            FLASH_CTRL_REG(FLASH_CTRL_DATA_REG_OFFSET) = data[index];
            FLASH_CTRL_REG(FLASH_CTRL_CTRL_REG_OFFSET) |=  1 << FLASH_CTRL_CTRL_START_BIT;
            while (FLASH_CTRL_REG(FLASH_CTRL_CTRL_REG_OFFSET) & (1 << FLASH_CTRL_CTRL_START_BIT));
            index++;
        }
    }

    if (len > 4) {
        flash_ctrl_program_deinit();
        while (FLASH_CTRL_REG(FLASH_CTRL_CTRL_REG_OFFSET) & (1 << FLASH_CTRL_CTRL_START_BIT));
    }

    if (FLASH_CTRL_REG(FLASH_CTRL_CTRL_REG_OFFSET) & (1 << FLASH_CTRL_CTRL_WRITE_ERROR_BIT))
        return 0;
    else
        return 1;
}

// 扇区擦除
// 返回值，1：成功，0：失败
uint8_t flash_ctrl_sector_erase(uint32_t sector_addr)
{
    FLASH_CTRL_REG(FLASH_CTRL_CTRL_REG_OFFSET) &= ~(FLASH_CTRL_CTRL_OP_MODE_MASK << FLASH_CTRL_CTRL_OP_MODE_OFFSET);
    FLASH_CTRL_REG(FLASH_CTRL_CTRL_REG_OFFSET) |= (FLASH_OP_ERASE << FLASH_CTRL_CTRL_OP_MODE_OFFSET);

    FLASH_CTRL_REG(FLASH_CTRL_ADDR_REG_OFFSET) = sector_addr & FLASH_CTRL_ADDR_RW_ADDRESS_MASK;

    FLASH_CTRL_REG(FLASH_CTRL_CTRL_REG_OFFSET) |=  1 << FLASH_CTRL_CTRL_START_BIT;
    while (FLASH_CTRL_REG(FLASH_CTRL_CTRL_REG_OFFSET) & (1 << FLASH_CTRL_CTRL_START_BIT));

    if (FLASH_CTRL_REG(FLASH_CTRL_CTRL_REG_OFFSET) & (1 << FLASH_CTRL_CTRL_WRITE_ERROR_BIT))
        return 0;
    else
        return 1;
}
