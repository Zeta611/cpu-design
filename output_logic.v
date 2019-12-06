//////////////////////////////////////////////////////////////////////////////////
// Company:   SNU HPCS
// Engineer:
//
// Create Date: 12/04/2018 01:26:32 AM
// Design Name:
// Module Name: output_logic
// Project Name:
// Target Devices: SPARTAN 3E
// Tool Versions:
// Description: module for LCD display and LED output
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module output_logic(
    input MCLK,
    input RESET,
    input [7:0] PC,
    input [15:0] output_port,
    output [7:0] LED,

    output       oLcdRegSel,
    output [7:0] oLcdDb,
    output       oLcdRW,
    output       oLcdEn
    );

    reg [20:0] clkdiv = 0;
    wire [2:0] counter;
    assign counter[2:0] = {clkdiv[20:19], clkdiv[0]};
    //assign counter[1:0] = clkdiv[1:0];
    assign LED[7:0] = PC[7:0];

    reg [6:0] iADDR;
    reg [7:0] iDATA;

    wire [7:0] DATA1;
    wire [7:0] DATA2;
    wire [7:0] DATA3;
    wire [7:0] DATA4;

    reg iEN;

    binary_to_segment seg1 (output_port[3:0], DATA1);
    binary_to_segment seg2 (output_port[7:4], DATA2);
    binary_to_segment seg3 (output_port[11:8], DATA3);
    binary_to_segment seg4 (output_port[15:12], DATA4);

    lcd_ctrl lcd(MCLK, RESET, iADDR, iDATA, iEN, oLcdRegSel, oLcdDb, oLcdRW, oLcdEn);

    always @(posedge MCLK) begin
        clkdiv <= clkdiv + 1;
        case(counter)
            3'b000:
                begin
                    iEN <= 0;
                    iADDR <= 7'b000_0000;
                    iDATA <= DATA4;
                end
            3'b001:
                begin
                    iEN <= 1;
                    iADDR <= 7'b000_0000;
                    iDATA <= DATA4;
                end
            3'b010:
                begin
                    iEN <= 0;
                    iADDR <= 7'b000_0001;
                    iDATA <= DATA3;
                end
            3'b011:
                begin
                    iEN <= 1;
                    iADDR <= 7'b000_0001;
                    iDATA <= DATA3;
                end
                3'b100:
                begin
                    iEN <= 0;
                    iADDR <= 7'b000_0010;
                    iDATA <= DATA2;
                end
            3'b101:
                begin
                    iEN <= 1;
                    iADDR <= 7'b000_0010;
                    iDATA <= DATA2;
                end
                3'b110:
                begin
                    iEN <= 0;
                    iADDR <= 7'b000_0011;
                    iDATA <= DATA1;
                end
            3'b111:
                begin
                    iEN <= 1;
                    iADDR <= 7'b000_0011;
                    iDATA <= DATA1;
                end
        endcase
    end
endmodule
