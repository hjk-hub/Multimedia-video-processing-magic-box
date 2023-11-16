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
//cmos1,cmos2二选一,作为视频源输入
// `define CMOS_1      //cmos1作为视频输入;
//`define CMOS_2      //cmos2作为视频输入;

module video_top#(
    parameter MEM_ROW_ADDR_WIDTH   = 15         ,
    parameter MEM_COL_ADDR_WIDTH   = 10         ,
    parameter MEM_BADDR_WIDTH      = 3          ,
    parameter MEM_DQ_WIDTH         =  32        ,
    parameter MEM_DQS_WIDTH        =  32/8
  )(
    input                                sys_clk              ,//50Mhz

    input     wire [7:0]                 key                 ,
    output    wire [7:0]                 led                 ,
    //OV5647
    // output  [1:0]                        cmos_init_done       ,//OV5640寄存器初始化完成
    //coms1
    inout                                cmos1_scl            ,//cmos1 i2c
    inout                                cmos1_sda            ,//cmos1 i2c
    input                                cmos1_vsync          ,//cmos1 vsync
    input                                cmos1_href           ,//cmos1 hsync refrence,data valid
    input                                cmos1_pclk           ,//cmos1 pxiel clock
    input   [7:0]                        cmos1_data           ,//cmos1 data
    output                               cmos1_reset          ,//cmos1 reset
    //coms2
    inout                                cmos2_scl            ,//cmos2 i2c
    inout                                cmos2_sda            ,//cmos2 i2c
    input                                cmos2_vsync          ,//cmos2 vsync
    input                                cmos2_href           ,//cmos2 hsync refrence,data valid
    input                                cmos2_pclk           ,//cmos2 pxiel clock
    input   [7:0]                        cmos2_data           ,//cmos2 data
    output                               cmos2_reset          ,//cmos2 reset
    //DDR
    output                               mem_rst_n                 ,
    output                               mem_ck                    ,
    output                               mem_ck_n                  ,
    output                               mem_cke                   ,
    output                               mem_cs_n                  ,
    output                               mem_ras_n                 ,
    output                               mem_cas_n                 ,
    output                               mem_we_n                  ,
    output                               mem_odt                   ,
    output      [MEM_ROW_ADDR_WIDTH-1:0] mem_a                     ,
    output      [MEM_BADDR_WIDTH-1:0]    mem_ba                    ,
    inout       [MEM_DQ_WIDTH/8-1:0]     mem_dqs                   ,
    inout       [MEM_DQ_WIDTH/8-1:0]     mem_dqs_n                 ,
    inout       [MEM_DQ_WIDTH-1:0]       mem_dq                    ,
    output      [MEM_DQ_WIDTH/8-1:0]     mem_dm                    ,
    // output reg                           heart_beat_led            ,
    // output                               ddr_init_done             ,
    //MS72xx
    output                               rstn_out                  ,
    output                               iic_tx_scl                ,
    inout                                iic_tx_sda                ,
    output                               iic_scl                   ,
    inout                                iic_sda                   ,
    // output                               hdmi_int_led              ,//HDMI_OUT初始化完成

    input                               pixclk_in                 /*synthesis PAP_MARK_DEBUG="1"*/,//pixclk
    input     wire                      vs_in                     /*synthesis PAP_MARK_DEBUG="1"*/,
    input     wire                      hs_in                     /*synthesis PAP_MARK_DEBUG="1"*/,
    input     wire                      de_in                     /*synthesis PAP_MARK_DEBUG="1"*/,
    input     wire [7:0]                r_in                      /*synthesis PAP_MARK_DEBUG="1"*/,
    input     wire [7:0]                g_in                      /*synthesis PAP_MARK_DEBUG="1"*/,
    input     wire [7:0]                b_in                      /*synthesis PAP_MARK_DEBUG="1"*/,

    //HDMI_OUT
    output                               pix_clk                   ,//pixclk
    output                               vs_out                    ,
    output                               hs_out                    ,
    output                               de_out                    ,
    output           [7:0]               r_out                     ,
    output           [7:0]               g_out                     ,
    output           [7:0]               b_out                      ,
    //UDP1 视频输入
    output       phy_rstn                                   ,
    input        rgmii_rxc                                  ,
    input        rgmii_rx_ctl                               ,
    input [3:0]  rgmii_rxd                                  ,

    output       rgmii_txc                                  ,
    output       rgmii_tx_ctl                               ,
    output [3:0] rgmii_txd
    // output       udp_led                                    ,
    //UDP2 字符等信息输入
    // output       phy_rstn2                                   ,
    // input        rgmii_rxc2                                  ,
    // input        rgmii_rx_ctl2                               ,
    // input [3:0]  rgmii_rxd2                                  ,

    // output       rgmii_txc2                                  ,
    // output       rgmii_tx_ctl2                               ,
    // output [3:0] rgmii_txd2                                   ,
    // output       udp_led2

  );
  /////////////////////////////////////////////////////////////////////////////////////
  // ENABLE_DDR
  parameter CTRL_ADDR_WIDTH = MEM_ROW_ADDR_WIDTH + MEM_BADDR_WIDTH + MEM_COL_ADDR_WIDTH;//28
  parameter TH_1S = 27'd33000000;
  /////////////////////////////////////////////////////////////////////////////////////
  wire                        ddr_init_done       ;
  wire [1:0]                  cmos_init_done      ;

  reg  [15:0]                 rstn_1ms            ;
  wire                        cmos_scl            ;//cmos i2c clock
  wire                        cmos_sda            ;//cmos i2c data
  wire                        cmos_vsync          ;//cmos vsync
  wire                        cmos_href           ;//cmos hsync refrence,data valid
  wire                        cmos_pclk           ;//cmos pxiel clock
  wire   [7:0]                cmos_data           ;//cmos data
  wire                        cmos_reset          ;//cmos reset
  wire                        initial_en          ;
  wire[15:0]                  cmos1_d_16bit       ;
  wire                        cmos1_href_16bit    ;
  reg [7:0]                   cmos1_d_d0          ;
  reg                         cmos1_href_d0       ;
  reg                         cmos1_vsync_d0      ;
  wire                        cmos1_pclk_16bit    ;
  wire[15:0]                  cmos2_d_16bit       /*synthesis PAP_MARK_DEBUG="1"*/;
  wire                        cmos2_href_16bit    /*synthesis PAP_MARK_DEBUG="1"*/;
  reg [7:0]                   cmos2_d_d0          /*synthesis PAP_MARK_DEBUG="1"*/;
  reg                         cmos2_href_d0       /*synthesis PAP_MARK_DEBUG="1"*/;
  reg                         cmos2_vsync_d0      /*synthesis PAP_MARK_DEBUG="1"*/;
  wire                        cmos2_pclk_16bit    /*synthesis PAP_MARK_DEBUG="1"*/;
  wire[15:0]                  o_rgb565            ;
  wire                        pclk_in_test        ;
  wire                        vs_in_test          ;
  wire                        de_in_test          ;
  wire[15:0]                  i_rgb565            ;
  wire                        de_re               ;
  wire                        img_hs              ;

  //axi bus
  wire [CTRL_ADDR_WIDTH-1:0]  axi_awaddr                 ;
  wire                        axi_awuser_ap              ;
  wire [3:0]                  axi_awuser_id              ;
  wire [3:0]                  axi_awlen                  ;
  wire                        axi_awready                ;/*synthesis PAP_MARK_DEBUG="1"*/
  wire                        axi_awvalid                ;/*synthesis PAP_MARK_DEBUG="1"*/
  wire [MEM_DQ_WIDTH*8-1:0]   axi_wdata                  ;
  wire [MEM_DQ_WIDTH*8/8-1:0] axi_wstrb                  ;
  wire                        axi_wready                 ;/*synthesis PAP_MARK_DEBUG="1"*/
  wire [3:0]                  axi_wusero_id              ;
  wire                        axi_wusero_last            ;
  wire [CTRL_ADDR_WIDTH-1:0]  axi_araddr                 ;
  wire                        axi_aruser_ap              ;
  wire [3:0]                  axi_aruser_id              ;
  wire [3:0]                  axi_arlen                  ;
  wire                        axi_arready                ;/*synthesis PAP_MARK_DEBUG="1"*/
  wire                        axi_arvalid                ;/*synthesis PAP_MARK_DEBUG="1"*/
  wire [MEM_DQ_WIDTH*8-1:0]   axi_rdata                   /* synthesis syn_keep = 1 */;
  wire                        axi_rvalid                  /* synthesis syn_keep = 1 */;
  wire [3:0]                  axi_rid                    ;
  wire                        axi_rlast                  ;
  reg  [26:0]                 cnt                        ;
  reg  [15:0]                 cnt_1                      ;

  //
  wire                        vs_o                       ;
  wire                        hs_o                       ;

  wire                        cmos1_clk_i                  /*synthesis PAP_MARK_DEBUG="1"*/;
  wire                        cmos1_vs_i                   /*synthesis PAP_MARK_DEBUG="1"*/;
  wire                        cmos1_de_i                   /*synthesis PAP_MARK_DEBUG="1"*/;
  wire  [15:0]                cmos1_data_i                 /*synthesis PAP_MARK_DEBUG="1"*/;

  wire                        cmos2_clk_i                  /*synthesis PAP_MARK_DEBUG="1"*/;
  wire                        cmos2_vs_i                   /*synthesis PAP_MARK_DEBUG="1"*/;
  wire                        cmos2_de_i                   /*synthesis PAP_MARK_DEBUG="1"*/;
  wire  [15:0]                cmos2_data_i                 /*synthesis PAP_MARK_DEBUG="1"*/;

  wire                        init_over_rx;
  wire                        init_over_tx;

  wire  [15:0]                hdmi_in_data_i/*synthesis PAP_MARK_DEBUG="1"*/;

  wire                        hdmi_in_clk /*synthesis PAP_MARK_DEBUG="1"*/;
  wire                        hdmi_in_vs  /*synthesis PAP_MARK_DEBUG="1"*/;
  wire                        hdmi_in_de  /*synthesis PAP_MARK_DEBUG="1"*/;
  wire   [15:0]               hdmi_in_data/*synthesis PAP_MARK_DEBUG="1"*/;

  wire                        udp_clk /*synthesis PAP_MARK_DEBUG="1"*/;
  wire                        udp_vs  /*synthesis PAP_MARK_DEBUG="1"*/;
  wire                        udp_de  /*synthesis PAP_MARK_DEBUG="1"*/;
  wire   [15:0]               udp_data/*synthesis PAP_MARK_DEBUG="1"*/;

  wire                        udp_char_clk /*synthesis PAP_MARK_DEBUG="1"*/;
  wire                        udp_char_vs  /*synthesis PAP_MARK_DEBUG="1"*/;
  wire                        udp_char_de  /*synthesis PAP_MARK_DEBUG="1"*/;
  wire   [15:0]               udp_char_data/*synthesis PAP_MARK_DEBUG="1"*/;


  
  wire               udp_data_clk         /*synthesis PAP_MARK_DEBUG="1"*/;

  wire               udp_send_en           /*synthesis PAP_MARK_DEBUG="1"*/;
  wire               udp_send_fifo_en      /*synthesis PAP_MARK_DEBUG="1"*/;
  wire    [7:0]      udp_send_fifo_data    /*synthesis PAP_MARK_DEBUG="1"*/;
  wire               udp_send_fifo_empty   /*synthesis PAP_MARK_DEBUG="1"*/;
  wire    [15:0]           udp_send_data_length   /*synthesis PAP_MARK_DEBUG="1"*/;

  wire               udp_rec_data_valid   /*synthesis PAP_MARK_DEBUG="1"*/;
  wire [7:0]         udp_rec_rdata        /*synthesis PAP_MARK_DEBUG="1"*/;
  wire [15:0]        udp_rec_data_length  /*synthesis PAP_MARK_DEBUG="1"*/;

  wire locked;
  //   wire clk_125M;
  //   wire clk_200M;
  wire          rec_pkt_done  ;
  wire          rec_en        ;
  wire  [31:0]  rec_data      ;
  wire  [15:0]  rec_byte_num  ;
  wire          tx_start_en   ;
  wire  [15:0]  tx_byte_num   ;
  wire          udp_tx_done   ;
  wire          tx_req        ;
  wire  [31:0]  tx_data       ;

  wire clk_1080p/*synthesis PAP_MARK_DEBUG="1"*/;
  wire clk_720p/*synthesis PAP_MARK_DEBUG="1"*/;

  wire  vs_720p/*synthesis PAP_MARK_DEBUG="1"*/                       ;
  wire  hs_720p/*synthesis PAP_MARK_DEBUG="1"*/                      ;
  wire  de_720p/*synthesis PAP_MARK_DEBUG="1"*/                       ;

  wire  vs_1080p/*synthesis PAP_MARK_DEBUG="1"*/                       ;
  wire  hs_1080p/*synthesis PAP_MARK_DEBUG="1"*/                       ;
  wire  de_1080p/*synthesis PAP_MARK_DEBUG="1"*/                       ;
  /////////////////////////////////////////////////////////////////////////////////////

  // assign pix_clk = pixclk_in;
  // assign vs_out  = vs_in ;
  // assign hs_out  = hs_in ;
  // assign de_out  = de_in ;
  // assign r_out   =  r_in ;
  // assign g_out   =  g_in ;
  // assign b_out   =  b_in ;



  /*******************************************/
  //第一路以太网传一路视频
  ethernet_test #(
                  .LOCAL_MAC ( 48'he1_e1_e1_e1_e1_e1  ),
                  .LOCAL_IP  ( 32'hC0_A8_01_0B        ),//192.168.1.11
                  .LOCL_PORT ( 16'h1F90               ),
                  .DEST_IP   ( 32'hC0_A8_01_69        ),//192.168.1.105
                  .DEST_PORT ( 16'h1F90               )
                )
                u_ethernet_1
                (
                  .clk_50m            (sys_clk           ),

                  .udp_data_clk       (udp_data_clk       ),

                  .udp_send_en        (udp_send_en        ),
                  .udp_send_fifo_en   (udp_send_fifo_en   ),//fifo_wr_en
                  .udp_send_fifo_data (udp_send_fifo_data ),
                  .udp_send_fifo_empty(udp_send_fifo_empty),
                  .udp_send_data_length(udp_send_data_length),

                  .udp_rec_data_valid (udp_rec_data_valid ),//fifo_wr_en
                  .udp_rec_rdata      (udp_rec_rdata      ),//fifo_wr_data
                  .udp_rec_data_length(udp_rec_data_length),

                  .led                  (udp_led     ),
                  .phy_rstn             (phy_rstn    ),

                  .rgmii_rxc            (rgmii_rxc   ),
                  .rgmii_rx_ctl         (rgmii_rx_ctl),
                  .rgmii_rxd            (rgmii_rxd   ),

                  .rgmii_txc            (rgmii_txc   ),
                  .rgmii_tx_ctl         (rgmii_tx_ctl),
                  .rgmii_txd            (rgmii_txd   )
                );

  udp_databus  udp_databus_inst (
                 .rst_n              (locked             ),
                 .udp_data_clk       (udp_data_clk       ),

                 .udp_send_en        (udp_send_en        ),
                 .udp_send_fifo_en   (udp_send_fifo_en   ),
                 .udp_send_fifo_data (udp_send_fifo_data ),
                 .udp_send_fifo_empty(udp_send_fifo_empty),
                 .udp_send_data_length(udp_send_data_length),

                 .udp_rec_data_valid (udp_rec_data_valid ),
                 .udp_rec_rdata      (udp_rec_rdata      ),
                 .udp_rec_data_length(udp_rec_data_length),

                 .udp_clk   (udp_clk                ),
                 .udp_vs    (udp_vs                 ),
                 .udp_de    (udp_de                 ),
                 .udp_data  (udp_data               )


               );

               udp_char  udp_char_inst (
                .rst_n              (locked             ),
                .udp_data_clk       (udp_data_clk       ),

                // .udp_send_en        (udp_send_en        ),
                // .udp_send_fifo_en   (udp_send_fifo_en   ),
                // .udp_send_fifo_data (udp_send_fifo_data ),
                // .udp_send_fifo_empty(udp_send_fifo_empty),
                // .udp_send_data_length(udp_send_data_length),

                .udp_rec_data_valid (udp_rec_data_valid ),
                .udp_rec_rdata      (udp_rec_rdata      ),
                .udp_rec_data_length(udp_rec_data_length),

                .udp_clk   (udp_char_clk                ),
                .udp_vs    (udp_char_vs                 ),
                .udp_de    (udp_char_de                 ),
                .udp_data  (udp_char_data               )


              );
  //第二路以太网,传字符等控制信息
  // ethernet_test #(
  //   .LOCAL_MAC ( 48'he2_e2_e2_e2_e2_e2  ),
  //   .LOCAL_IP  ( 32'hC0_A8_01_10        ),//192.168.1.09
  //   .LOCL_PORT ( 16'h1F90               ),
  //   .DEST_IP   ( 32'hC0_A8_01_69        ),//192.168.1.105
  //   .DEST_PORT ( 16'h1F90               )
  // )
  // u_ethernet_2
  // (
  //   .clk_50m              (sys_clk     ),

  //   .udp_data_clk       (udp_data_clk       ),

  //   .udp_send_en        (udp_send_en        ),
  //   .udp_send_fifo_en   (udp_send_fifo_en   ),//fifo_wr_en
  //   .udp_send_fifo_data (udp_send_fifo_data ),
  //   .udp_send_fifo_empty(udp_send_fifo_empty),
  //   .udp_send_data_length(udp_send_data_length),

  //   .udp_rec_data_valid (udp_rec_data_valid ),//fifo_wr_en
  //   .udp_rec_rdata      (udp_rec_rdata      ),//fifo_wr_data
  //   .udp_rec_data_length(udp_rec_data_length),

  //   .led                  (udp_led2     ),
  //   .phy_rstn             (phy_rstn2    ),

  //   .rgmii_rxc            (rgmii_rxc2   ),
  //   .rgmii_rx_ctl         (rgmii_rx_ctl2),
  //   .rgmii_rxd            (rgmii_rxd2   ),

  //   .rgmii_txc            (rgmii_txc2   ),
  //   .rgmii_tx_ctl         (rgmii_tx_ctl2),
  //   .rgmii_txd            (rgmii_txd2   )
  // );

  // eth_udp_loop  eth_udp_loop_inst (
  //                 .sys_clk          (sys_clk          ),
  //                 .sys_rst_n        (locked           ),

  //                 .gmii_rx_clk      (udp_data_clk     ),
  //                 .rec_pkt_done     (rec_pkt_done     ),
  //                 .rec_en           (rec_en           ),
  //                 .rec_data         (rec_data         ),
  //                 .rec_byte_num     (rec_byte_num     ),

  //                 .tx_start_en      (tx_start_en      ),
  //                 .tx_byte_num      (tx_byte_num      ),
  //                 .udp_tx_done      (udp_tx_done      ),
  //                 .tx_req           (tx_req           ),
  //                 .tx_data          (tx_data          ),

  //                 .eth_rxc          (rgmii_rxc          ),
  //                 .eth_rx_ctl       (rgmii_rx_ctl       ),
  //                 .eth_rxd          (rgmii_rxd          ),
  //                 .eth_txc          (rgmii_txc          ),
  //                 .eth_tx_ctl       (rgmii_tx_ctl       ),
  //                 .eth_txd          (rgmii_txd          ),
  //                 .eth_rst_n        (phy_rstn           )
  //               );



  //
  //PLL
  pll u_pll (
        .clkin1   (  sys_clk    ),//50MHz
        .clkout0  (  clk_720p    ),//37.125M 720P30
        .clkout1  (  cfg_clk    ),//10MHz
        .clkout2  (  clk_25M    ),//25M
        .clkout3  (  clk_1080p  ),
        .pll_lock (  locked     )
      );

  //配置7210
  ms72xx_ctl ms72xx_ctl(
               .clk             (  cfg_clk        ), //input       clk,
               .rst_n           (  rstn_out       ), //input       rstn,
               .init_over_tx    (  init_over_tx   ), //output      init_over,
               .init_over_rx    (  init_over_rx   ), //output      init_over,
               .iic_tx_scl      (  iic_tx_scl     ), //output      iic_scl,
               .iic_tx_sda      (  iic_tx_sda     ), //inout       iic_sda
               .iic_scl         (  iic_scl        ), //output      iic_scl,
               .iic_sda         (  iic_sda        )  //inout       iic_sda
             );
  // assign    hdmi_int_led    =    init_over_tx & init_over_rx;

  always @(posedge cfg_clk)
  begin
    if(!locked)
      rstn_1ms <= 16'd0;
    else
    begin
      if(rstn_1ms == 16'h2710)
        rstn_1ms <= rstn_1ms;
      else
        rstn_1ms <= rstn_1ms + 1'b1;
    end
  end

  assign rstn_out = (rstn_1ms == 16'h2710);

  //配置CMOS///////////////////////////////////////////////////////////////////////////////////
  //OV5640 register configure enable
  power_on_delay	power_on_delay_inst(
                   .clk_50M                 (sys_clk        ),//input
                   .reset_n                 (1'b1           ),//input
                   .camera1_rstn            (cmos1_reset    ),//output
                   .camera2_rstn            (cmos2_reset    ),//output
                   .camera_pwnd             (               ),//output
                   .initial_en              (initial_en     ) //output
                 );
  //CMOS1 Camera
  reg_config	coms1_reg_config(
               .clk_25M                 (clk_25M            ),//input
               .camera_rstn             (cmos1_reset        ),//input
               .initial_en              (initial_en         ),//input
               .i2c_sclk                (cmos1_scl          ),//output
               .i2c_sdat                (cmos1_sda          ),//inout
               .reg_conf_done           (cmos_init_done[0]  ),//output config_finished
               .reg_index               (                   ),//output reg [8:0]
               .clock_20k               (                   ) //output reg
             );

  //CMOS2 Camera
  reg_config	coms2_reg_config(
               .clk_25M                 (clk_25M            ),//input
               .camera_rstn             (cmos2_reset        ),//input
               .initial_en              (initial_en         ),//input
               .i2c_sclk                (cmos2_scl          ),//output
               .i2c_sdat                (cmos2_sda          ),//inout
               .reg_conf_done           (cmos_init_done[1]  ),//output config_finished
               .reg_index               (                   ),//output reg [8:0]
               .clock_20k               (                   ) //output reg
             );
  //CMOS 8bit转16bit///////////////////////////////////////////////////////////////////////////////////
  //CMOS1
  always@(posedge cmos1_pclk)
  begin
    cmos1_d_d0        <= cmos1_data    ;
    cmos1_href_d0     <= cmos1_href    ;
    cmos1_vsync_d0    <= cmos1_vsync   ;
  end

  cmos_8_16bit cmos1_8_16bit(
                 .pclk           (cmos1_pclk       ),//input
                 .rst_n          (cmos_init_done[0]),//input
                 .pdata_i        (cmos1_d_d0       ),//input[7:0]
                 .de_i           (cmos1_href_d0    ),//input
                 .vs_i           (cmos1_vsync_d0    ),//input

                 .pixel_clk      (cmos1_pclk_16bit ),//output
                 .pdata_o        (cmos1_d_16bit    ),//output[15:0]
                 .de_o           (cmos1_href_16bit ) //output
               );
  //CMOS2
  always@(posedge cmos2_pclk)
  begin
    cmos2_d_d0        <= cmos2_data    ;
    cmos2_href_d0     <= cmos2_href    ;
    cmos2_vsync_d0    <= cmos2_vsync   ;
  end

  cmos_8_16bit cmos2_8_16bit(
                 .pclk           (cmos2_pclk       ),//input
                 .rst_n          (cmos_init_done[1]),//input
                 .pdata_i        (cmos2_d_d0       ),//input[7:0]
                 .de_i           (cmos2_href_d0    ),//input
                 .vs_i           (cmos2_vsync_d0    ),//input

                 .pixel_clk      (cmos2_pclk_16bit ),//output
                 .pdata_o        (cmos2_d_16bit    ),//output[15:0]
                 .de_o           (cmos2_href_16bit ) //output
               );
  //输入视频源选择//////////////////////////////////////////////////////////////////////////////////////////
  // `ifdef CMOS_1
  assign     cmos1_clk_i     =    cmos1_pclk_16bit    ;
  assign     cmos1_vs_i      =    cmos1_vsync_d0      ;
  assign     cmos1_de_i      =    cmos1_href_16bit    ;
  assign     cmos1_data_i    =    {cmos1_d_16bit[4:0],cmos1_d_16bit[10:5],cmos1_d_16bit[15:11]};//{r,g,b}
  // `elsif CMOS_2
  assign     cmos2_clk_i     =    cmos2_pclk_16bit    ;
  assign     cmos2_vs_i      =    cmos2_vsync_d0      ;
  assign     cmos2_de_i      =    cmos2_href_16bit    ;
  assign     cmos2_data_i    =    {cmos2_d_16bit[4:0],cmos2_d_16bit[10:5],cmos2_d_16bit[15:11]};//{r,g,b}
  // `endif
  assign     hdmi_in_data_i    =    {r_in[7:3],g_in[7:2],b_in[7:3]};//{r,g,b}
  //////////////////////////////////////////////////////////////////////////////////////////////////////////
  /* de_frame  de_frame_inst (
               .rst_n          (ddr_init_done    ),
               .video_clk_i    (pixclk_in        ),
               .video_vs_i     (vs_in            ),
               .video_de_i     (de_in            ),
               .video_data_i   (hdmi_in_data_i   ),

               .video_clk_o    (hdmi_in_clk    ),
               .video_vs_o     (hdmi_in_vs     ),
               .video_de_o     (hdmi_in_de     ),
               .video_data_o   (hdmi_in_data   )
             );*/

  //修改ddr读写模块v1
  // wire clk_o;
  // GTP_OUTBUF#(
  //             .IOSTANDARD ("DEFAULT"),
  //             .SLEW_RATE ("FAST"),
  //             .DRIVE_STRENGTH ("8")
  //           )
  //           GTP_OUTBUF_inst (
  //             .I (clk_o),
  //             .O (pix_clk)
  //           );
            //  assign pix_clk = clk_720p;


  fram_buf fram_buf(
             .ddr_clk        (  core_clk             ),//input                         ddr_clk,
             .ddr_rstn       (  ddr_init_done        ),//input                         ddr_rstn,
             //data_in
             .key              (  key               ),
             .led              (  led               ),
             .cmos1_clk        (  cmos1_clk_i          ),//input                         vin_clk,
             .cmos1_vs         (  cmos1_vs_i           ),//input                         wr_fsync,
             .cmos1_de         (  cmos1_de_i           ),//input                         wr_en,
             .cmos1_data       (  cmos1_data_i         ),//input

             .cmos2_clk        (  cmos2_clk_i          ),//input                         vin_clk,
             .cmos2_vs         (  cmos2_vs_i           ),//input                         wr_fsync,
             .cmos2_de         (  cmos2_de_i           ),//input                         wr_en,
             .cmos2_data       (  cmos2_data_i         ),//input

             .hdmi_in_clk        (pixclk_in            ),//hdmi_in_clk ),//
             .hdmi_in_vs         (vs_in                ),//hdmi_in_vs  ),//
             .hdmi_in_de         (de_in                ),//hdmi_in_de  ),//
             .hdmi_in_data       (hdmi_in_data_i       ),//hdmi_in_data),//

             .udp_in_clk        (  udp_clk          ),
             .udp_in_vs         (  udp_vs           ),
             .udp_in_de         (  udp_de           ),
             .udp_in_data       (  udp_data         ),

             .udp_char_clk (udp_char_clk ),
             .udp_char_vs  (udp_char_vs  ),
             .udp_char_de  (udp_char_de  ),
             .udp_char_data(udp_char_data),
             //  hs_720p
             //  vs_720p
             //  de_720p
             //data_out
             .clk_720p       (  clk_720p              ),//i
             .vs_720p        (  vs_720p               ),//i
             .hs_720p        (  hs_720p               ), //
             .de_720p        (  de_720p               ),

             .clk_1080p       (  clk_1080p              ),
             .vs_1080p        (  vs_1080p               ),
             .hs_1080p        (  hs_1080p               ),
             .de_1080p        (  de_1080p               ),

             .vout_clk       (  pix_clk              ),
             .vout_vs        (  vs_o                 ),
             .vout_hs        (  hs_o                 ),
             .vout_de        (  de_o                 ),//ou
             .vout_data      (  o_rgb565             ),//ou



             //  .vout_clk       (     clk_720p           ),//input                         vout_clk,
             //  .rd_fsync       (  vs_720p                 ),//input                         rd_fsync,
             //  .rd_hs          (  hs_720p               ), //hs_o),//
             //  .rd_en          (  de_720p                ),//input                         rd_en,
             //  .vout_de        (  de_o                 ),//output                        vout_de,
             //  .vout_data      (  o_rgb565             ),//output [PIX_WIDTH- 1'b1 : 0]  vout_data,
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
  //  assign vs_o = vs_720p;
  //  assign hs_o = hs_720p;
  //  assign pix_clk = clk_720p;

  // always@(posedge clk_o)
  // begin
  //   r_out<={o_rgb565[15:11],3'b0   };
  //   g_out<={o_rgb565[10:5],2'b0    };
  //   b_out<={o_rgb565[4:0],3'b0     };
  //   vs_out<=vs_o;
  //   hs_out<=hs_o;
  //   de_out<=de_o;
  // end

 assign r_out   = {o_rgb565[15:11],3'b0   };
 assign g_out   = {o_rgb565[10:5],2'b0    };
 assign b_out   = {o_rgb565[4:0],3'b0     };
 assign vs_out  = vs_o;
 assign hs_out  = hs_o;
 assign de_out  = de_o;
  /////////////////////////////////////////////////////////////////////////////////////

  // 产生visa时序
  /*
    sync_vg sync_vg(
              .clk            (  pix_clk              ),//input                   clk,
              .rstn           (  init_done            ),//input                   rstn,
              .vs_out         (  vs_o                 ),//output reg              vs_out,
              .hs_out         (  hs_o                 ),//output reg              hs_out,
              .de_out         (  img_hs               ),//output reg              de_out,
              .de_re          (  de_re                )
            );*/
  // color_bar
  // #(
  //   .H_ACTIVE (16'd1280	),
  //   .H_FP 		(16'd110	),
  //   .H_SYNC 	(16'd40		),
  //   .H_BP 		(16'd220	),
  //   .V_ACTIVE	(16'd720	),
  //   .V_FP  		(16'd5		),
  //   .V_SYNC  	(16'd5		),
  //   .V_BP  		(16'd20		),
  //   .HS_POL 	(1'b1		),
  //   .VS_POL 	(1'b1		)
  // ) u_color_bar_11
  // (
  //   .clk   (pix_clk       ),
  //   .rst   (~init_done     ),
  //   .hs    (hs_o       ),
  //   .vs    (vs_o       ),
  //   .de    (de_re ),//img_hs       ),
  //   .rgb_r (    ),
  //   .rgb_g (    ),
  //   .rgb_b (    )
  // );
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
      .clk   (clk_720p       ),
      .rst   (~init_done     ),
      .hs    (hs_720p       ),
      .vs    (vs_720p       ),
      .de    (de_720p ),//img_hs       ),
      .rgb_r (    ),
      .rgb_g (    ),
      .rgb_b (    )
    );

  color_bar
    #(
      .H_ACTIVE ( 16'd1920  ),
      .H_FP 		( 16'd88	  ),
      .H_SYNC 	( 16'd44	  ),
      .H_BP 		( 16'd148   ),
      .V_ACTIVE	( 16'd1080  ),
      .V_FP  		( 16'd4	    ),
      .V_SYNC  	( 16'd5	    ),
      .V_BP  		( 16'd36	  ),
      .HS_POL 	( 1'b1		  ),
      .VS_POL 	( 1'b1		  )
    ) u_color_bar_12
    (
      .clk   (clk_1080p),//clk_145_5M       ),
      .rst   (~init_done       ),
      .hs    (hs_1080p       ),
      .vs    (vs_1080p       ),
      .de    (de_1080p       ),
      .rgb_r (),
      .rgb_g (),
      .rgb_b ()
    );
  ////////////////////////////////////////////////////////////////////////////////////////////
  //ddr
  DDR3_50H u_DDR3_50H (
             .ref_clk                   (sys_clk            ),
             .resetn                    (rstn_out           ),// input
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

  //心跳信号
  always@(posedge core_clk)
  begin
    if (!ddr_init_done)
      cnt <= 27'd0;
    else if ( cnt >= TH_1S )
      cnt <= 27'd0;
    else
      cnt <= cnt + 27'd1;
  end

  // always @(posedge core_clk)
  // begin
  //   if (!ddr_init_done)
  //     heart_beat_led <= 1'd1;
  //   else if ( cnt >= TH_1S )
  //     heart_beat_led <= ~heart_beat_led;
  // end

  /////////////////////////////////////////////////////////////////////////////////////
endmodule
