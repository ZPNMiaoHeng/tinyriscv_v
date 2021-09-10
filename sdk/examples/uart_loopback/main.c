#include <stdint.h>

#include "../../bsp/include/uart.h"
#include "../../bsp/include/xprintf.h"
#include "../../bsp/include/pinmux.h"


int main()
{
    uart0_init(uart0_putc);
    pinmux_set_io0_func(IO0_UART0_TX);
    pinmux_set_io3_func(IO3_UART0_RX);

    while (1) {
        // loopback
        xprintf("%c", uart0_getc());
    }
}
