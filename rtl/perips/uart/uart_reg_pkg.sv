// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Register Package auto-generated by `reggen` containing data structure

package uart_reg_pkg;

  // Address widths within the block
  parameter int BlockAw = 4;

  ////////////////////////////
  // Typedefs for registers //
  ////////////////////////////

  typedef struct packed {
    struct packed {
      logic        q;
      logic        qe;
    } tx_en;
    struct packed {
      logic        q;
      logic        qe;
    } rx_en;
    struct packed {
      logic        q;
      logic        qe;
    } tx_fifo_empty_int_en;
    struct packed {
      logic        q;
      logic        qe;
    } rx_fifo_not_empty_int_en;
    struct packed {
      logic        q;
      logic        qe;
    } tx_fifo_rst;
    struct packed {
      logic        q;
      logic        qe;
    } rx_fifo_rst;
    struct packed {
      logic [15:0] q;
      logic        qe;
    } baud_div;
  } uart_reg2hw_ctrl_reg_t;

  typedef struct packed {
    struct packed {
      logic        q;
      logic        re;
    } txfull;
    struct packed {
      logic        q;
      logic        re;
    } rxfull;
    struct packed {
      logic        q;
      logic        re;
    } txempty;
    struct packed {
      logic        q;
      logic        re;
    } rxempty;
    struct packed {
      logic        q;
      logic        re;
    } txidle;
    struct packed {
      logic        q;
      logic        re;
    } rxidle;
  } uart_reg2hw_status_reg_t;

  typedef struct packed {
    logic [7:0]  q;
    logic        qe;
  } uart_reg2hw_txdata_reg_t;

  typedef struct packed {
    logic [7:0]  q;
    logic        re;
  } uart_reg2hw_rxdata_reg_t;

  typedef struct packed {
    struct packed {
      logic        d;
    } txfull;
    struct packed {
      logic        d;
    } rxfull;
    struct packed {
      logic        d;
    } txempty;
    struct packed {
      logic        d;
    } rxempty;
    struct packed {
      logic        d;
    } txidle;
    struct packed {
      logic        d;
    } rxidle;
  } uart_hw2reg_status_reg_t;

  typedef struct packed {
    logic [7:0]  d;
  } uart_hw2reg_rxdata_reg_t;

  // Register -> HW type
  typedef struct packed {
    uart_reg2hw_ctrl_reg_t ctrl; // [58:30]
    uart_reg2hw_status_reg_t status; // [29:18]
    uart_reg2hw_txdata_reg_t txdata; // [17:9]
    uart_reg2hw_rxdata_reg_t rxdata; // [8:0]
  } uart_reg2hw_t;

  // HW -> register type
  typedef struct packed {
    uart_hw2reg_status_reg_t status; // [13:8]
    uart_hw2reg_rxdata_reg_t rxdata; // [7:0]
  } uart_hw2reg_t;

  // Register offsets
  parameter logic [BlockAw-1:0] UART_CTRL_OFFSET = 4'h0;
  parameter logic [BlockAw-1:0] UART_STATUS_OFFSET = 4'h4;
  parameter logic [BlockAw-1:0] UART_TXDATA_OFFSET = 4'h8;
  parameter logic [BlockAw-1:0] UART_RXDATA_OFFSET = 4'hc;

  // Reset values for hwext registers and their fields
  parameter logic [5:0] UART_STATUS_RESVAL = 6'h3c;
  parameter logic [0:0] UART_STATUS_TXEMPTY_RESVAL = 1'h1;
  parameter logic [0:0] UART_STATUS_RXEMPTY_RESVAL = 1'h1;
  parameter logic [0:0] UART_STATUS_TXIDLE_RESVAL = 1'h1;
  parameter logic [0:0] UART_STATUS_RXIDLE_RESVAL = 1'h1;
  parameter logic [7:0] UART_RXDATA_RESVAL = 8'h0;

  // Register index
  typedef enum int {
    UART_CTRL,
    UART_STATUS,
    UART_TXDATA,
    UART_RXDATA
  } uart_id_e;

  // Register width information to check illegal writes
  parameter logic [3:0] UART_PERMIT [4] = '{
    4'b1111, // index[0] UART_CTRL
    4'b0001, // index[1] UART_STATUS
    4'b0001, // index[2] UART_TXDATA
    4'b0001  // index[3] UART_RXDATA
  };

endpackage

