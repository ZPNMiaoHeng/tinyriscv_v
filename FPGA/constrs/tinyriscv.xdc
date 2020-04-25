set_property -dict { PACKAGE_PIN N14 IOSTANDARD LVCMOS33 } [get_ports {clk}]; 
create_clock -add -name sys_clk_pin -period 20.00 -waveform {0 10} [get_ports {clk}];

set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property PACKAGE_PIN N14 [get_ports clk]

set_property IOSTANDARD LVCMOS33 [get_ports rst]
set_property PACKAGE_PIN L13 [get_ports rst]

set_property IOSTANDARD LVCMOS33 [get_ports over]
set_property PACKAGE_PIN M16 [get_ports over]

set_property IOSTANDARD LVCMOS33 [get_ports succ]
set_property PACKAGE_PIN N16 [get_ports succ]

set_property IOSTANDARD LVCMOS33 [get_ports halted_ind]
set_property PACKAGE_PIN P15 [get_ports halted_ind]

set_property IOSTANDARD LVCMOS33 [get_ports tx_pin]
set_property PACKAGE_PIN M6 [get_ports tx_pin]

set_property IOSTANDARD LVCMOS33 [get_ports io_pin]
set_property PACKAGE_PIN P16 [get_ports io_pin]

# JTAG pin
set_property IOSTANDARD LVCMOS33 [get_ports jtag_TCK]
set_property PACKAGE_PIN N11 [get_ports jtag_TCK]

create_clock -name jtag_clk_pin -period 300 [get_ports {jtag_TCK}];

set_property IOSTANDARD LVCMOS33 [get_ports jtag_TMS]
set_property PACKAGE_PIN N3 [get_ports jtag_TMS]

set_property IOSTANDARD LVCMOS33 [get_ports jtag_TDI]
set_property PACKAGE_PIN N2 [get_ports jtag_TDI]

set_property IOSTANDARD LVCMOS33 [get_ports jtag_TDO]
set_property PACKAGE_PIN M1 [get_ports jtag_TDO]
