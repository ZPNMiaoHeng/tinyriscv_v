RISCV_ARCH := rv32im
RISCV_ABI := ilp32
RISCV_MCMODEL := medlow


TARGET = simple


CFLAGS += -DSIMULATION
CFLAGS += -g
#CFLAGS += -O2
#ASM_SRCS +=
#LDFLAGS +=
#INCLUDES += -I.

C_SRCS := \
	main.c \


BSP_DIR = ../../bsp
include ../../bsp/bsp.mk
