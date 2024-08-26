`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/05 15:56:56
// Design Name: CNLUZT 
// Module Name: ddr_wrapp
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


module ddr_rdapp(
    //sys port
    clk                 ,
    rst_n               ,
    en                  ,
    bl                  ,
    addr                ,
    dat_o               ,
    nd                  ,
    done                ,
    busy                ,
    //ddrctr interface port
    app_cmd             ,
    app_addr            ,
    app_en              ,
    app_rd_data         ,
    app_rd_data_end     ,
    app_rdy             ,
    app_rd_data_valid    
);
//sys param
parameter   ADDR_W  =   28  ;
parameter   DATA_W  =   128 ;
parameter   BURST_L =   8   ;
parameter   BL_W    =   8   ;

//state mechine param
parameter   STATE_W     =   2      ,
            IDLE        =   2'b01  ,
            ADDRANDRD   =   2'b10  ;



//sys port
input                   clk                 ;
input                   rst_n               ;
input                   en                  ;
input   [BL_W-1:0]      bl                  ;
input   [ADDR_W-1:0]    addr                ;
output  [DATA_W-1:0]    dat_o               ;
output                  nd                  ;
output                  done                ;
output                  busy                ;

//ddrctr interface port
output  [2:0]           app_cmd             ;
output  [ADDR_W-1:0]    app_addr            ;
output                  app_en              ;
input   [DATA_W-1:0]    app_rd_data         ;
input                   app_rd_data_end     ;
input                   app_rdy             ;
input                   app_rd_data_valid   ;


//ddrctr interface signal
reg     [2:0]           app_cmd             = 3'b001;
wire    [ADDR_W-1:0]    app_addr            ;
wire                    app_en              ;

//sys signal
reg     [DATA_W-1:0]    dat_o               ;
reg                     nd                  ;
reg                     busy                ;
reg                     done                ;

//state mechine singal
reg     [STATE_W-1:0]   state_c             ;
reg     [STATE_W-1:0]   state_n             ;
wire                    idl2addrandrd_start ;
wire                    addrandrd2rd_start  ;

//buf signal
reg     [BL_W-2:0]      bl_reg              ;

//cnt singal
reg     [BL_W-1:0]      cnt_raddr           ;
wire                    add_cnt_raddr       ;
wire                    end_cnt_raddr       ;

reg     [ADDR_W-1:0]    cnt_addr            ;
wire                    add_cnt_addr        ;
wire                    end_cnt_addr        ;

reg     [BL_W-1:0]      cnt_rd              ;
wire                    add_cnt_rd          ;
wire                    end_cnt_rd          ;

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
        if(idl2addrandrd_start)begin 
            state_n = ADDRANDRD;
        end
        else begin
            state_n = state_c; 
        end
    end
    ADDRANDRD:begin
        if(addrandrd2rd_start)begin 
            state_n = IDLE;
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

assign idl2addrandrd_start   =   state_c == IDLE        && en         ;
assign addrandrd2rd_start    =   state_c == ADDRANDRD   && end_cnt_rd ;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        bl_reg <= 1;
    else if(state_c == IDLE & en & (bl >= 1))
        bl_reg <= bl;
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt_raddr <= 0;
    end
    else if(add_cnt_raddr)begin
        if(end_cnt_raddr)
            cnt_raddr <= 0;
        else
            cnt_raddr <= cnt_raddr + 1;
        end
end
assign add_cnt_raddr = (state_c == ADDRANDRD) & app_rdy;
assign end_cnt_raddr = add_cnt_raddr && cnt_raddr == bl_reg - 1 ;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt_addr <= 0;
    end
    else if(state_c == IDLE && en)begin
        cnt_addr <= addr;
    end
    else if(add_cnt_addr)begin
        if(end_cnt_addr)
            cnt_addr <= 0;
        else
            cnt_addr <= cnt_addr + BURST_L;
    end
end
assign add_cnt_addr = (state_c == ADDRANDRD) & app_rdy;
assign end_cnt_addr = end_cnt_raddr;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt_rd <= 0;
    end
    else if(add_cnt_rd)begin
        if(end_cnt_rd)
            cnt_rd <= 0;
        else
            cnt_rd <= cnt_rd + 1;
        end
end
assign add_cnt_rd = (state_c == ADDRANDRD) & app_rd_data_valid;
assign end_cnt_rd = add_cnt_rd && cnt_rd == bl_reg - 1 ;

assign app_addr     =   cnt_addr        ;
assign app_en       =   add_cnt_raddr   ;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        dat_o <= 0;
    else if((state_c == ADDRANDRD) & app_rd_data_valid)
        dat_o <= app_rd_data;
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        nd <= 0;
    else if((state_c == ADDRANDRD) & app_rd_data_valid)
        nd <= 1;
    else
        nd <= 0;
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        busy <= 0;
    else if(state_c == IDLE & en)
        busy <= 1;
    else if(done)
        busy <= 0;
end

always @(posedge clk)begin
    if(state_c == ADDRANDRD & end_cnt_rd)
        done <= 1;
    else
        done <= 0;
end

endmodule
