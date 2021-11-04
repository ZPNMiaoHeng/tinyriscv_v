// Generated register defines for flash_ctrl

// Copyright information found in source file:
// Copyright lowRISC contributors.

// Licensing information found in source file:
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef _FLASH_CTRL_REG_DEFS_
#define _FLASH_CTRL_REG_DEFS_

#ifdef __cplusplus
extern "C" {
#endif
// Register width
#define FLASH_CTRL_PARAM_REG_WIDTH 32

#define FLASH_CTRL_BASE_ADDR      (0x0E000000)
#define FLASH_CTRL_REG(offset)    (*((volatile uint32_t *)(FLASH_CTRL_BASE_ADDR + offset)))

typedef enum {
    FLASH_OP_READ = 0,
    FLASH_OP_PROGRAM,
    FLASH_OP_ERASE,
    FLASH_OP_INIT
} flash_op_mode_e;

void flash_ctrl_init();
void flash_ctrl_deinit();
void flash_ctrl_qspi_init();
void flash_ctrl_read(uint32_t start_addr, uint32_t *data, uint32_t len);
uint8_t flash_ctrl_page_program(uint32_t page_addr, uint32_t *data, uint32_t len);
uint8_t flash_ctrl_sector_erase(uint32_t sector_addr);

// flash_ctrl control register
#define FLASH_CTRL_CTRL_REG_OFFSET 0x0
#define FLASH_CTRL_CTRL_REG_RESVAL 0x0
#define FLASH_CTRL_CTRL_START_BIT 0
#define FLASH_CTRL_CTRL_OP_MODE_MASK 0x3
#define FLASH_CTRL_CTRL_OP_MODE_OFFSET 1
#define FLASH_CTRL_CTRL_OP_MODE_FIELD \
  ((bitfield_field32_t) { .mask = FLASH_CTRL_CTRL_OP_MODE_MASK, .index = FLASH_CTRL_CTRL_OP_MODE_OFFSET })
#define FLASH_CTRL_CTRL_SW_CTRL_BIT 3
#define FLASH_CTRL_CTRL_PROGRAM_INIT_BIT 4
#define FLASH_CTRL_CTRL_WRITE_ERROR_BIT 5
#define FLASH_CTRL_CTRL_RESERVED_MASK 0x3ffffff
#define FLASH_CTRL_CTRL_RESERVED_OFFSET 6
#define FLASH_CTRL_CTRL_RESERVED_FIELD \
  ((bitfield_field32_t) { .mask = FLASH_CTRL_CTRL_RESERVED_MASK, .index = FLASH_CTRL_CTRL_RESERVED_OFFSET })

// flash_ctrl address register
#define FLASH_CTRL_ADDR_REG_OFFSET 0x4
#define FLASH_CTRL_ADDR_REG_RESVAL 0x0
#define FLASH_CTRL_ADDR_RW_ADDRESS_MASK 0x7fffff
#define FLASH_CTRL_ADDR_RW_ADDRESS_OFFSET 0
#define FLASH_CTRL_ADDR_RW_ADDRESS_FIELD \
  ((bitfield_field32_t) { .mask = FLASH_CTRL_ADDR_RW_ADDRESS_MASK, .index = FLASH_CTRL_ADDR_RW_ADDRESS_OFFSET })
#define FLASH_CTRL_ADDR_RESERVED_MASK 0x1ff
#define FLASH_CTRL_ADDR_RESERVED_OFFSET 23
#define FLASH_CTRL_ADDR_RESERVED_FIELD \
  ((bitfield_field32_t) { .mask = FLASH_CTRL_ADDR_RESERVED_MASK, .index = FLASH_CTRL_ADDR_RESERVED_OFFSET })

// flash_ctrl data register
#define FLASH_CTRL_DATA_REG_OFFSET 0x8
#define FLASH_CTRL_DATA_REG_RESVAL 0x0

#ifdef __cplusplus
}  // extern "C"
#endif
#endif  // _FLASH_CTRL_REG_DEFS_
// End generated register defines for flash_ctrl