#include <stdint.h>

#include "flash_ctrl.h"


// 烧写数据地址：4K + 1K + 256
#define DATA_ADDR    (0x20001500)

// 烧写数据长度
#define DATA_LEN     (0x20001400)

// 烧写(擦除)地址
#define PROGRAM_ADDR (0x20001404)

// 擦除标志
// 0: 不擦除，1：擦除
#define ERASE_FLAG   (0x20001408)

// 烧写状态标志
// bit0为烧写结束标志，0：未烧写完成，1：烧写完成。
// bit1为烧写结果标志，0：烧写失败，1：烧写成功
#define RESULT_FLAG  (0x2000140C)

#define PAGE_SIZE    (256)


static uint32_t *data_p;
static uint32_t *result_p;
static uint32_t len, addr;
static uint32_t erase;
static uint8_t succ;

int main()
{
    data_p = (uint32_t *)DATA_ADDR;
    result_p = (uint32_t *)RESULT_FLAG;
    len = *((uint32_t *)DATA_LEN);
    addr = *((uint32_t *)PROGRAM_ADDR);
    erase = *((uint32_t *)ERASE_FLAG);

    *result_p = 0;

    flash_ctrl_init();

    // 擦除操作
    if (erase) {
        // 擦除子扇区
        succ = flash_ctrl_sector_erase(addr);
    // 编程操作
    } else {
        // 编程
        succ = flash_ctrl_page_program(addr, data_p, len);
    }

    flash_ctrl_deinit();

    if (succ)
        *result_p = 0x3;
    else
        *result_p = 0x1;

    while (1);
}
