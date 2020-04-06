
include ../common.mk


.PHONY: all
all:
	$(RISCV_GCC) $(CFLAGS) ../start.S main.c xprintf.c -T ../link.lds -o uart_tx
	$(RISCV_OBJCOPY) -O binary uart_tx uart_tx.bin
	$(RISCV_OBJDUMP) --disassemble-all uart_tx > uart_tx.dump
