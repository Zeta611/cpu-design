module lcd_ctrl (
    input wire iMClk,
    input wire iMRst,

    input wire [6:0] iDDAddr,
    input wire [7:0] iDDData,
    input wire       iDDEn,

    output reg        oLcdRegSel,
    output wire [7:0] oLcdDb,
    output reg        oLcdRW,
    output reg        oLcdEn
);

// state parameters
parameter POWERON = 3'b000;
parameter FUNCSET = 3'b001;
parameter ENTRYMD = 3'b010;
parameter DISPONF = 3'b011;
parameter CLRDISP = 3'b100;
parameter IDLE    = 3'b101;
parameter LCDWR   = 3'b110;
parameter LINECNG = 3'b111;

reg [3:0] rLcdDb;
assign oLcdDb = {rLcdDb[3:0], 4'hF};


reg [7:0] rDDData0 [00:39];
reg [7:0] rDDData1 [00:39];
integer   i;

always @(posedge iMClk or posedge iMRst)
begin
    if (iMRst) begin
        for (i=0; i<40; i=i+1) begin
            rDDData0[i] <= #1 8'b 0010_0000;
            rDDData1[i] <= #1 8'b 0010_0000;
        end
    end
    else if (iDDEn) begin
        case (iDDAddr[6])
            1'b0 : rDDData0[iDDAddr[5:0]] <= iDDData;
            1'b1 : rDDData1[iDDAddr[5:0]] <= iDDData;
        endcase
    end
end

reg [2:0] rState;
reg       rCurLine;
reg [5:0] rLcdWrCnt;

// < rTmpCnt >
// 20'd      50 :   1    us
// 20'd   2,000 :  40    us
// 20'd   5,000 : 100    us
// 20'd 205,000 :   4.1  ms
// 20'd 662,500 :  13.25 ms
// 20'd 750,000 :  15    ms
reg [19:0] rTmpCnt;
reg [03:0] rTmpStg;

always @(posedge iMClk or posedge iMRst)
begin
    if (iMRst) begin
        rState <= #1 POWERON;
        rCurLine <= #1 1'b0;
        rLcdWrCnt <= #1 6'h0;
        rTmpCnt <= #1 20'h0;
        rTmpStg <= #1  4'h0;

        rLcdDb <= #1 4'h0;
        oLcdEn <= #1 1'b0;
        oLcdRegSel <= #1 1'b0;
        oLcdRW <= #1 1'b0;
    end
    else begin
        case (rState)
            POWERON : begin
                case (rTmpStg)
                    4'h0,               // wait 15 ms
                    4'h2,               // wait 4.1 ms
                    4'h4,               // wait 100 us
                    4'h6, 4'h8 : begin  // wait 40 us
                        if ((rTmpStg==4'h0) && (rTmpCnt==20'd 750000)) begin
                            rTmpCnt <= #1 20'd0;
                            rTmpStg <= #1 rTmpStg + 4'd1;
                        end
                        else if ((rTmpStg==4'h2) && (rTmpCnt==20'd 205000)) begin
                            rTmpCnt <= #1 20'd0;
                            rTmpStg <= #1 rTmpStg + 4'd1;
                        end
                        else if ((rTmpStg==4'h4) && (rTmpCnt==20'd 5000)) begin
                            rTmpCnt <= #1 20'd0;
                            rTmpStg <= #1 rTmpStg + 4'd1;
                        end
                        else if ((&rTmpStg[2:1]) && (rTmpCnt==20'd 2000)) begin
                            rTmpCnt <= #1 20'd0;
                            rTmpStg <= #1 rTmpStg + 4'd1;
                        end
                        else if ((rTmpStg[3]) && (rTmpCnt==20'd 2000)) begin
                            rTmpCnt <= #1 20'd0;
                            rTmpStg <= #1 4'd0;
                            rState <= #1 FUNCSET;
                        end
                        else
                            rTmpCnt <= #1 rTmpCnt + 20'd1;
                    end
                    4'h1, 4'h3, 4'h5, 4'h7 : begin
                        if (rTmpCnt==20'd0)       oLcdEn <= #1 1'b1;
                        else if (rTmpCnt==20'd12) oLcdEn <= #1 1'b0;

                        if (rTmpCnt==20'd0) begin
                            if (rTmpStg==4'h7)    rLcdDb <= #1 4'h2;
                            else                  rLcdDb <= #1 4'h3;
                        end

                        if (rTmpCnt==20'd 12) begin
                            rTmpCnt <= #1 20'd0;
                            rTmpStg <= #1 rTmpStg + 4'd1;
                        end
                        else
                            rTmpCnt <= #1 rTmpCnt + 20'd1;
                    end
                endcase
            end // end of POWERON

            FUNCSET, ENTRYMD, DISPONF, CLRDISP : begin
                oLcdRegSel <= #1 1'b0;
                oLcdRW <= #1 1'b0;

                case (rTmpStg)
                    4'h0,           // upper 4 bits
                    4'h3 : begin    // lower 4 bits
                        case (rState)
                            FUNCSET : begin
                                if (rTmpStg==4'h0)    rLcdDb <= #1 4'h2;
                                else                  rLcdDb <= #1 4'h8;
                            end
                            ENTRYMD : begin
                                if (rTmpStg==4'h0)    rLcdDb <= #1 4'h0;
                                else                  rLcdDb <= #1 4'h6;
                            end
                            DISPONF : begin
                                if (rTmpStg==4'h0)    rLcdDb <= #1 4'h0;
                                else                  rLcdDb <= #1 4'hC;
                            end
                            CLRDISP : begin
                                if (rTmpStg==4'h0)    rLcdDb <= #1 4'h0;
                                else                  rLcdDb <= #1 4'h1;
                            end
                        endcase

                        if (rTmpCnt==20'd2) begin
                            rTmpCnt <= #1 20'd0;
                            rTmpStg <= #1 rTmpStg + 4'd1;
                        end
                        else
                            rTmpCnt <= #1 rTmpCnt + 20'd1;
                    end
                    4'h1, 4'h4 : begin
                        oLcdEn <= #1 1'b1;

                        if (rTmpCnt==20'd 12) begin
                            rTmpCnt <= #1 20'd 0;
                            rTmpStg <= #1 rTmpStg + 4'd1;
                        end
                        else
                            rTmpCnt <= #1 rTmpCnt + 20'd1;
                    end
                    4'h2, 4'h5 : begin
                        oLcdEn <= #1 1'b0;

                        if ((rTmpStg==4'h2) && (rTmpCnt==20'd 51)) begin
                            rTmpCnt <= #1 20'd0;
                            rTmpStg <= #1 rTmpStg + 4'd1;
                        end
                        else if ((rTmpStg==4'h5) && (rTmpCnt==20'd 2001)) begin
                            rTmpCnt <= #1 20'd0;
                            rTmpStg <= #1  4'd0;

                            case (rState)
                                FUNCSET : rState <= #1 ENTRYMD;
                                ENTRYMD : rState <= #1 DISPONF;
                                DISPONF : rState <= #1 CLRDISP;
                                CLRDISP : rState <= #1 IDLE;
                            endcase
                        end
                        else
                            rTmpCnt <= #1 rTmpCnt + 20'd1;
                    end
                endcase
            end // end of FUNCSET, ENTRYMD, DISPONF, CLRDISP

            IDLE : begin    // wait 13.25 ms (for making about 60fps)
                if (rTmpCnt==20'd 662500) begin
                    rTmpCnt <= #1 20'd0;
                    rState <= #1 LCDWR;
                end
                else
                    rTmpCnt <= #1 rTmpCnt + 20'd1;
            end // end of IDLE

            LCDWR : begin
                case (rTmpStg)
                    4'h0,           // upper 4 bits
                    4'h3 : begin    // lower 4 bits
                        oLcdRegSel <= #1 1'b1;
                        oLcdRW <= #1 1'b0;

                        if (rCurLine==1'b0) begin
                            if (rTmpStg==4'h0)    rLcdDb <= #1 rDDData0[rLcdWrCnt][7:4];
                            else                    rLcdDb <= #1 rDDData0[rLcdWrCnt][3:0];
                        end
                        else begin
                            if (rTmpStg==4'h0)    rLcdDb <= #1 rDDData1[rLcdWrCnt][7:4];
                            else                    rLcdDb <= #1 rDDData1[rLcdWrCnt][3:0];
                        end

                        if (rTmpCnt==20'd2) begin
                            rTmpCnt <= #1 20'd0;
                            rTmpStg <= #1 rTmpStg + 4'd1;
                        end
                        else
                            rTmpCnt <= #1 rTmpCnt + 20'd1;
                    end
                    4'h1, 4'h4 : begin
                        oLcdEn <= #1 1'b1;

                        if (rTmpCnt==20'd 12) begin
                            rTmpCnt <= #1 20'd 0;
                            rTmpStg <= #1 rTmpStg + 4'd1;
                        end
                        else
                            rTmpCnt <= #1 rTmpCnt + 20'd1;
                    end
                    4'h2, 4'h5 : begin
                        oLcdEn <= #1 1'b0;

                        if ((rTmpStg==4'h2) && (rTmpCnt==20'd 51)) begin
                            rTmpCnt <= #1 20'd0;
                            rTmpStg <= #1 rTmpStg + 4'd1;
                        end
                        else if ((rTmpStg==4'h5) && (rTmpCnt==20'd 2001)) begin
                            rTmpCnt <= #1 20'd0;
                            rTmpStg <= #1  4'd0;

                            if (rLcdWrCnt==6'd39) begin
                                rLcdWrCnt <= #1 6'h0;
                                rState <= #1 LINECNG;
                            end
                            else
                                rLcdWrCnt <= #1 rLcdWrCnt + 6'h1;
                        end
                        else
                            rTmpCnt <= #1 rTmpCnt + 20'd1;
                        end
                endcase
            end // end of LCDWR

            LINECNG : begin
                case (rTmpStg)
                    4'h0,           // upper 4 bits
                    4'h3 : begin    // lower 4 bits
                        oLcdRegSel <= #1 1'b0;
                        oLcdRW <= #1 1'b0;

                        if (rCurLine==1'b0) begin
                            if (rTmpStg==4'h0)    rLcdDb <= #1 {1'b1, 3'd4};
                            else                    rLcdDb <= #1 4'h0;
                        end
                        else begin
                            if (rTmpStg==4'h0)    rLcdDb <= #1 {1'b1, 3'd0};
                            else                    rLcdDb <= #1 4'h0;
                        end

                        if (rTmpCnt==20'd2) begin
                            rTmpCnt <= #1 20'd0;
                            rTmpStg <= #1 rTmpStg + 4'd1;
                        end
                        else
                            rTmpCnt <= #1 rTmpCnt + 20'd1;
                    end
                    4'h1, 4'h4 : begin
                        oLcdEn <= #1 1'b1;

                        if (rTmpCnt==20'd 12) begin
                            rTmpCnt <= #1 20'd 0;
                            rTmpStg <= #1 rTmpStg + 4'd1;
                        end
                        else
                            rTmpCnt <= #1 rTmpCnt + 20'd1;
                    end
                    4'h2, 4'h5 : begin
                        oLcdEn <= #1 1'b0;

                        if ((rTmpStg==4'h2) && (rTmpCnt==20'd 51)) begin
                            rTmpCnt <= #1 20'd0;
                            rTmpStg <= #1 rTmpStg + 4'd1;
                        end
                        else if ((rTmpStg==4'h5) && (rTmpCnt==20'd 2001)) begin
                            rTmpCnt <= #1 20'd0;
                            rTmpStg <= #1  4'd0;

                            if (rCurLine==1'b0)
                                rState <= #1 LCDWR;
                            else
                                rState <= #1 IDLE;

                            rCurLine <= ~rCurLine;
                        end
                        else
                            rTmpCnt <= #1 rTmpCnt + 20'd1;
                    end
                endcase
            end // end of LINECNG
        endcase // end of rState case
    end
end
endmodule
