`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Meyesemi
// Engineer: Nill
// 
// Create Date: 15/03/23 14:17:29
// Design Name: 
// Module Name: fram_buf
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
module fram_buf 
#(
    `include"F:/Project/WorkSpace/FPGA/Video_pro/Source/top/global.vh"
)
(
    //
    input  [7 : 0]                key       ,
    output [7 : 0]                led       ,

    input                         cmos1_clk ,
    input                         cmos1_vs  ,
    input                         cmos1_de  ,
    input  [PIX_WIDTH- 1'b1 : 0]  cmos1_data,

    input                         cmos2_clk ,
    input                         cmos2_vs  ,
    input                         cmos2_de  ,
    input  [PIX_WIDTH- 1'b1 : 0]  cmos2_data,

    input                         hdmi_in_clk,
    input                         hdmi_in_vs,
    input                         hdmi_in_de,
    input  [PIX_WIDTH- 1'b1 : 0]  hdmi_in_data,

    input                         udp_in_clk,
    input                         udp_in_vs,
    input                         udp_in_de,
    input  [PIX_WIDTH- 1'b1 : 0]  udp_in_data,

    input                         udp_char_clk    ,
    input                         udp_char_vs     ,
    input                         udp_char_de     ,
    input  [PIX_WIDTH- 1'b1 : 0]  udp_char_data   ,

    output reg                    init_done=0,
    
    input                         ddr_clk,
    input                         ddr_rstn,
    
    // input                         vout_clk   ,
    // input                         rd_fsync   ,
    // input                         rd_hs      ,  
    // input                         rd_en      ,
    // output                        vout_de    ,
    // output [PIX_WIDTH- 1'b1 : 0]  vout_data  ,



    input   wire  clk_720p ,
    input   wire  vs_720p  ,
    input   wire  hs_720p  ,
    input   wire  de_720p  ,

    input   wire  clk_1080p,
    input   wire  vs_1080p ,
    input   wire  hs_1080p ,
    input   wire  de_1080p ,

    output wire         vout_clk ,
    output wire         vout_vs  ,
    output wire         vout_hs  ,
    output wire         vout_de  ,
    output wire  [15:0] vout_data,

    
    output [CTRL_ADDR_WIDTH-1:0]  axi_awaddr     ,
    output [3:0]                  axi_awid       ,
    output [3:0]                  axi_awlen      ,
    output [2:0]                  axi_awsize     ,
    output [1:0]                  axi_awburst    ,
    input                         axi_awready    ,
    output                        axi_awvalid    ,
                                                  
    output [MEM_DQ_WIDTH*8-1:0]   axi_wdata      ,
    output [MEM_DQ_WIDTH -1 :0]   axi_wstrb      ,
    input                         axi_wlast      ,
    output                        axi_wvalid     ,
    input                         axi_wready     ,
    input  [3 : 0]                axi_bid        ,                                      
                                                  
    output [CTRL_ADDR_WIDTH-1:0]  axi_araddr     ,
    output [3:0]                  axi_arid       ,
    output [3:0]                  axi_arlen      ,
    output [2:0]                  axi_arsize     ,
    output [1:0]                  axi_arburst    ,
    output                        axi_arvalid    ,
    input                         axi_arready    ,
                                                  
    output                        axi_rready     ,
    input  [MEM_DQ_WIDTH*8-1:0]   axi_rdata      ,
    input                         axi_rvalid     ,
    input                         axi_rlast      ,
    input  [3:0]                  axi_rid            
);
    // wire  vout_clk ; 
    // wire  rd_fsync ; 
    // wire  rd_hs    ; 
    // wire  rd_en    ; 
    // wire  vout_de  ; 
    // wire  vout_data; 
    wire         vout_clk_charAdd ;
    wire         vout_vs_charAdd  ;
    wire         vout_hs_charAdd  ;
    wire         vout_de_charAdd  ;
    wire  [15:0] vout_data_charAdd;
    // assign vout_clk =   ;
    // assign rd_fsync =   ;
    // assign rd_hs    =   ;
    // assign rd_en    =   ;
    // assign vout_de  =   ;
    // assign vout_data=   ;

    // parameter LEN_WIDTH       = 32;
    // parameter LINE_ADDR_WIDTH = 22;//19;//1440 * 1080 = 1 555 200 = 21'h17BB00
    // parameter FRAME_CNT_WIDTH = CTRL_ADDR_WIDTH - LINE_ADDR_WIDTH;
    
    wire                        ddr_wreq;     
    wire [AXI_ADDR_WIDTH-1:0]   ddr_waddr;    
    wire [LEN_WIDTH- 1'b1 : 0]  ddr_wr_len;   
    wire                        ddr_wrdy;     
    wire                        ddr_wdone;    
    wire [8*MEM_DQ_WIDTH-1 : 0] ddr_wdata;    
    wire                        ddr_wdata_req;
    
    wire                        rd_cmd_en   ;
    wire [AXI_ADDR_WIDTH-1:0]   rd_cmd_addr ;
    wire [LEN_WIDTH- 1'b1: 0]   rd_cmd_len  ;
    wire                        rd_cmd_ready;
    wire                        rd_cmd_done;
                                
    wire                        read_ready  = 1'b1;
    wire [MEM_DQ_WIDTH*8-1:0]   read_rdata  ;
    wire                        read_en     ;
    wire                        ddr_wr_bac;

    wire [27:0]                 write_BaseDdr_addr1;
    wire [27:0]                 write_BaseDdr_addr2;
    wire [27:0]                 write_BaseDdr_addr3;
    wire [27:0]                 write_BaseDdr_addr4;

    wire [27:0]                 read_BaseDdr_addr;

    //
    wire  							        ch0_wr_burst_req      ;/*synthesis PAP_MARK_DEBUG="1"*/
    wire   [LEN_WIDTH - 1:0] 		        ch0_wr_burst_len      ;/*synthesis PAP_MARK_DEBUG="1"*/
    wire   [AXI_ADDR_WIDTH-1:0] 			ch0_wr_burst_addr     ;/*synthesis PAP_MARK_DEBUG="1"*/
    wire   							        ch0_wr_burst_data_req ;
    wire   [AXI_DATA_WIDTH - 1:0] 		    ch0_wr_burst_data     ;
    wire   							        ch0_wr_burst_finish   ;/*synthesis PAP_MARK_DEBUG="1"*/
 
    wire  							        ch1_wr_burst_req      ;/*synthesis PAP_MARK_DEBUG="1"*/
    wire   [LEN_WIDTH - 1:0] 		        ch1_wr_burst_len      ;/*synthesis PAP_MARK_DEBUG="1"*/
    wire   [AXI_ADDR_WIDTH-1:0] 			ch1_wr_burst_addr     ;/*synthesis PAP_MARK_DEBUG="1"*/
    wire   							        ch1_wr_burst_data_req ;
    wire   [AXI_DATA_WIDTH - 1:0] 		    ch1_wr_burst_data     ;
    wire   							        ch1_wr_burst_finish   ;/*synthesis PAP_MARK_DEBUG="1"*/
 
    wire  							        ch2_wr_burst_req      ;/*synthesis PAP_MARK_DEBUG="1"*/
    wire   [LEN_WIDTH - 1:0] 		        ch2_wr_burst_len      ;/*synthesis PAP_MARK_DEBUG="1"*/
    wire   [AXI_ADDR_WIDTH-1:0] 			ch2_wr_burst_addr     ;/*synthesis PAP_MARK_DEBUG="1"*/
    wire   							        ch2_wr_burst_data_req ;
    wire   [AXI_DATA_WIDTH - 1:0] 		    ch2_wr_burst_data     ;
    wire   							        ch2_wr_burst_finish   ;/*synthesis PAP_MARK_DEBUG="1"*/
 
    wire  							        ch3_wr_burst_req      ;/*synthesis PAP_MARK_DEBUG="1"*/
    wire   [LEN_WIDTH - 1:0] 		        ch3_wr_burst_len      ;/*synthesis PAP_MARK_DEBUG="1"*/
    wire   [AXI_ADDR_WIDTH-1:0] 			ch3_wr_burst_addr     ;/*synthesis PAP_MARK_DEBUG="1"*/
    wire   							        ch3_wr_burst_data_req ;
    wire   [AXI_DATA_WIDTH - 1:0] 		    ch3_wr_burst_data     ;
    wire   							        ch3_wr_burst_finish   ;

    wire  							        ch4_wr_burst_req      ;/*synthesis PAP_MARK_DEBUG="1"*/
    wire   [LEN_WIDTH - 1:0] 		        ch4_wr_burst_len      ;/*synthesis PAP_MARK_DEBUG="1"*/
    wire   [AXI_ADDR_WIDTH-1:0] 			ch4_wr_burst_addr     ;/*synthesis PAP_MARK_DEBUG="1"*/
    wire   							        ch4_wr_burst_data_req ;
    wire   [AXI_DATA_WIDTH - 1:0] 		    ch4_wr_burst_data     ;
    wire   							        ch4_wr_burst_finish   ;
    //
    wire  							        ch0_rd_burst_req      ; /*synthesis PAP_MARK_DEBUG="1"*/
    wire   [LEN_WIDTH - 1:0] 		        ch0_rd_burst_len      ; /*synthesis PAP_MARK_DEBUG="1"*/
    wire   [AXI_ADDR_WIDTH-1:0] 			ch0_rd_burst_addr     ; /*synthesis PAP_MARK_DEBUG="1"*/
    wire   							        ch0_rd_burst_data_valid;
    wire   [AXI_DATA_WIDTH - 1:0] 		    ch0_rd_burst_data     ;
    wire   							        ch0_rd_burst_finish   ;
    //
    wire  							        ch1_rd_burst_req      ; /*synthesis PAP_MARK_DEBUG="1"*/
    wire   [LEN_WIDTH - 1:0] 		        ch1_rd_burst_len      ; /*synthesis PAP_MARK_DEBUG="1"*/
    wire   [AXI_ADDR_WIDTH-1:0] 			ch1_rd_burst_addr     ; /*synthesis PAP_MARK_DEBUG="1"*/
    wire   							        ch1_rd_burst_data_valid;
    wire   [AXI_DATA_WIDTH - 1:0] 		    ch1_rd_burst_data     ;
    wire   							        ch1_rd_burst_finish   ;

    wire cmos1_vs_o; 
    wire cmos2_vs_o; 
    wire hdmi_in_vs_o; 
    wire udp_in_vs_o; 
    
    wire wr_done_cmos1;
    wire wr_done_cmos2;

    wire        vout_de_w;
    wire [15:0] vout_data_w;


    wire  							        pro_wr_burst_req      ;
    wire   [LEN_WIDTH - 1:0] 		        pro_wr_burst_len      ;
    wire   [AXI_ADDR_WIDTH-1:0] 			pro_wr_burst_addr     ;
    wire   							        pro_wr_burst_data_req ;
    wire   [AXI_DATA_WIDTH - 1:0] 		    pro_wr_burst_data     ;
    wire   							        pro_wr_burst_finish   ;  
    
    wire  							        pro_rd_burst_req      ; 
    wire   [LEN_WIDTH - 1:0] 		        pro_rd_burst_len      ; 
    wire   [AXI_ADDR_WIDTH-1:0] 			pro_rd_burst_addr     ; 
    wire   							        pro_rd_burst_data_valid;
    wire   [AXI_DATA_WIDTH - 1:0] 		    pro_rd_burst_data     ;
    wire   							        pro_rd_burst_finish   ;

/*************************************************************/



    mode_choice  mode_choice_inst (
        .clk        (ddr_clk      ),
        .rst_n      (ddr_rstn      ),
        .key        (key           ),
        .led        (led           )
      );
/*
* processing
*/
// assign  vout_clk  = clk_720p;
// assign  vout_vs  = vs_720p;
// assign  vout_hs  = hs_720p;
// assign  vout_de  = vout_de_w;
// assign  vout_data  = vout_data_w;
// Char_add u_Char_add(






// )


processor  u_processor_inst (
    .axi_clk   (ddr_clk         ),
    .axi_arst_n(ddr_rstn        ),
    // .rst_n      (ddr_rstn       ),
    .mode       (led            ),//8'd1),//8'b0000_0001),//
    .write_BaseDdr_addr(write_BaseDdr_addr1),
    // .read_BaseDdr_addr(read_BaseDdr_addr),

    .img_720_clk_i       (clk_720p       ),
    .img_720_vs_i        (vs_720p        ),
    .img_720_hs_i        (hs_720p        ),
    .img_720_de_i        (vout_de_w      ),
    .img_720_data_i      (vout_data_w    ),

    .img_1080_clk_i  (clk_1080p     ),
    .img_1080_vs_i   (vs_1080p      ),
    .img_1080_hs_i   (hs_1080p      ),
    .img_1080_de_i   (de_1080p      ),

    .img_clk_charAdd (vout_clk_charAdd ),
    .img_vs_charAdd  (vout_vs_charAdd  ),
    .img_hs_charAdd  (vout_hs_charAdd  ),
    .img_de_charAdd  (vout_de_charAdd  ),
    .img_data_charAdd(vout_data_charAdd),
    // .img_1080_data_i (vout_data_w    ),

    .vout_clk  (vout_clk ),//vout_clk ),//(
    .vout_vs   (vout_vs  ),//vout_vs  ),//(
    .vout_hs   (vout_hs  ),//vout_hs  ),//(
    .vout_de   (vout_de  ),//vout_de  ),//(
    .vout_data (vout_data),//vout_data),//(

    .wr_burst_req     (pro_wr_burst_req     ),
    .wr_burst_len     (pro_wr_burst_len     ),
    .wr_burst_addr    (pro_wr_burst_addr    ),
    .wr_burst_data_req(pro_wr_burst_data_req),
    .wr_burst_data    (pro_wr_burst_data    ),
    .wr_burst_finish  (pro_wr_burst_finish  ),

    .rd_burst_req       (pro_rd_burst_req       ),
    .rd_burst_len       (pro_rd_burst_len       ),
    .rd_burst_addr      (pro_rd_burst_addr      ),
    .rd_burst_data_valid(pro_rd_burst_data_valid),
    .rd_burst_data      (pro_rd_burst_data      ),
    .rd_burst_finish    (pro_rd_burst_finish    )
  );


    
//
    Frame_index  u_Frame_index (
        .axi_aclk               (ddr_clk  ) ,
        .axi_aresetn            (ddr_rstn ) ,

        .cmos1_clk              (cmos1_clk ) ,
        .cmos1_vs               (cmos1_vs  ) ,
        .cmos1_vs_o             (cmos1_vs_o) ,  
        // .wr_done_cmos1          (wr_done_cmos1      ) , 
        .cmos2_clk              (cmos2_clk ) ,
        .cmos2_vs               (cmos2_vs  ) ,
        .cmos2_vs_o             (cmos2_vs_o) ,  

        .hdmi_in_clk            (hdmi_in_clk ) ,
        .hdmi_in_vs             (hdmi_in_vs  ) ,
        .hdmi_in_vs_o           (hdmi_in_vs_o) ,  

        .udp_in_clk            (udp_in_clk ) ,
        .udp_in_vs             (udp_in_vs  ) ,
        .udp_in_vs_o           (udp_in_vs_o) , 
        // .wr_done_cmos2          (wr_done_cmos2      ) ,  

        
        

        .write_BaseDdr_addr1    (write_BaseDdr_addr1),
        .write_BaseDdr_addr2    (write_BaseDdr_addr2),
        .write_BaseDdr_addr3    (write_BaseDdr_addr3),
        .write_BaseDdr_addr4    (write_BaseDdr_addr4),

        .read_BaseDdr_addr      (read_BaseDdr_addr)
        );

/*
*
*/
    wr_buf #(
        .ADDR_WIDTH       (  CTRL_ADDR_WIDTH  ),
        .ADDR_OFFSET      (  32'd0            ), 
        .H_NUM            (  H_NUM            ),
        .V_NUM            (  V_NUM            ),
        .DQ_WIDTH         (  MEM_DQ_WIDTH     ),
        .LEN_WIDTH        (  LEN_WIDTH        ),
        .PIX_WIDTH        (  PIX_WIDTH        ),
        .LINE_ADDR_WIDTH  (  LINE_ADDR_WIDTH  ),
        .FRAME_CNT_WIDTH  (  FRAME_CNT_WIDTH  ) 
    ) wr_buf_cmos1 (                            
        .ddr_clk          (  ddr_clk          ),
        .ddr_rstn         (  ddr_rstn         ),
        .write_BaseDdr_addr(write_BaseDdr_addr1) , 
        
        .wr_clk           (  cmos1_clk           ),
        .wr_fsync         (  cmos1_vs_o          ),
        .wr_en            (  cmos1_de            ),
        .wr_data          (  cmos1_data          ),
        .wr_done          (  wr_done_cmos1       ),
        
        .ddr_wreq         (  ch0_wr_burst_req        ),
        .ddr_waddr        (  ch0_wr_burst_addr       ),
        .ddr_wr_len       (  ch0_wr_burst_len        ),
        .ddr_wdone        (  ch0_wr_burst_finish     ),
        .ddr_wdata        (  ch0_wr_burst_data       ),
        .ddr_wdata_req    (  ch0_wr_burst_data_req   ),
                                              
        .frame_wirq       (          ) 
    );


    wr_buf #(
        .ADDR_WIDTH       (  CTRL_ADDR_WIDTH  ),
        .ADDR_OFFSET      (  32'd0            ),
        .H_NUM            (  H_NUM            ),
        .V_NUM            (  V_NUM            ),
        .DQ_WIDTH         (  MEM_DQ_WIDTH     ),
        .LEN_WIDTH        (  LEN_WIDTH        ),
        .PIX_WIDTH        (  PIX_WIDTH        ),
        .LINE_ADDR_WIDTH  (  LINE_ADDR_WIDTH  ),
        .FRAME_CNT_WIDTH  (  FRAME_CNT_WIDTH  ) 
    ) wr_buf_cmos2 (                                       
        .ddr_clk          (  ddr_clk          ),
        .ddr_rstn         (  ddr_rstn         ),
        .write_BaseDdr_addr(write_BaseDdr_addr2) , 
        
        .wr_clk           (  cmos2_clk           ),
        .wr_fsync         (  cmos2_vs_o          ),
        .wr_en            (  cmos2_de            ),
        .wr_data          (  cmos2_data          ),
        .wr_done          (  wr_done_cmos2       ),
               
        .ddr_wreq         (  ch1_wr_burst_req        ),
        .ddr_waddr        (  ch1_wr_burst_addr       ),
        .ddr_wr_len       (  ch1_wr_burst_len        ),   
        .ddr_wdone        (  ch1_wr_burst_finish     ),
        .ddr_wdata        (  ch1_wr_burst_data       ),
        .ddr_wdata_req    (  ch1_wr_burst_data_req   )    
    );  
    
    wr_buf #(
        .FLAG             (1920),
        .ADDR_WIDTH       (  CTRL_ADDR_WIDTH  ),
        .ADDR_OFFSET      (  32'd0            ),
        .H_NUM            (  H_NUM            ),
        .V_NUM            (  V_NUM            ),
        .DQ_WIDTH         (  MEM_DQ_WIDTH     ),
        .LEN_WIDTH        (  LEN_WIDTH        ),
        .PIX_WIDTH        (  PIX_WIDTH        ),
        .LINE_ADDR_WIDTH  (  LINE_ADDR_WIDTH  ),
        .FRAME_CNT_WIDTH  (  FRAME_CNT_WIDTH  ) 
    ) wr_buf_hdmi_in (                                       
        .ddr_clk          (  ddr_clk          ),
        .ddr_rstn         (  ddr_rstn         ),
        .write_BaseDdr_addr(write_BaseDdr_addr3) , 
        
        .wr_clk           (  hdmi_in_clk           ),
        .wr_fsync         (  hdmi_in_vs_o          ),
        .wr_en            (  hdmi_in_de            ),
        .wr_data          (  hdmi_in_data          ),
        .wr_done          (                   ),
               
        .ddr_wreq         (  ch2_wr_burst_req        ),
        .ddr_waddr        (  ch2_wr_burst_addr       ),
        .ddr_wr_len       (  ch2_wr_burst_len        ),   
        .ddr_wdone        (  ch2_wr_burst_finish     ),
        .ddr_wdata        (  ch2_wr_burst_data       ),
        .ddr_wdata_req    (  ch2_wr_burst_data_req   )   ,
.frame_wirq       (  frame_wirq       )  
    ); 

    wr_buf #(
        // .FLAG             (1920),
        .ADDR_WIDTH       (  CTRL_ADDR_WIDTH  ),
        .ADDR_OFFSET      (  32'd0            ),
        .H_NUM            (  H_NUM            ),
        .V_NUM            (  V_NUM            ),
        .DQ_WIDTH         (  MEM_DQ_WIDTH     ),
        .LEN_WIDTH        (  LEN_WIDTH        ),
        .PIX_WIDTH        (  PIX_WIDTH        ),
        .LINE_ADDR_WIDTH  (  LINE_ADDR_WIDTH  ),
        .FRAME_CNT_WIDTH  (  FRAME_CNT_WIDTH  ) 
    ) wr_buf_udp_in (                                       
        .ddr_clk          (  ddr_clk          ),
        .ddr_rstn         (  ddr_rstn         ),
        .write_BaseDdr_addr(write_BaseDdr_addr4), 
        
        .wr_clk           (  udp_in_clk           ),
        .wr_fsync         (  udp_in_vs_o          ),
        .wr_en            (  udp_in_de            ),
        .wr_data          (  udp_in_data          ),
        .wr_done          (                      ),
               
        .ddr_wreq         (  ch3_wr_burst_req        ),
        .ddr_waddr        (  ch3_wr_burst_addr       ),
        .ddr_wr_len       (  ch3_wr_burst_len        ),   
        .ddr_wdone        (  ch3_wr_burst_finish     ),
        .ddr_wdata        (  ch3_wr_burst_data       ),
        .ddr_wdata_req    (  ch3_wr_burst_data_req   )    
    ); 


    wr_char  u_wr_char (                                       
        .ddr_clk          (  ddr_clk          ),
        .ddr_rstn         (  ddr_rstn         ),
        .write_BaseDdr_addr(Base_Char_addr     ), 
        
        .wr_clk           (  udp_char_clk           ),
        .wr_fsync         (  udp_char_vs            ),
        .wr_en            (  udp_char_de            ),
        .wr_data          (  udp_char_data          ),
        // .wr_done          (                      ),
               
        .ddr_wreq         (  ch4_wr_burst_req        ),
        .ddr_waddr        (  ch4_wr_burst_addr       ),
        .ddr_wr_len       (  ch4_wr_burst_len        ),   
        .ddr_wdone        (  ch4_wr_burst_finish     ),
        .ddr_wdata        (  ch4_wr_burst_data       ),
        .ddr_wdata_req    (  ch4_wr_burst_data_req   )    
    ); 

    rd_char u_rd_char (
        .ddr_clk          (  ddr_clk          ),
        .ddr_rstn         (  ddr_rstn         ),
        .read_BaseDdr_addr(Base_Char_addr),

        .img_720_clk_i       (clk_720p       ),
        .img_720_vs_i        (vs_720p        ),
        .img_720_hs_i        (hs_720p        ),
        .img_720_de_i        (vout_de_w      ),
        .img_720_data_i      (vout_data_w    ),   
    
        .vout_clk  (vout_clk_charAdd ),
        .vout_vs   (vout_vs_charAdd  ),
        .vout_hs   (vout_hs_charAdd  ),
        .vout_de   (vout_de_charAdd  ),
        .vout_data (vout_data_charAdd),
      
        .ddr_rreq        (  ch1_rd_burst_req        ),//output                        ddr_rreq,
        .ddr_raddr       (  ch1_rd_burst_addr       ),//output [ADDR_WIDTH- 1'b1 : 0] ddr_raddr,
        .ddr_rd_len      (  ch1_rd_burst_len        ),//output [LEN_WIDTH- 1'b1 : 0]  ddr_rd_len,
        .ddr_rdone       (  ch1_rd_burst_finish     ),//input                         ddr_rdone,                               
        .ddr_rdata       (  ch1_rd_burst_data       ),//input [8*DQ_WIDTH- 1'b1 : 0]  ddr_rdata,
        .ddr_rdata_en    (  ch1_rd_burst_data_valid ) 
    );
 /*****************************************************/

    always @(posedge ddr_clk)
    begin
        if(frame_wirq)
            init_done <= 1'b1;
        else
            init_done <= init_done;
    end 
    
    rd_buf #(
        .ADDR_WIDTH       (  CTRL_ADDR_WIDTH  ),//parameter                     ADDR_WIDTH      = 6'd27,
        .ADDR_OFFSET      (  32'h0000_0000    ),//parameter                     ADDR_OFFSET     = 32'h0000_0000,
        .H_NUM            (  H_NUM            ),//parameter                     H_NUM           = 12'd1920,
        .V_NUM            (  V_NUM            ),//parameter                     V_NUM           = 12'd1080,
        .DQ_WIDTH         (  MEM_DQ_WIDTH     ),//parameter                     DQ_WIDTH        = 7'd32,
        .LEN_WIDTH        (  LEN_WIDTH        ),//parameter                     LEN_WIDTH       = 6'd16,
        .PIX_WIDTH        (  PIX_WIDTH        ),//parameter                     PIX_WIDTH       = 6'd24,
        .LINE_ADDR_WIDTH  (  LINE_ADDR_WIDTH  ),//parameter                     LINE_ADDR_WIDTH = 4'd19,
        .FRAME_CNT_WIDTH  (  FRAME_CNT_WIDTH  ) //parameter                     FRAME_CNT_WIDTH = 4'd8
    ) rd_buf (
        .ddr_clk         (  ddr_clk           ),//input                         ddr_clk,
        .ddr_rstn        (  ddr_rstn          ),//input                         ddr_rstn,
        .read_BaseDdr_addr      (read_BaseDdr_addr),
        
        .vout_clk        (  clk_720p          ),//input                         vout_clk,
        .rd_fsync        (  vs_720p          ),//input                         rd_fsync,
        .rd_en           (  de_720p             ),//input                         rd_en,
        .vout_de         (  vout_de_w         ),//output                        vout_de,
        .vout_data       (  vout_data_w       ),//output [PIX_WIDTH- 1'b1 : 0]  vout_data,
        
        .init_done       (  init_done         ),//input                         init_done,
      
        .ddr_rreq        (  ch0_rd_burst_req  ),//output                        ddr_rreq,
        .ddr_raddr       (  ch0_rd_burst_addr ),//output [ADDR_WIDTH- 1'b1 : 0] ddr_raddr,
        .ddr_rd_len      (  ch0_rd_burst_len  ),//output [LEN_WIDTH- 1'b1 : 0]  ddr_rd_len,
        .ddr_rrdy        (  1'b1              ),//input                         ddr_rrdy,
        .ddr_rdone       (  ch0_rd_burst_finish),//input                         ddr_rdone,
                                              
        .ddr_rdata       (  ch0_rd_burst_data  ),//input [8*DQ_WIDTH- 1'b1 : 0]  ddr_rdata,
        .ddr_rdata_en    (  ch0_rd_burst_data_valid ) 

        // .ddr_rreq        (  rd_cmd_en         ),//output                        ddr_rreq,
        // .ddr_raddr       (  rd_cmd_addr       ),//output [ADDR_WIDTH- 1'b1 : 0] ddr_raddr,
        // .ddr_rd_len      (  rd_cmd_len        ),//output [LEN_WIDTH- 1'b1 : 0]  ddr_rd_len,
        // .ddr_rrdy        (  rd_cmd_ready      ),//input                         ddr_rrdy,
        // .ddr_rdone       (  rd_cmd_done       ),//input                         ddr_rdone,
                                              
        // .ddr_rdata       (  read_rdata        ),//input [8*DQ_WIDTH- 1'b1 : 0]  ddr_rdata,
        // .ddr_rdata_en    (  read_en           ) //input                         ddr_rdata_en,
    );
/*
*   arbiter read
*/ 
mem_read_arbi u_mem_read_arbi (
    .rst_n                  (ddr_rstn               ),
    .mem_clk                (ddr_clk                ),

    .ch0_rd_burst_req       (ch0_rd_burst_req       ),
    .ch0_rd_burst_len       (ch0_rd_burst_len       ),
    .ch0_rd_burst_addr      (ch0_rd_burst_addr      ),
    .ch0_rd_burst_data_valid(ch0_rd_burst_data_valid),
    .ch0_rd_burst_data      (ch0_rd_burst_data      ),
    .ch0_rd_burst_finish    (ch0_rd_burst_finish    ),

    .ch1_rd_burst_req       (pro_rd_burst_req       ),
    .ch1_rd_burst_len       (pro_rd_burst_len       ),
    .ch1_rd_burst_addr      (pro_rd_burst_addr      ),
    .ch1_rd_burst_data_valid(pro_rd_burst_data_valid),
    .ch1_rd_burst_data      (pro_rd_burst_data      ),
    .ch1_rd_burst_finish    (pro_rd_burst_finish    ),

    .ch2_rd_burst_req       (ch1_rd_burst_req       ),
    .ch2_rd_burst_len       (ch1_rd_burst_len       ),
    .ch2_rd_burst_addr      (ch1_rd_burst_addr      ),
    .ch2_rd_burst_data_valid(ch1_rd_burst_data_valid),
    .ch2_rd_burst_data      (ch1_rd_burst_data      ),
    .ch2_rd_burst_finish    (ch1_rd_burst_finish    ),


    .rd_burst_req           (rd_cmd_en              ),
    .rd_burst_len           (rd_cmd_len             ),
    .rd_burst_addr          (rd_cmd_addr            ),
    .rd_burst_data_valid    (read_en                ),
    .rd_burst_data          (read_rdata             ),
    .rd_burst_finish        (rd_cmd_done            )
  );
/*
*   arbiter writer
*/   
    mem_write_arbi mem_write_arbi_m0(
        .rst_n                       (ddr_rstn       ),
        .mem_clk                     (ddr_clk        ),
        
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

        .ch3_wr_burst_req            (ch3_wr_burst_req      ),
        .ch3_wr_burst_len            (ch3_wr_burst_len      ),
        .ch3_wr_burst_addr           (ch3_wr_burst_addr     ),
        .ch3_wr_burst_data_req       (ch3_wr_burst_data_req ),
        .ch3_wr_burst_data           (ch3_wr_burst_data     ),
        .ch3_wr_burst_finish         (ch3_wr_burst_finish   ),

        .ch4_wr_burst_req            (pro_wr_burst_req      ),
        .ch4_wr_burst_len            (pro_wr_burst_len      ),
        .ch4_wr_burst_addr           (pro_wr_burst_addr     ),
        .ch4_wr_burst_data_req       (pro_wr_burst_data_req ),
        .ch4_wr_burst_data           (pro_wr_burst_data     ),
        .ch4_wr_burst_finish         (pro_wr_burst_finish   ),

        .ch5_wr_burst_req            (ch4_wr_burst_req      ),
        .ch5_wr_burst_len            (ch4_wr_burst_len      ),
        .ch5_wr_burst_addr           (ch4_wr_burst_addr     ),
        .ch5_wr_burst_data_req       (ch4_wr_burst_data_req ),
        .ch5_wr_burst_data           (ch4_wr_burst_data     ),
        .ch5_wr_burst_finish         (ch4_wr_burst_finish   ),

        .wr_burst_req                 (ddr_wreq             ),
        .wr_burst_len                 (ddr_wr_len           ),
        .wr_burst_addr                (ddr_waddr            ),
        .wr_burst_data_req            (ddr_wdata_req        ),
        .wr_burst_data                (ddr_wdata            ),
        .wr_burst_finish              (ddr_wdone            )	
    );


/*
*
*/    
    wr_rd_ctrl_top#(
        .CTRL_ADDR_WIDTH  (  CTRL_ADDR_WIDTH  ),//parameter                    CTRL_ADDR_WIDTH      = 28,
        .MEM_DQ_WIDTH     (  MEM_DQ_WIDTH     ) //parameter                    MEM_DQ_WIDTH         = 16
    )wr_rd_ctrl_top (                         
        .clk              (  ddr_clk          ),//input                        clk            ,            
        .rstn             (  ddr_rstn         ),//input                        rstn           ,            
                                              
        .wr_cmd_en        (  ddr_wreq         ),//input                        wr_cmd_en   ,
        .wr_cmd_addr      (  ddr_waddr        ),//input  [CTRL_ADDR_WIDTH-1:0] wr_cmd_addr ,
        .wr_cmd_len       (  ddr_wr_len       ),//input  [31£º0]               wr_cmd_len  ,
        .wr_cmd_ready     (  ddr_wrdy         ),//output                       wr_cmd_ready,
        .wr_cmd_done      (  ddr_wdone        ),//output                       wr_cmd_done,
        .wr_bac           (  ddr_wr_bac       ),//output                       wr_bac,                                     
        .wr_ctrl_data     (  ddr_wdata        ),//input  [MEM_DQ_WIDTH*8-1:0]  wr_ctrl_data,
        .wr_data_re       (  ddr_wdata_req    ),//output                       wr_data_re  ,
                                              
        .rd_cmd_en        (  rd_cmd_en        ),//input                        rd_cmd_en   ,
        .rd_cmd_addr      (  rd_cmd_addr      ),//input  [CTRL_ADDR_WIDTH-1:0] rd_cmd_addr ,
        .rd_cmd_len       (  rd_cmd_len       ),//input  [31£º0]               rd_cmd_len  ,
        .rd_cmd_ready     (  rd_cmd_ready     ),//output                       rd_cmd_ready, 
        .rd_cmd_done      (  rd_cmd_done      ),//output                       rd_cmd_done,
                                              
        .read_ready       (  read_ready       ),//input                        read_ready  ,    
        .read_rdata       (  read_rdata       ),//output [MEM_DQ_WIDTH*8-1:0]  read_rdata  ,    
        .read_en          (  read_en          ),//output                       read_en     ,                                          
        // write channel                        
        .axi_awaddr       (  axi_awaddr       ),//output [CTRL_ADDR_WIDTH-1:0] axi_awaddr     ,  
        .axi_awid         (  axi_awid         ),//output [3:0]                 axi_awid       ,
        .axi_awlen        (  axi_awlen        ),//output [3:0]                 axi_awlen      ,
        .axi_awsize       (  axi_awsize       ),//output [2:0]                 axi_awsize     ,
        .axi_awburst      (  axi_awburst      ),//output [1:0]                 axi_awburst    , //only support 2'b01: INCR
        .axi_awready      (  axi_awready      ),//input                        axi_awready    ,
        .axi_awvalid      (  axi_awvalid      ),//output                       axi_awvalid    ,
                                              
        .axi_wdata        (  axi_wdata        ),//output [MEM_DQ_WIDTH*8-1:0]  axi_wdata      ,
        .axi_wstrb        (  axi_wstrb        ),//output [MEM_DQ_WIDTH -1 :0]  axi_wstrb      ,
        .axi_wlast        (  axi_wlast        ),//output                       axi_wlast      ,
        .axi_wvalid       (  axi_wvalid       ),//output                       axi_wvalid     ,
        .axi_wready       (  axi_wready       ),//input                        axi_wready     ,
        .axi_bid          (  4'd0             ),//input  [3 : 0]               axi_bid        , // Master Interface Write Response.
        .axi_bresp        (  2'd0             ),//input  [1 : 0]               axi_bresp      , // Write response. This signal indicates the status of the write transaction.
        .axi_bvalid       (  1'b0             ),//input                        axi_bvalid     , // Write response valid. This signal indicates that the channel is signaling a valid write response.
        .axi_bready       (                   ),//output                       axi_bready     ,
                                              
        // read channel                          
        .axi_araddr       (  axi_araddr       ),//output [CTRL_ADDR_WIDTH-1:0] axi_araddr     ,    
        .axi_arid         (  axi_arid         ),//output [3:0]                 axi_arid       ,
        .axi_arlen        (  axi_arlen        ),//output [3:0]                 axi_arlen      ,
        .axi_arsize       (  axi_arsize       ),//output [2:0]                 axi_arsize     ,
        .axi_arburst      (  axi_arburst      ),//output [1:0]                 axi_arburst    ,
        .axi_arvalid      (  axi_arvalid      ),//output                       axi_arvalid    , 
        .axi_arready      (  axi_arready      ),//input                        axi_arready    , //only support 2'b01: INCR
                                              
        .axi_rready       (  axi_rready       ),//output                       axi_rready     ,
        .axi_rdata        (  axi_rdata        ),//input  [MEM_DQ_WIDTH*8-1:0]  axi_rdata      ,
        .axi_rvalid       (  axi_rvalid       ),//input                        axi_rvalid     ,
        .axi_rlast        (  axi_rlast        ),//input                        axi_rlast      ,
        .axi_rid          (  axi_rid          ),//input  [3:0]                 axi_rid        ,
        .axi_rresp        (  2'd0             ) //input  [1:0]                 axi_rresp      
    );


endmodule
