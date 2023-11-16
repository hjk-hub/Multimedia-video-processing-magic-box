`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:Meyesemi
// Engineer: Will
//
// Create Date: 2023-03-17
// Design Name:
// Module Name:
// Project Name:
// Target Devices: Pango
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 1.0 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
`define UD #1

module processor
  #(
`include"F:/Project/WorkSpace/FPGA/Video_pro/Source/top/global.vh"
   )
   (
     input                 axi_clk               ,
     input                 axi_arst_n            ,
     input     [7:0]       mode                  ,
     input     [27:0]      write_BaseDdr_addr    ,
     //  output     [27:0]     read_BaseDdr_addr     ,


     output wire           vout_clk      /*synthesis PAP_MARK_DEBUG="1"*/,
     output wire           vout_vs       /*synthesis PAP_MARK_DEBUG="1"*/,
     output wire           vout_hs       /*synthesis PAP_MARK_DEBUG="1"*/,
     output wire           vout_de       /*synthesis PAP_MARK_DEBUG="1"*/,
     output wire  [15:0]   vout_data     /*synthesis PAP_MARK_DEBUG="1"*/,


     input   wire          img_720_clk_i /*synthesis PAP_MARK_DEBUG="1"*/,
     input   wire          img_720_vs_i  /*synthesis PAP_MARK_DEBUG="1"*/,
     input   wire          img_720_hs_i  /*synthesis PAP_MARK_DEBUG="1"*/,
     input   wire          img_720_de_i  /*synthesis PAP_MARK_DEBUG="1"*/,
     input   wire  [15:0]  img_720_data_i/*synthesis PAP_MARK_DEBUG="1"*/,

     input   wire          img_1080_clk_i ,
     input   wire          img_1080_vs_i  ,
     input   wire          img_1080_hs_i  ,
     input   wire          img_1080_de_i  ,

     input   wire          img_clk_charAdd ,
     input   wire          img_vs_charAdd  ,
     input   wire          img_hs_charAdd  ,
     input   wire          img_de_charAdd  ,
     input   wire  [15:0]  img_data_charAdd,

     output wire  						            wr_burst_req      ,
     output wire   [LEN_WIDTH - 1:0] 	    wr_burst_len      ,
     output wire   [AXI_ADDR_WIDTH-1:0]   wr_burst_addr     ,
     input  wire   					              wr_burst_data_req ,
     output wire   [AXI_DATA_WIDTH - 1:0] wr_burst_data     ,
     input  wire   						            wr_burst_finish   ,

     output wire  						            rd_burst_req        ,
     output wire   [LEN_WIDTH - 1:0] 	    rd_burst_len        ,
     output wire   [AXI_ADDR_WIDTH-1:0]   rd_burst_addr       ,
     input  wire   						            rd_burst_data_valid ,
     input  wire   [AXI_DATA_WIDTH - 1:0] rd_burst_data       ,
     input  wire   						            rd_burst_finish

   );
  //parameter

  //reg and wire

  reg                                img_hs;

  wire                               img_vs_YcBcr     ;
  wire                               img_hs_YcBcr     ;
  wire                               img_de_YcBcr     ;
  wire      [15:0]                   img_data_YcBcr   ;


  wire                               img_vs_Filter    ;
  wire                               img_hs_Filter    ;
  wire                               img_de_Filter    ;
  wire      [7:0]                    r_data   ;
  wire      [7:0]                    g_data   ;
  wire      [7:0]                    b_data   ;
  wire      [15:0]                   img_data_Filter;

  wire           scale_clk ;
  wire           scale_vs  ;
  wire           scale_hs  ;
  wire           scale_de  ;
  wire  [15:0]   scale_data;

  wire           camera_clk ;
  wire           camera_vs  ;
  wire           camera_hs  ;
  wire           camera_de  ;
  wire  [15:0]   camera_data;

  wire           brightness_contrast_clk ;
  wire           brightness_contrast_vs  ;
  wire           brightness_contrast_hs  ;
  wire           brightness_contrast_de  ;
  wire  [15:0]   brightness_contrast_data;

  

  wire                               rset_n_YcBcr     ;
  wire                               rset_n_Camera     ;
  wire                               rset_n_Filter     ;
  wire                               rset_n_Scale     ;
  //   wire clk_i;
  //   GTP_INBUFG#(
  //     .IOSTANDARD ("DEFAULT"))
  //     GTP_INBUFG_inst (
  //     .I (clk_i),
  //     .O (vout_clk)
  // );

  wire  						            rd_burst_req_scale     ;
  wire   [LEN_WIDTH - 1:0] 	    rd_burst_len_scale    ;
  wire   [AXI_ADDR_WIDTH-1:0]   rd_burst_addr_scale    ;

  wire  						            rd_burst_req_camera     ;
  wire   [LEN_WIDTH - 1:0] 	    rd_burst_len_camera    ;
  wire   [AXI_ADDR_WIDTH-1:0]   rd_burst_addr_camera    ;

  assign  rd_burst_req   = ((mode[2:0]) == 3'b101)?rd_burst_req_camera:rd_burst_req_scale;
  assign  rd_burst_len   = ((mode[2:0]) == 3'b101)?rd_burst_len_camera:rd_burst_len_scale;
  assign  rd_burst_addr  = ((mode[2:0]) == 3'b101)?rd_burst_addr_camera:rd_burst_addr_scale;
  // assign  vout_clk  = img_720_clk_i;
  // assign  vout_vs  = img_720_vs_i;
  // assign  vout_hs  = img_720_hs_i;
  // assign  vout_de  = img_720_de_i;
  // assign  vout_data  = img_720_data_i;

  assign  vout_clk     = (mode[0])?img_720_clk_i:img_1080_clk_i;

  // assign  vout_clk     = ((mode[2:0]) == 3'b100)?scale_clk:
  //                         ((mode[2:0]) == 3'b011)?img_720_clk_i:
  //                           ((mode[2:0]) == 3'b010)?img_720_clk_i:
  //                             ((mode[2:0]) == 3'b001)?img_720_clk_i:1'b0;
//000调节亮度、对比度
//001原图
//010灰度图
//011双目+中值滤波
//100缩放
//101双目
//110字符叠加
//111旋转
  assign  vout_vs     = ((mode[2:0]) == 3'b110)?img_vs_charAdd:
          ((mode[2:0]) == 3'b101)?camera_vs:
          ((mode[2:0]) == 3'b100)?scale_vs:
          ((mode[2:0]) == 3'b011)?img_vs_Filter:
          ((mode[2:0]) == 3'b010)?img_vs_YcBcr:
          ((mode[2:0]) == 3'b000)?brightness_contrast_vs:
          ((mode[2:0]) == 3'b001)?img_720_vs_i:1'b0;

  assign  vout_hs     = ((mode[2:0]) == 3'b110)?img_hs_charAdd:
          ((mode[2:0]) == 3'b101)?camera_hs:
          ((mode[2:0]) == 3'b100)?scale_hs:
          ((mode[2:0]) == 3'b011)?img_hs_Filter:
          ((mode[2:0]) == 3'b010)?img_hs_YcBcr:
          ((mode[2:0]) == 3'b000)?brightness_contrast_hs:
          ((mode[2:0]) == 3'b001)?img_720_hs_i:1'b0;

  assign  vout_de     = ((mode[2:0]) == 3'b110)?img_de_charAdd:
          ((mode[2:0]) == 3'b101)?camera_de:
          ((mode[2:0]) == 3'b100)?scale_de:
          ((mode[2:0]) == 3'b011)?img_de_Filter:
          ((mode[2:0]) == 3'b010)?img_de_YcBcr:
          ((mode[2:0]) == 3'b000)?brightness_contrast_de:
          ((mode[2:0]) == 3'b001)?img_720_de_i:1'b0;

  assign  vout_data     = ((mode[2:0]) == 3'b110)?img_data_charAdd:
          ((mode[2:0]) == 3'b101)?camera_data:
          ((mode[2:0]) == 3'b100)?scale_data:
          ((mode[2:0]) == 3'b011)?img_data_Filter:
          ((mode[2:0]) == 3'b010)?img_data_YcBcr:
          ((mode[2:0]) == 3'b000)?brightness_contrast_data:
          ((mode[2:0]) == 3'b001)?img_720_data_i:16'd0;


  // assign vout_de     = ((mode[2:0]) == 3'b011)?img_de_Filter:
  //        ((mode[2:0]) == 3'b010)?img_de_YcBcr:
  //        ((mode[2:0]) == 3'b001)?img_720_de_i:1'b0;

  // assign vout_data   = ((mode[2:0]) == 3'b011)?img_data_Filter:
  //        ((mode[2:0]) == 3'b010)?img_data_YcBcr:
  //        ((mode[2:0]) == 3'b001)?img_720_data_i:15'd0;
  assign rset_n_YcBcr = ((mode[2:0]) == 3'b010)?1'b1:1'b0;
  assign rset_n_Filter = ((mode[2:0]) == 3'b011)?1'b1:1'b0;
  assign rset_n_Scale = ((mode[2:0]) == 3'b100)?1'b1:1'b0;
  assign rset_n_Camera = ((mode[2:0]) == 3'b101 || (mode[2:0]) == 3'b011)?1'b1:1'b0;
  /************************************************************************/
  // assign img_data_Filter = {r_data[7:3],g_data[7:2],b_data[7:3]};
  assign img_data_Filter = {r_data[7:3],g_data[7:2],b_data[7:3]};
  /*
  *灰度图
  */
  always @(posedge img_720_clk_i)
  begin
    if(!axi_arst_n)
    begin
      img_hs <= 1'b0;
    end
    else
    begin
      img_hs <= img_720_vs_i;
    end

  end

  //
  vip u_vip(
        //module clock
        .clk              (img_720_clk_i    ),           // 时钟信号
        .rst_n            (axi_arst_n & rset_n_YcBcr ),          // 复位信号(低有效)
        // .rst_n            (rst_n      ),
        //图像处理前的数据接口
        .pre_frame_vsync  (img_720_vs_i     ),
        .pre_frame_hsync  (img_720_hs_i       ),
        .pre_frame_de     (img_720_de_i     ),
        .pre_rgb          (img_720_data_i   ),
        .xpos             (10'd0        ),
        .ypos             (10'd0        ),
        //图像处理后的数据接口
        .post_frame_vsync (img_vs_YcBcr  ),  // 场同步信号
        .post_frame_hsync (img_hs_YcBcr  ),                  // 行同步信号
        .post_frame_de    (img_de_YcBcr  ),     // 数据输入使能
        .post_rgb         (img_data_YcBcr)            // RGB565颜色数据

      );
  /*************************************************************/
  /*
  *中值滤波
  */
  vip_gray_median_filter u_vip_gray_median_filter_r(
                           .clk    (img_720_clk_i),
                           .rst_n  (axi_arst_n & rset_n_Filter ),

                           //处理前图像数据
                           .pe_frame_vsync (camera_vs),      // vsync信号
                           .pe_frame_href  (camera_de),       // href信号
                           .pe_frame_clken (camera_de),      // data enable信号
                           .pe_img_y       ({camera_data[15:11],3'd0}),

                           //处理后的图像数据
                           .pos_frame_vsync (img_vs_Filter),   // vsync信号
                           .pos_frame_href  (img_hs_Filter),   // href信号
                           .pos_frame_clken (img_de_Filter),   // data enable信号
                           .pos_img_y       (r_data       )    //中值滤波后的灰度数据
                         );

  //g
  vip_gray_median_filter u_vip_gray_median_filter_g(
                           .clk    (img_720_clk_i),
                           .rst_n  (axi_arst_n & rset_n_Filter ),

                           //处理前图像数据
                           .pe_frame_vsync (camera_vs),      // vsync信号
                           .pe_frame_href  (camera_de),       // href信号
                           .pe_frame_clken (camera_de),      // data enable信号
                           .pe_img_y       ({camera_data[10:5],2'd0}),

                           //处理后的图像数据
                           .pos_frame_vsync (             ),   // vsync信号
                           .pos_frame_href  (             ),   // href信号
                           .pos_frame_clken (              ),   // data enable信号
                           .pos_img_y       (g_data       )    //中值滤波后的灰度数据
                         );

  //b
  vip_gray_median_filter u_vip_gray_median_filter_b(
                           .clk    (img_720_clk_i),
                           .rst_n  (axi_arst_n & rset_n_Filter ),

                           //处理前图像数据
                           .pe_frame_vsync (camera_vs),      // vsync信号
                           .pe_frame_href  (camera_de),       // href信号
                           .pe_frame_clken (camera_de),      // data enable信号
                           .pe_img_y       ({camera_data[4:0],3'd0}),

                           //处理后的图像数据
                           .pos_frame_vsync (             ),   // vsync信号
                           .pos_frame_href  (             ),   // href信号
                           .pos_frame_clken (             ),   // data enable信号
                           .pos_img_y       (b_data       )    //中值滤波后的灰度数据
                         );
  /****************************************************************/
  /*
  *缩放
  */
  scale_ctr u_scale_ctr
            (
              .axi_clk               (axi_clk    ),
              .rst_n                 (axi_arst_n  & rset_n_Scale),
              .mode                  (mode       ),

              .vout_clk      (scale_clk ),
              .vout_vs       (scale_vs  ),
              .vout_hs       (scale_hs  ),
              .vout_de       (scale_de  ),
              .vout_data     (scale_data),


              .img_720_clk_i (img_720_clk_i ),
              .img_720_vs_i  (img_720_vs_i  ),
              .img_720_hs_i  (img_720_hs_i  ),
              .img_720_de_i  (img_720_de_i  ),
              .img_720_data_i(img_720_data_i),

              .img_1080_clk_i (img_1080_clk_i),
              .img_1080_vs_i  (img_1080_vs_i ),
              .img_1080_hs_i  (img_1080_hs_i ),
              .img_1080_de_i  (img_1080_de_i ),

              .wr_burst_req      (wr_burst_req     ),
              .wr_burst_len      (wr_burst_len     ),
              .wr_burst_addr     (wr_burst_addr    ),
              .wr_burst_data_req (wr_burst_data_req),
              .wr_burst_data     (wr_burst_data    ),
              .wr_burst_finish   (wr_burst_finish  ),

              .rd_burst_req       (rd_burst_req_scale       ),
              .rd_burst_len       (rd_burst_len_scale       ),
              .rd_burst_addr      (rd_burst_addr_scale      ),
              .rd_burst_data_valid(rd_burst_data_valid),
              .rd_burst_data      (rd_burst_data      ),
              .rd_burst_finish    (rd_burst_finish    )
            );
  /*
  *双目视觉融合
  */
  multiCamera_ctr u_multiCamera_ctr
                  (
                    .axi_clk               (axi_clk    ),
                    .rst_n                 (axi_arst_n  & rset_n_Camera),
                    .mode                  (mode       ),
                    .write_BaseDdr_addr    (write_BaseDdr_addr),

                    .vout_clk      (camera_clk ),
                    .vout_vs       (camera_vs  ),
                    .vout_hs       (camera_hs  ),
                    .vout_de       (camera_de  ),
                    .vout_data     (camera_data),


                    .img_720_clk_i (img_720_clk_i ),
                    .img_720_vs_i  (img_720_vs_i  ),
                    .img_720_hs_i  (img_720_hs_i  ),
                    .img_720_de_i  (img_720_de_i  ),
                    .img_720_data_i(img_720_data_i  ),

                    .rd_burst_req       (rd_burst_req_camera       ),
                    .rd_burst_len       (rd_burst_len_camera       ),
                    .rd_burst_addr      (rd_burst_addr_camera      ),
                    .rd_burst_data_valid(rd_burst_data_valid),
                    .rd_burst_data      (rd_burst_data      ),
                    .rd_burst_finish    (rd_burst_finish    )
                  );

/*
*亮度对比度
*/
brightness_contrast  brightness_contrast_inst (
    .axi_clk        (axi_clk        ),
    .rst_n          (axi_arst_n     ),
    .mode           (mode           ),

    .vout_clk       (brightness_contrast_clk       ),
    .vout_vs        (brightness_contrast_vs        ),
    .vout_hs        (brightness_contrast_hs        ),
    .vout_de        (brightness_contrast_de        ),
    .vout_data      (brightness_contrast_data      ),

    .img_720_clk_i  (img_720_clk_i  ),
    .img_720_vs_i   (img_720_vs_i   ),
    .img_720_hs_i   (img_720_hs_i   ),
    .img_720_de_i   (img_720_de_i   ),
    .img_720_data_i (img_720_data_i )
  );
  /*
  para_change  u_para_change (
      .clk_wr         (clk_wr         ),
      .clk_rd         (clk_rd         ),
      .change_en      (change_en      ),
      .t_width        (t_width        ),
      .t_height       (t_height       ),
      .rst_n          (rst_n          ),
      .rd_vsync       (rd_vsync       ),
      .wr_vsync       (wr_vsync       ),
      .s_width        (s_width        ),
      .s_height       (s_height       ),
      .t_width_wr     (t_width_wr     ),
      .t_height_wr    (t_height_wr    ),
      .t_width_rd     (t_width_rd     ),
      .t_height_rd    (t_height_rd    ),
      .h_scale_k      (h_scale_k      ),
      .v_scale_k      (v_scale_k      ),
      .change_en_wr   (change_en_wr   ),
      .change_en_rd   (change_en_rd   ),
      .app_addr_rd_max(app_addr_rd_max),
      .rd_bust_len    (rd_bust_len    ),
      .app_addr_wr_max(app_addr_wr_max),
      .wr_bust_len    (wr_bust_len    )
    );
    scale_top  u_scale_top (
      .pixel_clk      (pixel_clk          ),
      .sram_clk       (sram_clk           ),
      .sys_rst_n      (sys_rst_n          ),
      .hs             (hs                 ),
      .vs             (vs                 ),
      .de             (de                 ),
      .s_width        (s_width            ),
      .s_height       (s_height           ),
      .t_width        (t_width            ),
      .t_height       (t_height           ),
      .h_scale_k      (h_scale_k          ),
      .v_scale_k      (v_scale_k          ),
      .pixel_data     (pixel_data         ),
      .sram_data_out  (sram_data_out      ),
      .data_valid     (data_valid         )
    );*/
  /////////////////////////////////////////////////////////////////////////////////////
endmodule
