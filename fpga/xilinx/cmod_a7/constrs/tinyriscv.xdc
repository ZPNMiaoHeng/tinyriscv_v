
## 12 MHz Clock Signal
set_property -dict { PACKAGE_PIN L17   IOSTANDARD LVCMOS33 } [get_ports { clk_12m_i }]
create_clock -add -name sys_clk_pin -period 83.33 -waveform {0 41.66} [get_ports {clk_12m_i}]

# 复位引脚
set_property -dict { PACKAGE_PIN B18   IOSTANDARD LVCMOS33 } [get_ports rst_ext_i]

# CPU停住指示引脚
set_property -dict { PACKAGE_PIN A17   IOSTANDARD LVCMOS33 } [get_ports halted_ind_pin]

# 串口引脚
# 串口发送引脚
set_property -dict { PACKAGE_PIN J18   IOSTANDARD LVCMOS33 } [get_ports {io_pins[0]}]
# 串口接收引脚
set_property -dict { PACKAGE_PIN J17   IOSTANDARD LVCMOS33 } [get_ports {io_pins[3]}]

# I2C引脚
# I2C0 SCL引脚
set_property -dict { PACKAGE_PIN M3   IOSTANDARD LVCMOS33 } [get_ports {io_pins[6]}]
# I2C0 SDA引脚
set_property -dict { PACKAGE_PIN L3   IOSTANDARD LVCMOS33 } [get_ports {io_pins[8]}]

# SPI引脚
# SPI DQ3引脚
set_property -dict { PACKAGE_PIN A16  IOSTANDARD LVCMOS33 } [get_ports {io_pins[15]}]
# SPI DQ2引脚
set_property -dict { PACKAGE_PIN K3   IOSTANDARD LVCMOS33 } [get_ports {io_pins[14]}]
# SPI DQ1引脚
set_property -dict { PACKAGE_PIN C15  IOSTANDARD LVCMOS33 } [get_ports {io_pins[13]}]
# SPI DQ0引脚
set_property -dict { PACKAGE_PIN H1   IOSTANDARD LVCMOS33 } [get_ports {io_pins[12]}]
# SPI SS引脚
set_property -dict { PACKAGE_PIN A15  IOSTANDARD LVCMOS33 } [get_ports {io_pins[11]}]
# SPI CLK引脚
set_property -dict { PACKAGE_PIN B15  IOSTANDARD LVCMOS33 } [get_ports {io_pins[10]}]

# GPIO0引脚
set_property -dict { PACKAGE_PIN A14  IOSTANDARD LVCMOS33 } [get_ports {io_pins[7]}]
# GPIO1引脚
set_property -dict { PACKAGE_PIN J3   IOSTANDARD LVCMOS33 } [get_ports {io_pins[9]}]
# GPIO2引脚
set_property -dict { PACKAGE_PIN J1   IOSTANDARD LVCMOS33 } [get_ports {io_pins[2]}]
# GPIO3引脚
set_property -dict { PACKAGE_PIN K2   IOSTANDARD LVCMOS33 } [get_ports {io_pins[1]}]
# GPIO4引脚
set_property -dict { PACKAGE_PIN L1   IOSTANDARD LVCMOS33 } [get_ports {io_pins[4]}]
# GPIO5引脚
set_property -dict { PACKAGE_PIN L2   IOSTANDARD LVCMOS33 } [get_ports {io_pins[5]}]

# SPI Flash引脚
# CLK
set_property -dict { PACKAGE_PIN E19  IOSTANDARD LVCMOS33 } [get_ports flash_spi_clk_pin]
# SS
set_property -dict { PACKAGE_PIN K19  IOSTANDARD LVCMOS33 } [get_ports flash_spi_ss_pin]
# DQ0
set_property -dict { PACKAGE_PIN D18  IOSTANDARD LVCMOS33 } [get_ports {flash_spi_dq_pin[0]}]
# DQ1
set_property -dict { PACKAGE_PIN D19  IOSTANDARD LVCMOS33 } [get_ports {flash_spi_dq_pin[1]}]
# DQ2
set_property -dict { PACKAGE_PIN G18  IOSTANDARD LVCMOS33 } [get_ports {flash_spi_dq_pin[2]}]
# DQ3
set_property -dict { PACKAGE_PIN F18  IOSTANDARD LVCMOS33 } [get_ports {flash_spi_dq_pin[3]}]

# JTAG引脚
# JTAG TCK引脚
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets jtag_TCK_pin]
set_property -dict { PACKAGE_PIN W7   IOSTANDARD LVCMOS33 } [get_ports jtag_TCK_pin]
# JTAG TMS引脚
set_property -dict { PACKAGE_PIN U8   IOSTANDARD LVCMOS33 } [get_ports jtag_TMS_pin]
# JTAG TDI引脚
set_property -dict { PACKAGE_PIN V8   IOSTANDARD LVCMOS33 } [get_ports jtag_TDI_pin]
# JTAG TDO引脚
set_property -dict { PACKAGE_PIN U7   IOSTANDARD LVCMOS33 } [get_ports jtag_TDO_pin]

## Set unused pin pullnone
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullnone [current_design]
