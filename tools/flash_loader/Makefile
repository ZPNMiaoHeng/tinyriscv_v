TARGET := flash_loader

BSP_DIR := ../../sdk/bsp

RISCV_TOOLS_PATH := /opt/riscv32/bin
RISCV_TOOLS_PREFIX := riscv32-unknown-elf-

RISCV_GCC     := $(abspath $(RISCV_TOOLS_PATH)/$(RISCV_TOOLS_PREFIX)gcc)
RISCV_AS      := $(abspath $(RISCV_TOOLS_PATH)/$(RISCV_TOOLS_PREFIX)as)
RISCV_GXX     := $(abspath $(RISCV_TOOLS_PATH)/$(RISCV_TOOLS_PREFIX)g++)
RISCV_OBJDUMP := $(abspath $(RISCV_TOOLS_PATH)/$(RISCV_TOOLS_PREFIX)objdump)
RISCV_GDB     := $(abspath $(RISCV_TOOLS_PATH)/$(RISCV_TOOLS_PREFIX)gdb)
RISCV_AR      := $(abspath $(RISCV_TOOLS_PATH)/$(RISCV_TOOLS_PREFIX)ar)
RISCV_OBJCOPY := $(abspath $(RISCV_TOOLS_PATH)/$(RISCV_TOOLS_PREFIX)objcopy)
RISCV_READELF := $(abspath $(RISCV_TOOLS_PATH)/$(RISCV_TOOLS_PREFIX)readelf)


.PHONY: all
all: $(TARGET)

ASM_SRCS += start.S

C_SRCS += main.c
C_SRCS += $(BSP_DIR)/lib/flash_ctrl.c

LINKER_SCRIPT := link.ld

INCLUDES += -I$(BSP_DIR)/include

LDFLAGS += -Os -T $(LINKER_SCRIPT) -nostartfiles -Wl,--gc-sections -Wl,--check-sections

ASM_OBJS := $(ASM_SRCS:.S=.o)
C_OBJS := $(C_SRCS:.c=.o)

LINK_OBJS += $(ASM_OBJS) $(C_OBJS)
LINK_DEPS += $(LINKER_SCRIPT)

CLEAN_OBJS += $(TARGET) $(LINK_OBJS) $(TARGET).dump $(TARGET).bin $(TARGET).hex $(TARGET).mem tinyriscv.inc

CFLAGS += -march=rv32im
CFLAGS += -mabi=ilp32
CFLAGS += -mcmodel=medlow -ffunction-sections -fdata-sections -fno-builtin-printf -fno-builtin-malloc

$(TARGET): $(LINK_OBJS) $(LINK_DEPS) Makefile
	$(RISCV_GCC) $(CFLAGS) $(INCLUDES) $(LINK_OBJS) -o $@ $(LDFLAGS)
	$(RISCV_OBJCOPY) -O binary $@ $@.bin
	$(RISCV_OBJDUMP) --disassemble-all $@ > $@.dump
	./bin2char.sh < flash_loader.bin > tinyriscv.inc

$(ASM_OBJS): %.o: %.S
	$(RISCV_GCC) $(CFLAGS) $(INCLUDES) -c -o $@ $<

$(C_OBJS): %.o: %.c
	$(RISCV_GCC) $(CFLAGS) $(INCLUDES) -c -o $@ $<

.PHONY: clean
clean:
	rm -f $(CLEAN_OBJS)
