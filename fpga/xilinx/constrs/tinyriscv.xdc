# 时钟约束50MHz
set_property -dict { PACKAGE_PIN N14 IOSTANDARD LVCMOS33 } [get_ports {clk}]; 
create_clock -add -name sys_clk_pin -period 20.00 -waveform {0 10} [get_ports {clk}];

# 时钟引脚
set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property PACKAGE_PIN N14 [get_ports clk]

# 复位引脚
set_property IOSTANDARD LVCMOS33 [get_ports rst_ext_ni]
set_property PACKAGE_PIN L13 [get_ports rst_ext_ni]

# CPU停住指示引脚
set_property IOSTANDARD LVCMOS33 [get_ports halted_ind_pin]
set_property PACKAGE_PIN P15 [get_ports halted_ind_pin]

# 串口发送引脚
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx_pin]
set_property PACKAGE_PIN M6 [get_ports uart_tx_pin]

# 串口接收引脚
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx_pin]
set_property PACKAGE_PIN N6 [get_ports uart_rx_pin]

# GPIO0引脚
set_property IOSTANDARD LVCMOS33 [get_ports {gpio_pins[0]}]
set_property PACKAGE_PIN P16 [get_ports {gpio_pins[0]}]

# GPIO1引脚
set_property IOSTANDARD LVCMOS33 [get_ports {gpio_pins[1]}]
set_property PACKAGE_PIN T15 [get_ports {gpio_pins[1]}]

# JTAG TCK引脚
set_property IOSTANDARD LVCMOS33 [get_ports jtag_TCK_pin]
set_property PACKAGE_PIN N11 [get_ports jtag_TCK_pin]

#create_clock -name jtag_clk_pin -period 300 [get_ports {jtag_TCK_pin}];

# JTAG TMS引脚
set_property IOSTANDARD LVCMOS33 [get_ports jtag_TMS_pin]
set_property PACKAGE_PIN N3 [get_ports jtag_TMS_pin]

# JTAG TDI引脚
set_property IOSTANDARD LVCMOS33 [get_ports jtag_TDI_pin]
set_property PACKAGE_PIN N2 [get_ports jtag_TDI_pin]

# JTAG TDO引脚
set_property IOSTANDARD LVCMOS33 [get_ports jtag_TDO_pin]
set_property PACKAGE_PIN M1 [get_ports jtag_TDO_pin]

set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]  
set_property CONFIG_MODE SPIx4 [current_design] 
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
