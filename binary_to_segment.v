`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SNU HPCS
// Engineer:
//
// Create Date: 12/03/2018 21:20:21 PM
// Design Name:
// Module Name: binary_to_segment
// Project Name:
// Target Devices: SPARTAN 3E
// Tool Versions:
// Description: Converting binary value to appropriate value for LCD output
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module binary_to_segment(
    input [3:0] binary,
    output reg [7:0] segment
    );

    always @(*)begin
        case(binary)
            4'd0:
                begin
                    segment = 8'b0011_0000;
                end
            4'd1:
                begin
                    segment = 8'b0011_0001;
                end
            4'd2:
                begin
                    segment = 8'b0011_0010;
                end
            4'd3:
                begin
                    segment = 8'b0011_0011;
                end
            4'd4:
                begin
                    segment = 8'b0011_0100;
                end
            4'd5:
                begin
                    segment = 8'b0011_0101;
                end
            4'd6:
                begin
                    segment = 8'b0011_0110;
                end
            4'd7:
                begin
                    segment = 8'b0011_0111;
                end
            4'd8:
                begin
                    segment = 8'b0011_1000;
                end
            4'd9:
                begin
                    segment = 8'b0011_1001;
                end
            4'd10:    //A
                begin
                    segment = 8'b0100_0001;
                end
            4'd11:    //B
                begin
                    segment = 8'b0100_0010;
                end
            4'd12:    //C
                begin
                    segment = 8'b0100_0011;
                end
            4'd13:   //D
                begin
                     segment = 8'b0100_0100;
                end
            4'd14:   //E
                begin
                    segment = 8'b0100_0101;
                end
            4'd15:    //F
                begin
                    segment = 8'b0100_0110;
                end
        endcase
    end
endmodule
