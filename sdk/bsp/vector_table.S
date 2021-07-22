#define REGBYTES  4
#define STORE     sw
#define LOAD      lw

    .section      .text.vector
    .align 2
    .global vector_table
vector_table:
    .org 0x00
    /* exception */
    jal x0, illegal_instruction_handler
    jal x0, instruction_addr_misaligned_handler
    jal x0, ecall_handler
    jal x0, ebreak_handler
    jal x0, load_misaligned_handler
    jal x0, store_misaligned_handler
    jal x0, handle_exception_unknown
    jal x0, handle_exception_unknown
    /* interrupt */
    jal x0, irqs_handler

irqs_vector_table:
    .word timer_irq_handler
    /* add your ISR here */

.weak illegal_instruction_handler
.weak instruction_addr_misaligned_handler
.weak ecall_handler
.weak ebreak_handler
.weak load_misaligned_handler
.weak store_misaligned_handler
.weak handle_exception_unknown
.weak timer_irq_handler

handle_exception_unknown:
    j handle_exception_unknown

illegal_instruction_handler:
#ifdef SIMULATION
    call sim_ctrl_init
    la a0, illegal_instruction_msg
    jal ra, xputs
#endif
illegal_instruction_loop:
    j illegal_instruction_loop

instruction_addr_misaligned_handler:
    j instruction_addr_misaligned_handler

ecall_handler:
    j ecall_handler

ebreak_handler:
    j ebreak_handler

load_misaligned_handler:
    j load_misaligned_handler

store_misaligned_handler:
    j store_misaligned_handler

timer_irq_handler:
    j timer_irq_handler

irqs_handler:
    addi sp, sp, -32*17
    sw x1,   0*4(sp)
    sw x5,   1*4(sp)
	sw x6,   2*4(sp)
	sw x7,   3*4(sp)
	sw x10,  4*4(sp)
	sw x11,  5*4(sp)
	sw x12,  6*4(sp)
	sw x13,  7*4(sp)
	sw x14,  8*4(sp)
	sw x15,  9*4(sp)
	sw x16, 10*4(sp)
	sw x17, 11*4(sp)
	sw x28, 12*4(sp)
	sw x29, 13*4(sp)
	sw x30, 14*4(sp)
	sw x31, 15*4(sp)
    csrr a0, mepc
    sw a0, 16*4(sp)

    /* 使能全局中断 */
    csrrsi x0, mstatus, 0x8

    /* 读取中断号 */
    csrr a1, mcause
    /* 计算偏移地址: id * 4 */
    slli a1, a1, 2
    la a0, irqs_vector_table
    add a1, a0, a1
    /* 读取中断处理函数地址 */
    lw a1, 0(a1)
    /* 跳转到中断处理函数 */
    jalr ra, 0(a1)

    lw a0,  16*4(sp)
    csrw mepc, a0
    lw x1,   0*4(sp)
	lw x5,   1*4(sp)
	lw x6,   2*4(sp)
	lw x7,   3*4(sp)
	lw x10,  4*4(sp)
	lw x11,  5*4(sp)
	lw x12,  6*4(sp)
	lw x13,  7*4(sp)
	lw x14,  8*4(sp)
	lw x15,  9*4(sp)
	lw x16, 10*4(sp)
	lw x17, 11*4(sp)
	lw x28, 12*4(sp)
	lw x29, 13*4(sp)
	lw x30, 14*4(sp)
	lw x31, 15*4(sp)
    addi sp, sp, 32*17
    mret

.section .rodata
illegal_instruction_msg:
	.string "illegal instruction exception handler entered\n"
