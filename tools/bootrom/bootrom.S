
    .global entry
    .option norvc
entry:
    lui	    a0, 0x0200
    slli	a0, a0, 0x4
    // jump to 0x02000000
    jalr	a0
loop:
    j loop
