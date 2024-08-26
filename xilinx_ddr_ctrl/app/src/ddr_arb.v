`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: CNLNTR
// 
// Create Date: 2022/03/08 21:48:56
// Design Name: 
// Module Name: ddr_arb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ddr_arb(
    clk     ,
    rst_n   ,

    wr_en   ,
    wr_req  ,
    wr_done ,
    rd_en   ,
    rd_req  ,
    rd_done  
);

//state mechine param
parameter   IDLE    =   4'b0001,
            ARB     =   4'b0010,
            WR      =   4'b0100,
            RD      =   4'b1000,
            STATE_W =   4; 

input                   clk             ;
input                   rst_n           ;

output                  wr_en           ;
input                   wr_req          ;
input                   wr_done         ;
output                  rd_en           ;
input                   rd_req          ;
input                   rd_done         ;

//in-out singal
reg                     wr_en           ;
reg                     rd_en           ;

//state mechine signal
reg     [STATE_W-1:0]   state_c         ;
reg     [STATE_W-1:0]   state_n         ;
wire                    idl2arb_start   ;
wire                    arb2wr_start    ;
wire                    arb2rd_start    ;
wire                    wr2arb_start    ;
wire                    rd2arb_start    ;

//flag signal
reg                     wr_flag         ;
reg                     rd_flag         ;

always@(posedge clk or negedge rst_n)begin  
    if(!rst_n)begin   
        state_c <= IDLE;
    end 
    else begin
        state_c <= state_n; 
    end
end

always@(*)begin 
case(state_c)   
    IDLE: begin  
        if(idl2arb_start)begin 
            state_n = ARB;
        end
        else begin
            state_n = state_c; 
        end
    end
    ARB:begin
        if(arb2wr_start)begin
            state_n = WR;
        end
        else if(arb2rd_start)begin
            state_n = RD;
        end
        else begin
            state_n = state_c;
        end
    end
    WR:begin
        if(wr2arb_start)begin 
            state_n = ARB;
        end
        else begin
            state_n = state_c;
        end
    end
    RD:begin
        if(rd2arb_start)begin 
            state_n = ARB;
        end
        else begin
            state_n = state_c;
        end
    end
    default:begin
        state_n = IDLE;
    end 
    endcase
end

assign idl2arb_start= state_c == IDLE && 1      ;
assign arb2wr_start = state_c == ARB  && wr_req ;
assign arb2rd_start = state_c == ARB  && rd_req ;
assign wr2arb_start = state_c == WR   && wr_done;
assign rd2arb_start = state_c == RD   && rd_done;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        wr_flag <= 0;
    else if(state_c == ARB & wr_req)
        wr_flag <= 1;
    else if(state_c == WR)
        wr_flag <= 0;
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        wr_en <= 0;
    else if(state_c == WR & wr_flag)
        wr_en <= 1;
    else
        wr_en <= 0;
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        rd_flag <= 0;
    else if(state_c == ARB & rd_req)
        rd_flag <= 1;
    else if(state_c == RD)
        rd_flag <= 0;
end


always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        rd_en <= 0;
    else if(state_c == RD & rd_flag)
        rd_en <= 1;
    else
        rd_en <= 0;
end

endmodule
