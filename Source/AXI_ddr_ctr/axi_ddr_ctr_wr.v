
`timescale 1 ns / 1 ps

module axi_ddr_ctr_wr
#(
  `include"F:/Project/WorkSpace/FPGA/Video_pro/Source/top/global.vh"
 )
  //%1
  (
    // Users to add ports here
    input wire                                Send_START    ,
    input wire    [7:0]                       Send_BurstLen ,
    input wire [AXI_ADDR_WIDTH-1 : 0]         Send_Addr     ,
    output wire                               Send_fifo_R_en  ,
    input wire  [AXI_DATA_WIDTH-1 : 0]        Send_fifo_R_data,

    output wire                               Send_DONE    ,

    // input wire                                M_AXI_START   ,
    // output wire                               M_AXI_DONE    ,



    // output wire                               M_AXI_ERROR   ,
    // User ports ends
    input wire                                M_AXI_ACLK    ,
    input wire                                M_AXI_ARESETN ,
    // Master Interface Write Address ID
    output wire [AXI_ID_WIDTH-1 : 0]          M_AXI_AWID    ,
    output wire [AXI_ADDR_WIDTH-1 : 0]        M_AXI_AWADDR  ,
    output wire [7 : 0]                       M_AXI_AWLEN   ,
    output wire [2 : 0]                       M_AXI_AWSIZE  ,
    output wire [1 : 0]                       M_AXI_AWBURST ,
    output wire                               M_AXI_AWLOCK  ,
    output wire [3 : 0]                       M_AXI_AWCACHE ,
    output wire [2 : 0]                       M_AXI_AWPROT  ,
    output wire [3 : 0]                       M_AXI_AWQOS   ,
    output wire [AXI_AWUSER_WIDTH-1 : 0]      M_AXI_AWUSER  ,
    output wire                               M_AXI_AWVALID ,
    input wire                                M_AXI_AWREADY ,
    output wire [AXI_DATA_WIDTH-1 : 0]        M_AXI_WDATA   ,
    output wire [AXI_DATA_WIDTH/8-1 : 0]      M_AXI_WSTRB   ,
    output wire                               M_AXI_WLAST   ,
    output wire [AXI_WUSER_WIDTH-1 : 0]       M_AXI_WUSER   ,
    output wire                               M_AXI_WVALID  ,
    input wire                                M_AXI_WREADY  ,
    input wire [AXI_ID_WIDTH-1 : 0]           M_AXI_BID     ,
    input wire [1 : 0]                        M_AXI_BRESP   ,
    input wire [AXI_BUSER_WIDTH-1 : 0]        M_AXI_BUSER   ,
    input wire                                M_AXI_BVALID  ,
    output wire                               M_AXI_BREADY

  );
  //%2

  function integer clogb2 (input integer bit_depth);
    begin
      for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
        bit_depth = bit_depth >> 1;
    end
  endfunction

  localparam integer C_TRANSACTIONS_NUM = clogb2(AXI_BURST_LEN-1) + 4;
  // AXI4LITE signals
  //AXI4 internal temp signals
  reg [AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
  reg  	axi_awvalid;
  reg [AXI_DATA_WIDTH-1 : 0] 	axi_wdata;
  reg  	axi_wlast;
  reg  	axi_wvalid;
  reg  	axi_bready;
  //
  reg [C_TRANSACTIONS_NUM : 0] 	write_index;
  reg [C_TRANSACTIONS_NUM : 0] 	read_index;
  wire [C_TRANSACTIONS_NUM+2 : 0] 	burst_size_bytes;
  // reg [C_NO_BURSTS_REQ : 0] 	write_burst_counter;
  // reg [C_NO_BURSTS_REQ : 0] 	read_burst_counter;
  reg  	start_single_burst_write;
  reg  	start_single_burst_read;
  reg  	writes_done;
  reg  	reads_done;
  reg  	error_reg;
  reg  	compare_done;
  reg  	read_mismatch;
  reg  	burst_write_active;
  reg  	burst_read_active;
  reg [AXI_DATA_WIDTH-1 : 0] 	expected_rdata;
  //Interface response error flags
  wire  	write_resp_error;
  wire  	read_resp_error;
  wire  	wnext;
  wire  	rnext;
  reg  	m_axi_start_ff;
  reg  	m_axi_start_ff2;
  wire  axi_start_edge;

  reg   last_d1,last_d2;
  wire  m_axi_done;

  assign Send_fifo_R_en = axi_start_edge | (wnext&(~axi_wlast));
  assign Send_DONE = axi_wlast;
  //I/O Connections. Write Address (AW)
  assign M_AXI_AWID	= 'b0;
  assign M_AXI_AWADDR	= Send_Addr;
  assign M_AXI_AWLEN	= Send_BurstLen - 1;
  assign M_AXI_AWSIZE	= 3'b011;//clogb2((AXI_DATA_WIDTH/8)-1);//
  assign M_AXI_AWBURST	= 2'b01;
  assign M_AXI_AWLOCK	= 1'b0;
  assign M_AXI_AWCACHE	= 4'b0010;
  assign M_AXI_AWPROT	= 3'h0;
  assign M_AXI_AWQOS	= 4'h0;
  assign M_AXI_AWUSER	= 'b1;
  assign M_AXI_AWVALID	= axi_awvalid;
  assign M_AXI_WDATA	= Send_fifo_R_data;//axi_wdata;
  assign M_AXI_WSTRB	= {(AXI_DATA_WIDTH/8){1'b1}};
  assign M_AXI_WLAST	= axi_wlast;
  assign M_AXI_WUSER	= 'b1;
  assign M_AXI_WVALID	= M_AXI_WREADY;//axi_wvalid;
  assign M_AXI_BREADY	= axi_bready;

  assign M_AXI_ERROR  = write_resp_error;
  assign M_AXI_DONE   = m_axi_done;
  //Burst size in bytes
  assign burst_size_bytes	= AXI_BURST_LEN * AXI_DATA_WIDTH/8;
  assign axi_start_edge	= (!m_axi_start_ff2) && m_axi_start_ff;
  /*
  *
  */
  //Generate a pulse to initiate AXI transaction.
  always @(posedge M_AXI_ACLK)
  begin
    // Initiates AXI transaction delay
    if (M_AXI_ARESETN == 0 )
    begin
      m_axi_start_ff <= 1'b0;
      m_axi_start_ff2 <= 1'b0;
    end
    else
    begin
      m_axi_start_ff <= Send_START;
      m_axi_start_ff2 <= m_axi_start_ff;
    end
  end

    //Generate a pulse to stand for AXI transaction stop.
  // reg [7:0] cnt;
     assign m_axi_done =M_AXI_WREADY;
  // assign m_axi_done = (~last_d1) & last_d2;//下降沿
  // always @(posedge M_AXI_ACLK)
  // begin
  //   // Initiates AXI transaction delay
  //   if (M_AXI_ARESETN == 0)
  //   begin
  //     last_d1 <= 1'b0;
  //     last_d2 <= 1'b0;
  //   end
  //   else
  //   begin
  //       last_d1 <= axi_wlast;
  //       last_d2 <= last_d1;
  //   end
  // end

  //--------------------
  //Write Address Channel
  //--------------------
  //axi_awvalid
  always @(posedge M_AXI_ACLK)
  begin
    if (M_AXI_ARESETN == 0)
    begin
      axi_awvalid <= 1'b0;
    end
    else if (~axi_awvalid && axi_start_edge)
    begin
      axi_awvalid <= 1'b1;
    end
    else if (M_AXI_AWREADY && axi_awvalid)
    begin
      axi_awvalid <= 1'b0;
    end
    else
      axi_awvalid <= axi_awvalid;
  end
  //axi_awaddr
  always @(posedge M_AXI_ACLK)
  begin
    if (M_AXI_ARESETN == 0)
    begin
      axi_awaddr <= 'b0;
    end
    else if (M_AXI_AWREADY && axi_awvalid)
    begin
      axi_awaddr <= axi_awaddr + 8;
    end
    else
      axi_awaddr <= axi_awaddr;
  end
  //--------------------
  //Write Data Channel
  //--------------------
  assign wnext = M_AXI_WREADY & axi_wvalid;
  always @(posedge M_AXI_ACLK)
  begin
    if (M_AXI_ARESETN == 0)
    begin
      axi_wvalid <= 1'b0;
    end
    else if (~axi_wvalid && axi_start_edge)
    begin
      axi_wvalid <= 1'b1;
    end
    else if (wnext && axi_wlast)
      axi_wvalid <= 1'b0;
    else
      axi_wvalid <= axi_wvalid;
  end
  //wlast
  always @(posedge M_AXI_ACLK)                                                      
  begin                                                                             
    if (M_AXI_ARESETN == 0)                                                        
      begin                                                                         
        axi_wlast <= 1'b0;                                                          
      end                                                                           
    else if (((write_index == Send_BurstLen-2 && Send_BurstLen >= 2) && wnext) || (Send_BurstLen == 1 ))
      begin                                                                         
        axi_wlast <= 1'b1;                                                          
      end                                                                                                        
    else if (wnext)                                                                 
      axi_wlast <= 1'b0;                                                            
    else if (axi_wlast && Send_BurstLen == 1)                                   
      axi_wlast <= 1'b0;                                                            
    else                                                                            
      axi_wlast <= axi_wlast;                                                       
  end  
	/* Burst length counter. Uses extra counter register bit to indicate terminal       
	 count to reduce decode logic */                                                    
   always @(posedge M_AXI_ACLK)                                                      
   begin                                                                             
     if (M_AXI_ARESETN == 0 || axi_start_edge == 1'b1)    
       begin                                                                         
         write_index <= 0;                                                           
       end                                                                           
     else if (wnext && (write_index != Send_BurstLen-1))                         
       begin                                                                         
         write_index <= write_index + 1;                                             
       end                                                                           
     else                                                                            
       write_index <= write_index;                                                   
   end  
	/* Write Data Generator                                                             
	 Data pattern is only a simple incrementing count from 0 for each burst  */         
	  always @(posedge M_AXI_ACLK)                                                      
	  begin                                                                             
	    if (M_AXI_ARESETN == 0 || axi_start_edge == 1'b1)                                                         
	      axi_wdata <= axi_awaddr;                                                                                                                     
	    // else if (wnext)                                                                 
	    //   axi_wdata <= axi_wdata + 1;                                                   
	    else                                                                            
	      axi_wdata <= Send_fifo_R_data;                                                       
	    end
	//----------------------------
	//Write Response (B) Channel
	//----------------------------
      always @(posedge M_AXI_ACLK)                                     
      begin                                                                 
        if (M_AXI_ARESETN == 0 || axi_start_edge == 1'b1 )                                            
          begin                                                             
            axi_bready <= 1'b0;                                             
          end                                                                                    
        else if (M_AXI_BVALID && ~axi_bready)                               
          begin                                                             
            axi_bready <= 1'b1;                                             
          end                                                                                           
        else if (axi_bready)                                                
          begin                                                             
            axi_bready <= 1'b0;                                             
          end                                                                                                   
        else                                                                
          axi_bready <= axi_bready;                                         
      end         
	//Flag any write response errors                                        
      assign write_resp_error = axi_bready & M_AXI_BVALID & M_AXI_BRESP[1]; 
      
      
  // Add user logic here

  // User logic ends

endmodule
