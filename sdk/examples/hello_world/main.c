#include <stdint.h>
#include "../../bsp/include/sim_ctrl.h"
#include "../../bsp/include/xprintf.h"




int main()
{
    sim_ctrl_init();

    xprintf("hello world\n");

    while (1);
}
