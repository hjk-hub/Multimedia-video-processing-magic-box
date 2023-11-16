`timescale 1 ps / 1 ps

// `include "F:/Project/WorkSpace/FPGA/MES50HP/07_ddr3_test/ipcore/ddr3_test/example_design/bench/mem/ddr3_parameters.vh"

module axi_ddr_ctr
#(
  `include"F:/Project/WorkSpace/FPGA/Video_pro/Source/top/global.vh"
 )
  (
    input wire                                  wr_burst_req     , 
    input wire    [7:0]                         wr_burst_len     ,
    input wire    [27:0]                        wr_burst_addr    ,
    output wire                                 wr_burst_data_req/*synthesis PAP_MARK_DEBUG="1"*/,
    output wire   [AXI_DATA_WIDTH-1 : 0]        wr_burst_data    /*synthesis PAP_MARK_DEBUG="1"*/,
    output wire                                 wr_burst_finish  /*synthesis PAP_MARK_DEBUG="1"*/,

    input wire                                  rd_burst_req     , 
    input wire     [7:0]                        rd_burst_len     ,
    input wire     [27:0]                       rd_burst_addr    ,
    output wire                                 rd_burst_data_valid,
    output wire   [AXI_DATA_WIDTH-1 : 0]        rd_burst_data    ,
    output wire                                 rd_burst_finish  ,

    // input  [27:0]   addr,

    input wire                                  m_axi_aclk,
    input wire                                  m_axi_aresetn,
    output wire [AXI_ID_WIDTH-1 : 0]            m_axi_awid,
    output wire [AXI_ADDR_WIDTH-1 : 0]          m_axi_awaddr,
    output wire [7 : 0]                         m_axi_awlen,
    output wire [2 : 0]                         m_axi_awsize,
    output wire [1 : 0]                         m_axi_awburst,
    output wire                                 m_axi_awlock,
    output wire [3 : 0]                         m_axi_awcache,
    output wire [2 : 0]                         m_axi_awprot,
    output wire [3 : 0]                         m_axi_awqos,
    output wire [AXI_AWUSER_WIDTH-1 : 0]        m_axi_awuser,
    output wire                                 m_axi_awvalid,
    input wire                                  m_axi_awready,
    output wire [AXI_DATA_WIDTH-1 : 0]          m_axi_wdata,
    output wire [AXI_DATA_WIDTH/8-1 : 0]        m_axi_wstrb,
    output wire                                 m_axi_wlast,
    output wire [AXI_WUSER_WIDTH-1 : 0]         m_axi_wuser,
    output wire                                 m_axi_wvalid,
    input wire                                  m_axi_wready,
    input wire [AXI_ID_WIDTH-1 : 0]             m_axi_bid,
    input wire [1 : 0]                          m_axi_bresp,
    input wire [AXI_BUSER_WIDTH-1 : 0]          m_axi_buser,
    input wire                                  m_axi_bvalid,
    output wire                                 m_axi_bready,
    output wire [AXI_ID_WIDTH-1 : 0]            m_axi_arid,
    output wire [AXI_ADDR_WIDTH-1 : 0]          m_axi_araddr,
    output wire [7 : 0]                         m_axi_arlen,
    output wire [2 : 0]                         m_axi_arsize,
    output wire [1 : 0]                         m_axi_arburst,
    output wire                                 m_axi_arlock,
    output wire [3 : 0]                         m_axi_arcache,
    output wire [2 : 0]                         m_axi_arprot,
    output wire [3 : 0]                         m_axi_arqos,
    output wire [AXI_ARUSER_WIDTH-1 : 0]        m_axi_aruser,
    output wire                                 m_axi_arvalid,
    input wire                                  m_axi_arready,
    input wire [AXI_ID_WIDTH-1 : 0]             m_axi_rid,
    input wire [AXI_DATA_WIDTH-1 : 0]           m_axi_rdata,
    input wire [1 : 0]                          m_axi_rresp,
    input wire                                  m_axi_rlast,
    input wire [AXI_RUSER_WIDTH-1 : 0]          m_axi_ruser,
    input wire                                  m_axi_rvalid,
    output wire                                 m_axi_rready
  );
 // assign m_axi_arid = id;
 // assign m_axi_awid = id;

  /***********************************************************/

  localparam IDLE       = 8'd0;
  localparam START      = 8'd1;
  localparam WAIT       = 8'd2;
  localparam DONE       = 8'd3;
  localparam DONE_CNT   = 8'd4;
  localparam READ_DONE  = 8'd5;  
  /**************************************************/

  reg wr_burst_req_d1,wr_burst_req_d2;
  reg rd_burst_req_d1,rd_burst_req_d2;
  wire wr_req_pos;/*synthesis PAP_MARK_DEBUG="1"*/
  wire rd_req_pos;/*synthesis PAP_MARK_DEBUG="1"*/

  reg [7:0]  wr_state/* synthesis syn_preserve = 1 */;
  reg [7:0]  rd_state/* synthesis syn_preserve = 1 */;

  assign wr_req_pos = (wr_burst_req_d1)& (~wr_burst_req_d2);
  assign rd_req_pos = (rd_burst_req_d1)& (~rd_burst_req_d2);
//


  reg                               Send_START      ;
  reg   [7:0]                       Send_BurstLen   ;
  reg   [27:0]                      Send_Addr       ;
  wire                              Send_DONE       ;

  reg                               Recv_START      ;  
  reg   [7:0]                       Recv_BurstLen   ;
  reg   [27:0]                      Recv_Addr       ;   
  wire                              Recv_DONE       ; 
  
  reg [7:0] cnt;
  // wire                              Recv_fifo_W_en   ;
  // wire   [255:0]                    Recv_fifo_W_data ;
      
  assign wr_burst_finish = (wr_state == DONE)?1'b1:1'b0;
  assign rd_burst_finish = Recv_DONE;
/*
*
*/
  always@(posedge m_axi_aclk)
  begin
    if(!m_axi_aresetn)
    begin
      wr_burst_req_d1    <=  1'b0;
      wr_burst_req_d2    <=  1'b0;
    end
    else
    begin
      wr_burst_req_d1    <=  wr_burst_req;
      wr_burst_req_d2    <=  wr_burst_req_d1;
    end
  end
//
  always@(posedge m_axi_aclk)
  begin
    if(!m_axi_aresetn)
    begin
      rd_burst_req_d1    <=  1'b0;
      rd_burst_req_d2    <=  1'b0;
    end
    else
    begin
      rd_burst_req_d1    <=  rd_burst_req;
      rd_burst_req_d2    <=  rd_burst_req_d1;
    end
  end
/*
*send state
*/
always @(posedge m_axi_aclk)
begin
  if(!m_axi_aresetn)
  begin
    wr_state <= IDLE;
    Send_START    <= 1'b0;
    Send_BurstLen <= 8'd16;
    Send_Addr     <= 28'd0;
    cnt           <= 8'd0;
  end
  else begin
    case(wr_state)
    IDLE:
    begin
      if(wr_req_pos)
      begin
        Send_START    <= 1'b1;
        Send_BurstLen <= wr_burst_len;
        Send_Addr     <= wr_burst_addr;  
        wr_state <= START;
      end
      else begin
        Send_START    <= 1'b0;
        Send_BurstLen <= Send_BurstLen;
        Send_Addr     <= Send_Addr;  
        wr_state <= IDLE;
      end
    end    
    START:
    begin
      if(Send_DONE)
      begin
        Send_START    <= 1'b0;
        Send_BurstLen <= Send_BurstLen;
        Send_Addr     <= Send_Addr;  
        cnt           <= 8'd0;
        wr_state <= DONE_CNT;
      end
      else begin
        Send_START    <= 1'b0;
        Send_BurstLen <= Send_BurstLen;
        Send_Addr     <= Send_Addr;  
        wr_state <= START;
      end
    end
      DONE_CNT:
      begin
        cnt           <= cnt + 8'd1;
        if(cnt >= 8'd16)
          wr_state <= DONE;
        else begin
          wr_state <= DONE_CNT;
        end
      end 
      DONE:
      begin
        Send_START    <= 1'b0;
        Send_BurstLen <= Send_BurstLen;
        Send_Addr     <= Send_Addr;  
        wr_state <= IDLE;
      end 
      
      default:wr_state <= IDLE;
    endcase   
  end
end
/*
* read state
*/
always @(posedge m_axi_aclk)
begin
  if(!m_axi_aresetn)
  begin
    rd_state <= IDLE;
    Recv_START    <= 1'b0;
    Recv_BurstLen <= 8'd16;
    Recv_Addr     <= 28'd0;
  end
  else begin
    case(rd_state)
    IDLE:
    begin
      if(rd_req_pos)
      begin
        Recv_START    <= 1'b1;
        Recv_BurstLen <= rd_burst_len;
        Recv_Addr     <= rd_burst_addr;  
        rd_state <= START;
      end
      else begin
        Recv_START    <= 1'b0;
        Recv_BurstLen <= Recv_BurstLen;
        Recv_Addr     <= Recv_Addr;  
        rd_state <= IDLE;
      end
    end    
    START:
    begin
      if(Recv_DONE)
      begin
        Recv_START    <= 1'b0;
        Recv_BurstLen <= Recv_BurstLen;
        Recv_Addr     <= Recv_Addr;  
        rd_state <= DONE;
      end
      else begin
        Recv_START    <= 1'b0;
        Recv_BurstLen <= Recv_BurstLen;
        Recv_Addr     <= Recv_Addr;  
        rd_state <= START;
      end
    end
      DONE:
      begin
        Recv_START    <= 1'b0;
        Recv_BurstLen <= Recv_BurstLen;
        Recv_Addr     <= Recv_Addr;  
        rd_state <= IDLE;
      end 
      default:rd_state <= IDLE;
    endcase
  end
end
  /**************************************************/
  axi_ddr_ctr_wr inst_axi_ddr_ctr_wr (

    .Send_START      (Send_START        ),
    .Send_BurstLen   (Send_BurstLen     ),
    .Send_Addr       (Send_Addr         ),
    .Send_fifo_R_en  (wr_burst_data_req ),
    .Send_fifo_R_data(wr_burst_data     ),
    .Send_DONE       (Send_DONE         ),
    
    .M_AXI_ACLK   (m_axi_aclk     ),
    .M_AXI_ARESETN(m_axi_aresetn  ),
     .M_AXI_AWID   (m_axi_awid     ),
    .M_AXI_AWADDR (m_axi_awaddr   ),
    .M_AXI_AWLEN  (m_axi_awlen    ),
    .M_AXI_AWSIZE (m_axi_awsize   ),
    .M_AXI_AWBURST(m_axi_awburst  ),
    .M_AXI_AWLOCK (m_axi_awlock   ),
    .M_AXI_AWCACHE(m_axi_awcache  ),
    .M_AXI_AWPROT (m_axi_awprot   ),
    .M_AXI_AWQOS  (m_axi_awqos    ),
    .M_AXI_AWUSER (m_axi_awuser   ),
    .M_AXI_AWVALID(m_axi_awvalid  ),
    .M_AXI_AWREADY(m_axi_awready  ),
    .M_AXI_WDATA  (m_axi_wdata    ),
    .M_AXI_WSTRB  (m_axi_wstrb    ),
    .M_AXI_WLAST  (m_axi_wlast    ),
    .M_AXI_WUSER  (m_axi_wuser    ),
    .M_AXI_WVALID (m_axi_wvalid   ),
    .M_AXI_WREADY (m_axi_wready   ),
    .M_AXI_BID    (m_axi_bid      ),
    .M_AXI_BRESP  (m_axi_bresp    ),
    .M_AXI_BUSER  (m_axi_buser    ),
    .M_AXI_BVALID (m_axi_bvalid   ),
    .M_AXI_BREADY (m_axi_bready   )
  );

  axi_ddr_ctr_rd inst_axi_ddr_ctr_rd (

    .Recv_START      (Recv_START      ),
    .Recv_BurstLen   (Recv_BurstLen   ),
    .Recv_Addr       ( Recv_Addr      ),
    .Recv_fifo_W_en  (rd_burst_data_valid  ),
    .Recv_fifo_W_data(rd_burst_data),
    .Recv_DONE       (Recv_DONE       ),

    // .M_AXI_START  (start_read),
    // .M_AXI_DONE   (axi_rd_done    ),
    // .M_AXI_ERROR  (               ),
    
    .M_AXI_ACLK   (m_axi_aclk     ),
    .M_AXI_ARESETN(m_axi_aresetn  ),

    .M_AXI_ARID    (m_axi_arid    ),
    .M_AXI_ARADDR  (m_axi_araddr  ),
    .M_AXI_ARLEN   (m_axi_arlen   ),
    .M_AXI_ARSIZE  (m_axi_arsize  ),	
    .M_AXI_ARBURST (m_axi_arburst ),
    .M_AXI_ARLOCK  (m_axi_arlock  ),	
    .M_AXI_ARCACHE (m_axi_arcache ),
    .M_AXI_ARPROT  (m_axi_arprot  ),	
    .M_AXI_ARQOS   (m_axi_arqos   ),
    .M_AXI_ARUSER  (m_axi_aruser  ),
    .M_AXI_ARVALID (m_axi_arvalid ),
    .M_AXI_ARREADY (m_axi_arready ),
    .M_AXI_RID     (m_axi_rid     ),
    .M_AXI_RDATA   (m_axi_rdata   ),
    .M_AXI_RRESP   (m_axi_rresp   ),
    .M_AXI_RLAST   (m_axi_rlast   ),
    .M_AXI_RUSER   (m_axi_ruser   ),
    .M_AXI_RVALID  (m_axi_rvalid  ),
    .M_AXI_RREADY  (m_axi_rready  )
  );
  /******************************************/
endmodule

