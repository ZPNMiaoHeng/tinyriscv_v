#include <stdint.h>

#include "../../bsp/include/uart.h"
#include "../../bsp/include/xprintf.h"



int main()
{
    uart_init();

    while (1) {
        // loopback
        xprintf("%c", uart_getc());
    }
}
