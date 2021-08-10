#include <stdint.h>

#include "../../bsp/include/uart.h"
#include "../../bsp/include/xprintf.h"



int main()
{
    uart0_init(uart0_putc);

    while (1) {
        // loopback
        xprintf("%c", uart0_getc());
    }
}
