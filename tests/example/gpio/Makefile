
include ../common.mk


.PHONY: all
all:
	$(RISCV_GCC) $(CFLAGS) ../start.S main.c -T ../link.lds -o gpio
	$(RISCV_OBJCOPY) -O binary gpio gpio.bin
	$(RISCV_OBJDUMP) --disassemble-all gpio > gpio.dump
