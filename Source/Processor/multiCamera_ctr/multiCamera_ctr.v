module multiCamera_ctr
  #(
`include"F:/Project/WorkSpace/FPGA/Video_pro/Source/top/global.vh"
   )
   (
     input                                axi_clk               ,
     input                                rst_n                 ,
     input     [7:0]                      mode                  ,
     input     [27:0]                     write_BaseDdr_addr    ,

     output wire           vout_clk      ,
     output wire           vout_vs       ,
     output wire           vout_hs       ,
     output wire           vout_de       ,
     output wire  [15:0]   vout_data     ,


     input   wire          img_720_clk_i ,
     input   wire          img_720_vs_i  ,
     input   wire          img_720_hs_i  ,
     input   wire          img_720_de_i  ,
     input   wire  [15:0]  img_720_data_i  ,


     output reg  						    rd_burst_req        ,
     output reg   [LEN_WIDTH - 1:0] 	    rd_burst_len        ,
     output reg   [AXI_ADDR_WIDTH-1:0]      rd_burst_addr       ,
     input  wire   						    rd_burst_data_valid ,
     input  wire   [AXI_DATA_WIDTH - 1:0]   rd_burst_data       ,
     input  wire   						    rd_burst_finish
   );
  reg [11:0] skip/*synthesis PAP_MARK_DEBUG="1"*/;


  localparam IDLE = 4'd0;
  localparam START = 4'd1;
  localparam SECOND = 4'd2;
  localparam STEP3 = 4'd3;

  //   STEP2
  //   STEP2
  //   STEP2
  //   localparam START = 4'd1;
  //reg define
  reg mode4_d1,mode4_d2;
  reg mode5_d1,mode5_d2;
  reg mode6_d1,mode6_d2;
  reg mode7_d1,mode7_d2;

  reg fifo_en_d1;
  wire [10:0]  wr_water_level;
  wire fifo_en/*synthesis PAP_MARK_DEBUG="1"*/;
  wire [15:0] fifo_data;

  reg [15:0] img_720_data_i_d1;
  reg img_720_vs_i_d1,img_720_vs_i_d2;
  reg img_720_vs_i_d3,img_720_vs_i_d4;
  reg img_720_hs_i_d1;
  reg img_720_de_i_d1;


  reg [11:0] x_cnt/*synthesis PAP_MARK_DEBUG="1"*/;
  reg [11:0] y_cnt/*synthesis PAP_MARK_DEBUG="1"*/;

  reg [3:0]  state;

  wire img_720_vs_i_pos;
  wire img_720_vs_i_neg;
  wire [27:0]                     read_BaseDdr_addr;

  assign img_720_vs_i_pos = img_720_vs_i_d3 & (~img_720_vs_i_d4);
  assign img_720_vs_i_neg = img_720_vs_i_d4 & (~img_720_vs_i_d3);

  assign read_BaseDdr_addr  = (write_BaseDdr_addr == Base_addr1_1)?Base_addr1_4:
         (write_BaseDdr_addr == Base_addr2_1)?Base_addr1_1:
         (write_BaseDdr_addr == Base_addr3_1)?Base_addr2_1:
         (write_BaseDdr_addr == Base_addr4_1)?Base_addr3_1:Base_addr1_1;

  assign vout_clk = img_720_clk_i;
  assign vout_vs  = img_720_vs_i;
  assign vout_hs  = img_720_hs_i;
  assign vout_de  = img_720_de_i;

  assign plus10_pos = mode4_d1 & (~mode4_d2);
  assign minus10_pos = mode5_d1 & (~mode5_d2);
  assign plus100_pos = mode6_d1 & (~mode6_d2);
  assign minus100_pos = mode7_d1 & (~mode7_d2);
  //
  always @(posedge axi_clk)
  begin
    if(!rst_n)
    begin
      skip <= 12'd600;
    end
    else
    begin
      if(mode[3])
      begin
        if(plus10_pos)
          skip <= skip + 12'd1;
        else if(minus10_pos)
          skip <= skip - 12'd1;
        else if(plus100_pos)
          skip <= skip + 12'd5;
        else if(plus100_pos)
          skip <= skip - 12'd5;
        else
        begin
          skip <= skip;
        end
      end
      else
      begin
        if(plus10_pos)
          skip <= skip + 12'd10;
        else if(minus10_pos)
          skip <= skip - 12'd10;
        else if(plus100_pos)
          skip <= skip + 12'd50;
        else if(plus100_pos)
          skip <= skip - 12'd50;
        else
        begin
          skip <= skip;
        end
      end

    end
  end

  always@(posedge axi_clk)
  begin
    img_720_vs_i_d3<= img_720_vs_i;
    img_720_vs_i_d4 <= img_720_vs_i_d3;

    mode4_d1 <= mode[4];
    mode4_d2 <= mode4_d1;
    mode5_d1 <= mode[5];
    mode5_d2 <= mode5_d1;
    mode6_d1 <= mode[6];
    mode6_d2 <= mode6_d1;
    mode7_d1 <= mode[7];
    mode7_d2 <= mode7_d1;
  end
  //
  always@(posedge img_720_clk_i)
  begin
    img_720_vs_i_d1<= img_720_vs_i;
    img_720_hs_i_d1<= img_720_hs_i;
    img_720_de_i_d1<= img_720_de_i;

    img_720_vs_i_d2 <= img_720_vs_i_d1;
    fifo_en_d1 <= fifo_en;
    img_720_data_i_d1 <= img_720_data_i;
  end



  always@(posedge img_720_clk_i)
  begin
    if(img_720_vs_i)
    begin
      x_cnt    <=  12'd0;
    end
    else
    begin
      if(img_720_de_i)
      begin
        if(x_cnt >= IMG_COL-1)
          x_cnt    <=  12'd0;
        else
          x_cnt    <=  x_cnt + 12'd1;
      end
      else
        x_cnt    <=  x_cnt;
    end
  end

  always@(posedge img_720_clk_i)
  begin
    if(img_720_vs_i)
    begin
      y_cnt    <=  12'd0;
    end
    else
    begin

      if(x_cnt == IMG_COL-1)
        y_cnt    <=  y_cnt + 12'd1;
      else
        y_cnt    <=  y_cnt;
    end
  end
  //

//   always@(posedge axi_clk)
//   begin
//     if(!rst_n)
//     begin
//       state    <=  IDLE;
//       rd_burst_req  <= 1'b0;
//       rd_burst_len  <= 'd0;
//       rd_burst_addr <= 28'd0;
//       //   flag <= 1'b0;
//     end
//     else
//     begin
//       case(state)
//         IDLE:
//         begin
//           rd_burst_req  <= 1'b0;
//           rd_burst_len  <= IMG_COL/32;
//           rd_burst_addr <= read_BaseDdr_addr;
//           if(img_720_vs_i_neg)
//           begin
//             state    <=  START;
//           end
//           else
//             state    <=  IDLE;
//         end
//         START:
//         begin
//           if(img_720_vs_i_pos)
//             state    <=  IDLE;
//           else if(rd_burst_req == 1'b0 && wr_water_level < 16)
//           begin
//             rd_burst_req <= 1'b1;
//             rd_burst_len  <= IMG_COL/32;
//             rd_burst_addr <= rd_burst_addr;
//             state    <=  START;
//           end
//           else if(rd_burst_finish)
//           begin
//             rd_burst_req <= 1'b0;
//             state    <=  SECOND;
//           end
//           else
//           begin
//             rd_burst_req <= rd_burst_req;
//             state    <=  START;
//           end

//         end

//         SECOND:
//         begin
//           if(img_720_vs_i_pos)
//             state    <=  IDLE;
//           else if(rd_burst_req == 1'b0 && wr_water_level < 16)
//           begin
//             rd_burst_req <= 1'b1;
//             rd_burst_len  <= IMG_COL/32 - skip;
//             rd_burst_addr <= rd_burst_addr + IMG_COL/4 + skip*8;
//             state    <=  START;
//           end
//           else if(rd_burst_finish)
//           begin
//             rd_burst_req <= 1'b0;
//             rd_burst_addr <= rd_burst_addr + rd_burst_len*8;
//             state    <=  SECOND;
//           end
//           else
//           begin
//             rd_burst_req <= rd_burst_req;
//             state    <=  START;
//           end

//         end
//         default:
//           state    <=  IDLE;
//       endcase
//     end
//   end


  //   always@(posedge axi_clk)
  //   begin
  //     if(!rst_n)
  //     begin
  //       state    <=  IDLE;
  //       rd_burst_req  <= 1'b0;
  //       rd_burst_len  <= 'd0;
  //       rd_burst_addr <= 28'd0;
  //     end
  //     else
  //     begin
  //       case(state)
  //         IDLE:
  //         begin
  //           if(img_720_vs_i_neg)
  //           begin
  //             state    <=  STEP1;
  //             rd_burst_req  <= 1'b0;
  //             rd_burst_len  <= IMG_COL/32;
  //             rd_burst_addr <= read_BaseDdr_addr - IMG_COL/4;
  //           end
  //           else
  //             state    <=  IDLE;
  //         end
  //         STEP1:
  //         begin

  //           if(rd_burst_req == 1'b0 && wr_water_level < 16)
  //           begin
  //             rd_burst_req <= 1'b1;
  //             rd_burst_len  <= IMG_COL/32;
  //             rd_burst_addr <= rd_burst_addr + IMG_COL/4;
  //           end
  //           else if(rd_burst_finish)
  //             rd_burst_req <= 1'b0;
  //           else
  //           begin
  //             rd_burst_req <= rd_burst_req;
  //           end

  //           if(img_720_vs_i_pos)
  //             state    <=  IDLE;
  //           else if(y_cnt ==IMG_ROW/2 -1 && x_cnt >= IMG_COL/2 + 10)
  //           begin
  //             state    <=  STEP2;
  //             // rd_burst_addr <= read_BaseDdr_addr;
  //             rd_burst_addr <= read_BaseDdr_addr -( IMG_COL/4 - skip*8);
  //           end
  //           else
  //             state    <=  STEP1;
  //         end
  //         STEP2:
  //         begin
  //           if(img_720_vs_i_pos)
  //             state    <=  IDLE;
  //           else if(rd_burst_req == 1'b0 && wr_water_level < 16)
  //           begin
  //             rd_burst_req <= 1'b1;
  //             rd_burst_len  <= IMG_COL/32;
  //             rd_burst_addr <= rd_burst_addr + IMG_COL/4 - skip*8;
  //             // state    <=  STEP3;
  //             state    <=  STEP2;
  //           end
  //           else if(rd_burst_finish)
  //           begin
  //             rd_burst_req <= 1'b0;
  //             // state    <=  STEP2;
  //             state    <=  STEP3;
  //           end
  //           else
  //           begin
  //             rd_burst_req <= rd_burst_req;
  //             state    <=  STEP2;
  //           end
  //         end
  //         STEP3:
  //         begin
  //           if(img_720_vs_i_pos)
  //             state    <=  IDLE;
  //           else if(rd_burst_req == 1'b0 && wr_water_level < 16)
  //           begin
  //             rd_burst_req <= 1'b1;
  //             rd_burst_len  <= IMG_COL/32 - skip;
  //             rd_burst_addr <= rd_burst_addr + IMG_COL/4 + skip*8;
  //             // state    <=  STEP2;
  //             state    <=  STEP3;
  //           end
  //           else if(rd_burst_finish)
  //           begin
  //             rd_burst_req <= 1'b0;
  //             // state    <=  STEP3;
  //             state    <=  STEP2;
  //           end
  //           else
  //           begin
  //             rd_burst_req <= rd_burst_req;
  //             state    <=  STEP3;
  //           end
  //         end
  //       endcase
  //     end
  //   end
  wire fifo_wr_en/*synthesis PAP_MARK_DEBUG="1"*/;
  wire fifo_wr_en_1,fifo_wr_en_2;
  assign fifo_wr_en_1 = ((img_720_de_i==1'b1) &&((((0)<= x_cnt)&&(x_cnt <= IMG_COL/2 -1) && (0<= y_cnt)&&(y_cnt <= IMG_ROW/2 - 1))))?1'b1:1'b0;
  assign fifo_wr_en_2 = ((img_720_de_i==1'b1) &&((((IMG_COL/2 + skip)<= x_cnt)&&(x_cnt <= IMG_COL -1) && (0<= y_cnt)&&(y_cnt <= IMG_ROW/2 - 1))))?1'b1:1'b0;
  assign fifo_wr_en = fifo_wr_en_1 | fifo_wr_en_2;

  fifo_16i_16o_2048 u_fifo_16i_16o_2048 (
                      //   .wr_clk         (vout_clk            ),
                      //   .wr_rst         (vout_vs             ),
                      .clk(vout_clk),                          // input
                      .rst(vout_vs),

                      .wr_en          (fifo_wr_en        ),
                      .wr_data        (img_720_data_i           ),
                      .wr_full        (                     ),
                      .wr_water_level (                     ),
                      .almost_full    (                     ),
                      //   .rd_clk         (vout_clk             ),
                      //   .rd_rst         (vout_vs               ),
                      .rd_en          (fifo_en          ),//img_de                ),//fifo_img_de_16o),//
                      .rd_data        (fifo_data        ),//vout_data            ),//fifo_rd_data_16o),//
                      .rd_empty       (                     ),
                      .rd_water_level (                     ),
                      .almost_empty   (                     )
                    );

  //   assign fifo_en = ((img_720_de_i==1'b1) &&(((0<= x_cnt)&&(x_cnt <= IMG_COL -1) && (0<= y_cnt)&&(y_cnt <= IMG_ROW/2 -1))
  //                     ||(((skip*16 - 1)<= x_cnt)&&(x_cnt <= IMG_COL -1) && (IMG_ROW/2<= y_cnt)&&(y_cnt <= IMG_ROW - 1))))?1'b1:1'b0;
  assign fifo_en = ((img_720_de_i==1'b1) &&((((skip/2)<= x_cnt)&&(x_cnt <= IMG_COL -1 - skip/2) && (1<= y_cnt)&&(y_cnt <= IMG_ROW/2 ))))?1'b1:1'b0;

  //   assign vout_data = fifo_en_d1?fifo_data:16'd0;
  assign vout_data = fifo_en_d1?fifo_data:16'd0;

endmodule
