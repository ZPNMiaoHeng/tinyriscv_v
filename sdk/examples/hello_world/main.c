#include <stdint.h>

#include "../../bsp/include/sim_ctrl.h"
#include "../../bsp/include/uart.h"
#include "../../bsp/include/xprintf.h"



int main()
{
#ifdef SIMULATION
    sim_ctrl_init();
#else
    uart_init();
#endif

    xprintf("hello world\n");

    while (1);
}