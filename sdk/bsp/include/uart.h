#ifndef _UART_REG_DEFS_
#define _UART_REG_DEFS_

#ifdef __cplusplus
extern "C" {
#endif
// Register width
#define UART_PARAM_REG_WIDTH 32

#define UART0_BASE_ADDR      (0x05000000)
#define UART0_REG(offset)    (*((volatile uint32_t *)(UART0_BASE_ADDR + offset)))

#define UART1_BASE_ADDR      (0x09000000)
#define UART1_REG(offset)    (*((volatile uint32_t *)(UART1_BASE_ADDR + offset)))

#define UART2_BASE_ADDR      (0x0A000000)
#define UART2_REG(offset)    (*((volatile uint32_t *)(UART2_BASE_ADDR + offset)))

// UART control register
#define UART_CTRL_REG_OFFSET 0x0
#define UART_CTRL_REG_RESVAL 0xd90000
#define UART_CTRL_TX_EN_BIT 0
#define UART_CTRL_RX_EN_BIT 1
#define UART_CTRL_TX_FIFO_EMPTY_INT_EN_BIT 2
#define UART_CTRL_RX_FIFO_NOT_EMPTY_INT_EN_BIT 3
#define UART_CTRL_TX_FIFO_RST_BIT 4
#define UART_CTRL_RX_FIFO_RST_BIT 5
#define UART_CTRL_BAUD_DIV_MASK 0xffff
#define UART_CTRL_BAUD_DIV_OFFSET 16
#define UART_CTRL_BAUD_DIV_FIELD \
  ((bitfield_field32_t) { .mask = UART_CTRL_BAUD_DIV_MASK, .index = UART_CTRL_BAUD_DIV_OFFSET })

// UART status register
#define UART_STATUS_REG_OFFSET 0x4
#define UART_STATUS_REG_RESVAL 0x3c
#define UART_STATUS_TXFULL_BIT 0
#define UART_STATUS_RXFULL_BIT 1
#define UART_STATUS_TXEMPTY_BIT 2
#define UART_STATUS_RXEMPTY_BIT 3
#define UART_STATUS_TXIDLE_BIT 4
#define UART_STATUS_RXIDLE_BIT 5

// UART TX data register
#define UART_TXDATA_REG_OFFSET 0x8
#define UART_TXDATA_REG_RESVAL 0x0
#define UART_TXDATA_TXDATA_MASK 0xff
#define UART_TXDATA_TXDATA_OFFSET 0
#define UART_TXDATA_TXDATA_FIELD \
  ((bitfield_field32_t) { .mask = UART_TXDATA_TXDATA_MASK, .index = UART_TXDATA_TXDATA_OFFSET })

// UART RX data register
#define UART_RXDATA_REG_OFFSET 0xc
#define UART_RXDATA_REG_RESVAL 0x0
#define UART_RXDATA_RXDATA_MASK 0xff
#define UART_RXDATA_RXDATA_OFFSET 0
#define UART_RXDATA_RXDATA_FIELD \
  ((bitfield_field32_t) { .mask = UART_RXDATA_RXDATA_MASK, .index = UART_RXDATA_RXDATA_OFFSET })

typedef void (*myputc)(uint8_t);

void uart0_init(myputc putc);
uint8_t uart0_getc();
void uart0_putc(uint8_t c);

#ifdef __cplusplus
}  // extern "C"
#endif
#endif  // _UART_REG_DEFS_
