
    .section      .text.vector
    .align 2
    .global vector_table
vector_table:
    .org 0x00
    jal x0, illegal_instruction_handler
    jal x0, instruction_addr_misaligned_handler
    jal x0, ecall_handler
    jal x0, ebreak_handler
    jal x0, load_misaligned_handler
    jal x0, store_misaligned_handler
    jal x0, handle_exception_unknown
    jal x0, handle_exception_unknown
    jal x0, external_irq_handler
    jal x0, software_irq_handler
    jal x0, timer_irq_handler
    jal x0, fast_irq0_handler
    jal x0, fast_irq1_handler
    jal x0, fast_irq2_handler
    jal x0, fast_irq3_handler
    jal x0, fast_irq4_handler
    .rept 10
    jal x0, fast_irq_handler
    .endr


.weak illegal_instruction_handler
.weak instruction_addr_misaligned_handler
.weak ecall_handler
.weak ebreak_handler
.weak load_misaligned_handler
.weak store_misaligned_handler
.weak handle_exception_unknown
.weak external_irq_handler
.weak software_irq_handler
.weak timer_irq_handler
.weak fast_irq0_handler
.weak fast_irq1_handler
.weak fast_irq2_handler
.weak fast_irq3_handler
.weak fast_irq4_handler
.weak fast_irq_handler

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

external_irq_handler:
    j external_irq_handler

software_irq_handler:
    j software_irq_handler

timer_irq_handler:
    j timer_irq_handler

fast_irq0_handler:
    j fast_irq0_handler

fast_irq1_handler:
    j fast_irq1_handler

fast_irq2_handler:
    j fast_irq2_handler

fast_irq3_handler:
    j fast_irq3_handler

fast_irq4_handler:
    j fast_irq4_handler

fast_irq_handler:
    j fast_irq_handler

.section .rodata
illegal_instruction_msg:
	.string "illegal instruction exception handler entered\n"
