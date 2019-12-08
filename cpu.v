///////////////////////////////////////////////////////////////////////////
// MODULE: CPU for TSC microcomputer: cpu.v
// Author: SNU HPCS
// Description: CPU module

// DEFINITIONS do not touch definition and
`define WORD_SIZE 16    // data and address word size
`define MEMORY_SIZE 32

`define REGS_SIZE 4
`define OPCODE_SIZE 4
`define FUNC_SIZE 6
`define IMM_SIZE 8
`define TARGET_SIZE 12

`include "opcodes.v"    // "opcode.v" consists of "define" statements for
                        // the opcodes and function codes for all instructions


/////////////////////// cpu ///////////////////////
module cpu (
    input reset_cpu,    // reset signal for CPU. active-high(reset at 1)
    input clk,          // clock signal
    input cpu_enable,   // enables CPU too move PC, and write register
    input wwd_enable,   // enables wwd. if unasserted then wwd operation
                        // should not assign register value to output_port
    input [1:0] register_selection, // selects which register to show on output_port. It should only work when wwd is disabled
    // output reg[`WORD_SIZE-1:0] num_inst,   // number of instruction during execution. !!!!!!! IMPORTANT!!! DISABLE!! this port when programming FPGA
                        // You should enable num_inst port only for SIMULATION purposes.
    output [`WORD_SIZE-1:0] output_port,   // this will be used to show values in registers in case of WWD or register_selection
    output [7:0] PC_below8bit              // lower 8-bit of PC for LED output on output_logic.v. You need to assign lower 8bit of current PC to this port
);
/////////////////////// instruction memory ///////////////////////
// Do not touch this part. Otherwise, your CPU will not work properly according to the tsc-ISA
    reg [`WORD_SIZE-1:0] memory [0:`MEMORY_SIZE-1]; //memory where instruction is saved
    always@(reset_cpu) begin
        if(reset_cpu == 1'b1) begin    // when reset, it will be initialized as below
            memory[0]  <= 16'h6000;    // LHI $0, 0
            memory[1]  <= 16'h6101;    // LHI $1, 1
            memory[2]  <= 16'h6202;    // LHI $2, 2
            memory[3]  <= 16'h6303;    // LHI $3, 3
            memory[4]  <= 16'hf01c;    // WWD $0
            memory[5]  <= 16'hf41c;    // WWD $1
            memory[6]  <= 16'hf81c;    // WWD $2
            memory[7]  <= 16'hfc1c;    // WWD $3
            memory[8]  <= 16'h4204;    // ADI $2, $0, 4
            memory[9]  <= 16'h47fc;    // ADI $3, $1, -4
            memory[10] <= 16'hf81c;    // WWD $2
            memory[11] <= 16'hfc1c;    // WWD $3
            memory[12] <= 16'hf6c0;    // ADD $3, $1, $2
            memory[13] <= 16'hf180;    // ADD $2, $0, $1
            memory[14] <= 16'hf81c;    // WWD $2
            memory[15] <= 16'hfc1c;    // WWD $3
            memory[16] <= 16'h9015;    // JMP 21
            memory[17] <= 16'hf01c;    // WWD $0
            memory[18] <= 16'hf180;    // ADD $2, $0, $1
            memory[19] <= 16'hf180;    // ADD $2, $0, $1
            memory[20] <= 16'hf180;    // ADD $2, $0, $1
            memory[21] <= 16'h6000;    // LHI $0, 0
            memory[22] <= 16'h4000;    // ADI $0, $0, 0
            memory[23] <= 16'hfd80;    // ADD $2, $3, $1
            memory[24] <= 16'hf01c;    // WWD $0
            memory[25] <= 16'hf41c;    // WWD $1
            memory[26] <= 16'hf81c;    // WWD $2
            memory[27] <= 16'hfc1c;    // WWD $3
        end
    end

    // PC initialization
    reg [`WORD_SIZE:0] pc;
    initial begin
        pc <= 16'b0;
    end
    assign PC_below8bit = pc[7:0];

    // Instruction from memory[pc]
    wire [15:0] inst;
    assign inst = memory[pc];

    // control
    // Input wires for control
    wire [3:0] opcode;
    wire [5:0] func;
    // Output wires for control
    wire rdst, jmp, alus, lhi, wwd;

    assign opcode = inst[15:12];
    assign func = inst[5:0];

    // register
    // Input wires for registers
    wire       regw;
    wire [1:0] rreg1;
    wire [1:0] rreg2;
    wire [1:0] wreg;
    wire [15:0] wdat;
    // Output wires for registers
    wire [15:0] sdat;
    wire [15:0] rdat1;
    wire [15:0] rdat2;

    assign rreg1 = inst[11:10];
    assign rreg2 = inst[9:8];
    assign wreg = rdst ? inst[7:6] : inst[9:8];

    assign output_port = sdat;

    // sign_extend
    // Input wires for sign_extend
    wire [7:0] imm;
    // Output wires for sign_extend
    wire [15:0] ext;

    assign imm = inst[7:0];

    // alu
    // Input wires for alu
    wire [15:0] mux_rdat2;
    // Output wires for alu
    wire [15:0] alu_res;

    assign mux_rdat2 = alus ? ext : rdat2;

    wire [15:0] ext_imm;
    assign ext_imm = {imm[7:0], 8'b0};

    assign wdat = lhi ? ext_imm : alu_res;

    // PC incremented by 1
    wire [`WORD_SIZE-1:0] ipc;
    assign ipc = pc + 1;

    wire [`TARGET_SIZE-1:0] taddr;
    assign taddr = inst[11:0];

    // Address to jump
    wire [`WORD_SIZE-1:0] jres;

    always@(posedge clk) begin
        pc <= jmp ? jres : ipc;
    end

    control cont(
        cpu_enable,
        opcode,
        func,

        rdst,  // RegDst
        jmp,   // Jump
        alus,  // ALUSrc
        regw,  // RegWrite
        lhi,   // LHI 
        wwd    // WWD
    );

    registers regi(
        reset_cpu,
        clk,
        cpu_enable,
        register_selection,
        wwd_enable,

        wwd,    // WWD
        regw,   // RegWrite
        rreg1,  // read register 1
        rreg2,  // read register 2
        wreg,   // write register
        wdat,   // write data

        sdat,   // selected data
        rdat1,  // read data 1
        rdat2   // read data 2
    );

    sign_extend sign(
        imm,
        ext
    );

    concat conc(
        ipc,
        taddr,
        jres
    );

    alu arith(
        rdat1,
        mux_rdat2,
        alu_res
    );
endmodule
///////////////////////////////////////////////////


/////////////////////// registers ///////////////////////
module registers (
    input       reset_cpu,
    input       clk,
    input       cpu_enable,
    input [1:0] register_selection,
    input       wwd_enable,

    input                  wwd,    // WWD
    input                  regw,   // RegWrite
    input [1:0]            rreg1,  // read register 1
    input [1:0]            rreg2,  // read register 2
    input [1:0]            wreg,   // write register
    input [`WORD_SIZE-1:0] wdat,   // write data

    output reg  [`WORD_SIZE-1:0] sdat,   // selected data
    output wire [`WORD_SIZE-1:0] rdat1,  // read data 1
    output wire [`WORD_SIZE-1:0] rdat2  // read data 2
);
    reg [`WORD_SIZE-1:0] regvec [`REGS_SIZE-1:0];

    assign rdat1 = regvec[rreg1];
    assign rdat2 = regvec[rreg2];

    initial begin
        sdat = 16'd0;
    end

    integer i;
    always@(posedge clk or posedge reset_cpu) begin
        if (reset_cpu) begin
            for (i = 0; i < `REGS_SIZE; i = i + 1) begin
                regvec[i] <= 0;
            end
        end
        else begin
            if (cpu_enable && regw) begin
                regvec[regw] = wdat;
            end
            if (cpu_enable && wwd) begin
                sdat <= wwd_enable ?
                    regvec[register_selection] : regvec[rreg1];
            end
        end
    end

    always@(posedge wwd_enable) begin
        sdat <= wwd_enable ? regvec[register_selection] : regvec[rreg1];
    end
endmodule
/////////////////////////////////////////////////////////


/////////////////////// control ///////////////////////
module control (
    input cpu_enable,

    input [`OPCODE_SIZE-1:0] opcode,
    input [`FUNC_SIZE-1:0]   func,

    output reg rdst,  // RegDst
    output reg jmp,   // Jump
    output reg alus,  // ALUSrc
    output reg regw,  // RegWrite
    output reg lhi,   // LHI 
    output reg wwd    // WWD
);

    initial begin
        rdst <= 0;
        jmp <= 0;
        alus <= 0;
        regw <= 0;
        lhi <= 0;
        wwd <= 0;
    end

    always@(*) begin
        if (cpu_enable) begin
            case (opcode)
                4'd15: begin //?
                    case (func)
                        `FUNC_ADD: begin
                            rdst <= 1;
                            jmp <= 0;
                            alus <= 0;
                            regw <= 1;
                            lhi <= 0;
                            wwd <= 0;
                        end
                        `FUNC_WWD: begin
                            rdst <= 0;
                            jmp <= 0;
                            alus <= 0;
                            regw <= 0;
                            lhi <= 0;
                            wwd <= 1;
                        end
                    endcase
                end
                `OPCODE_ADI: begin
                    rdst <= 0;
                    jmp <= 0;
                    alus <= 1;
                    regw <= 1;
                    lhi <= 0;
                    wwd <= 0;
                end
                `OPCODE_LHI: begin
                    rdst <= 0;
                    jmp <= 0;
                    alus <= 0;
                    regw <= 1;
                    lhi <= 1;
                    wwd <= 0;
                end
                `OPCODE_JMP: begin
                    rdst <= 0;
                    jmp <= 1;
                    alus <= 0;
                    regw <= 0;
                    lhi <= 0;
                    wwd <= 0;
                end
            endcase
        end
    end
endmodule
///////////////////////////////////////////////////////


/////////////////////// alu ///////////////////////
module alu (
    input [`WORD_SIZE-1:0] dat1,
    input [`WORD_SIZE-1:0] dat2,
    output wire [`WORD_SIZE-1:0] res
);
    assign res = dat1 + dat2;
endmodule
///////////////////////////////////////////////////


/////////////////////// sign_extend ///////////////////////
module sign_extend (
    input [`IMM_SIZE-1:0] imm,
    output wire [`WORD_SIZE-1:0] ext
);
    // `WORD_SIZE - `IMM_SIZE == 8
    assign ext = imm[`IMM_SIZE-1] ?
        {8'b11111111, imm[`IMM_SIZE-1:0]} : {8'b0, imm[`IMM_SIZE-1:0]};
endmodule
///////////////////////////////////////////////////////////


/////////////////////// concat ///////////////////////
module concat (
    input [`WORD_SIZE-1:0]     pc,
    input [`TARGET_SIZE-1:0] taddr,
    output wire [`WORD_SIZE-1:0] res
);
    // `WORD_SIZE - `TARGET_SIZE == 4
    assign res = {pc[`WORD_SIZE-1:`WORD_SIZE-2], taddr, 2'b0};
endmodule
///////////////////////////////////////////////////////////
