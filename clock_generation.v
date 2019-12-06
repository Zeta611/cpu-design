//////////////////////////////////////////////////////////////////////////////////
// Company:   SNU HPCS
// Engineer:
//
// Create Date: 12/04/2017 03:26:32 PM
// Design Name:
// Module Name: output_logic
// Project Name:
// Target Devices: SPARTAN 3E
// Tool Versions:
// Description: module that generates clk from MCLK
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////


module clock_generation(
    input MCLK,   //frequency of 50 Mhz  ~= 20ns we need to make this around as period of 2s.
    input RESET_IN,
    output reg clk
    );
    reg [25:0]counter;  //we need to count up to 10^8 / 2

    always @(posedge MCLK)begin
        if(RESET_IN == 1'b1)begin
            counter <= 0;
            clk <= 0;
        end
        else begin
            if(counter == 26'b10111110101111000010000000) begin
            //if(counter == 29'b00000000000000000000000000100) begin
                counter <= 0;
                clk <= ~ clk;  //invert when it counter reach 1s
            end
            else begin
                counter <= counter + 1;
                clk <= clk; //if not reach 1s, do not invert
            end
        end
    end
endmodule
