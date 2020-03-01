iverilog -s tinyriscv_core_tb -o out.vvp -I ..\rtl\core tinyriscv_core_tb.v ..\rtl\core\defines.v ..\rtl\core\ex.v ..\rtl\core\id.v ..\rtl\core\tinyriscv_core.v ..\rtl\core\pc_reg.v ..\rtl\core\regs.v ..\rtl\core\sim_ram.v ..\rtl\core\if_id.v ..\rtl\core\div.v ..\rtl\debug\jtag_dm.v ..\rtl\debug\jtag_driver.v ..\rtl\debug\jtag_top.v
vvp out.vvp
