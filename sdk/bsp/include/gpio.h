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

#define GPIO_BASE_ADDR      (0x30000000)
#define GPIO_REG(offset)    (*((volatile uint32_t *)(GPIO_BASE_ADDR + offset)))

typedef enum {
    GPIO_MODE_NONE = 0,
    GPIO_MODE_INPUT,
    GPIO_MODE_OUTPUT,
} gpio_mode_e;

typedef enum {
    GPIO_INTR_NONE = 0,
    GPIO_INTR_RAISING_EDGE,
    GPIO_INTR_FALLING_EDGE,
    GPIO_INTR_DOUBLE_EDGE,
} gpio_intr_mode_e;

typedef enum {
    GPIO0 = 0,
    GPIO1,
    GPIO2,
    GPIO3,
    GPIO4,
    GPIO5,
    GPIO6,
    GPIO7,
} gpio_e;

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

void gpio_set_mode(gpio_e gpio, gpio_mode_e mode);
uint8_t gpio_get_input_data(gpio_e gpio);
void gpio_set_output_data(gpio_e gpio, uint8_t data);
void gpio_set_output_toggle(gpio_e gpio);
void gpio_set_input_filter_enable(gpio_e gpio, uint8_t en);
void gpio_set_interrupt_mode(gpio_e gpio, gpio_intr_mode_e mode);
void gpio_clear_intr_pending(gpio_e gpio);
uint8_t gpio_get_intr_pending(gpio_e gpio);

#ifdef __cplusplus
}  // extern "C"
#endif
#endif  // _GPIO_REG_DEFS_
// End generated register defines for gpio