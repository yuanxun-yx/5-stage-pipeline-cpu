# Pipelined CPU (5-Stage)

## Goal

The purpose of this lab is to implement a RISC-V32 5-stage pipelined CPU which supports the following instructions **and resolves all hazards**.

- Integer Computational Instructions
  - Integer Register-Immediate Instructions
    - addi, slti[u]
    - andi, ori, xori
    - slli, srli, srai
    - lui, auipc
  - Integer Register-Register Operations
    - add, slt[u]
    - and, or, xor
    - sll, srl
    - sub, sra
  - NOP Instruction
- Control Transfer Instructions
  - Unconditional Jumps
    - jal
    - jalr
  - Conditional Branches
    - beq, bne
    - blt[u]
    - bge[u]
- Load and Store Instructions
    - lw, sw

The above instructions cover most part of RV32I base integer instruction set, the full version of which has 40 unique instructions. This simple implementation would be powerful enough to run many programs.

## An Overview of the Design

With a careful check to all timing issues, I redesigned every detail of this CPU so that it can run at **full speed (200MHz)** on Xilinx Kintex-7 FPGA chip. Two major hazards are resolved in following ways:

- Data hazard: forwarding & stalling.
- Control hazard: assume branch is always not taken, flush bubbles if the prediction is incorrect.

Here's an overview of this design:

![Pipelined CPU](figure/Pipelined%20CPU.jpg)

<center>
    Figure 1 Pipelined CPU
</center>

The highly complex and intertwined wires make it hard to understand the structure at first glance. I'll break it down to several parts and explain them one by one in the following chapters.

## Data Hazard

If some data is required for computation, but hasn't been written back to register file yet, data hazard will occur. For data that are already computed, we forward the data from subsequent stages; for data that are not yet generated, we stall the instruction for several cycles until it appears at any stage. 

Next, we'll zoom into all details and demonstrate my intentions.

### Forwarding

#### Why Forwarding Should Be Done at EX Stage

First you'll notice that forwarding is done at EX stage, when ALU requires its two operands. You might wonder why it's not done at previous stage after two data are read out from the register file. It has to do with our very purpose of forwarding: get data that are not written back in advance. We wish forwarding cases to be as less as possible to decrease the complexity of the circuit, therefore we should give as much time as possible for subsequent stages to compute the data. In this design, the deadline is before ALU. In other words, when an instruction is here, the operand must be correct or otherwise we'll get wrong results.

#### Pass rs1 & rs2 to Subsequent Stages

rs1 & rs2 is needed at subsequent stages so that the forwarding unit can decide whether forwarding is needed. Note that rd is not specially added for forwarding unit,it already exists in our original design where data hazard is not considered for register file write back. The idea is simple: if rd is equal to either of rs1 or rs2 (and rd isn't zero), then the data that you're going to write is exactly the one I need right now, therefore I should forward this one. However, there exists two problems that are not mention in the book.

First, there exists two active instructions (spatially) after EX stage, which one should we select? Because the instruction at MEM stage is the newest one, therefore it should be considered first. Here's the corresponding code in Verilog:

```verilog
// MEM hazard
// consider data in MEM stage first, because this one is the newest one
if (mem_wb_wb_reg_write_reg && (mem_wb_rd_reg != 5'b0) 
    && (mem_wb_rd_reg == id_ex_rs1_reg))
    forward_alu_a = forward_alu_a_wb;
// EX hazard
else if (ex_mem_wb_reg_write_reg && (ex_mem_rd_reg != 5'b0) 
    && (ex_mem_rd_reg == id_ex_rs1_reg))
    forward_alu_a = forward_alu_a_mem;
```

Second, how can we know the rs1/rs2 field of this instruction is valid? It's possible that this instruction might even don't possess a rs1/rs2 field (e.g. Integer Register-Immediate Instructions), but the corresponding bits happened to match rd field of previous instructions, then forwarding will proceed without we asking for it. Therefore, I added a circuitry at ID stage to avoid this scenario. The format of this instruction will be checked at ID stage so that if the rs1/rs2 doesn't exist, it'll be set zero so that forwarding won't occur. Here's the corresponding code in Verilog:

```verilog
// if instruction doesn't have rs1/rs2 field,
// they should be assigned zero for forwarding unit
always @*
    case (if_id_inst_reg[6:0])
        opcode_jalr, opcode_branch, opcode_load, 
        opcode_store, opcode_op_imm, opcode_op:
            id_ex_rs1_next = if_id_inst_reg[19:15];
        default: 
            id_ex_rs1_next = 5'b0;
    endcase
always @*
    case (if_id_inst_reg[6:0])
        opcode_branch, opcode_store, opcode_op:
            id_ex_rs2_next = if_id_inst_reg[24:20];
        default: 
            id_ex_rs2_next = 5'b0;
    endcase
```

#### Multiplex Write Data in Advance

For RV32I instruction set, there are 4 possible write back values: 

- ALU result: for integer computational instructions except `lui`.
- Memory data: for load instructions.
- Immediate: for `lui`.
- PC+4: for linking process of unconditional jumps.

The reader might also notice that 4 signals are multiplexed as soon as they are computed, instead of multiplexing the 4 of them at WB stage in one 4-to-1 multiplexer. There are two advantages for this design. First and foremost, at MEM & WB stage, only one write back signal exists, which simplifies the forwarding circuitry, because only one signal is needed for one subsequence stage. This also allows us to increase the frequency of main clock. The second is that the number of pipeline registers are reduced (2 or 3 32-bit registers), which isn't a small number.

### Stall

In my design, double bump is applied to register file so as to reduce one more cases where hazard can't be resolved by forwarding. Therefore, the only case for stalling is that two instructions are only 1 cycle apart and memory data is used unfortunately. This can be detected at ID stage. ID stage is chosen for 2 reasons. First, the hazard should be detected as early as possible, for the complexity of the circuit increases with the number of stalling stages. For example, if it's detected at EX stage, both IF and ID stages should be stalled. Second, the instruction must be read out from the instruction memory before the circuit decides whether a stall is needed, therefore it can't be at IF stage where the instruction is still inside instruction memory. 

Also, the problem of the validity of rs1/rs2 field exists. Thus the rs1/rs2 field generated by above method should be used here. 

Stalling is implemented as deasserting write enable signals of PC & IF/ID, and asserting ID.Flush. Because the unwanted (flushed) instruction has just reached ID stage, it hasn't made any changes to the internal data. Therefore there's nothing needed to be undone. Here's the stalling logic in Verilog:

```verilog
assign if_flush = (ctrl_pc_source == pc_source_pc_plus_offset) ||
                  (ex_mem_mem_pc_source_reg == pc_source_alu_result) ||
                  branch_taken;

assign pc_alter_id_flush = (ex_mem_mem_pc_source_reg == pc_source_alu_result) ||
                           branch_taken;
assign id_flush = pc_alter_id_flush | hazard_id_flush;

assign ex_flush = (ex_mem_mem_pc_source_reg == pc_source_alu_result) ||
                  branch_taken;
```

After two instructions are separated 2 cycles apart, the forwarding unit will forward the correct data for the stalled instruction.

## Control Hazard

Branching is the most annoying problem for pipelined design. For simplicity, I only implemented the always assume branch is not taken scheme. However, this simple method also has a lot of details worth considering to achieve timing requirements.

### Why Branching (and `jalr`) is Done at MEM stage

As we all know, the earlier the branch is taken, the less penalty it'll have. Therefore the PC change for `jal` takes place at ID stage, just as the computation of the new address is completed. However, for `jalr` and branches, which requires data inside register file, the instruction has to wait for the register file to complete because we cannot add another register file so that we'll have two copies of the same data. Unfortunately, the register file has a very large delay, because of the huge multiplexer (32-to-1). This means when the data is available, the corresponding cycle is just about to end. Therefore we cannot do any extra work at ID stage. Also, even if we have enough time to determine the branch condition, doing so at ID stage would require another forwarding & stalling unit, which makes the circuit even more complicated.

What about EX stage? Again, unfortunately, the ALU implementation on FPGA chip also has a very large delay (mostly net delay) due to the large amount of resources it uses. Thus ALU result can only be available at the end of the cycle. 

Therefore, branch decision unit, and even zero should be moved to the MEM stage. The reason is the same for `jalr`, which also requires register file & ALU.

Although we'll have 4 cycles of penalty in this way, the clock rate can be doubled and overall performance can be improved. 

### Redo the Effects of Misprediction

MEM is the bottom-line for branch decision, because once an instruction enters MEM stage, it will write data to either memory or registers. This also explains why branch unit can't be placed further at WB stage.

If a misprediction happens, we only have to flush all previous instructions, just like what we've done for stalling. The difference is that stall only flushes the instruction at ID stage and stalls the instruction at IF stage, branches need to stall all 3 stages before MEM.

### Select Correct Value for PC

Next value of PC is not obvious here because jumps and branches take place at several stages. The principle is opposite to what we have for forwarding: examine the oldest instruction first. Because if a jump/branch occurs, the subsequent (newer) instructions should not be executed. Here's the corresponding code in Verilog:

```verilog
always @*
    begin
        // default: next instuction
        next_pc = pc_plus_4;
        
        // check MEM first, because it's the foremost one
        // if branch at MEM stage is taken
        if (branch_taken)
            next_pc = ex_mem_pc_plus_offset_reg;
        // jalr at MEM stage
        else if (ex_mem_mem_pc_source_reg == pc_source_alu_result)
            next_pc = {ex_mem_alu_result_reg[31:1], 1'b0};
        // then check jal at ID stage
        else if (ctrl_pc_source == pc_source_pc_plus_offset)
            next_pc = pc_plus_offset;
    end
```

## Verification

After explaining every detail of my design, now it's time to verify it.

### Behavioral Simulation

The same program for single-cycle CPU verification is used here. We can compare the result with the one we had for single-cycle CPU.

```assembly
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
```

| register name | register number |   value    |
| :-----------: | :-------------: | :--------: |
|      ra       |        1        | 0x0000001c |
|      t0       |        5        | 0x9be02467 |
|      t1       |        6        | 0x88888889 |
|      t2       |        7        | 0x00000000 |
|      s0       |        8        | 0x12345678 |
|      s1       |        9        | 0x89abcdef |
|      s2       |       18        | 0xfffff000 |
|      s3       |       19        | 0xfffff038 |
|      t3       |       28        | 0x9b9f9b97 |
|      t4       |       29        | 0x00000000 |
|      t5       |       30        | 0xfc4d5e6f |

<center>
    Table 1 Correct Value of Used GPRs After Running the Program (by RARS)
</center>

![single cycle sim](figure/single%20cycle%20sim.PNG)

<center>
    Figure 2 Simulation Result of <b>Single-Cycle</b> CPU
</center>

![pipelined cpu sim](figure/pipelined%20cpu%20sim.jpg)

<center>
    Figure 3 Simulation Result of <b>Pipelined</b> CPU
</center>

The first thing is to examine the value of GPRs at each cycle. From table 1 we can see that the final values are all correct. Note that there are several instructions after `jal` and `beq` that alters the value of GPRs, by examining the values of GPR in figure 3, we can say that all the instructions are not supposed to be executed are indeed not executed, which means the stall logic is correct. Also, the first 4 instructions provide testing of the forwarding unit, and the value of t0 and t1 demonstrates its correctness.

Then let's check the value of PC. From figure 3, we can notice that `0c` is stalled for one extra cycle. This shows the correctness of hazard detection unit, for when PC is `0c` at IF stage, the instruction at ID stage corresponds to PC `08`, which is `add t0, s0, s1`. Because `lw s1, 4(zero)` is only one cycle apart and s1 is used, therefore stalling for one cycle is needed.

In conclusion, the short program contains all hazard cases and it can be run correctly on my CPU.

### Timing Verification

<img src="figure/pipelined cpu timing.PNG" alt="pipelined cpu timing" style="zoom: 50%;" />

<center>
    Figure 4 Timing Summary (without VGA)
</center>

After all these efforts, timing reports in figure 4 gives us good news that all constraints (200MHz main clock) are met. Also, check the tight slack paths, I found that the tight setup slacks are all caused by the logic delay of BRAM cell on board, to which I gave a whole half clock time. These cells are fixed and cannot be redesigned, so this is the limit. For hold slack, most of the tight ones come from PC computation on ID stage which requires only one addition and thus are too fast. 

## Future Improvements

The pipelined CPU implemented here is definitely a masterpiece. First, it considers timing issues, which is the very purpose of applying a pipelined design. Second, the neat Verilog code has great readability and extendibility and it converts the complex design into highly logical descriptions. 

However, due to limited time and energy, it's only a minimal design required to run a program correctly. Advanced features are underway and some might be added in the future:

- Switch to SystemVerilog to improve efficiency.
- 2-bit dynamic branch prediction.
- Exception & Zicsr.
- Memory hierarchy.
- "M" standard extension.
- "F" standard extension (FPU).
- Privileged instruction set.
- ...

## Reference

1. David A. Patterson, John L. Hennessy. Computer Organization and Design: The Hardware/Software Interface (RISC-V Edition).
2. David A. Patterson, John L. Hennessy. Computer Architecture: A Quantitative Approach, Sixth Edition.
3. Andrew Waterman, Krste Asanovi'c. The RISC-V Instruction Set Manual, Volume I: Unprivileged ISA (Document Version 20191214-draft).

