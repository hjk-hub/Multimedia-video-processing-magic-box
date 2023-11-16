//仿真很多地方用了绝对地址,以后若是要移植的话,需要修改为相对地址
//ddr_test
//
//

`timescale 1 ps / 1 ps

//`include "F:/Project/WorkSpace/FPGA/MES50HP/07_ddr3_test/ipcore/ddr3_test/example_design/bench/mem/ddr3_parameters.vh"

module tb3
  #(
`include"F:/Project/WorkSpace/FPGA/Video_pro/Source/top/global.vh"
   )();

  parameter real CLKIN_FREQ  = 50.0;
  parameter PLL_REFCLK_IN_PERIOD = 1000000 / CLKIN_FREQ;

  reg sys_clk;//50Mhz
  reg sys_rst_n;
  initial
  begin
    #1 sys_clk = 1'b1;
    sys_rst_n = 1'b1;
  end
  // initial
  // begin

  //   //reset the bu_top
  //   #10000 sys_rst_n = 1'b0;
  //   #50000 sys_rst_n = 1'b1;
  //   $display("%t keyboard reset sequence finished!", $time);

  //   @ (posedge ddr_init_done);
  //   $display("%t ddr_init_complete is high now!", $time);
  //   // $stop;
  // end
  always #(PLL_REFCLK_IN_PERIOD / 2)  sys_clk = ~sys_clk;
  //pll
  wire pix_clk;
  wire cfg_clk;
  wire clk_25M;
  wire clk_145_5M;
  wire locked;

  pll u_pll_1 (
        .clkin1   (  sys_clk    ),//50MHz
        .clkout0  (  pix_clk    ),//74.25M 720P30
        .clkout1  (  cfg_clk    ),//10MHz
        .clkout2  (  clk_25M    ),//25M
        .clkout3  (  clk_145_5M    ),//25M
        .pll_lock (  locked     )
      );

  // color_bar u_color_bar_3(
  //             .clk   (pix_clk       ),
  //             .rst   (~locked       ),
  //             .hs    (              ),
  //             .vs    (Img1_vs       ),
  //             .de    (Img1_de       ),
  //             .rgb_r (color_bar_r   ),
  //             .rgb_g (color_bar_g   ),
  //             .rgb_b (color_bar_b   )
  //           );
  /**************************************************/
  wire [10:0] t_width_wr ;
  wire [10:0] t_height_wr;
  wire [10:0] t_width_rd ;
  wire [10:0] t_height_rd;
  wire [15:0] h_scale_k  ;
  wire [15:0] v_scale_k  ;

  wire Img_vs_i;
  wire Img_hs_i;
  wire Img_de_i;

  wire Img_vs_o;
  wire Img_hs_o;
  wire Img_de_o;

  wire Img_de_scale;
  wire [15:0] Img_data_scale;



  reg [15:0] Img_data_i;
  wire [15:0] Img_data_o;

  wire [7:0] color_bar_r;
  wire [7:0] color_bar_g;
  wire [7:0] color_bar_b;
  // wire Img1_de;
  wire Img1_vs_o;
  wire Img1_hs_o;
  wire Img1_de_o;
  wire [7:0] Img1_data_o;
  wire [11:0] s_width ;
  wire [11:0] s_height;
  wire [11:0] t_width ;
  wire [11:0] t_height;

  assign s_width  =   11'd1280;//11'd1280;
  assign s_height =   11'd720 ;//11'd720 ;
  assign t_width  =   11'd640;//11'd640 ;
  assign t_height =   11'd720;//11'd360 ;

  // assign Img_data_i = {color_bar_r[7:3],color_bar_g[7:2],color_bar_b[7:3]};
  always @(posedge pix_clk)
  begin
    if(Img_vs_i)
    begin
      Img_data_i <= 16'd0;
    end
    else
    begin
      if(Img_de_i)
      begin
        Img_data_i <= Img_data_i + 1'b1;
      end
      else 
        Img_data_i <= Img_data_i;
    end


  end



  color_bar
    #(
      .H_ACTIVE (16'd1280	),
      .H_FP 		(16'd110	),
      .H_SYNC 	(16'd40		),
      .H_BP 		(16'd220	),
      .V_ACTIVE	(16'd720	),
      .V_FP  		(16'd5		),
      .V_SYNC  	(16'd5		),
      .V_BP  		(16'd20		),
      .HS_POL 	(1'b1		),
      .VS_POL 	(1'b1		)
    ) u_color_bar_11
    (
      .clk   (pix_clk       ),
      .rst   (~locked       ),
      .hs    (Img_hs_i       ),
      .vs    (Img_vs_i       ),
      .de    (Img_de_i       ),
      .rgb_r (    ),
      .rgb_g (    ),
      .rgb_b (    )
    );

    sync_vg u_sync_vg(
      .clk            (  pix_clk              ),//input                   clk,
      .rstn           (  locked            ),//input                   rstn,
      .vs_out         (                    ),//output reg              vs_out,
      .hs_out         (                    ),//output reg              hs_out,
      .de_out         (                  ),//output reg              de_out,
      .de_re          (                   )
    );

  // color_bar
  //   #(
  //     .H_ACTIVE ( 16'd1920  ),
  //     .H_FP 		( 16'd88	  ),
  //     .H_SYNC 	( 16'd44	  ),
  //     .H_BP 		( 16'd148   ),
  //     .V_ACTIVE	( 16'd1080  ),
  //     .V_FP  		( 16'd4	    ),
  //     .V_SYNC  	( 16'd5	    ),
  //     .V_BP  		( 16'd36	  ),
  //     .HS_POL 	( 1'b1		  ),
  //     .VS_POL 	( 1'b1		  )
  //   ) u_color_bar_12
  //   (
  //     .clk   (clk_145_5M),//clk_145_5M       ),
  //     .rst   (~locked       ),
  //     .hs    (Img_hs_o       ),
  //     .vs    (Img_vs_o       ),
  //     .de    (Img_de_o       ),
  //     .rgb_r (color_bar_r),
  //     .rgb_g (color_bar_g),
  //     .rgb_b (color_bar_b)
  //   );



    // de_frame  u_de_frame (
    //   .rst_n          (locked    ),
    //   .video_clk_i    (clk_145_5M        ),
    //   .video_vs_i     (Img_vs_o            ),
    //   .video_de_i     (Img_de_o            ),
    //   .video_data_i   (Img_data_i   ),

    //   .video_clk_o    (    ),
    //   .video_vs_o     (    ),
    //   .video_de_o     (    ),
    //   .video_data_o   (    )
    // );
  // para_change  u_para_change (
  //                .clk_wr         (pix_clk         ),
  //                .clk_rd         (pix_clk),//clk_145_5M       ),//
  //                .change_en      (2'd0            ),
  //                .s_width        (s_width         ),//缩放前宽度
  //                .s_height       (s_height        ),//缩放前高度

  //                .t_width        (t_width       ),//缩放后宽度
  //                .t_height       (t_height      ),//缩放后高度
  //                .rst_n          (locked         ),
  //                .rd_vsync       (Img_vs_i       ),
  //                .wr_vsync       (Img_vs_i),//Img_vs_o       ),//

  //                .t_width_wr     (t_width_wr     ),
  //                .t_height_wr    (t_height_wr    ),
  //                .t_width_rd     (t_width_rd     ),
  //                .t_height_rd    (t_height_rd    ),
  //                .h_scale_k      (h_scale_k      ),
  //                .v_scale_k      (v_scale_k      )

  //                //  .change_en_wr   (change_en_wr   ),
  //                //  .change_en_rd   (change_en_rd   ),
  //                //  .app_addr_rd_max(app_addr_rd_max),
  //                //  .rd_bust_len    (rd_bust_len    ),
  //                //  .app_addr_wr_max(app_addr_wr_max),
  //                //  .wr_bust_len    (wr_bust_len    )
  //              );
  // scale_top  u_scale_top (
  //              .sys_rst_n      (locked          ),

  //              .pixel_clk      (pix_clk          ),
  //              .pixel_data     (Img_data_i         ),
  //              .hs             (Img_de_i           ),
  //              .vs             (Img_vs_i           ),
  //              .de             (Img_de_i           ),

  //              .sram_clk       (pix_clk),//clk_145_5M         ),//
  //              .sram_data_out  (Img_data_scale         ),
  //              .data_valid     (Img_de_scale           ),

  //              .s_width        (s_width            ),
  //              .s_height       (s_height           ),
  //              .t_width        (t_width            ),
  //              .t_height       (t_height           ),

  //              .h_scale_k      (h_scale_k          ),
  //              .v_scale_k      (v_scale_k          )


  //            );

  // processor  u_processor_inst (
  //              .rst_n      (locked         ),
  //              .mode       (8'd3           ),
  //              .img_clk_i  (pix_clk       ),
  //              .img_vs_i   (Img1_vs       ),
  //              .img_hs_i   (Img1_hs          ),
  //              .img_de_i   (Img1_de      ),
  //              .img_data_i ({color_bar_r[7:3],color_bar_g[7:2],color_bar_b[7:3]}),
  //              .img_vs_o   (Img1_vs_o      ),
  //              .img_de_o   (Img1_de_o      ),
  //              .img_data_o (Img1_data      )
  //            );



  // vip_gray_median_filter u_vip_gray_median_filter_r(
  //                          .clk    (pix_clk),
  //                          .rst_n  (locked),

  //                          //处理前图像数据
  //                          .pe_frame_vsync (Img1_vs),      // vsync信号
  //                          .pe_frame_href  (Img1_hs),       // href信号
  //                          .pe_frame_clken (Img1_de),      // data enable信号
  //                          .pe_img_y       (color_bar_r),

  //                          //处理后的图像数据
  //                          .pos_frame_vsync (Img1_vs_o    ),   // vsync信号
  //                          .pos_frame_href  (Img1_hs_o    ),   // href信号
  //                          .pos_frame_clken (Img1_de_o    ),   // data enable信号
  //                          .pos_img_y       (Img1_data_o  )    //中值滤波后的灰度数据
  //                        );

  // reg   key;
  // wire   ctrl;

  // initial
  // begin
  //   key = 8'd0;

  //   #200000 key = 8'd1;
  //   #200000 key = 8'd0;
  //   #200000 key = 8'd1;
  //   #200000 key = 8'd0;

  // end

  // btn_deb_fix
  //   #(.BTN_WIDTH(4'd1))
  //   u_btn_deb_fix
  //   (
  //     .clk            (pix_clk),  //12MHz
  //     .btn_in         (key),

  //     .btn_deb_fix    (ctrl)
  //   );

  /****************************************************/
  reg  grs_n;
  GTP_GRS GRS_INST(
            .GRS_N (grs_n)
          );
  initial
  begin
    grs_n = 1'b0;
    #5000 grs_n = 1'b1;
  end










  /****************************************************/
endmodule

