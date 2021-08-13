// Generated register defines for gpio

// Copyright information found in source file:
// Copyright lowRISC contributors.

// Licensing information found in source file:
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef _GPIO_REG_DEFS_
#define _GPIO_REG_DEFS_

#ifdef __cplusplus
extern "C" {
#endif
// Register width
#define GPIO_PARAM_REG_WIDTH 32

// gpio mode register
#define GPIO_MODE_REG_OFFSET 0x0
#define GPIO_MODE_REG_RESVAL 0x0
#define GPIO_MODE_GPIO_MASK 0xffff
#define GPIO_MODE_GPIO_OFFSET 0
#define GPIO_MODE_GPIO_FIELD \
  ((bitfield_field32_t) { .mask = GPIO_MODE_GPIO_MASK, .index = GPIO_MODE_GPIO_OFFSET })

// gpio interrupt register
#define GPIO_INTR_REG_OFFSET 0x4
#define GPIO_INTR_REG_RESVAL 0x0
#define GPIO_INTR_GPIO_INT_MASK 0xffff
#define GPIO_INTR_GPIO_INT_OFFSET 0
#define GPIO_INTR_GPIO_INT_FIELD \
  ((bitfield_field32_t) { .mask = GPIO_INTR_GPIO_INT_MASK, .index = GPIO_INTR_GPIO_INT_OFFSET })
#define GPIO_INTR_GPIO_PENDING_MASK 0xff
#define GPIO_INTR_GPIO_PENDING_OFFSET 16
#define GPIO_INTR_GPIO_PENDING_FIELD \
  ((bitfield_field32_t) { .mask = GPIO_INTR_GPIO_PENDING_MASK, .index = GPIO_INTR_GPIO_PENDING_OFFSET })

// gpio data register
#define GPIO_DATA_REG_OFFSET 0x8
#define GPIO_DATA_REG_RESVAL 0x0
#define GPIO_DATA_GPIO_MASK 0xff
#define GPIO_DATA_GPIO_OFFSET 0
#define GPIO_DATA_GPIO_FIELD \
  ((bitfield_field32_t) { .mask = GPIO_DATA_GPIO_MASK, .index = GPIO_DATA_GPIO_OFFSET })

// gpio input filter enable register
#define GPIO_FILTER_REG_OFFSET 0xc
#define GPIO_FILTER_REG_RESVAL 0x0
#define GPIO_FILTER_GPIO_MASK 0xff
#define GPIO_FILTER_GPIO_OFFSET 0
#define GPIO_FILTER_GPIO_FIELD \
  ((bitfield_field32_t) { .mask = GPIO_FILTER_GPIO_MASK, .index = GPIO_FILTER_GPIO_OFFSET })

#ifdef __cplusplus
}  // extern "C"
#endif
#endif  // _GPIO_REG_DEFS_
// End generated register defines for gpio