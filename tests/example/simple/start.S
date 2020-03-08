    .section .text;
    .align  2;
    .globl _start;

    .weak  TIMER_IRQHandler


_start:
    j _reset_handler
    j _timer_handler

_reset_handler:
    la sp, _sp
    li x26, 0x00
    li x27, 0x00

    call main

    li x26, 0x01

loop:
    j loop

_timer_handler:
    call TIMER_IRQHandler
    ret
