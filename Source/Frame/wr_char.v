`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Meyesemi
// Engineer: Nill
// 
// Create Date: 07/03/23 19:13:35
// Design Name: 
// Module Name: wr_buf
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
`define UD #1
module wr_char  
#(
    `include"F:/Project/WorkSpace/FPGA/Video_pro/Source/top/global.vh"
)
(                               
    input                         ddr_clk,
    input                         ddr_rstn,
    input wire  [27:0]            write_BaseDdr_addr,
                                  
    input                         wr_clk    /*synthesis PAP_MARK_DEBUG="1"*/,
    input                         wr_fsync  /*synthesis PAP_MARK_DEBUG="1"*/,
    input                         wr_en     /*synthesis PAP_MARK_DEBUG="1"*/,
    input  [PIX_WIDTH- 1'b1 : 0]  wr_data   /*synthesis PAP_MARK_DEBUG="1"*/,
    output                        wr_done   ,
    
    output reg                    ddr_wreq/*synthesis PAP_MARK_DEBUG="1"*/,
    output [AXI_ADDR_WIDTH- 1'b1 : 0] ddr_waddr,
    output [LEN_WIDTH- 1'b1 : 0]  ddr_wr_len,
    input                         ddr_wdone/*synthesis PAP_MARK_DEBUG="1"*/,
    output [8*MEM_DQ_WIDTH- 1'b1 : 0] ddr_wdata,
    input                         ddr_wdata_req
    
);
    // localparam RAM_WIDTH      = 16'd16;
    // localparam DDR_DATA_WIDTH = DQ_WIDTH * 8;
    // localparam WR_LINE_NUM    = H_NUM*PIX_WIDTH/RAM_WIDTH;
    localparam RD_LINE_NUM    = 40;//WR_LINE_NUM*RAM_WIDTH/DDR_DATA_WIDTH/2;
    localparam DDR_ADDR_OFFSET= 320;//2*RD_LINE_NUM*DDR_DATA_WIDTH/DQ_WIDTH;
    
    //===========================================================================
    reg       wr_fsync_1d;
    reg       wr_en_1d/* synthesis syn_preserve = 1 */;
    wire      wr_rst;
    reg       wr_enable=1/* synthesis syn_preserve = 1 */;
    
    reg       ddr_rstn_1d,ddr_rstn_2d;

    wire                fifo_rd_en;
    wire  [255:0]       fifo_rd_data;
    wire   [7:0]        rd_water_level/*synthesis PAP_MARK_DEBUG="1"*/;
    reg                 fifo_en_x1,fifo_en_x1_d1,fifo_en_x1_d2;   
    wire                fifo_en_x1_pos/*synthesis PAP_MARK_DEBUG="1"*/;
    
    wire fifo_wr_en_16i  ;
    wire [15:0] fifo_wr_data_16i;


 /*********************************************/   
    always @(posedge wr_clk)
    begin
        wr_fsync_1d <= wr_fsync;
        wr_en_1d <= wr_en;
        ddr_rstn_1d <= ddr_rstn;
        ddr_rstn_2d <= ddr_rstn_1d;
        
        // if(~wr_fsync_1d & wr_fsync && ddr_rstn_2d) 
        //     wr_enable <= 1'b1;
        // else 
        //     wr_enable <= wr_enable;
    end 
    
    assign wr_rst = (~wr_fsync_1d & wr_fsync) | (~ddr_rstn_2d);
    
    //===========================================================================
    reg      rd_fsync_1d,rd_fsync_2d,rd_fsync_3d;
    wire     rd_rst;
    always @(posedge ddr_clk)
    begin
        rd_fsync_1d <= wr_fsync;
        rd_fsync_2d <= rd_fsync_1d;
        rd_fsync_3d <= rd_fsync_2d;
    end 
    
    assign rd_rst = (~rd_fsync_3d && rd_fsync_2d) | (~ddr_rstn);

    //===========================================================================
    // wr_addr control
    reg [11:0]                 x_cnt/* synthesis syn_preserve = 1 */;
    reg [11:0]                 y_cnt/* synthesis syn_preserve = 1 */;
    reg [31 : 0]  write_data;
    reg [PIX_WIDTH- 1'b1 : 0]  wr_data_1d;
    reg                        write_en;
    reg [11:0]                 wr_addr=0;

    assign wr_done = (y_cnt == (V_NUM / 2)) && (x_cnt == (H_NUM / 2))?1'b1:1'b0;
// generate
//     if(PIX_WIDTH == 6'd24)
//     begin
//         always @(posedge wr_clk)
//         begin
//             wr_data_1d <= wr_data;
            
//             write_en <= (x_cnt[1:0] != 0);
            
//             if(x_cnt[1:0] == 2'd1)
//                 write_data <= {wr_data[7:0],wr_data_1d};
//             else if(x_cnt[1:0] == 2'd2)
//                 write_data <= {wr_data[15:0],wr_data_1d[PIX_WIDTH-1'b1:8]};
//             else if(x_cnt[1:0] == 2'd3)
//                 write_data <= {wr_data,wr_data_1d[PIX_WIDTH-1'b1:16]};
//             else
//                 write_data <= write_data;
//         end 
//     end
//     else if(PIX_WIDTH == 6'd16)
//     begin
//         always @(posedge wr_clk)
//         begin
//             wr_data_1d <= wr_data;
            
//             write_en <= x_cnt[0];
//             if(x_cnt[0])
//                 write_data <= {wr_data,wr_data_1d};
//             else
//                 write_data <= write_data;
//         end 
//     end
//     else
//     begin
//         always @(posedge wr_clk)
//         begin
//             write_data <= wr_data;
//             write_en <= wr_en;
//         end 
//     end
// endgenerate

    // always @(posedge wr_clk)
    // begin
    //     if(wr_rst)
    //         wr_addr <= 12'd0;
    //     else
    //     begin
    //         if(write_en & wr_enable)
    //             wr_addr <= wr_addr + 12'd1;
    //         else
    //             wr_addr <= wr_addr;
    //     end 
    // end

    always @(posedge wr_clk)
    begin 
        if(wr_rst)
            x_cnt <= 12'd0;
        else if(wr_en & wr_enable)
            x_cnt <= x_cnt + 1'b1;
        else
            x_cnt <= 12'd0;
    end 
    
    always @(posedge wr_clk)
    begin 
        if(wr_rst)
            y_cnt <= 12'd0;
        else if(~wr_en_1d & wr_en & wr_enable)
            y_cnt <= y_cnt + 1'b1;
        else
            y_cnt <= y_cnt;
    end 
    
    // reg rd_pulse;
    // always @(posedge wr_clk)
    // begin
    //     if(x_cnt > H_NUM - 5'd20  & wr_enable)
    //         rd_pulse <= 1'b1;
    //     else
    //         rd_pulse <= 1'b0; 
    // end 
 
    always @(posedge wr_clk)
    begin 
        if(wr_rst)
            fifo_en_x1 <= 1'b0;
            else if(y_cnt == 1 && x_cnt == H_NUM/6)//else if(y_cnt == 1 && x_cnt == H_NUM/2)
            fifo_en_x1 <= 1'b1;
        else
            fifo_en_x1 <= fifo_en_x1;
    end 
    // reg  [8:0] rd_addr=0;
    // wire [255:0] rd_wdata;
    // reg  [255:0] rd_wdata_1d=0;
    always @(posedge ddr_clk)
    begin
        fifo_en_x1_d1 <= fifo_en_x1;
        fifo_en_x1_d2 <= fifo_en_x1_d1;
    end 
    
    assign fifo_en_x1_pos = (~fifo_en_x1_d2 && fifo_en_x1_d1);
    assign fifo_rd_en = fifo_en_x1_pos | ddr_wdata_req;
/*
*
*/
//     Frame_cnt  
//     #(
//         .FLAG(FLAG)
//     )
//     u_Frame_cnt
//     (
//         .rst_n          (~wr_rst),
//         .Img_pclk       (wr_clk),
//         .Img_de         (wr_en),
//         .Img_data       (wr_data),
//         .fifo_wr_en     (fifo_wr_en_16i),
//         .fifo_wr_data   (fifo_wr_data_16i)
// ); 


    fifo_16i_256O u_fifo_16i_256O_axiWr (
        .wr_clk         (wr_clk               ),
        .wr_rst         (wr_rst               ),
        .wr_en          (wr_en       ),
        .wr_data        (wr_data     ),
        .wr_full        (                     ),
        .wr_water_level (                     ),
        .almost_full    (                     ),
        .rd_clk         (ddr_clk              ),
        .rd_rst         (rd_rst               ),
        .rd_en          (fifo_rd_en           ),
        .rd_data        (fifo_rd_data         ),
        .rd_empty       (                     ),
        .rd_water_level (rd_water_level       ),
        .almost_empty   (                     ) 
      );    

/***************************************************/
/*************************************************************/
    // wr_fram_buf wr_fram_buf (
    //     .wr_data            (  write_data     ),// input [31:0]               
    //     .wr_addr            (  wr_addr        ),// input [11:0]               
    //     .wr_en              (  write_en       ),// input                      
    //     .wr_clk             (  wr_clk         ),// input                      
    //     .wr_rst             (  ~ddr_rstn_2d   ),// input    
                          
    //     .rd_addr            (  rd_addr        ),// input [8:0]                
    //     .rd_data            (  rd_wdata       ),// output [255:0]             
    //     .rd_clk             (  ddr_clk        ),// input                      
    //     .rd_rst             (  ~ddr_rstn      ) // input                      
    // );
    
    // reg rd_pulse_1d,rd_pulse_2d,rd_pulse_3d;
    // always @(posedge ddr_clk)
    // begin 
    //     rd_pulse_1d <= rd_pulse;
    //     rd_pulse_2d <= rd_pulse_1d;
    //     rd_pulse_3d <= rd_pulse_2d;
    // end   
    // wire rd_trig;
    // assign rd_trig = ~rd_pulse_3d && rd_pulse_2d;
    
    // reg ddr_wr_req=0;
    // reg ddr_wr_req_1d;
    // assign ddr_wreq =ddr_wr_req;
    
    // always @(posedge ddr_clk)
    // begin 
    //     ddr_wr_req_1d <= ddr_wr_req;
        
    //     if(rd_trig)
    //         ddr_wr_req <= 1'b1;
    //     else if(ddr_wdata_req)
    //         ddr_wr_req <= 1'b0;
    //     else
    //         ddr_wr_req <= ddr_wr_req;
    // end 
    
    // reg  rd_en_1d;
    // reg  ddr_wdata_req_1d;
    // always @(posedge ddr_clk)
    // begin
    //     ddr_wdata_req_1d <= ddr_wdata_req;
    //     rd_en_1d <= ~ddr_wr_req_1d & ddr_wr_req;
    // end 
    
    // always @(posedge ddr_clk)
    // begin
    //     if(ddr_wdata_req_1d | rd_en_1d)
    //         rd_wdata_1d <= rd_wdata;
    //     else 
    //         rd_wdata_1d <= rd_wdata_1d;
    // end 
    
    // reg line_flag=0;
    // always@(posedge ddr_clk)
    // begin
    //     if(rd_rst)
    //         line_flag <= 1'b0;
    //     else if(rd_trig)
    //         line_flag <= 1'b1;
    //     else
    //         line_flag <= line_flag;
    // end 
    
    // always @(posedge ddr_clk)
    // begin 
    //     if(rd_rst)
    //         rd_addr <= 1'b0;
    //     else if(~ddr_wr_req_1d & ddr_wr_req)
    //         rd_addr <= rd_addr + 1'b1;
    //     else if(ddr_wdata_req)
    //         rd_addr <= rd_addr + 1'b1;
    //     else if(rd_trig & line_flag)
    //         rd_addr <= rd_addr - 1'b1;
    //     else
    //         rd_addr <= rd_addr;
    // end 
 
    always @(posedge ddr_clk)
    begin 
        if(rd_rst)
            ddr_wreq <= 1'b0;
        else if(rd_water_level >= RD_LINE_NUM && ddr_wdata_req == 1'b0)
            ddr_wreq <= 1'b1;
        else if(ddr_wdata_req == 1'b1)
            ddr_wreq <= 1'b0;
        else
            ddr_wreq <= ddr_wreq; 
    end     


    reg [FRAME_CNT_WIDTH - 1'b1 :0] rd_frame_cnt=1;
    always @(posedge ddr_clk)
    begin 
        if(~ddr_rstn)
            rd_frame_cnt <= 'd0;
        else if(~rd_fsync_3d && rd_fsync_2d)
            rd_frame_cnt <= rd_frame_cnt + 1'b1;
        else
            rd_frame_cnt <= rd_frame_cnt;
    end 

    reg [LINE_ADDR_WIDTH - 1'b1 :0] rd_cnt;
    always @(posedge ddr_clk)
    begin 
        if(rd_rst)
            rd_cnt <= 9'd0;
        else if(ddr_wdone)
            rd_cnt <= rd_cnt + DDR_ADDR_OFFSET;
        else
            rd_cnt <= rd_cnt;
    end 
    
    reg wirq_en=0;
    always @(posedge ddr_clk)
    begin
        if (~rd_fsync_2d && rd_fsync_3d)
            wirq_en <= 1'b1;
        else
            wirq_en <= wirq_en;
    end 
    
    assign ddr_wdata = fifo_rd_data;//(~ddr_wdata_req_1d & ddr_wdata_req) ? rd_wdata_1d : rd_wdata;
    assign ddr_waddr = rd_cnt + write_BaseDdr_addr;//{rd_frame_cnt[0],rd_cnt} + ADDR_OFFSET;
    assign ddr_wr_len = RD_LINE_NUM;
    assign frame_wcnt = rd_frame_cnt;
    assign frame_wirq = wirq_en && rd_fsync_3d;
    
endmodule
