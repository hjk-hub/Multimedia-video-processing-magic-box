//仿真很多地方用了绝对地址,以后若是要移植的话,需要修改为相对地址
//ddr_test
//
//

`timescale 1 ps / 1 ps

`include "F:/Project/WorkSpace/FPGA/MES50HP/07_ddr3_test/ipcore/ddr3_test/example_design/bench/mem/ddr3_parameters.vh"

module new_top
  #(
`include"F:/Project/WorkSpace/FPGA/Video_pro/Source/top/global.vh"
   )();


  wire ddr_clk;  //50Mhz
  wire ddr_rst_n;

  wire                             axi_aclk        ;
  wire                             axi_aresetn     ;
  wire                             ddr_init_done   ;

  wire [CTRL_ADDR_WIDTH-1:0]        axi_awaddr     ;
  wire                              axi_awuser_ap  ;
  wire [3:0]                        axi_awuser_id  ;
  wire [3:0]                        axi_awlen      ;
  wire                             axi_awready    ;
  wire                              axi_awvalid    ;

  wire [MEM_DQ_WIDTH*8-1:0]         axi_wdata      ;
  wire [MEM_DQ_WIDTH-1:0]           axi_wstrb      ;
  wire                             axi_wready     ;
  wire [3:0]                       axi_wusero_id  ;
  wire                             axi_wusero_last;

  wire                              axi_bready     ;
  wire                             axi_bvalid     ;

  wire [CTRL_ADDR_WIDTH-1:0]        axi_araddr     ;
  wire                              axi_aruser_ap  ;
  wire [3:0]                        axi_aruser_id  ;
  wire [3:0]                        axi_arlen      ;
  wire                             axi_arready    ;
  wire                              axi_arvalid    ;

  wire[8*MEM_DQ_WIDTH-1:0]         axi_rdata      ;
  wire[3:0]                        axi_rid        ;
  wire                             axi_rlast      ;
  wire                             axi_rvalid      ;



  assign axi_bvalid = axi_bready;

  // parameter real CLKIN_FREQ  = 50.0;


  // parameter PLL_REFCLK_IN_PERIOD = 1000000 / CLKIN_FREQ;


  // parameter MEM_ADDR_WIDTH = 15;

  // parameter MEM_BADDR_WIDTH = 3;

  // parameter MEM_DQ_WIDTH = 32;


  // parameter MEM_DM_WIDTH         = MEM_DQ_WIDTH/8;
  // parameter MEM_DQS_WIDTH        = MEM_DQ_WIDTH/8;
  // parameter MEM_NUM              = MEM_DQ_WIDTH/16;

  // reg                           sys_clk          ;
  // reg                           free_clk         ;
  // reg                           ddr_rstn         ;
  // reg                           uart_rxd         ;
  // wire                          uart_txd         ;
  // reg                           grs_n            ;
  wire                          mem_rst_n        ;
  wire                          mem_ck           ;
  wire                          mem_ck_n         ;
  wire                          mem_cke          ;
  wire                          mem_cs_n         ;
  wire                          mem_ras_n        ;
  wire                          mem_cas_n        ;
  wire                          mem_we_n         ;
  wire                          mem_odt          ;
  wire [ MEM_ADDR_WIDTH-1:0]    mem_a            ;
  wire [MEM_BADDR_WIDTH-1:0]    mem_ba           ;
  wire [  MEM_DQS_WIDTH-1:0]    mem_dqs          ;
  wire [  MEM_DQS_WIDTH-1:0]    mem_dqs_n        ;
  wire [   MEM_DQ_WIDTH-1:0]    mem_dq           ;
  wire [   MEM_DM_WIDTH-1:0]    mem_dm           ;
  wire [      ADDR_BITS-1:0]    mem_addr         ;
  wire                          dfi_init_complete;

  /************************************************************/
  //   wire                             core_clk_rst_n            ;
  //   wire                             free_clk_rst_n            ;
  wire                             core_clk                  ;
  wire                             pll_lock                  ;

  //   wire                             free_clk_g                ;
  // wire [CTRL_ADDR_WIDTH-1:0]       axi_awaddr                ;
  // wire                             axi_awuser_ap             ;
  // wire [3:0]                       axi_awuser_id             ;
  // wire [3:0]                       axi_awlen                 ;
  // wire                             axi_awready               ;
  // wire                             axi_awvalid               ;
  // wire [MEM_DQ_WIDTH*8-1:0]        axi_wdata                 ;
  // wire [MEM_DQ_WIDTH*8/8-1:0]      axi_wstrb                 ;
  // wire                             axi_wready                ;
  // wire [CTRL_ADDR_WIDTH-1:0]       axi_araddr                ;
  // wire                             axi_aruser_ap             ;
  // wire [3:0]                       axi_aruser_id             ;
  // wire [3:0]                       axi_arlen                 ;
  // wire                             axi_arready               ;
  // wire                             axi_arvalid               ;
  // wire [MEM_DQ_WIDTH*8-1:0]        axi_rdata                 ;
  // wire                             axi_rvalid                ;
  wire                             resetn                    ;

  // reg  [26:0]                      cnt                       ;

  wire [7:0]                       ck_dly_set_bin            ;
  wire                             force_ck_dly_en           ;
  wire [7:0]                       force_ck_dly_set_bin      ;
  wire [7:0]                       dll_step                  ;
  wire                             dll_lock                  ;

  wire [1:0]                       init_read_clk_ctrl        ;
  wire [3:0]                       init_slip_step            ;
  wire                             force_read_clk_ctrl       ;
  wire                             ddrphy_gate_update_en     ;

  wire [34*MEM_DQS_WIDTH-1:0]      debug_data                ;
  wire [13*MEM_DQS_WIDTH-1:0]      debug_slice_state         ;
  wire [34*4-1:0]                  status_debug_data         ;
  wire [13*4-1:0 ]                 status_debug_slice_state  ;

  wire                             rd_fake_stop              ;
  wire                             bist_run_led              ;
  /******************************************************************/

  // DDR3_50H u_DDR3_50H(
  //             .ref_clk                   (ddr_clk            ),//50Mhz
  //             .resetn                    (ddr_rst_n          ),// wire
  //             .ddr_init_done             (ddr_init_done      ),// wire
  //             .ddrphy_clkin              (axi_aclk           ),// wire    ***axi_aclk
  //             .pll_lock                  (axi_aresetn        ),// wire    ***axi_aresetn

  //             .axi_awaddr                (axi_awaddr         ),// wire [27:0]
  //             .axi_awuser_ap             (1'b0               ),// wire
  //             .axi_awuser_id             (axi_awuser_id      ),// wire [3:0]
  //             .axi_awlen                 (axi_awlen          ),// wire [3:0]
  //             .axi_awready               (axi_awready        ),// wire
  //             .axi_awvalid               (axi_awvalid        ),// wire
  //             .axi_wdata                 (axi_wdata          ),
  //             .axi_wstrb                 (axi_wstrb          ),// wire [31:0]
  //             .axi_wready                (axi_wready         ),// wire
  //             .axi_wusero_id             (                   ),// wire [3:0]
  //             .axi_wusero_last           (axi_wusero_last    ),// wire
  //             .axi_araddr                (axi_araddr         ),// wire [27:0]
  //             .axi_aruser_ap             (1'b0               ),// wire
  //             .axi_aruser_id             (axi_aruser_id      ),// wire [3:0]
  //             .axi_arlen                 (axi_arlen          ),// wire [3:0]
  //             .axi_arready               (axi_arready        ),// wire
  //             .axi_arvalid               (axi_arvalid        ),// wire
  //             .axi_rdata                 (axi_rdata          ),// wire [255:0]
  //             .axi_rid                   (axi_rid            ),// wire [3:0]
  //             .axi_rlast                 (axi_rlast          ),// wire
  //             .axi_rvalid                (axi_rvalid         ),// wire

  //             .apb_clk                   (1'b0               ),// wire
  //             .apb_rst_n                 (1'b1               ),// wire
  //             .apb_sel                   (1'b0               ),// wire
  //             .apb_enable                (1'b0               ),// wire
  //             .apb_addr                  (8'b0               ),// wire [7:0]
  //             .apb_write                 (1'b0               ),// wire
  //             .apb_ready                 (                   ), // wire
  //             .apb_wdata                 (16'b0              ),// wire [15:0]
  //             .apb_rdata                 (                   ),// wire [15:0]
  //             .apb_int                   (                   ),// wire

  //             .mem_rst_n                 (mem_rst_n          ),// wire
  //             .mem_ck                    (mem_ck             ),// wire
  //             .mem_ck_n                  (mem_ck_n           ),// wire
  //             .mem_cke                   (mem_cke            ),// wire
  //             .mem_cs_n                  (mem_cs_n           ),// wire
  //             .mem_ras_n                 (mem_ras_n          ),// wire
  //             .mem_cas_n                 (mem_cas_n          ),// wire
  //             .mem_we_n                  (mem_we_n           ),// wire
  //             .mem_odt                   (mem_odt            ),// wire
  //             .mem_a                     (mem_a              ),// wire [14:0]
  //             .mem_ba                    (mem_ba             ),// wire [2:0]
  //             .mem_dqs                   (mem_dqs            ),// inout [3:0]
  //             .mem_dqs_n                 (mem_dqs_n          ),// inout [3:0]
  //             .mem_dq                    (mem_dq             ),// inout [31:0]
  //             .mem_dm                    (mem_dm             ),// wire [3:0]
  //             //debug
  //             .debug_data                (                   ),// wire [135:0]
  //             .debug_slice_state         (                   ),// wire [51:0]
  //             .debug_calib_ctrl          (                   ),// wire [21:0]
  //             .ck_dly_set_bin            (                   ),// wire [7:0]
  //             .force_ck_dly_en           (1'b0               ),// wire
  //             .force_ck_dly_set_bin      (8'h05              ),// wire [7:0]
  //             .dll_step                  (                   ),// wire [7:0]
  //             .dll_lock                  (                   ),// wire
  //             .init_read_clk_ctrl        (2'b0               ),// wire [1:0]
  //             .init_slip_step            (4'b0               ),// wire [3:0]
  //             .force_read_clk_ctrl       (1'b0               ),// wire
  //             .ddrphy_gate_update_en     (1'b0               ),// wire
  //             .update_com_val_err_flag   (                   ),// wire [3:0]
  //             .rd_fake_stop              (1'b0               ) // wire
  //           );
  parameter real CLKIN_FREQ  = 50.0;
  parameter PLL_REFCLK_IN_PERIOD = 1000000 / CLKIN_FREQ;

  reg sys_clk;//50Mhz
  reg sys_rst_n;
  initial
  begin
    #1 sys_clk = 1'b1;
    sys_rst_n = 1'b1;
  end
  initial
  begin

    //reset the bu_top
    #10000 sys_rst_n = 1'b0;
    #50000 sys_rst_n = 1'b1;
    $display("%t keyboard reset sequence finished!", $time);

    @ (posedge ddr_init_done);
    $display("%t ddr_init_complete is high now!", $time);
    // $stop;
  end
  always #(PLL_REFCLK_IN_PERIOD / 2)  sys_clk = ~sys_clk;
  //pll
  wire pix_clk;
  wire cfg_clk;
  wire clk_25M;
  wire locked;
  wire clk_145_5M;

  wire  clk_1080p;
  wire  vs_1080p ;
  wire  hs_1080p ;
  wire  de_1080p ;

  pll u_pll (
        .clkin1   (  sys_clk    ),//50MHz
        .clkout0  (  pix_clk    ),//74.25M 720P30
        .clkout1  (  cfg_clk    ),//10MHz
        .clkout2  (  clk_25M    ),//25M
        .clkout3  (  clk_1080p    ),//25M
        .pll_lock (  locked     )
      );

  /**************************************************/
  DDR3_50H u_DDR3_50H (
             .ref_clk                   (sys_clk            ),
             .resetn                    (sys_rst_n          ),// input
             .ddr_init_done             (ddr_init_done      ),// output
             .ddrphy_clkin              (core_clk           ),// output
             .pll_lock                  (pll_lock           ),// output

             .axi_awaddr                (axi_awaddr         ),// input [27:0]
             .axi_awuser_ap             (1'b0               ),// input
             .axi_awuser_id             (axi_awuser_id      ),// input [3:0]
             .axi_awlen                 (axi_awlen          ),// input [3:0]
             .axi_awready               (axi_awready        ),// output
             .axi_awvalid               (axi_awvalid        ),// input
             .axi_wdata                 (axi_wdata          ),
             .axi_wstrb                 (axi_wstrb          ),// input [31:0]
             .axi_wready                (axi_wready         ),// output
             .axi_wusero_id             (                   ),// output [3:0]
             .axi_wusero_last           (axi_wusero_last    ),// output
             .axi_araddr                (axi_araddr         ),// input [27:0]
             .axi_aruser_ap             (1'b0               ),// input
             .axi_aruser_id             (axi_aruser_id      ),// input [3:0]
             .axi_arlen                 (axi_arlen          ),// input [3:0]
             .axi_arready               (axi_arready        ),// output
             .axi_arvalid               (axi_arvalid        ),// input
             .axi_rdata                 (axi_rdata          ),// output [255:0]
             .axi_rid                   (axi_rid            ),// output [3:0]
             .axi_rlast                 (axi_rlast          ),// output
             .axi_rvalid                (axi_rvalid         ),// output

             .apb_clk                   (1'b0               ),// input
             .apb_rst_n                 (1'b1               ),// input
             .apb_sel                   (1'b0               ),// input
             .apb_enable                (1'b0               ),// input
             .apb_addr                  (8'b0               ),// input [7:0]
             .apb_write                 (1'b0               ),// input
             .apb_ready                 (                   ), // output
             .apb_wdata                 (16'b0              ),// input [15:0]
             .apb_rdata                 (                   ),// output [15:0]
             .apb_int                   (                   ),// output

             .mem_rst_n                 (mem_rst_n          ),// output
             .mem_ck                    (mem_ck             ),// output
             .mem_ck_n                  (mem_ck_n           ),// output
             .mem_cke                   (mem_cke            ),// output
             .mem_cs_n                  (mem_cs_n           ),// output
             .mem_ras_n                 (mem_ras_n          ),// output
             .mem_cas_n                 (mem_cas_n          ),// output
             .mem_we_n                  (mem_we_n           ),// output
             .mem_odt                   (mem_odt            ),// output
             .mem_a                     (mem_a              ),// output [14:0]
             .mem_ba                    (mem_ba             ),// output [2:0]
             .mem_dqs                   (mem_dqs            ),// inout [3:0]
             .mem_dqs_n                 (mem_dqs_n          ),// inout [3:0]
             .mem_dq                    (mem_dq             ),// inout [31:0]
             .mem_dm                    (mem_dm             ),// output [3:0]
             //debug
             .debug_data                (                   ),// output [135:0]
             .debug_slice_state         (                   ),// output [51:0]
             .debug_calib_ctrl          (                   ),// output [21:0]
             .ck_dly_set_bin            (                   ),// output [7:0]
             .force_ck_dly_en           (1'b0               ),// input
             .force_ck_dly_set_bin      (8'h05              ),// input [7:0]
             .dll_step                  (                   ),// output [7:0]
             .dll_lock                  (                   ),// output
             .init_read_clk_ctrl        (2'b0               ),// input [1:0]
             .init_slip_step            (4'b0               ),// input [3:0]
             .force_read_clk_ctrl       (1'b0               ),// input
             .ddrphy_gate_update_en     (1'b0               ),// input
             .update_com_val_err_flag   (                   ),// output [3:0]
             .rd_fake_stop              (1'b0               ) // input
           );





  ///
  //color_bar
  wire                          Img1_pclk    ;
  wire                          Img1_vs      ;
  wire                          Img1_hs      ;
  wire                          Img1_de      ;

  reg   [15 : 0]               Img1_data    ;

  wire                          Img2_pclk    ;
  wire                          Img2_vs      ;
  wire                          Img2_de      ;
  wire   [15 : 0]               Img2_data    ;

  wire                          Img3_pclk    ;
  wire                          Img3_vs      ;
  wire                          Img3_de      ;
  wire   [15 : 0]               Img3_data    ;

  wire                          Img4_pclk    ;
  wire                          Img4_vs      ;
  wire                          Img4_de      ;
  wire   [15 : 0]               Img4_data    ;





  wire [7:0]  color_bar_r ;
  wire [7:0]  color_bar_g ;
  wire [7:0]  color_bar_b ;

  assign Img1_pclk = pix_clk;
  assign Img2_pclk = pix_clk;
  assign Img3_pclk = pix_clk;
  assign Img4_pclk = pix_clk;


  reg [31:0] cnt;

  reg [15:0] mem1 [0:IMG_ROW] [0:IMG_COL];

  integer m,n;
  initial
  begin
    cnt = 0;
    for (m=0; m<=IMG_ROW; m=m+1)
      for (n=0; n<=IMG_COL; n=n+1)
        mem1[m][n] =0;

    repeat(10) @ (negedge Img1_vs)
    begin
      cnt = cnt + 1;
      $display("cnt time %d!!!", cnt);
      if(cnt == 6)
        $stop;
    end
  end
  integer i,j;
  always @(posedge Img1_pclk or negedge Img1_vs)
  begin
    if(Img1_vs)
    begin
      i <= 0;
      j <= 0;
    end
    else
    begin
      if(cnt == 4)
      begin
        if(Img1_de)
        begin
          j <= j + 1;
          if(j == IMG_COL-1)
          begin
            j <= 0;
            i <= i + 1;
          end
          mem1[i][j] = Img1_data;
        end
      end
      else
      begin
        i <= 0;
        j <= 0;
      end

    end
  end


  wire  vs_o    ;
  wire  de_re   ;
  wire  de_o    ;
  wire  [15:0] o_rgb565;
  //产生视频第一路
  // color_bar u_color_bar_1(
  //             .clk                        (Img1_pclk                  ),
  //             .rst                        (~ddr_init_done           ),
  //             .hs                         (Img1_hs              ),
  //             .vs                         (Img1_vs             ),
  //             .de                         (Img1_de             ),
  //             .rgb_r                      (color_bar_r              ),
  //             .rgb_g                      (color_bar_g              ),
  //             .rgb_b                      (color_bar_b              )
  //           );


  // wire                        hdmi_in_clk ;
  // wire                        hdmi_in_vs  ;
  // wire                        hdmi_in_de  ;
  // wire   [15:0]               hdmi_in_data;

  // de_frame  de_frame_inst (
  //             .rst_n          (ddr_init_done  ),
  //             .video_clk_i    (Img1_pclk        ),
  //             .video_vs_i     (Img1_vs            ),
  //             .video_de_i     (Img1_de            ),
  //             .video_data_i   (Img1_data   ),

  //             .video_clk_o    (hdmi_in_clk    ),
  //             .video_vs_o     (hdmi_in_vs     ),
  //             .video_de_o     (hdmi_in_de     ),
  //             .video_data_o   (hdmi_in_data   )
  //           );


  color_bar 
  // #(
  //   .H_ACTIVE (16'd320	) ,
  //   .H_FP 		(16'd1		) ,
  //   .H_SYNC 	(16'd41	) ,
  //   .H_BP 		(16'd1		) ,
  //   .V_ACTIVE (16'd40	) ,
  //   .V_FP  	  (16'd1		) ,
  //   .V_SYNC   (16'd1		) ,
  //   .V_BP  	  (16'd1		) ,
  //   .HS_POL 	(1'b1		) ,
  //   .VS_POL 	(1'b1		) 
  // )
  u_color_bar_11
            (
              .clk   (Img1_pclk      ),
              .rst   (~ddr_init_done),
              .hs    (Img1_hs       ),
              .vs    (Img1_vs       ),
              .de    (Img1_de       ),
              .rgb_r (    ),
              .rgb_g (    ),
              .rgb_b (    )
            );

            color_bar u_color_bar_12
            (
              .clk   (clk_1080p      ),
              .rst   (~ddr_init_done),
              .hs    (hs_1080p       ),
              .vs    (vs_1080p       ),
              .de    (de_1080p       ),
              .rgb_r (    ),
              .rgb_g (    ),
              .rgb_b (    )
            );

            
// vs_1080p 
// hs_1080p 
// de_1080p 

  // color_bar
  //           #(
  //             .H_ACTIVE ( 16'd1920  ),
  //             .H_FP 		( 16'd88	  ),
  //             .H_SYNC 	( 16'd44	  ),
  //             .H_BP 		( 16'd148   ),
  //             .V_ACTIVE	( 16'd1080  ),
  //             .V_FP  		( 16'd4	    ),
  //             .V_SYNC  	( 16'd5	    ),
  //             .V_BP  		( 16'd36	  ),
  //             .HS_POL 	( 1'b1		  ),
  //             .VS_POL 	( 1'b1		  )
  //           ) u_color_bar_12
  //           (
  //             .clk   (clk_145_5M       ),
  //             .rst   (~locked       ),
  //             .hs    (Img_hs_o       ),
  //             .vs    (Img_vs_o       ),
  //             .de    (Img_de_o       ),
  //             .rgb_r (    ),
  //             .rgb_g (    ),
  //             .rgb_b (    )
  //           );



  fram_buf
    #(
      .H_NUM  (640),
      .V_NUM  (40)
    )

    u_fram_buf(
      .ddr_clk        (  core_clk             ),//input                         ddr_clk,
      .ddr_rstn       (  ddr_init_done        ),//input                         ddr_rstn,
      //data_in
      .cmos1_clk        (  Img1_pclk          ),//input                         vin_clk,
      .cmos1_vs         (  Img1_vs           ),//input                         wr_fsync,
      .cmos1_de         (  Img1_de           ),//input                         wr_en,
      .cmos1_data       (  Img1_data         ),//input

      .cmos2_clk        (  Img1_pclk          ),//input                         vin_clk,
      .cmos2_vs         (  Img1_vs            ),//input                         wr_fsync,
      .cmos2_de         (  Img1_de            ),//input                         wr_en,
      .cmos2_data       (  Img1_data          ),//input

      .hdmi_in_clk        (  Img1_pclk          ),
      .hdmi_in_vs         (  Img1_vs            ),
      .hdmi_in_de         (  Img1_de            ),
      .hdmi_in_data       (  Img1_data          ),

      .udp_in_clk        (  Img1_pclk          ),
      .udp_in_vs         (  Img1_vs            ),
      .udp_in_de         (  Img1_de            ),
      .udp_in_data       (  Img1_data          ),


      .udp_char_clk (Img1_pclk),
      .udp_char_vs  (Img1_vs  ),
      .udp_char_de  (Img1_de  ),
      .udp_char_data(Img1_data),
      //data_out
      // .vout_clk       (  Img1_pclk              ),//input                         vout_clk,
      // .rd_fsync       (  Img1_vs               ),//input                         rd_fsync,
      // .rd_en          (  Img1_de                ),//input                         rd_en,
      // .vout_de        (  de_o               ),//output                        vout_de,
      // .vout_data      (  o_rgb565             ),//output [PIX_WIDTH- 1'b1 : 0]  vout_data,

      .clk_720p(Img1_pclk ),
      .vs_720p (Img1_vs   ),
      .hs_720p (Img1_hs   ),
      .de_720p (Img1_de   ),

      .clk_1080p(Img1_pclk),
      .vs_1080p (Img1_vs  ),
      .hs_1080p (Img1_hs  ),
      .de_1080p (Img1_de  ),

      .vout_clk (),
      .vout_vs  (),
      .vout_hs  (),
      .vout_de  (),
      .vout_data(),


      .init_done      (  init_done            ),//output reg                    init_done,
      //axi bus
      .axi_awaddr     (  axi_awaddr           ),// output[27:0]
      .axi_awid       (  axi_awuser_id        ),// output[3:0]
      .axi_awlen      (  axi_awlen            ),// output[3:0]
      .axi_awsize     (                       ),// output[2:0]
      .axi_awburst    (                       ),// output[1:0]
      .axi_awready    (  axi_awready          ),// input
      .axi_awvalid    (  axi_awvalid          ),// output
      .axi_wdata      (  axi_wdata            ),// output[255:0]
      .axi_wstrb      (  axi_wstrb            ),// output[31:0]
      .axi_wlast      (  axi_wusero_last      ),// input
      .axi_wvalid     (                       ),// output
      .axi_wready     (  axi_wready           ),// input
      .axi_bid        (  4'd0                 ),// input[3:0]
      .axi_araddr     (  axi_araddr           ),// output[27:0]
      .axi_arid       (  axi_aruser_id        ),// output[3:0]
      .axi_arlen      (  axi_arlen            ),// output[3:0]
      .axi_arsize     (                       ),// output[2:0]
      .axi_arburst    (                       ),// output[1:0]
      .axi_arvalid    (  axi_arvalid          ),// output
      .axi_arready    (  axi_arready          ),// input
      .axi_rready     (                       ),// output
      .axi_rdata      (  axi_rdata            ),// input[255:0]
      .axi_rvalid     (  axi_rvalid           ),// input
      .axi_rlast      (  axi_rlast            ),// input
      .axi_rid        (  axi_rid              ) // input[3:0]
    );


  always @(posedge Img1_pclk or negedge Img1_vs)
  begin
    if(Img1_vs)
    begin
      Img1_data <= 16'd0;
    end
    else
    begin
      if(Img1_de)
        Img1_data <= Img1_data + 16'd1;
      else
        Img1_data <= Img1_data;
    end

  end



  /***********************************************************/
  // wire  							                  pro_wr_burst_req      ;
  // wire   [LEN_WIDTH - 1:0] 		          pro_wr_burst_len      ;
  // wire   [AXI_ADDR_WIDTH-1:0] 			    pro_wr_burst_addr     ;
  // wire   							                  pro_wr_burst_data_req ;
  // wire   [AXI_DATA_WIDTH - 1:0] 		    pro_wr_burst_data     ;
  // wire   							                  pro_wr_burst_finish   ;

  // wire  							                  pro_rd_burst_req      ;
  // wire   [LEN_WIDTH - 1:0] 		          pro_rd_burst_len      ;
  // wire   [AXI_ADDR_WIDTH-1:0] 			    pro_rd_burst_addr     ;
  // wire   							                  pro_rd_burst_data_valid;
  // wire   [AXI_DATA_WIDTH - 1:0] 		    pro_rd_burst_data     ;
  // wire   							                  pro_rd_burst_finish   ;

  // wire                        rd_cmd_en   ;
  // wire [AXI_ADDR_WIDTH-1:0]   rd_cmd_addr ;
  // wire [LEN_WIDTH- 1'b1: 0]   rd_cmd_len  ;
  // wire                        rd_cmd_ready;
  // wire                        rd_cmd_done ;

  // wire                        read_en   ;
  // wire [255:0]   read_rdata ;



  // wire                        ddr_wreq;
  // wire [AXI_ADDR_WIDTH-1:0]   ddr_waddr;
  // wire [LEN_WIDTH- 1'b1 : 0]  ddr_wr_len;
  // wire                        ddr_wrdy;
  // wire                        ddr_wdone;
  // wire [8*MEM_DQ_WIDTH-1 : 0] ddr_wdata;
  // wire                        ddr_wdata_req;


  // processor  u_processor_inst (
  //              .axi_clk   (core_clk         ),
  //              .axi_arst_n(ddr_init_done        ),
  //              // .rst_n      (ddr_rstn       ),
  //              .mode       (8'd3            ),

  //              .img_720_clk_i       (Img1_pclk       ),
  //              .img_720_vs_i        (Img1_vs        ),
  //              .img_720_hs_i        (Img1_hs        ),
  //              .img_720_de_i        (Img1_de      ),
  //              .img_720_data_i      (Img1_data    ),

  //              .img_1080_clk_i  (clk_1080p     ),
  //              .img_1080_vs_i   (vs_1080p       ),
  //              .img_1080_hs_i   (hs_1080p       ),
  //              .img_1080_de_i   (de_1080p       ),
  //              // .img_1080_data_i (vout_data_w    ),

  //              .vout_clk  (       ),
  //              .vout_vs   (       ),
  //              .vout_hs   (       ),
  //              .vout_de   (       ),
  //              .vout_data (       ),

  //              .wr_burst_req     (pro_wr_burst_req     ),
  //              .wr_burst_len     (pro_wr_burst_len     ),
  //              .wr_burst_addr    (pro_wr_burst_addr    ),
  //              .wr_burst_data_req(pro_wr_burst_data_req),
  //              .wr_burst_data    (pro_wr_burst_data    ),
  //              .wr_burst_finish  (pro_wr_burst_finish  ),

  //              .rd_burst_req       (pro_rd_burst_req       ),
  //              .rd_burst_len       (pro_rd_burst_len       ),
  //              .rd_burst_addr      (pro_rd_burst_addr      ),
  //              .rd_burst_data_valid(pro_rd_burst_data_valid),
  //              .rd_burst_data      (pro_rd_burst_data      ),
  //              .rd_burst_finish    (pro_rd_burst_finish    )
  //            );




  // mem_read_arbi u_mem_read_arbi (
  //                 .rst_n                  (     ddr_init_done               ),
  //                 .mem_clk                (      core_clk         ),

  //                 // .ch0_rd_burst_req       (ch0_rd_burst_req     ),
  //                 // .ch0_rd_burst_len       (ch0_rd_burst_len     ),
  //                 // .ch0_rd_burst_addr      (ch0_rd_burst_addr    ),
  //                 // .ch0_rd_burst_data_valid(ch0_rd_burst_data_valid),
  //                 // .ch0_rd_burst_data      (ch0_rd_burst_data    ),
  //                 // .ch0_rd_burst_finish    (ch0_rd_burst_finish  ),

  //                 .ch1_rd_burst_req       (pro_rd_burst_req       ),
  //                 .ch1_rd_burst_len       (pro_rd_burst_len       ),
  //                 .ch1_rd_burst_addr      (pro_rd_burst_addr      ),
  //                 .ch1_rd_burst_data_valid(pro_rd_burst_data_valid),
  //                 .ch1_rd_burst_data      (pro_rd_burst_data      ),
  //                 .ch1_rd_burst_finish    (pro_rd_burst_finish    ),


  //                 .rd_burst_req           (rd_cmd_en              ),
  //                 .rd_burst_len           (rd_cmd_len             ),
  //                 .rd_burst_addr          (rd_cmd_addr            ),
  //                 .rd_burst_data_valid    (read_en                ),
  //                 .rd_burst_data          (read_rdata             ),
  //                 .rd_burst_finish        (rd_cmd_done            )
  //               );
  // /*
  // *   arbiter writer
  // */
  // mem_write_arbi mem_write_arbi_m0(
  //                  .rst_n                       (ddr_init_done       ),
  //                  .mem_clk                     ( core_clk          ),

  //                  // .ch0_wr_burst_req            (ch0_wr_burst_req),
  //                  // .ch0_wr_burst_len            (ch0_wr_burst_len),
  //                  // .ch0_wr_burst_addr           (ch0_wr_burst_addr),
  //                  // .ch0_wr_burst_data_req       (ch0_wr_burst_data_req),
  //                  // .ch0_wr_burst_data           (ch0_wr_burst_data),
  //                  // .ch0_wr_burst_finish         (ch0_wr_burst_finish),

  //                  // .ch1_wr_burst_req            (ch1_wr_burst_req),
  //                  // .ch1_wr_burst_len            (ch1_wr_burst_len),
  //                  // .ch1_wr_burst_addr           (ch1_wr_burst_addr),
  //                  // .ch1_wr_burst_data_req       (ch1_wr_burst_data_req),
  //                  // .ch1_wr_burst_data           (ch1_wr_burst_data),
  //                  // .ch1_wr_burst_finish         (ch1_wr_burst_finish),

  //                  // .ch2_wr_burst_req            (ch2_wr_burst_req),
  //                  // .ch2_wr_burst_len            (ch2_wr_burst_len),
  //                  // .ch2_wr_burst_addr           (ch2_wr_burst_addr),
  //                  // .ch2_wr_burst_data_req       (ch2_wr_burst_data_req),
  //                  // .ch2_wr_burst_data           (ch2_wr_burst_data),
  //                  // .ch2_wr_burst_finish         (ch2_wr_burst_finish),

  //                  // .ch3_wr_burst_req            (ch3_wr_burst_req      ),
  //                  // .ch3_wr_burst_len            (ch3_wr_burst_len      ),
  //                  // .ch3_wr_burst_addr           (ch3_wr_burst_addr     ),
  //                  // .ch3_wr_burst_data_req       (ch3_wr_burst_data_req ),
  //                  // .ch3_wr_burst_data           (ch3_wr_burst_data     ),
  //                  // .ch3_wr_burst_finish         (ch3_wr_burst_finish   ),

  //                  .ch4_wr_burst_req            (pro_wr_burst_req      ),
  //                  .ch4_wr_burst_len            (pro_wr_burst_len      ),
  //                  .ch4_wr_burst_addr           (pro_wr_burst_addr     ),
  //                  .ch4_wr_burst_data_req       (pro_wr_burst_data_req ),
  //                  .ch4_wr_burst_data           (pro_wr_burst_data     ),
  //                  .ch4_wr_burst_finish         (pro_wr_burst_finish   ),

  //                  .wr_burst_req                 (ddr_wreq             ),
  //                  .wr_burst_len                 (ddr_wr_len           ),
  //                  .wr_burst_addr                (ddr_waddr            ),
  //                  .wr_burst_data_req            (ddr_wdata_req        ),
  //                  .wr_burst_data                (ddr_wdata            ),
  //                  .wr_burst_finish              (ddr_wdone            )
  //                );


  // /*
  // *
  // */
  // wr_rd_ctrl_top#(
  //                 .CTRL_ADDR_WIDTH  (  CTRL_ADDR_WIDTH  ),//parameter                    CTRL_ADDR_WIDTH      = 28,
  //                 .MEM_DQ_WIDTH     (  MEM_DQ_WIDTH     ) //parameter                    MEM_DQ_WIDTH         = 16
  //               )wr_rd_ctrl_top (
  //                 .clk              (       core_clk    ),//input                        clk            ,
  //                 .rstn             (     ddr_init_done           ),//input                        rstn           ,

  //                 .wr_cmd_en        (  ddr_wreq         ),//input                        wr_cmd_en   ,
  //                 .wr_cmd_addr      (  ddr_waddr        ),//input  [CTRL_ADDR_WIDTH-1:0] wr_cmd_addr ,
  //                 .wr_cmd_len       (  ddr_wr_len       ),//input  [31£º0]               wr_cmd_len  ,
  //                 .wr_cmd_ready     (  ddr_wrdy         ),//output                       wr_cmd_ready,
  //                 .wr_cmd_done      (  ddr_wdone        ),//output                       wr_cmd_done,
  //                 .wr_bac           (  ddr_wr_bac       ),//output                       wr_bac,
  //                 .wr_ctrl_data     (  ddr_wdata        ),//input  [MEM_DQ_WIDTH*8-1:0]  wr_ctrl_data,
  //                 .wr_data_re       (  ddr_wdata_req    ),//output                       wr_data_re  ,

  //                 .rd_cmd_en        (  rd_cmd_en        ),//input                        rd_cmd_en   ,
  //                 .rd_cmd_addr      (  rd_cmd_addr      ),//input  [CTRL_ADDR_WIDTH-1:0] rd_cmd_addr ,
  //                 .rd_cmd_len       (  rd_cmd_len       ),//input  [31£º0]               rd_cmd_len  ,
  //                 .rd_cmd_ready     (  rd_cmd_ready     ),//output                       rd_cmd_ready,
  //                 .rd_cmd_done      (  rd_cmd_done      ),//output                       rd_cmd_done,

  //                 .read_ready       (  read_ready       ),//input                        read_ready  ,
  //                 .read_rdata       (  read_rdata       ),//output [MEM_DQ_WIDTH*8-1:0]  read_rdata  ,
  //                 .read_en          (  read_en          ),//output                       read_en     ,
  //                 // write channel
  //                 .axi_awaddr       (  axi_awaddr       ),//output [CTRL_ADDR_WIDTH-1:0] axi_awaddr     ,
  //                 .axi_awid         (  axi_awid         ),//output [3:0]                 axi_awid       ,
  //                 .axi_awlen        (  axi_awlen        ),//output [3:0]                 axi_awlen      ,
  //                 .axi_awsize       (  axi_awsize       ),//output [2:0]                 axi_awsize     ,
  //                 .axi_awburst      (  axi_awburst      ),//output [1:0]                 axi_awburst    , //only support 2'b01: INCR
  //                 .axi_awready      (  axi_awready      ),//input                        axi_awready    ,
  //                 .axi_awvalid      (  axi_awvalid      ),//output                       axi_awvalid    ,

  //                 .axi_wdata        (  axi_wdata        ),//output [MEM_DQ_WIDTH*8-1:0]  axi_wdata      ,
  //                 .axi_wstrb        (  axi_wstrb        ),//output [MEM_DQ_WIDTH -1 :0]  axi_wstrb      ,
  //                 .axi_wlast        (  axi_wusero_last        ),//output                       axi_wlast      ,
  //                 .axi_wvalid       (  axi_wvalid       ),//output                       axi_wvalid     ,
  //                 .axi_wready       (  axi_wready       ),//input                        axi_wready     ,
  //                 .axi_bid          (  4'd0             ),//input  [3 : 0]               axi_bid        , // Master Interface Write Response.
  //                 .axi_bresp        (  2'd0             ),//input  [1 : 0]               axi_bresp      , // Write response. This signal indicates the status of the write transaction.
  //                 .axi_bvalid       (  1'b0             ),//input                        axi_bvalid     , // Write response valid. This signal indicates that the channel is signaling a valid write response.
  //                 .axi_bready       (                   ),//output                       axi_bready     ,

  //                 // read channel
  //                 .axi_araddr       (  axi_araddr       ),//output [CTRL_ADDR_WIDTH-1:0] axi_araddr     ,
  //                 .axi_arid         (  axi_arid         ),//output [3:0]                 axi_arid       ,
  //                 .axi_arlen        (  axi_arlen        ),//output [3:0]                 axi_arlen      ,
  //                 .axi_arsize       (  axi_arsize       ),//output [2:0]                 axi_arsize     ,
  //                 .axi_arburst      (  axi_arburst      ),//output [1:0]                 axi_arburst    ,
  //                 .axi_arvalid      (  axi_arvalid      ),//output                       axi_arvalid    ,
  //                 .axi_arready      (  axi_arready      ),//input                        axi_arready    , //only support 2'b01: INCR

  //                 .axi_rready       (  axi_rready       ),//output                       axi_rready     ,
  //                 .axi_rdata        (  axi_rdata        ),//input  [MEM_DQ_WIDTH*8-1:0]  axi_rdata      ,
  //                 .axi_rvalid       (  axi_rvalid       ),//input                        axi_rvalid     ,
  //                 .axi_rlast        (  axi_rlast        ),//input                        axi_rlast      ,
  //                 .axi_rid          (  axi_rid          ),//input  [3:0]                 axi_rid        ,
  //                 .axi_rresp        (  2'd0             ) //input  [1:0]                 axi_rresp
  //               );

  /*
  *main code
  */
  // Frame_top u_Frame_top (

  //             .Img1_pclk         (Img1_pclk),
  //             .Img1_vs           (Img1_vs  ),
  //             .Img1_de           (Img1_de  ),
  //             .Img1_data         (Img1_data),

  //             .Img2_pclk         (Img1_pclk),
  //             .Img2_vs           (Img1_vs  ),
  //             .Img2_de           (Img1_de  ),
  //             .Img2_data         (Img1_data),

  //             .Img3_pclk         (Img1_pclk),
  //             .Img3_vs           (Img1_vs  ),
  //             .Img3_de           (Img1_de  ),
  //             .Img3_data         (Img1_data),

  //             .Img4_pclk         (Img1_pclk),
  //             .Img4_vs           (Img1_vs  ),
  //             .Img4_de           (Img1_de  ),
  //             .Img4_data         (Img1_data),

  //             .Img_pclk_i        (pix_clk     ),//hdmi clk 74.25MHZ
  //             .Img_pclk_o        (            ),
  //             .Img_vs_o          (vs_out      ),
  //             .Img_hs_o          (hs_out      ),
  //             .Img_de_o          (de_out      ),
  //             .Img_data_o        (hdmi_data_o ),

  //             //AXI
  //             .axi_aclk          (core_clk         ),
  //             .axi_aresetn       (pll_lock         ),
  //             .ddr_init_done     (ddr_init_done    ),
  //             .m_axi_awaddr      (  axi_awaddr     ),
  //             .m_axi_awid        (  axi_awuser_id  ),
  //             .m_axi_awlen       (  axi_awlen      ),
  //             .m_axi_awready     (  axi_awready    ),
  //             .m_axi_awvalid     (  axi_awvalid    ),
  //             .m_axi_wdata       (  axi_wdata      ),
  //             .m_axi_wstrb       (  axi_wstrb      ),
  //             .m_axi_wready      (  axi_wready     ),
  //             .m_axi_wlast       (                 ),
  //             .m_axi_bvalid      (                 ),
  //             .m_axi_bready      (                 ),
  //             .m_axi_araddr      (  axi_araddr     ),
  //             .m_axi_arid        (  axi_aruser_id  ),
  //             .m_axi_arlen       (  axi_arlen      ),
  //             .m_axi_arready     (  axi_arready    ),
  //             .m_axi_arvalid     (  axi_arvalid    ),
  //             .m_axi_rdata       (  axi_rdata      ),
  //             .m_axi_rid         (  axi_rid        ),
  //             .m_axi_rlast       (  axi_rlast      ),
  //             .m_axi_rvalid      (  axi_rvalid     )
  //           );
  /*****************************************************************/

  reg  [MEM_NUM:0]              mem_ck_dly;
  reg  [MEM_NUM:0]              mem_ck_n_dly;

  always @ (*)
  begin
    mem_ck_dly[0]   <=  mem_ck;
    mem_ck_n_dly[0] <=  mem_ck_n;
  end

  assign mem_addr = {{(ADDR_BITS-MEM_ADDR_WIDTH){1'b0}},{mem_a}};

  genvar gen_mem;
  generate
    for(gen_mem=0; gen_mem<MEM_NUM; gen_mem=gen_mem+1)
    begin   : i_mem

      always @ (*)
      begin
        mem_ck_dly[gen_mem+1] <= #50 mem_ck_dly[gen_mem];
        mem_ck_n_dly[gen_mem+1] <= #50 mem_ck_n_dly[gen_mem];
      end

      ddr3      mem_core (

                  .rst_n             (mem_rst_n                        ),
                  .ck                (mem_ck_dly[gen_mem+1]            ),
                  .ck_n              (mem_ck_n_dly[gen_mem+1]          ),

                  .cs_n              (mem_cs_n                         ),

                  .addr              (mem_addr                         ),
                  .dq                (mem_dq[16*gen_mem+15:16*gen_mem] ),
                  .dqs               (mem_dqs[2*gen_mem+1:2*gen_mem]   ),
                  .dqs_n             (mem_dqs_n[2*gen_mem+1:2*gen_mem] ),
                  .dm_tdqs           (mem_dm[2*gen_mem+1:2*gen_mem]    ),
                  .tdqs_n            (                                 ),
                  .cke               (mem_cke                          ),
                  .odt               (mem_odt                          ),
                  .ras_n             (mem_ras_n                        ),
                  .cas_n             (mem_cas_n                        ),
                  .we_n              (mem_we_n                         ),
                  .ba                (mem_ba                           )
                );
    end
  endgenerate


  /********************clk and init******************/

  //   always #(PLL_REFCLK_IN_PERIOD / 2)  sys_clk = ~sys_clk;

  //   //   always #(20000 / 2)  free_clk = ~free_clk;


  //   initial
  //   begin

  //     #1
  //      sys_clk = 0;

  //     //default wire from keyboard
  //     ddr_rstn = 1'b1;

  //   end
  /*******************end of clk and init*******************/


  //GTP_GRS I_GTP_GRS(
  // GTP_GRS u2_GRS_INST(
  //           .GRS_N (grs_n)
  //         );
  // initial
  // begin
  //   grs_n = 1'b0;
  //   #5000 grs_n = 1'b1;
  // end

  //   initial
  //   begin

  //     //reset the bu_top
  //     #10000 ddr_rstn = 1'b0;
  //     #50000 ddr_rstn = 1'b1;
  //     $display("%t keyboard reset sequence finished!", $time);

  //     @ (posedge dfi_init_complete);
  //     $display("%t dfi_init_complete is high now!", $time);
  //     //   #100000000;
  //     //   $finish;
  //   end

  //   initial
  //   begin
  //     $fsdbDumpfile("ddr_test_top_tb.fsdb");
  //     $fsdbDumpvars(0,"ddr_test_top_tb");
  //   end
  /**************************************************/
  /**************************************************/







  //   wire [10:0] t_width_wr ;
  //   wire [10:0] t_height_wr;
  //   wire [10:0] t_width_rd ;
  //   wire [10:0] t_height_rd;
  //   wire [15:0] h_scale_k  ;
  //   wire [15:0] v_scale_k  ;

  //   wire Img_vs_i;
  //   wire Img_hs_i;
  //   wire Img_de_i;

  //   wire Img_vs_o;
  //   wire Img_hs_o;
  //   wire Img_de_o;

  //   wire [15:0] Img_data_i;
  //   wire [15:0] Img_data_o;

  //   wire [7:0] color_bar_r1;
  //   wire [7:0] color_bar_g1;
  //   wire [7:0] color_bar_b1;
  //   // wire Img1_de;
  //   wire Img1_vs_o;
  //   wire Img1_hs_o;
  //   wire Img1_de_o;
  //   wire [7:0] Img1_data_o;
  //   wire [11:0] s_width ;
  //   wire [11:0] s_height;
  //   wire [11:0] t_width ;
  //   wire [11:0] t_height;

  // assign s_width  =   11'd1280;
  // assign s_height =   11'd720 ;
  // assign t_width  =   11'd640 ;
  // assign t_height =   11'd360  ;

  //   assign Img_data_i = {color_bar_r1[7:3],color_bar_g1[7:2],color_bar_b1[7:3]};




  //   color_bar
  //             #(
  //               .H_ACTIVE (16'd1280	),
  //               .H_FP 		(16'd110	),
  //               .H_SYNC 	(16'd40		),
  //               .H_BP 		(16'd220	),
  //               .V_ACTIVE	(16'd720	),
  //               .V_FP  		(16'd5		),
  //               .V_SYNC  	(16'd5		),
  //               .V_BP  		(16'd20		),
  //               .HS_POL 	(1'b1		),
  //               .VS_POL 	(1'b1		)
  //             ) u_color_bar_11
  //             (
  //               .clk   (pix_clk       ),
  //               .rst   (~locked       ),
  //               .hs    (Img_hs_i       ),
  //               .vs    (Img_vs_i       ),
  //               .de    (Img_de_i       ),
  //               .rgb_r (color_bar_r1   ),
  //               .rgb_g (color_bar_g1   ),
  //               .rgb_b (color_bar_b1   )
  //             );


  //   color_bar
  //             #(
  //               .H_ACTIVE ( 16'd1920  ),
  //               .H_FP 		( 16'd88	  ),
  //               .H_SYNC 	( 16'd44	  ),
  //               .H_BP 		( 16'd148   ),
  //               .V_ACTIVE	( 16'd1080  ),
  //               .V_FP  		( 16'd4	    ),
  //               .V_SYNC  	( 16'd5	    ),
  //               .V_BP  		( 16'd36	  ),
  //               .HS_POL 	( 1'b1		  ),
  //               .VS_POL 	( 1'b1		  )
  //             ) u_color_bar_12
  //             (
  //               .clk   (clk_145_5M       ),
  //               .rst   (~locked       ),
  //               .hs    (Img_hs_o       ),
  //               .vs    (Img_vs_o       ),
  //               .de    (Img_de_o       ),
  //               .rgb_r (    ),
  //               .rgb_g (    ),
  //               .rgb_b (    )
  //             );




  //   para_change  u_para_change (
  //                  .clk_wr         (pix_clk         ),
  //                  .clk_rd         (clk_145_5M       ),
  //                  .change_en      (2'd0            ),
  //                  .s_width        (s_width         ),//缩放前宽度
  //                  .s_height       (s_height        ),//缩放前高度

  //                  .t_width        (t_width       ),//缩放后宽度
  //                  .t_height       (t_height      ),//缩放后高度
  //                  .rst_n          (locked         ),
  //                  .rd_vsync       (Img_vs_i       ),
  //                  .wr_vsync       (Img_vs_o       ),

  //                  .t_width_wr     (t_width_wr     ),
  //                  .t_height_wr    (t_height_wr    ),
  //                  .t_width_rd     (t_width_rd     ),
  //                  .t_height_rd    (t_height_rd    ),
  //                  .h_scale_k      (h_scale_k      ),
  //                  .v_scale_k      (v_scale_k      )

  //                  //  .change_en_wr   (change_en_wr   ),
  //                  //  .change_en_rd   (change_en_rd   ),
  //                  //  .app_addr_rd_max(app_addr_rd_max),
  //                  //  .rd_bust_len    (rd_bust_len    ),
  //                  //  .app_addr_wr_max(app_addr_wr_max),
  //                  //  .wr_bust_len    (wr_bust_len    )
  //                );
  //   scale_top  u_scale_top (
  //                .sys_rst_n      (locked          ),

  //                .pixel_clk      (pix_clk          ),
  //                .pixel_data     (Img_data_i         ),
  //                .hs             (Img_de_i           ),
  //                .vs             (Img_vs_i           ),
  //                .de             (Img_de_i           ),

  //                .sram_clk       (pix_clk         ),//clk_145_5M
  //                .sram_data_out  (Img_data_o         ),
  //                .data_valid     (Img_de_o           ),

  //                .s_width        (s_width            ),
  //                .s_height       (s_height           ),
  //                .t_width        (t_width            ),
  //                .t_height       (t_height           ),

  //                .h_scale_k      (h_scale_k          ),
  //                .v_scale_k      (v_scale_k          )


  //              );

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

