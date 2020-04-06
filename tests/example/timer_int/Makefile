
include ../common.mk


.PHONY: all
all:
	$(RISCV_GCC) $(CFLAGS) ../start.S main.c -T ../link.lds -o timer_int
	$(RISCV_OBJCOPY) -O binary timer_int timer_int.bin
	$(RISCV_OBJDUMP) --disassemble-all timer_int > timer_int.dump
