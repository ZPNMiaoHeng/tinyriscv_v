#ifndef _UTILS_H_
#define _UTILS_H_

#define read_csr(reg) ({ unsigned long __tmp; \
  asm volatile ("csrr %0, " #reg : "=r"(__tmp)); \
  __tmp; })


#endif
