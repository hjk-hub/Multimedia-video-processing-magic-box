`timescale 1 ps / 1 ps
module tb_top
#(
  `include"F:/Project/WorkSpace/FPGA/Video_pro/Source/top/global.vh"
 )
();

  parameter real CLKIN_FREQ  = 50.0;
  parameter PLL_REFCLK_IN_PERIOD = 1000000 / CLKIN_FREQ;


  // parameter FIFO_ADDR_WIDTH = 11;
  /*****************************************************/
  //Ports
  wire                          axi_aclk        ;
  wire                          axi_aresetn     ;
  wire                          ddr_init_done   ;

  wire  [CTRL_ADDR_WIDTH-1:0]        m_axi_awaddr     ;
  wire  [3:0]                        m_axi_awid       ;
  wire  [3:0]                        m_axi_awlen      ;
  wire                               m_axi_awready    ;
  wire                               m_axi_awvalid    ;

  wire  [MEM_DQ_WIDTH*8-1:0]         m_axi_wdata      ;
  wire  [MEM_DQ_WIDTH-1:0]           m_axi_wstrb      ;
  wire                               m_axi_wready     ;
  wire                               m_axi_wlast      ;

  wire                               m_axi_bready     ;
  wire                               m_axi_bvalid     ;

  wire [CTRL_ADDR_WIDTH-1:0]        m_axi_araddr     ;
  wire [3:0]                        m_axi_arid       ;
  wire [3:0]                        m_axi_arlen      ;
  wire                              m_axi_arready    ;
  wire                              m_axi_arvalid    ;

  wire [8*MEM_DQ_WIDTH-1:0]           m_axi_rdata      ;
  wire [3:0]                          m_axi_rid        ;
  wire                                m_axi_rlast      ;
  wire                                m_axi_rvalid     ;
  /****************************************************/
  // clk and rst_n
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


  
  /****************************************************/
  //pll
  wire pix_clk;
  wire cfg_clk;
  wire clk_25M;

  //color_bar
  wire                          Img1_pclk    ;  
  wire                          Img1_vs      ;  
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

  // reg [31:0] cnt;
  // initial
  // begin
  //   cnt = 0;
  //   @ (negedge Img1_vs);
  //     cnt = cnt + 1;
  //   $display("开始输入视频!", $time);
  //   //   #100000000;
  //   if(cnt >= 2)
  //     $stop;
  // end
  reg [31:0] cnt;
  
  reg [15:0] mem1 [0:IMG_ROW] [0:IMG_COL];

  integer m,n;
  initial
  begin
    cnt = 0;
    for (m=0; m<=IMG_ROW; m=m+1)
      for (n=0; n<=IMG_COL; n=n+1)
          mem1[m][n] =0;

    repeat(10) @ (negedge Img1_vs)begin
      cnt = cnt + 1;
      $display("cnt time %d!!!", cnt);
      if(cnt == 4)
        $stop;
    end
  end
  integer i,j;
  always @(posedge Img1_pclk or negedge Img1_vs)begin
    if(Img1_vs)begin
      i <= 0;
      j <= 0;
    end
    else begin
      if(cnt == 2)begin
        if(Img1_de)begin
          j <= j + 1;
          if(j == IMG_COL-1)begin
            j <= 0;
            i <= i + 1;
          end
          mem1[i][j] = Img1_data;
        end
      end 
      else begin
        i <= 0;
        j <= 0;
      end
        
    end
end


  pll u_pll (
        .clkin1   (  sys_clk    ),//50MHz
        .clkout0  (  pix_clk    ),//74.25M 720P30
        .clkout1  (  cfg_clk    ),//10MHz
        .clkout2  (  clk_25M    ),//25M
        .pll_lock (  locked     )
      );
  //产生视频第一路
  color_bar u_color_bar_1(
              .clk                        (Img1_pclk                  ),
              .rst                        (~ddr_init_done           ),
              .hs                         (              ),
              .vs                         (Img1_vs             ),
              .de                         (Img1_de             ),
              .rgb_r                      (color_bar_r              ),
              .rgb_g                      (color_bar_g              ),
              .rgb_b                      (color_bar_b              )
            );



  always @(posedge Img1_pclk or negedge Img1_vs)begin
    if(Img1_vs)begin
      Img1_data <= 16'd0;
    end
    else begin
      if(Img1_de)
          Img1_data <= Img1_data + 16'd1;
      else
        Img1_data <= Img1_data;
    end

    end


  //    cnt_1 <= 'd0;

// assign Img1_data = {color_bar_r[7:3],color_bar_g[7:2],color_bar_b[7:3]};
// wire           Img_pclk_o;
wire           Img_vs_o  ;
wire           Img_de_o  ;
wire  [15:0]   Img_data_o;

  Frame_top u_Frame_top (

            .Img1_pclk         (Img1_pclk),
            .Img1_vs           (Img1_vs  ),
            .Img1_de           (Img1_de  ),
            .Img1_data         (Img1_data),

            .Img2_pclk         (Img1_pclk),
            .Img2_vs           (Img1_vs  ),
            .Img2_de           (Img1_de  ),
            .Img2_data         (Img1_data),

            .Img3_pclk         (Img1_pclk),
            .Img3_vs           (Img1_vs  ),
            .Img3_de           (Img1_de  ),
            .Img3_data         (Img1_data),
            
            .Img4_pclk         (Img1_pclk),
            .Img4_vs           (Img1_vs  ),
            .Img4_de           (Img1_de  ),
            .Img4_data         (Img1_data),

            .Img_pclk_i        (Img1_pclk ),//hdmi clk 74.25MHZ
            .Img_pclk_o        (Img_pclk_o),
            .Img_vs_o          (Img_vs_o  ),
            .Img_de_o          (Img_de_o  ),
            .Img_data_o        (Img_data_o),  

            //AXI
            .axi_aclk          (axi_aclk         ),
            .axi_aresetn       (axi_aresetn      ),
            .ddr_init_done     (ddr_init_done    ),
            .m_axi_awaddr      (m_axi_awaddr     ),
            .m_axi_awid        (m_axi_awid       ),
            .m_axi_awlen       (m_axi_awlen      ),
            .m_axi_awready     (m_axi_awready    ),
            .m_axi_awvalid     (m_axi_awvalid    ),
            .m_axi_wdata       (m_axi_wdata      ),
            .m_axi_wstrb       (m_axi_wstrb      ),
            .m_axi_wready      (m_axi_wready     ),
            .m_axi_wlast       (m_axi_wlast      ),
            .m_axi_bvalid      (m_axi_bvalid     ),
            .m_axi_bready      (m_axi_bready     ),
            .m_axi_araddr      (m_axi_araddr     ),
            .m_axi_arid        (m_axi_arid       ),
            .m_axi_arlen       (m_axi_arlen      ),
            .m_axi_arready     (m_axi_arready    ),
            .m_axi_arvalid     (m_axi_arvalid    ),
            .m_axi_rdata       (m_axi_rdata      ),
            .m_axi_rid         (m_axi_rid        ),
            .m_axi_rlast       (m_axi_rlast      ),
            .m_axi_rvalid      (m_axi_rvalid     )
          );


  /*******************************************************/
  ddr_tb u_S_ddr_tb_inst (
           .ddr_clk         (sys_clk        ),
           .ddr_rst_n       (sys_rst_n      ),
           .axi_aclk        (axi_aclk       ),
           .axi_aresetn     (axi_aresetn    ),

           .ddr_init_done   (ddr_init_done  ),

           .axi_awaddr      (m_axi_awaddr     ),
           .axi_awuser_ap   (1'b1             ),
           .axi_awuser_id   (m_axi_awid       ),
           .axi_awlen       (m_axi_awlen      ),
           .axi_awready     (m_axi_awready    ),
           .axi_awvalid     (m_axi_awvalid    ),
           .axi_wdata       (m_axi_wdata      ),
           .axi_wstrb       (m_axi_wstrb      ),
           .axi_wready      (m_axi_wready     ),
           //  .axi_wusero_id   (                 ),
          //  .axi_wusero_last (m_axi_wlast      ),
           .axi_bvalid      (m_axi_bvalid     ),
           .axi_bready      (m_axi_bready     ),

           .axi_araddr      (m_axi_araddr     ),
           .axi_aruser_ap   (                 ),
           .axi_aruser_id   (m_axi_arid  ),
           .axi_arlen       (m_axi_arlen      ),
           .axi_arready     (m_axi_arready    ),
           .axi_arvalid     (m_axi_arvalid    ),
           .axi_rdata       (m_axi_rdata      ),
           .axi_rid         (m_axi_rid        ),
           .axi_rlast       (m_axi_rlast      ),
           .axi_rvalid      (m_axi_rvalid     )
         );

  // //always #5  clk = ! clk ;
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
