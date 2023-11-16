//仿真很多地方用了绝对地址，以后若是要移植的话，需要修改为相对地址
//ddr_test
//
//

`timescale 1 ps / 1 ps

`include "F:/Project/WorkSpace/FPGA/MES50HP/07_ddr3_test/ipcore/ddr3_test/example_design/bench/mem/ddr3_parameters.vh"

module ddr_tb
  #(

    //  parameter DFI_CLK_PERIOD       = 10000         ,

     parameter MEM_ROW_WIDTH   = 15         ,

     parameter MEM_COLUMN_WIDTH   = 10         ,

     parameter MEM_BANK_WIDTH      = 3          ,

     parameter MEM_DQ_WIDTH         =  32         ,

     parameter MEM_DM_WIDTH         =  4         ,

     parameter MEM_DQS_WIDTH        =  4         ,

     parameter REGION_NUM           =  3         ,

     parameter CTRL_ADDR_WIDTH      = MEM_ROW_WIDTH + MEM_COLUMN_WIDTH + MEM_BANK_WIDTH
   )
   (

     input ddr_clk,  //50Mhz
     input ddr_rst_n,

     output                             axi_aclk,
     output                             axi_aresetn,
     output                             ddr_init_done,

     input [CTRL_ADDR_WIDTH-1:0]        axi_awaddr     ,
     input                              axi_awuser_ap  ,
     input [3:0]                        axi_awuser_id  ,
     input [3:0]                        axi_awlen      ,
     output                             axi_awready    ,
     input                              axi_awvalid    ,

     input [MEM_DQ_WIDTH*8-1:0]         axi_wdata      ,
     input [MEM_DQ_WIDTH-1:0]           axi_wstrb      ,
     output                             axi_wready     ,
     output [3:0]                       axi_wusero_id  ,
     output                             axi_wusero_last,

     input                              axi_bready     ,
     output                             axi_bvalid     ,

     input [CTRL_ADDR_WIDTH-1:0]        axi_araddr     ,
     input                              axi_aruser_ap  ,
     input [3:0]                        axi_aruser_id  ,
     input [3:0]                        axi_arlen      ,
     output                             axi_arready    ,
     input                              axi_arvalid    ,

     output[8*MEM_DQ_WIDTH-1:0]         axi_rdata      ,
     output[3:0]                        axi_rid        ,
     output                             axi_rlast      ,
     output                             axi_rvalid
   );


  assign axi_bvalid = axi_bready;

  // parameter real CLKIN_FREQ  = 50.0;


  // parameter PLL_REFCLK_IN_PERIOD = 1000000 / CLKIN_FREQ;


  parameter MEM_ADDR_WIDTH = 15;

  parameter MEM_BADDR_WIDTH = 3;

  // parameter MEM_DQ_WIDTH = 32;


  // parameter MEM_DM_WIDTH         = MEM_DQ_WIDTH/8;
  // parameter MEM_DQS_WIDTH        = MEM_DQ_WIDTH/8;
  parameter MEM_NUM              = MEM_DQ_WIDTH/16;

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
  //   wire                             core_clk                  ;
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

  reg  [26:0]                      cnt                       ;

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

  DDR3_50H u_DDR3_50H(
              .ref_clk                   (ddr_clk            ),//50Mhz
              .resetn                    (ddr_rst_n          ),// input
              .ddr_init_done             (ddr_init_done      ),// output
              .ddrphy_clkin              (axi_aclk           ),// output    ***axi_aclk
              .pll_lock                  (axi_aresetn        ),// output    ***axi_aresetn

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

  //     //default input from keyboard
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

endmodule

