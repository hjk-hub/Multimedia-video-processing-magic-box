`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Meyesemi
// Engineer: Nill
//
// Create Date: 15/03/23 15:02:21
// Design Name:
// Module Name: rd_buf
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
module rd_char
  #(
`include"F:/Project/WorkSpace/FPGA/Video_pro/Source/top/global.vh"
   )
   (
     input                         ddr_clk,
     input                         ddr_rstn,
     input wire  [27:0]            read_BaseDdr_addr  ,

     input                         img_720_clk_i/*synthesis PAP_MARK_DEBUG="1"*/  ,
     input                         img_720_vs_i/*synthesis PAP_MARK_DEBUG="1"*/   ,
     input                         img_720_hs_i/*synthesis PAP_MARK_DEBUG="1"*/   ,
     input                         img_720_de_i/*synthesis PAP_MARK_DEBUG="1"*/   ,
     input [PIX_WIDTH- 1'b1 : 0]   img_720_data_i/*synthesis PAP_MARK_DEBUG="1"*/ ,

     output                        vout_clk/*synthesis PAP_MARK_DEBUG="1"*/  ,
     output                        vout_vs/*synthesis PAP_MARK_DEBUG="1"*/   ,
     output                        vout_hs/*synthesis PAP_MARK_DEBUG="1"*/   ,
     output                        vout_de/*synthesis PAP_MARK_DEBUG="1"*/   ,
     output [PIX_WIDTH- 1'b1 : 0]  vout_data/*synthesis PAP_MARK_DEBUG="1"*/ ,

     output                        ddr_rreq,
     output [AXI_ADDR_WIDTH- 1'b1 : 0] ddr_raddr,
     output [LEN_WIDTH- 1'b1 : 0]  ddr_rd_len,
     input                         ddr_rdone,
     input [8*MEM_DQ_WIDTH- 1'b1 : 0]  ddr_rdata,
     input                         ddr_rdata_en
   );
  // localparam SIM            = 1'b0;
  // localparam RAM_WIDTH      = 16'd16;
  // localparam DDR_DATA_WIDTH = DQ_WIDTH * 8;
  // localparam WR_LINE_NUM    = H_NUM * PIX_WIDTH/RAM_WIDTH;
  localparam RD_LINE_NUM    = 40;//WR_LINE_NUM * RAM_WIDTH/DDR_DATA_WIDTH;
  localparam DDR_ADDR_OFFSET= 320;//RD_LINE_NUM*DDR_DATA_WIDTH/DQ_WIDTH;

  //===========================================================================
  // reg         img_720_clk_i  ;
  reg         img_720_vs_i_d1;
  reg         img_720_hs_i_d1;
  reg         img_720_de_i_d1;
  reg [15:0]  img_720_data_i_d1;

  reg       rd_fsync_1d;
  reg       rd_en_1d,rd_en_2d;
  wire      rd_rst;
  reg       ddr_rstn_1d,ddr_rstn_2d;
  wire [10:0]  fifo_rd_data_16o;
  wire [10:0]  wr_water_level;

  reg ddr_rreq_r;
  // reg ddr_rdata_en_d1;
  assign vout_clk = img_720_clk_i     ;
  assign vout_vs  = img_720_vs_i_d1   ;
  assign vout_hs  = img_720_hs_i_d1   ;
  assign vout_de  = img_720_de_i_d1   ;
  assign vout_data=  img_720_de_i_d1?((fifo_rd_data_16o == 0)?img_720_data_i_d1:fifo_rd_data_16o):img_720_data_i_d1;
//fifo_rd_data_16o;//
//   img_720_data_i_d1;//
  // assign vout_de = rd_en_1d;




  assign ddr_rreq = ddr_rreq_r;
  // assign vout_data = read_data;
  // assign vout_de = rd_en_1d;

  ///

  always @(posedge vout_clk)
  begin
    rd_fsync_1d <= img_720_vs_i;
    rd_en_1d <= img_720_de_i;
    rd_en_2d <= rd_en_1d;
    ddr_rstn_1d <= ddr_rstn;
    ddr_rstn_2d <= ddr_rstn_1d;

    img_720_vs_i_d1<= img_720_vs_i;
    img_720_hs_i_d1<= img_720_hs_i;
    img_720_de_i_d1<= img_720_de_i;
    img_720_data_i_d1 <= img_720_data_i;

  end

  assign rd_rst = ~rd_fsync_1d &img_720_vs_i;

  //===========================================================================
  reg      wr_fsync_1d,wr_fsync_2d,wr_fsync_3d;
  wire     wr_rst;

  reg      wr_en_1d,wr_en_2d,wr_en_3d;
  // reg      wr_trig;
  // reg [11:0] wr_line;
  always @(posedge ddr_clk)
  begin
    wr_fsync_1d <= img_720_vs_i;
    wr_fsync_2d <= wr_fsync_1d;
    wr_fsync_3d <= wr_fsync_2d;

    wr_en_1d <= img_720_de_i;
    wr_en_2d <= wr_en_1d;
    wr_en_3d <= wr_en_2d;

    // ddr_rdata_en_d1 <=  ddr_rdata_en;

    // wr_trig <= (wr_rst || (~wr_en_3d && wr_en_2d && wr_line != V_NUM));
  end
  // always @(posedge ddr_clk)
  // begin
  //     if(wr_rst || (~ddr_rstn))
  //         wr_line <= 12'd1;
  //     else if(wr_trig)
  //         wr_line <= wr_line + 12'd1;
  // end

  assign wr_rst = ~wr_fsync_3d && wr_fsync_2d;

  //==========================================================================


  reg [LINE_ADDR_WIDTH - 1'b1 :0] wr_cnt;
  always @(posedge ddr_clk)
  begin
    if(wr_rst)
      wr_cnt <= 9'd0;
    else if(ddr_rdone)
      wr_cnt <= wr_cnt + DDR_ADDR_OFFSET;
    else
      wr_cnt <= wr_cnt;
  end

  // assign ddr_rreq = (wr_water_level<= 16)?1'b1:1'b0;//wr_trig;
  assign ddr_raddr = wr_cnt + read_BaseDdr_addr;//{wr_frame_cnt[0],wr_cnt} + ADDR_OFFSET;
  assign ddr_rd_len = RD_LINE_NUM;

  always @(posedge ddr_clk)
  begin
    if(wr_rst)
      ddr_rreq_r <= 1'b0;
    else if(ddr_rreq_r == 1'b0 && wr_water_level < 16)
      ddr_rreq_r <= 1'b1;
    else if(ddr_rdone)
      ddr_rreq_r <= 1'b0;
    else
    begin
      ddr_rreq_r <= ddr_rreq_r;
    end
  end



  //===========================================================================


  /*
  *
  */

  fifo_256i_16O u_fifo_256i_16O_axiRd (
                  .wr_clk         (ddr_clk             ),
                  .wr_rst         (wr_rst              ),
                  .wr_en          (ddr_rdata_en        ),
                  .wr_data        (ddr_rdata           ),
                  .wr_full        (                     ),
                  .wr_water_level (wr_water_level       ),
                  .almost_full    (                     ),
                  .rd_clk         (vout_clk             ),
                  .rd_rst         (rd_rst               ),
                  .rd_en          (img_720_de_i                ),//fifo_rd_en_16o),//
                  .rd_data        (fifo_rd_data_16o            ),//fifo_rd_data_16o),//
                  .rd_empty       (                     ),
                  .rd_water_level (                     ),
                  .almost_empty   (                     )
                );

  // rd_fram_buf rd_fram_buf (
  //     .wr_data    (  ddr_rdata       ),// input [255:0]
  //     .wr_addr    (  wr_addr         ),// input [8:0]
  //     .wr_en      (  ddr_rdata_en    ),// input
  //     .wr_clk     (  ddr_clk         ),// input
  //     .wr_rst     (  ~ddr_rstn       ),// input
  //     .rd_addr    (  rd_addr         ),// input [11:0]
  //     .rd_data    (  rd_data         ),// output [31:0]
  //     .rd_clk     (  vout_clk        ),// input
  //     .rd_rst     (  ~ddr_rstn_2d    ) // input
  // );

  // reg [1:0] rd_cnt;
  // wire      read_en;
  // always @(posedge vout_clk)
  // begin
  //     if(img_720_de_i)
  //         rd_cnt <= rd_cnt + 1'b1;
  //     else
  //         rd_cnt <= 2'd0;
  // end

  // always @(posedge vout_clk)
  // begin
  //     if(rd_rst)
  //         rd_addr <= 'd0;
  //     else if(read_en)
  //         rd_addr <= rd_addr + 1'b1;
  //     else
  //         rd_addr <= rd_addr;
  // end

  // reg [PIX_WIDTH- 1'b1 : 0] read_data;
  // reg [RAM_WIDTH-1:0]       rd_data_1d;
  // always @(posedge vout_clk)
  // begin
  //     rd_data_1d <= rd_data;
  // end

  //     generate
  //     if(PIX_WIDTH == 6'd24)
  //     begin
  //         assign read_en = img_720_de_i && (rd_cnt != 2'd3);

  //         always @(posedge vout_clk)
  //         begin
  //             if(rd_en_1d)
  //             begin
  //                 if(rd_cnt[1:0] == 2'd1)
  //                     read_data <= rd_data[PIX_WIDTH-1:0];
  //                 else if(rd_cnt[1:0] == 2'd2)
  //                     read_data <= {rd_data[15:0],rd_data_1d[31:PIX_WIDTH]};
  //                 else if(rd_cnt[1:0] == 2'd3)
  //                     read_data <= {rd_data[7:0],rd_data_1d[31:16]};
  //                 else
  //                     read_data <= rd_data_1d[31:8];
  //             end
  //             else
  //                 read_data <= 'd0;
  //         end
  //     end
  //     else if(PIX_WIDTH == 6'd16)
  //     begin
  //         assign read_en = img_720_de_i && (rd_cnt[0] != 1'b1);

  //         always @(posedge vout_clk)
  //         begin
  //             if(rd_en_1d)
  //             begin
  //                 if(rd_cnt[0])
  //                     read_data <= rd_data[15:0];
  //                 else
  //                     read_data <= rd_data_1d[31:16];
  //             end
  //             else
  //                 read_data <= 'd0;
  //         end
  //     end
  //     else
  //     begin
  //         assign read_en = img_720_de_i;

  //         always @(posedge vout_clk)
  //         begin
  //             read_data <= rd_data;
  //         end
  //     end
  // endgenerate



endmodule
