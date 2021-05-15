#ifndef _GPIO_H_
#define _GPIO_H_

#define GPIO_BASE      (0x30000000)
#define GPIO_CTRL      (GPIO_BASE + (0x00))
#define GPIO_DATA      (GPIO_BASE + (0x04))

#define GPIO_REG(addr) (*((volatile uint32_t *)addr))


#define GPIO0   (0)
#define GPIO1   (1)

#define GPIO_OUTPUT     (1)
#define GPIO_INPUT      (2)

void gpio_output_enable(uint8_t gpio);
void gpio_input_enable(uint8_t gpio);
uint8_t gpio_get_data(uint8_t gpio);
void gpio_set_data(uint8_t gpio, uint8_t data);
void gpio_data_toggle(uint8_t gpio);

#endif
