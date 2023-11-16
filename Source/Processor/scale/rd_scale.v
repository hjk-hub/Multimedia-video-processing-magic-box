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
module rd_scale
  #(
`include"F:/Project/WorkSpace/FPGA/Video_pro/Source/top/global.vh"
   )
   (

     input                         Is720P,

     input                         ddr_clk,
     input                         ddr_rstn,

     input wire  [27:0]            read_BaseDdr_addr,

     input   wire [11:0]           s_width  ,
     input   wire [11:0]           s_height ,

     output wire          o_clk      ,
     output wire          o_vs       ,
     output wire          o_hs       ,
     output wire          o_de       ,
     output wire  [15:0]  o_data     ,

     input                         img_clk    ,
     input                         img_vs     ,
     input                         img_hs     ,
     input                         img_de     ,
     //  output                        vout_de      ,
     //  output [PIX_WIDTH- 1'b1 : 0]  vout_data    ,

     //    input                         init_done,

     output                        ddr_rreq     ,
     output [AXI_ADDR_WIDTH- 1'b1 : 0] ddr_raddr    ,
     output [LEN_WIDTH- 1'b1 : 0]  ddr_rd_len   ,
     //  input                         ddr_rrdy     ,
     input                         ddr_rdone    ,

     input [8*MEM_DQ_WIDTH- 1'b1 : 0]  ddr_rdata,
     input                         ddr_rdata_en
   );
  localparam SIM            = 1'b0;
  localparam RAM_WIDTH      = 16'd16;
  localparam DDR_DATA_WIDTH = 256;
  //    localparam WR_LINE_NUM    = ;//H_NUM * PIX_WIDTH/RAM_WIDTH;
  localparam RD_LINE_NUM    = 32;//16;//WR_LINE_NUM * RAM_WIDTH/DDR_DATA_WIDTH;
  localparam DDR_ADDR_OFFSET= 256;//128;//RD_LINE_NUM*DDR_DATA_WIDTH/DQ_WIDTH;

  //
  reg fifo_en,fifo_en_1d;
  wire [15:0] fifo_data;
  //===========================================================================
  //   reg       img_vs_1d;
  //   reg       img_de_1d,img_de_2d;
  wire      rd_rst;
  reg       ddr_rstn_1d,ddr_rstn_2d;

  wire [10:0]  wr_water_level;

  reg ddr_rreq_r;

  reg img_vs_1d;
  reg img_hs_1d;
  reg img_de_1d;
  // reg ddr_rdata_en_d1;


  //   assign vout_de = img_de_1d;
  assign vout_de = fifo_en_1d;
  assign ddr_rreq = ddr_rreq_r;

  assign o_clk = img_clk;
  assign o_vs   = img_vs_1d;
  assign o_hs   = img_hs_1d;
  assign o_de   = img_de_1d;
  assign o_data =  fifo_en_1d?fifo_data:16'd0;
  ;

  //   o_clk
  // o_vs
  // o_hs
  // o_de
  // o_data

  // assign vout_data = read_data;
  // assign vout_de = img_de_1d;

  ///

  always @(posedge img_clk)
  begin
    // img_vs_1d <= img_vs;
    // img_de_1d <= img_de;
    // img_de_2d <= img_de_1d;
    ddr_rstn_1d <= ddr_rstn;
    ddr_rstn_2d <= ddr_rstn_1d;

    img_vs_1d   <= img_vs;
    img_hs_1d   <= img_hs;
    img_de_1d   <= img_de;

  end
  assign rd_rst = ~img_vs_1d &img_vs;

  //===========================================================================
  reg      wr_fsync_1d,wr_fsync_2d,wr_fsync_3d;
  wire     wr_rst;

  reg      wr_en_1d,wr_en_2d,wr_en_3d;
  // reg      wr_trig;
  // reg [11:0] wr_line;
  always @(posedge ddr_clk)
  begin
    wr_fsync_1d <= img_vs;
    wr_fsync_2d <= wr_fsync_1d;
    wr_fsync_3d <= wr_fsync_2d;

    wr_en_1d <= img_de;
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
  reg [FRAME_CNT_WIDTH - 1'b1 :0] wr_frame_cnt=0;
  always @(posedge ddr_clk)
  begin
    if(wr_rst)
      wr_frame_cnt <= wr_frame_cnt + 1'b1;
    else
      wr_frame_cnt <= wr_frame_cnt;
  end

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

  // reg  [ 8:0]           wr_addr;
  // reg  [11:0]           rd_addr;
  // wire [RAM_WIDTH-1:0]  rd_data;
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
  // always @(posedge ddr_clk)
  // begin
  //     if(wr_rst)
  //         wr_addr <= (SIM == 1'b1) ? 9'd180 : 9'd0;
  //     else if(ddr_rdata_en)
  //         wr_addr <= wr_addr + 9'd1;
  //     else
  //         wr_addr <= wr_addr;
  // end

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
                  .rd_clk         (img_clk             ),
                  .rd_rst         (rd_rst               ),
                  .rd_en          (fifo_en),//img_de                ),//fifo_img_de_16o),//
                  .rd_data        (fifo_data),//vout_data            ),//fifo_rd_data_16o),//
                  .rd_empty       (                     ),
                  .rd_water_level (                     ),
                  .almost_empty   (                     )
                );

  //
  reg [12:0] x_cnt;
  reg [12:0] y_cnt;

  reg [12:0] x_start;
  reg [12:0] x_end;
  reg [12:0] y_start;
  reg [12:0] y_end;

  always @(posedge img_clk)
  begin
    if(rd_rst)
      x_cnt <= 'd0;
    else if((Is720P==1'b1)  && x_cnt >= COL_720P - 1)
      x_cnt <= 'd0;
    else if((Is720P==1'b0)  && x_cnt >= COL_1080P - 1)
      x_cnt <= 'd0;
    else if(img_de)
      x_cnt <= x_cnt + 1'b1;
    else
    begin
      x_cnt <= x_cnt;
    end
  end

  always @(posedge img_clk)
  begin
    if(rd_rst)
      y_cnt <= 'd0;
    else if((Is720P==1'b1)  && x_cnt >= COL_720P - 1)
      y_cnt <= y_cnt + 1'b1;
    else if((Is720P==1'b0)  && x_cnt >= COL_1080P - 1)
      y_cnt <= y_cnt + 1'b1;
    else
    begin
      y_cnt <= y_cnt;
    end
  end

  always @(posedge img_clk)
  begin
    if(rd_rst)
    begin
      if(Is720P)
      begin
        x_start <=  COL_720P/2 - s_width/2;
        x_end <=    COL_720P/2 + s_width/2 -1;
        y_start <=  ROW_720P/2 - s_height/2;
        y_end <=    ROW_720P/2 + s_height/2 -1 - s_height/10;
      end
      else
      begin
        x_start <= COL_1080P/2 - s_width/2;
        x_end   <= COL_1080P/2 + s_width/2 -1;
        y_start <= ROW_1080P/2 - s_height/2;
        y_end   <= ROW_1080P/2 + s_height/2 -1;
      end
    end
  end

  always @(posedge img_clk)
  begin
    if(rd_rst)
    begin
      fifo_en <= 1'b0;
    end
    else if((img_de == 1'b1) && (x_cnt >= x_start) && (x_cnt <= x_end) && (y_cnt >= y_start) && (y_cnt <= y_end))
      fifo_en <= 1'b1;
    else
    begin
      fifo_en <= 1'b0;
    end
  end

  always @(posedge img_clk)
  begin
    if(rd_rst)
    begin
      fifo_en_1d <= 1'b0;
    end
    else
    begin
      fifo_en_1d <= fifo_en;
    end
  end


  // rd_fram_buf rd_fram_buf (
  //     .wr_data    (  ddr_rdata       ),// input [255:0]
  //     .wr_addr    (  wr_addr         ),// input [8:0]
  //     .wr_en      (  ddr_rdata_en    ),// input
  //     .wr_clk     (  ddr_clk         ),// input
  //     .wr_rst     (  ~ddr_rstn       ),// input
  //     .rd_addr    (  rd_addr         ),// input [11:0]
  //     .rd_data    (  rd_data         ),// output [31:0]
  //     .rd_clk     (  img_clk        ),// input
  //     .rd_rst     (  ~ddr_rstn_2d    ) // input
  // );

  // reg [1:0] rd_cnt;
  // wire      read_en;
  // always @(posedge img_clk)
  // begin
  //     if(img_de)
  //         rd_cnt <= rd_cnt + 1'b1;
  //     else
  //         rd_cnt <= 2'd0;
  // end

  // always @(posedge img_clk)
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
  // always @(posedge img_clk)
  // begin
  //     rd_data_1d <= rd_data;
  // end

  //     generate
  //     if(PIX_WIDTH == 6'd24)
  //     begin
  //         assign read_en = img_de && (rd_cnt != 2'd3);

  //         always @(posedge img_clk)
  //         begin
  //             if(img_de_1d)
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
  //         assign read_en = img_de && (rd_cnt[0] != 1'b1);

  //         always @(posedge img_clk)
  //         begin
  //             if(img_de_1d)
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
  //         assign read_en = img_de;

  //         always @(posedge img_clk)
  //         begin
  //             read_data <= rd_data;
  //         end
  //     end
  // endgenerate



endmodule
