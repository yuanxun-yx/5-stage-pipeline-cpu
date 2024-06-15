.data
0x12345678, 0x89abcdef
.text
__start:
lw s0, 0(zero)
lw s1, 4(zero)
add t0, s0, s1
sub t1, s0, s1
slt t2, s0, s1
xor t3, s0, s1
jal ra, r_i_inst_test
sw t2, 8(zero)
lw t3, 8(zero)
beq t2, t3, __start

r_i_inst_test:
sltiu t4, s0, 0xff
srai t5, s1, 5
bltu t0, t1, r_i_inst_test
lui s2, -1
auipc s3, -1
jalr zero, 0(ra)