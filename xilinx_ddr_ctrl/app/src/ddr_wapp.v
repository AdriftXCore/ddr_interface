//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/05 15:56:56
// Design Name: CNLUZT: 
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


module ddr_wrapp(
    //sys port
    clk         ,
    rst_n       ,
    en          ,
    bl          ,
    addr        ,
    dat_i       ,
    dat_req     ,
    done        ,
    busy        ,
    //ddrctr interface port
    app_cmd     ,
    app_addr    ,
    app_en      ,
    app_wdf_data,
    app_wdf_end ,
    app_wdf_wren,
    app_rdy     ,
    app_wdf_rdy  
);
//sys param
parameter   ADDR_W  =   28  ;
parameter   DATA_W  =   128 ;
parameter   BURST_L =   8   ;
parameter   BL_W    =   8   ;

//state mechine param
parameter   STATE_W     =   2      ,
            IDLE        =   2'b01  ,
            WRANDADDR   =   2'b10  ;



//sys port
input                   clk             ;
input                   rst_n           ;
input                   en              ;
input   [BL_W-1:0]      bl              ;
input   [ADDR_W-1:0]    addr            ;
input   [DATA_W-1:0]    dat_i           ;
output                  dat_req         ;
output                  done            ;
output                  busy            ;

//ddrctr interface port
output  [2:0]           app_cmd         ;
output  [ADDR_W-1:0]    app_addr        ;
output                  app_en          ;
output  [DATA_W-1:0]    app_wdf_data    ;
output                  app_wdf_end     ;
output                  app_wdf_wren    ;
input                   app_rdy         ;
input                   app_wdf_rdy     ;

//ddrctr interface signal
reg     [2:0]           app_cmd         = 0;
wire    [ADDR_W-1:0]    app_addr        ;
wire                    app_en          ;
wire    [DATA_W-1:0]    app_wdf_data    ;
wire                    app_wdf_end     ;
wire                    app_wdf_wren    ;

//sys signal
wire                    dat_req         ;
reg                     done            ;
reg                     busy            ;

//cnt singal
reg     [BL_W-2:0]      cnt_wr          ;
wire                    add_cnt_wr      ;
wire                    end_cnt_wr      ;

reg     [ADDR_W-1:0]    cnt_addr        ;
wire                    add_cnt_addr    ;
wire                    end_cnt_addr    ;

//buf signal
reg     [BL_W-2:0]      bl_reg          ;

//state mechine singal
reg     [STATE_W-1:0]   state_c             ;
reg     [STATE_W-1:0]   state_n             ;
wire                    idl2wrandaddr_start ;
wire                    wrandaddr2addr_start;

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
        if(idl2wrandaddr_start)begin 
            state_n = WRANDADDR;
        end
        else begin
            state_n = state_c; 
        end
    end
    WRANDADDR:begin
        if(wrandaddr2addr_start)begin
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

assign idl2wrandaddr_start  = state_c == IDLE && en;
assign wrandaddr2addr_start = state_c == WRANDADDR && end_cnt_wr;

always @(posedge clk)begin
    if(!rst_n)
        bl_reg <= 1;
    else if(state_c == IDLE & en & (bl >= 1))
        bl_reg <= bl;
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt_wr <= 0;
    end
    else if(add_cnt_wr)begin
        if(end_cnt_wr)
            cnt_wr <= 0;
        else
            cnt_wr <= cnt_wr + 1;
    end
end
assign add_cnt_wr = state_c == WRANDADDR & app_rdy & app_wdf_rdy;
assign end_cnt_wr = add_cnt_wr && cnt_wr == bl_reg - 1;


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
assign add_cnt_addr = state_c == WRANDADDR & app_rdy & app_wdf_rdy;
assign end_cnt_addr = end_cnt_wr;
    
assign app_wdf_wren =   add_cnt_wr;
assign app_wdf_end  =   add_cnt_wr;
assign app_en       =   add_cnt_wr;
assign dat_req      =   add_cnt_wr;
assign app_addr     =   cnt_addr  ;
assign app_wdf_data =   dat_i     ;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        done <= 0;
    else if(end_cnt_wr)
        done <= 1;
    else
        done <= 0;
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        busy <= 0;
    else if(state_c == IDLE & en)
        busy <= 1;
    else if(done)
        busy <= 0;
end

endmodule
