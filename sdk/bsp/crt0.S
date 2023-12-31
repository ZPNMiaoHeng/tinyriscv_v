    .section .init;
    .globl _start;
    .type _start,@function


_start:
.option push
.option norelax
	la gp, __global_pointer$
.option pop
	la sp, _sp
#ifdef SIMULATION
    /* clear sim result flags */
    csrrwi x0, sstatus, 0x0
#endif

	/* Load data section */
	la a0, _data_lma
	la a1, _data
	la a2, _edata
	bgeu a1, a2, 2f
1:
	lw t0, (a0)
	sw t0, (a1)
	addi a0, a0, 4
	addi a1, a1, 4
	bltu a1, a2, 1b
2:

	/* Clear bss section */
	la a0, __bss_start
	la a1, _end
	bgeu a0, a1, 2f
1:
	sw zero, (a0)
	addi a0, a0, 4
	bltu a0, a1, 1b
2:

    /* set exception and interrupt entry */
    la a0, trap_entry
    csrw mtvec, a0

    li a0, 0
    li a1, 0
    call main

loop:
    j loop
