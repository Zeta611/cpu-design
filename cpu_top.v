`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SNU HPCS
// Engineer:
//
// Create Date: 2017/12/05 15:21:04
// Design Name:
// Module Name: cpu_top
// Project Name:
// Target Devices:
// Tool Versions:
// Description:  CPU top module. Do not touch this module.
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module cpu_top(            //DO not touch this file.
    input reset_clk,       //reset clk generation module.
    input reset_cpu,       //reset signal for cpu module.
    input MCLK,            //MCLK signal from fpga board
    input cpu_enable,      //cpu enable signal
    input wwd_enable,      //wwd enable signal
    input [1:0] register_selection,      //input which selects what register to show when wwd_enable is 0 (wwd is disabled)

    output [7:0] LED,        //output for LED on FPGA
    output       oLcdRegSel, //below are ports for LCD display
    output [7:0] oLcdDb,
    output       oLcdRW,
    output       oLcdEn
    );

    wire clk;    //clk for CPU
    wire [15:0] output_port;
    wire [7:0] pc_8bit;

    clock_generation clock_generator(MCLK, reset_clk, clk);
    cpu cpu(reset_cpu, clk, cpu_enable, wwd_enable, register_selection, output_port,pc_8bit);   ///DO not forget to disable num_inst in cpu.v . That siganl is only for simulation debugging. No need in real implementation
    output_logic out(MCLK, reset_clk , pc_8bit, output_port, LED, oLcdRegSel, oLcdDb, oLcdRW, oLcdEn );
endmodule
