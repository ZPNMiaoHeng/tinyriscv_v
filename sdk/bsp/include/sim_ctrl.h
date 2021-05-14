#ifndef _SIM_CTRL_H_
#define _SIM_CTRL_H_

#define SIM_END_REG     0xE0000000
#define SIM_STDOUT_REG  0xE0000004

void sim_ctrl_init();
void sim_end();

#endif
