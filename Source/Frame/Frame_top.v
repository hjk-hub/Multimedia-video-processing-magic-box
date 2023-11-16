//*********************************************
//   设置输入为1280*720即720P数据,存储设置四块图像拼成一块
//      即输入四路720P存为一块720P,乒乓操作
//      拟指定每个模块地址范围
//      地址范围Image_720*1280*16/32 = 28'h007_0800;
//
//      乒乓操作使用两块Image块,eg,A,B:A写则B读,B写则A读
// 一:
//      Base_Addr:Image1 = 28'h000_0000;
//                 Image2 = 28'h010_0000;
// 二:
//      Image块内部地址偏移:
//                 image1 : base_addr1 = 0;
//                 image2 : base_addr2 = 1280*16/32=640;
//                 image3 : base_addr3 = 1280*360*16/32=230400;
//                 image4 : base_addr4 = base_addr3 + base_addr2 = 231040;
// 三:
//      线性存储事项:
//                 image1 : base_addr1 = 0;每次burst一行,640个点,burst_len = 640*2/32=40
//                                     burst之后,地址增长640*16/32 = 320,下同
//                 image2 : base_addr2 = 1280*16/32=640;
//                 image3 : base_addr3 = 1280*360*16/32=230400;
//                 image4 : base_addr4 = base_addr3 + base_addr2 = 231040;
//      ------------------
//      11111111|22222222
//      11111111|22222222
//      11111111|22222222
//      ------------------
//      33333333|44444444
//      33333333|44444444
//      33333333|44444444
//      ------------------
//
// 四:参数
//      1:
//          parameter Image_row = 720;
//          parameter Image_col = 1280;
//          parameter Base_Addr1 = 28'h000_0000;
//          parameter Base_Addr2 = 28'h010_0000;
//          parameter Img_dataWidth = 16;
//          parameter Mem_dataWidth = 32;
//
//          localparam  image1_Addaddr = 28'd0;  //偏移地址
//          localparam  image2_Addaddr = Image_col*Img_dataWidth/Mem_dataWidth;
//          localparam  image3_Addaddr = Image_col*(Image_row/2)*Img_dataWidth/Mem_dataWidth;
//
//
//      存储方式选择:线性/块状
//      突发长度:线性存储方式
//      块大小:16*16起步,,,16*16时burst_len=1
//
//写输入:帧同步vs,
//
//
//**********************************************
module Frame_top
#(
  `include"F:/Project/WorkSpace/FPGA/Video_pro/Source/top/global.vh"
 )
   (

    //  input wire                          axi_aclk        ,
    //  input wire                          axi_aresetn     ,
     //图像1输入
     input wire                          Img1_pclk       ,
     input wire                          Img1_vs         ,
     input wire                          Img1_de         ,
     input wire   [15 : 0]               Img1_data       ,
     //图像2输入
     input wire                          Img2_pclk       ,
     input wire                          Img2_vs         ,
     input wire                          Img2_de         ,
     input wire   [15 : 0]               Img2_data       ,
     //图像3输入
     input wire                          Img3_pclk       ,
     input wire                          Img3_vs         ,
     input wire                          Img3_de         ,
     input wire   [15 : 0]               Img3_data       ,
     //图像4输入
     input wire                          Img4_pclk       ,
     input wire                          Img4_vs         ,
     input wire                          Img4_de         ,
     input wire   [15 : 0]               Img4_data       ,
    //HDMI输出
     input  wire                         Img_pclk_i       ,//hdmi输出用时钟74.25Mhz

     output wire                         Img_pclk_o       ,
     output wire                         Img_vs_o         ,
     output wire                         Img_hs_o         ,    
     output wire                         Img_de_o         ,
     output wire   [15:0]                Img_data_o       ,
     //DDR AXI接口
    //  input                               axi_aresetn      ,
     input wire                          axi_aclk        ,
     input wire                          axi_aresetn     ,
     input wire                          ddr_init_done   ,

     output [CTRL_ADDR_WIDTH-1:0]        m_axi_awaddr     ,
     output [3:0]                        m_axi_awid  ,
     output [3:0]                        m_axi_awlen      ,
     input                               m_axi_awready    ,
     output                              m_axi_awvalid    ,

     output [MEM_DQ_WIDTH*8-1:0]         m_axi_wdata      ,
     output [MEM_DQ_WIDTH-1:0]           m_axi_wstrb      ,
     input                               m_axi_wready     ,
     input                               m_axi_wlast,

     output                              m_axi_bready     ,
     input                               m_axi_bvalid     ,

     output [CTRL_ADDR_WIDTH-1:0]        m_axi_araddr     ,
     output [3:0]                        m_axi_arid  ,
     output [3:0]                        m_axi_arlen      ,
     input                               m_axi_arready    ,
     output                              m_axi_arvalid    ,

     input[8*MEM_DQ_WIDTH-1:0]           m_axi_rdata      ,
     input[3:0]                          m_axi_rid        ,
     input                               m_axi_rlast      ,
     input                               m_axi_rvalid

   );

  /*******************************************************/
    //
   wire                         write_index     ;
   wire [3:0]                   write_req       ;
   wire  [3:0]                  write_done      ;
   wire [28*4-1:0]              write_addr      ;

   wire [27:0]                  write_start_addr1;
   wire [27:0]                  write_start_addr2;
   wire [27:0]                  write_start_addr3;
   wire [27:0]                  write_start_addr4;

   wire [3:0] Img_pclk;
   wire [3:0] Img_vs;
   wire [3:0] Img_de;

   wire [16*4-1:0] Img_data;


   //
    // wire     [7:0] rgb_r;
    // wire     [7:0] rgb_g;
    // wire     [7:0] rgb_b;
    // assign  Img_data_o = {rgb_r[7:3],rgb_g[7:2],rgb_b[7:3]};
   /*
   *arbit
   */

   wire                                  wr_burst_req     ;/*synthesis PAP_MARK_DEBUG="1"*/
   wire     [7:0]                        wr_burst_len     ;/*synthesis PAP_MARK_DEBUG="1"*/
   wire   [AXI_ADDR_WIDTH-1:0]           wr_burst_addr    ;
   wire                                  wr_burst_data_req;/*synthesis PAP_MARK_DEBUG="1"*/
   wire   [AXI_DATA_WIDTH-1 : 0]         wr_burst_data    ;
   wire                                  wr_burst_finish  ;/*synthesis PAP_MARK_DEBUG="1"*/
  
  
   wire                                  rd_burst_req     ;/*synthesis PAP_MARK_DEBUG="1"*/
   wire      [7:0]                       rd_burst_len     ;/*synthesis PAP_MARK_DEBUG="1"*/
  wire    [AXI_ADDR_WIDTH-1:0]           rd_burst_addr    ;
   wire                                  rd_burst_data_valid;/*synthesis PAP_MARK_DEBUG="1"*/
   wire   [AXI_DATA_WIDTH-1 : 0]         rd_burst_data    ;
   wire                                  rd_burst_finish  ;/*synthesis PAP_MARK_DEBUG="1"*/
  //wr
   wire  							                  ch0_wr_burst_req      ;/*synthesis PAP_MARK_DEBUG="1"*/
   wire   [8 - 1:0] 		                ch0_wr_burst_len      ;/*synthesis PAP_MARK_DEBUG="1"*/
   wire   [AXI_ADDR_WIDTH-1:0] 			    ch0_wr_burst_addr     ;/*synthesis PAP_MARK_DEBUG="1"*/
   wire   							                ch0_wr_burst_data_req ;
   wire   [AXI_DATA_WIDTH - 1:0] 		    ch0_wr_burst_data     ;
   wire   							                ch0_wr_burst_finish   ;/*synthesis PAP_MARK_DEBUG="1"*/

   wire  							                  ch1_wr_burst_req      ;/*synthesis PAP_MARK_DEBUG="1"*/
   wire   [8 - 1:0] 		                ch1_wr_burst_len      ;/*synthesis PAP_MARK_DEBUG="1"*/
   wire   [AXI_ADDR_WIDTH-1:0] 			    ch1_wr_burst_addr     ;/*synthesis PAP_MARK_DEBUG="1"*/
   wire   							                ch1_wr_burst_data_req ;
   wire   [AXI_DATA_WIDTH - 1:0] 		    ch1_wr_burst_data     ;
   wire   							                ch1_wr_burst_finish   ;/*synthesis PAP_MARK_DEBUG="1"*/

   wire  							                  ch2_wr_burst_req      ;/*synthesis PAP_MARK_DEBUG="1"*/
   wire   [8 - 1:0] 		                ch2_wr_burst_len      ;/*synthesis PAP_MARK_DEBUG="1"*/
   wire   [AXI_ADDR_WIDTH-1:0] 			    ch2_wr_burst_addr     ;/*synthesis PAP_MARK_DEBUG="1"*/
   wire   							                ch2_wr_burst_data_req ;
   wire   [AXI_DATA_WIDTH - 1:0] 		    ch2_wr_burst_data     ;
   wire   							                ch2_wr_burst_finish   ;/*synthesis PAP_MARK_DEBUG="1"*/

   wire  							                  ch3_wr_burst_req      ;/*synthesis PAP_MARK_DEBUG="1"*/
   wire   [8 - 1:0] 		                ch3_wr_burst_len      ;/*synthesis PAP_MARK_DEBUG="1"*/
   wire   [AXI_ADDR_WIDTH-1:0] 			    ch3_wr_burst_addr     ;/*synthesis PAP_MARK_DEBUG="1"*/
   wire   							                ch3_wr_burst_data_req ;
   wire   [AXI_DATA_WIDTH - 1:0] 		    ch3_wr_burst_data     ;
   wire   							                ch3_wr_burst_finish   ;/*synthesis PAP_MARK_DEBUG="1"*/
   //rd
   wire  							                  ch0_rd_burst_req      ;
   wire   [8 - 1:0] 		                ch0_rd_burst_len      ;
   wire   [AXI_ADDR_WIDTH-1:0] 			    ch0_rd_burst_addr     ;
   wire   							                ch0_rd_burst_data_valid ;
   wire   [AXI_DATA_WIDTH - 1:0] 		    ch0_rd_burst_data     ;
   wire   							                ch0_rd_burst_finish   ;

   wire  							                  ch1_rd_burst_req      ;
   wire   [8 - 1:0] 		                ch1_rd_burst_len      ;
   wire   [AXI_ADDR_WIDTH-1:0] 			    ch1_rd_burst_addr     ;
   wire   							                ch1_rd_burst_data_valid ;
   wire   [AXI_DATA_WIDTH - 1:0] 		    ch1_rd_burst_data     ;
   wire   							                ch1_rd_burst_finish   ;

   wire  							                  ch2_rd_burst_req      ;
   wire   [8 - 1:0] 		                ch2_rd_burst_len      ;
   wire   [AXI_ADDR_WIDTH-1:0] 			    ch2_rd_burst_addr     ;
   wire   							                ch2_rd_burst_data_valid ;
   wire   [AXI_DATA_WIDTH - 1:0] 		    ch2_rd_burst_data     ;
   wire   							                ch2_rd_burst_finish   ;

   wire  							                  ch3_rd_burst_req      ;
   wire   [8 - 1:0] 		                ch3_rd_burst_len      ;
   wire   [AXI_ADDR_WIDTH-1:0] 			    ch3_rd_burst_addr     ;
   wire   							                ch3_rd_burst_data_valid ;
   wire   [AXI_DATA_WIDTH - 1:0] 		    ch3_rd_burst_data     ;
   wire   							                ch3_rd_burst_finish   ;
   //color bar
   wire                                 Img_vs_bar;
   wire                                 Img_hs_bar;
   wire                                 Img_de_bar;
   
   //   
   assign Img_pclk = {Img1_pclk,Img2_pclk,Img3_pclk,Img4_pclk};
   assign Img_vs = {Img1_vs,Img2_vs,Img3_vs,Img4_vs};
   assign Img_de = {Img1_de,Img2_de,Img3_de,Img4_de};
   assign Img_data = {Img1_data,Img2_data,Img3_data,Img4_data};
   assign write_addr = {write_start_addr1,write_start_addr2,write_start_addr3,write_start_addr4};

  /*****************************************************/
  Frame_orderGen  u_Frame_orderGen(
    .axi_aclk           (axi_aclk           ),
    .axi_aresetn        (axi_aresetn        ),
    .Img1_pclk          (Img1_pclk          ),
    .Img1_vs            (Img1_vs            ),
    .Img2_pclk          (Img2_pclk          ),
    .Img2_vs            (Img2_vs            ),
    .Img3_pclk          (Img3_pclk          ),
    .Img3_vs            (Img3_vs            ),
    .Img4_pclk          (Img4_pclk          ),
    .Img4_vs            (Img4_vs            ),
    .write_index        (write_index        ),
    .write_req          (write_req          ),
    .write_done         (write_done         ),
    .write_start_addr1  (write_start_addr1  ),
    .write_start_addr2  (write_start_addr2  ),
    .write_start_addr3  (write_start_addr3  ),
    .write_start_addr4  (write_start_addr4  )
  );




/*
*
*/
Frame_write u_Frame_write_video_1 (
    .axi_aclk         (axi_aclk               ),
    .axi_aresetn      (axi_aresetn  & (~Img1_vs)   ),

    .Img_pclk         (Img1_pclk              ),
    .Img_vs           (Img1_vs              ),
    .Img_de           (Img1_de             ),
    .Img_data         (Img1_data              ),

    .wr_burst_req     (ch0_wr_burst_req       ),
    .wr_burst_len     (ch0_wr_burst_len       ),
    .wr_burst_addr    (ch0_wr_burst_addr      ),
    .wr_burst_data_req(ch0_wr_burst_data_req  ),
    .wr_burst_data    (ch0_wr_burst_data      ),
    .wr_burst_finish  (ch0_wr_burst_finish    ),

    .write_addr       (write_start_addr1      ),
    .write_req        (write_req[3]           ),
    .write_done       (write_done[3]          )
  );

  Frame_write u_Frame_write_video_2 (
    .axi_aclk         (axi_aclk               ),
    .axi_aresetn      (axi_aresetn  & (~Img2_vs)             ),

    .Img_pclk         (Img2_pclk              ),
    .Img_vs           (Img2_vs              ),
    .Img_de           (Img2_de             ),
    .Img_data         (Img2_data              ),

    .wr_burst_req     (ch1_wr_burst_req       ),
    .wr_burst_len     (ch1_wr_burst_len       ),
    .wr_burst_addr    (ch1_wr_burst_addr      ),
    .wr_burst_data_req(ch1_wr_burst_data_req  ),
    .wr_burst_data    (ch1_wr_burst_data      ),
    .wr_burst_finish  (ch1_wr_burst_finish    ),

    .write_addr       (write_start_addr2      ),
    .write_req        (write_req[2]           ),
    .write_done       (write_done[2]          )
  );

  Frame_write u_Frame_write_video_3 (
    .axi_aclk         (axi_aclk               ),
    .axi_aresetn      (axi_aresetn  & (~Img3_vs)             ),

    .Img_pclk         (Img3_pclk              ),
    .Img_vs           (Img3_vs              ),
    .Img_de           (Img3_de             ),
    .Img_data         (Img3_data              ),

    .wr_burst_req     (ch2_wr_burst_req       ),
    .wr_burst_len     (ch2_wr_burst_len       ),
    .wr_burst_addr    (ch2_wr_burst_addr      ),
    .wr_burst_data_req(ch2_wr_burst_data_req  ),
    .wr_burst_data    (ch2_wr_burst_data      ),
    .wr_burst_finish  (ch2_wr_burst_finish    ),

    .write_addr       (write_start_addr3      ),
    .write_req        (write_req[1]           ),
    .write_done       (write_done[1]          )
  );

  Frame_write u_Frame_write_video_4 (
    .axi_aclk         (axi_aclk               ),
    .axi_aresetn      (axi_aresetn  & (~Img4_vs)             ),

    .Img_pclk         (Img4_pclk              ),
    .Img_vs           (Img4_vs              ),
    .Img_de           (Img4_de             ),
    .Img_data         (Img4_data              ),

    .wr_burst_req     (ch3_wr_burst_req       ),
    .wr_burst_len     (ch3_wr_burst_len       ),
    .wr_burst_addr    (ch3_wr_burst_addr      ),
    .wr_burst_data_req(ch3_wr_burst_data_req  ),
    .wr_burst_data    (ch3_wr_burst_data      ),
    .wr_burst_finish  (ch3_wr_burst_finish    ),

    .write_addr       (write_start_addr4      ),
    .write_req        (write_req[0]           ),
    .write_done       (write_done[0]          )
  );
  
/*
* frame read
*/
//产生输出时序
color_bar u_color_bar_1(
  .clk                        (Img_pclk_i),//Img_pclk_i    ),
  .rst                        (~ddr_init_done),
  .hs                         (Img_hs_o    ),
  .vs                         (Img_vs_bar      ),
  .de                         (Img_de_bar    ),
  .rgb_r                      ( ),
  .rgb_g                      ( ),
  .rgb_b                      ( )
);

Frame_read u_Frame_read (
    .axi_aclk           (axi_aclk             ),
    .axi_aresetn        (axi_aresetn          ),
    //输入color bar hdmi时序
    .Img_pclk_i         (Img_pclk_i),//Img_pclk_i           ),
    .Img_vs_i           (Img_vs_bar           ),
    // .Img_hs_i           (Img_hs_bar           ),
    .Img_de_i           (Img_de_bar           ),

    .Img_pclk_o         (Img_pclk_o           ),         
    .Img_vs_o           (Img_vs_o             ),
    .Img_de_o           (Img_de_o             ),
    .Img_data_o         (Img_data_o           ),

    .rd_burst_req       (ch0_rd_burst_req     ),
    .rd_burst_len       (ch0_rd_burst_len     ),
    .rd_burst_addr      (ch0_rd_burst_addr    ),
    .rd_burst_data_valid(ch0_rd_burst_data_valid),
    .rd_burst_data      (ch0_rd_burst_data    ),
    .rd_burst_finish    (ch0_rd_burst_finish  ),
    .write_index        (write_index          )
  );

  // Frame_write u_Frame_write_video_1 (
  //   .axi_aclk         (axi_aclk               ),
  //   .axi_aresetn      (axi_aresetn            ),

  //   .Img_pclk         (Img1_pclk              ),
  //   .Img_vs           (Img1_vs                ),
  //   .Img_de           (Img1_de                ),
  //   .Img_data         (Img1_data              ),

  //   .wr_burst_req     (ch0_wr_burst_req       ),
  //   .wr_burst_len     (ch0_wr_burst_len       ),
  //   .wr_burst_addr    (ch0_wr_burst_addr      ),
  //   .wr_burst_data_req(ch0_wr_burst_data_req  ),
  //   .wr_burst_data    (ch0_wr_burst_data      ),
  //   .wr_burst_finish  (ch0_wr_burst_finish    ),

  //   .write_addr       (write_start_addr1      ),
  //   .write_req        (write_req[3]           ),
  //   .write_done       (write_done[3]          )
  // );
/*
*arbit
*/
mem_write_arbi mem_write_arbi_m0(
	.rst_n                       (axi_aresetn   ),
	.mem_clk                     (axi_aclk      ),
	
	.ch0_wr_burst_req            (ch0_wr_burst_req),
	.ch0_wr_burst_len            (ch0_wr_burst_len),
	.ch0_wr_burst_addr           (ch0_wr_burst_addr),
	.ch0_wr_burst_data_req       (ch0_wr_burst_data_req),
	.ch0_wr_burst_data           (ch0_wr_burst_data),
	.ch0_wr_burst_finish         (ch0_wr_burst_finish),
	
	.ch1_wr_burst_req            (ch1_wr_burst_req),
	.ch1_wr_burst_len            (ch1_wr_burst_len),
	.ch1_wr_burst_addr           (ch1_wr_burst_addr),
	.ch1_wr_burst_data_req       (ch1_wr_burst_data_req),
	.ch1_wr_burst_data           (ch1_wr_burst_data),
	.ch1_wr_burst_finish         (ch1_wr_burst_finish),

  .ch2_wr_burst_req            (ch2_wr_burst_req),
	.ch2_wr_burst_len            (ch2_wr_burst_len),
	.ch2_wr_burst_addr           (ch2_wr_burst_addr),
	.ch2_wr_burst_data_req       (ch2_wr_burst_data_req),
	.ch2_wr_burst_data           (ch2_wr_burst_data),
	.ch2_wr_burst_finish         (ch2_wr_burst_finish),

  .ch3_wr_burst_req            (ch3_wr_burst_req),
	.ch3_wr_burst_len            (ch3_wr_burst_len),
	.ch3_wr_burst_addr           (ch3_wr_burst_addr),
	.ch3_wr_burst_data_req       (ch3_wr_burst_data_req),
	.ch3_wr_burst_data           (ch3_wr_burst_data),
	.ch3_wr_burst_finish         (ch3_wr_burst_finish),

	.wr_burst_req                 (wr_burst_req),
	.wr_burst_len                 (wr_burst_len),
	.wr_burst_addr                (wr_burst_addr),
	.wr_burst_data_req            (wr_burst_data_req),
	.wr_burst_data                (wr_burst_data),
	.wr_burst_finish              (wr_burst_finish)	
);

mem_read_arbi mem_read_arbi_m0
(
	.rst_n                        (axi_aresetn  ),
	.mem_clk                      (axi_aclk     ),
	.ch0_rd_burst_req             (ch0_rd_burst_req),
	.ch0_rd_burst_len             (ch0_rd_burst_len),
	.ch0_rd_burst_addr            (ch0_rd_burst_addr),
	.ch0_rd_burst_data_valid      (ch0_rd_burst_data_valid),
	.ch0_rd_burst_data            (ch0_rd_burst_data),
	.ch0_rd_burst_finish          (ch0_rd_burst_finish),
	
	.ch1_rd_burst_req             (ch1_rd_burst_req),
	.ch1_rd_burst_len             (ch1_rd_burst_len),
	.ch1_rd_burst_addr            (ch1_rd_burst_addr),
	.ch1_rd_burst_data_valid      (ch1_rd_burst_data_valid),
	.ch1_rd_burst_data            (ch1_rd_burst_data),
	.ch1_rd_burst_finish          (ch1_rd_burst_finish),

	.ch2_rd_burst_req             (ch2_rd_burst_req),
	.ch2_rd_burst_len             (ch2_rd_burst_len),
	.ch2_rd_burst_addr            (ch2_rd_burst_addr),
	.ch2_rd_burst_data_valid      (ch2_rd_burst_data_valid),
	.ch2_rd_burst_data            (ch2_rd_burst_data),
	.ch2_rd_burst_finish          (ch2_rd_burst_finish),
  
  .ch3_rd_burst_req             (ch3_rd_burst_req),
	.ch3_rd_burst_len             (ch3_rd_burst_len),
	.ch3_rd_burst_addr            (ch3_rd_burst_addr),
	.ch3_rd_burst_data_valid      (ch3_rd_burst_data_valid),
	.ch3_rd_burst_data            (ch3_rd_burst_data),
	.ch3_rd_burst_finish          (ch3_rd_burst_finish),

	
	.rd_burst_req                 (rd_burst_req),
	.rd_burst_len                 (rd_burst_len),
	.rd_burst_addr                (rd_burst_addr),
	.rd_burst_data_valid          (rd_burst_data_valid),
	.rd_burst_data                (rd_burst_data),
	.rd_burst_finish              (rd_burst_finish)	
);



  
  axi_ddr_ctr u_axi_ddr_ctr(


    .wr_burst_req           (wr_burst_req     ),
    .wr_burst_len           (wr_burst_len     ),
    .wr_burst_addr          (wr_burst_addr    ),
    .wr_burst_data_req      (wr_burst_data_req),
    .wr_burst_data          (wr_burst_data    ),
    .wr_burst_finish        (wr_burst_finish  ),

    .rd_burst_req           (rd_burst_req     ),
    .rd_burst_len           (rd_burst_len     ),
    .rd_burst_addr          (rd_burst_addr    ),
    .rd_burst_data_valid      (rd_burst_data_valid),
    .rd_burst_data          (rd_burst_data    ),
    .rd_burst_finish        (rd_burst_finish  ),

     .m_axi_aclk           (axi_aclk   ),
     .m_axi_aresetn        (axi_aresetn   ),
     .m_axi_awid           (m_axi_awid   ),
     .m_axi_awaddr         (m_axi_awaddr ),
     .m_axi_awlen          (m_axi_awlen  ),
     .m_axi_awsize         (m_axi_awsize ),
     .m_axi_awburst        (m_axi_awburst),
     .m_axi_awlock         (m_axi_awlock ),
     .m_axi_awcache        (m_axi_awcache),
     .m_axi_awprot         (m_axi_awprot ),
     .m_axi_awqos          (m_axi_awqos  ),
     .m_axi_awuser         (m_axi_awuser ),
     .m_axi_awvalid        (m_axi_awvalid),
     .m_axi_awready        (m_axi_awready),
     .m_axi_wdata          (m_axi_wdata  ),
     .m_axi_wstrb          (m_axi_wstrb  ),
     .m_axi_wlast          (m_axi_wlast  ),
    //  .m_axi_wuser          (m_axi_wuser  ),
     .m_axi_wvalid         (m_axi_wvalid ),
     .m_axi_wready         (m_axi_wready ),
     .m_axi_bid            (m_axi_bid    ),
     .m_axi_bresp          (m_axi_bresp  ),
     .m_axi_buser          (m_axi_buser  ),
     .m_axi_bvalid         (m_axi_bvalid ),
     .m_axi_bready         (m_axi_bready ),
     .m_axi_arid           (m_axi_arid   ),
     .m_axi_araddr         (m_axi_araddr ),
     .m_axi_arlen          (m_axi_arlen  ),
     .m_axi_arsize         (m_axi_arsize ),
     .m_axi_arburst        (m_axi_arburst),
     .m_axi_arlock         (m_axi_arlock ),
     .m_axi_arcache        (m_axi_arcache),
     .m_axi_arprot         (m_axi_arprot ),
     .m_axi_arqos          (m_axi_arqos  ),
     .m_axi_aruser         (m_axi_aruser ),
     .m_axi_arvalid        (m_axi_arvalid),
     .m_axi_arready        (m_axi_arready),
     .m_axi_rid            (m_axi_rid    ),
     .m_axi_rdata          (m_axi_rdata  ),
     .m_axi_rresp          (m_axi_rresp  ),
     .m_axi_rlast          (m_axi_rlast  ),
     .m_axi_ruser          (m_axi_ruser  ),
     .m_axi_rvalid         (m_axi_rvalid ),
     .m_axi_rready         (m_axi_rready )
   );






                   
endmodule
