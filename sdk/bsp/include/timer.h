// Generated register defines for timer

// Copyright information found in source file:
// Copyright lowRISC contributors.

// Licensing information found in source file:
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef _TIMER_REG_DEFS_
#define _TIMER_REG_DEFS_

#ifdef __cplusplus
extern "C" {
#endif
// Register width
#define TIMER_PARAM_REG_WIDTH 32

#define TIMER0_BASE_ADDR      (0x40000000)
#define TIMER0_REG(offset)    (*((volatile uint32_t *)(TIMER0_BASE_ADDR + offset)))

// Timer control register
#define TIMER_CTRL_REG_OFFSET 0x0
#define TIMER_CTRL_REG_RESVAL 0x0
#define TIMER_CTRL_EN_BIT 0
#define TIMER_CTRL_INT_EN_BIT 1
#define TIMER_CTRL_INT_PENDING_BIT 2
#define TIMER_CTRL_MODE_BIT 3
#define TIMER_CTRL_CLK_DIV_MASK 0xffffff
#define TIMER_CTRL_CLK_DIV_OFFSET 8
#define TIMER_CTRL_CLK_DIV_FIELD \
  ((bitfield_field32_t) { .mask = TIMER_CTRL_CLK_DIV_MASK, .index = TIMER_CTRL_CLK_DIV_OFFSET })

// Timer expired value register
#define TIMER_VALUE_REG_OFFSET 0x4
#define TIMER_VALUE_REG_RESVAL 0x0

// Timer current count register
#define TIMER_COUNT_REG_OFFSET 0x8
#define TIMER_COUNT_REG_RESVAL 0x0

void timer0_start(uint8_t en);
void timer0_set_value(uint32_t val);
void timer0_set_int_enable(uint8_t en);
void timer0_clear_int_pending();
uint8_t timer0_get_int_pending();
uint32_t timer0_get_current_count();
void timer0_set_mode_auto_reload();
void timer0_set_mode_ontshot();
void timer0_set_div(uint32_t div);

#ifdef __cplusplus
}  // extern "C"
#endif
#endif  // _TIMER_REG_DEFS_
// End generated register defines for timer