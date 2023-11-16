
`timescale 1 ns / 1 ps

module axi_ddr_ctr_rd 
#(
  `include"F:/Project/WorkSpace/FPGA/Video_pro/Source/top/global.vh"
 )
  (
    // Users to add ports here
  input wire                                Recv_START    ,
  input wire    [7:0]                       Recv_BurstLen ,
  input wire    [    AXI_ADDR_WIDTH-1 : 0]  Recv_Addr     ,
  output wire                               Recv_fifo_W_en  ,
  input wire  [AXI_DATA_WIDTH-1 : 0]        Recv_fifo_W_data,

  output wire                               Recv_DONE     ,
    // User ports ends
    input wire                                M_AXI_ACLK    ,
    input wire                                M_AXI_ARESETN ,

    output wire [    AXI_ID_WIDTH-1 : 0]      M_AXI_ARID    ,
		output wire [    AXI_ADDR_WIDTH-1 : 0]    M_AXI_ARADDR  ,
		output wire [7 : 0]                       M_AXI_ARLEN   ,
		output wire [2 : 0]                       M_AXI_ARSIZE  ,		   
		output wire [1 : 0]                       M_AXI_ARBURST ,
		output wire                               M_AXI_ARLOCK  ,	
		output wire [3 : 0]                       M_AXI_ARCACHE ,
		output wire [2 : 0]                       M_AXI_ARPROT  ,	
		output wire [3 : 0]                       M_AXI_ARQOS   ,
		output wire [    AXI_ARUSER_WIDTH-1 : 0]  M_AXI_ARUSER  ,
		output wire                               M_AXI_ARVALID ,
		input wire                                M_AXI_ARREADY ,
		input wire [    AXI_ID_WIDTH-1 : 0]       M_AXI_RID     ,
		input wire [    AXI_DATA_WIDTH-1 : 0]     M_AXI_RDATA   ,
		input wire [1 : 0]                        M_AXI_RRESP   ,
		input wire                                M_AXI_RLAST   ,
		input wire [    AXI_RUSER_WIDTH-1 : 0]    M_AXI_RUSER   ,
		input wire                                M_AXI_RVALID  ,
		output wire                               M_AXI_RREADY

  );

  function integer clogb2 (input integer bit_depth);
    begin
      for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
        bit_depth = bit_depth >> 1;
    end
  endfunction

  localparam integer C_TRANSACTIONS_NUM = clogb2(AXI_BURST_LEN-1);
  // AXI4LITE signals
  //AXI4 internal temp signals
  reg  [    AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	                            axi_arvalid;
	reg  	                            axi_rready;

  reg  [C_TRANSACTIONS_NUM : 0] 	  read_index;
  wire [C_TRANSACTIONS_NUM+2 : 0] 	burst_size_bytes;
  wire  	                          rnext;

  // wire  rnext;
  reg  	m_axi_start_ff;
  reg  	m_axi_start_ff2;
  wire  axi_start_edge;

	// I/O Connections assignments
	assign M_AXI_ARID	  = 'b0;
	assign M_AXI_ARADDR	= Recv_Addr;//AXI_TARGET_SLAVE_BASE_ADDR + axi_araddr;//Recv_Addr;//
	assign M_AXI_ARLEN	= Recv_BurstLen - 1;
	assign M_AXI_ARSIZE	= 3'b011;//clogb2((AXI_DATA_WIDTH/8)-1);//
	assign M_AXI_ARBURST= 2'b01;
	assign M_AXI_ARLOCK	= 1'b0;
	assign M_AXI_ARCACHE= 4'b0010;
	assign M_AXI_ARPROT	= 3'h0;
	assign M_AXI_ARQOS	= 4'h0;
	assign M_AXI_ARUSER	= 'b1;
	assign M_AXI_ARVALID= axi_arvalid;
	assign M_AXI_RREADY	= M_AXI_RVALID;//axi_rready;//

  // assign M_AXI_ERROR  = write_resp_error;
  assign M_AXI_DONE   = M_AXI_RVALID;
  assign Recv_fifo_W_en = M_AXI_RVALID & M_AXI_RREADY;
  assign Recv_fifo_W_data = M_AXI_RDATA;
  assign Recv_DONE = M_AXI_RLAST;

  //assign burst_size_bytes	= Recv_BurstLen * AXI_DATA_WIDTH/8;
  assign axi_start_edge	= (!m_axi_start_ff2) && m_axi_start_ff;
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
      m_axi_start_ff <= Recv_START;
      m_axi_start_ff2 <= m_axi_start_ff;
    end
  end
	//----------------------------
	//Read Address Channel
	//---------------------------- 
  always @(posedge M_AXI_ACLK)                                 
  begin                                                              
                                                                     
    if (M_AXI_ARESETN == 0)                                         
      begin                                                          
        axi_arvalid <= 1'b0;                                         
      end                                                            
    // If previously not valid , start next transaction              
    else if (~axi_arvalid && axi_start_edge)                
      begin                                                          
        axi_arvalid <= 1'b1;                                         
      end                                                            
    else if (M_AXI_ARREADY && axi_arvalid)                           
      begin                                                          
        axi_arvalid <= 1'b0;                                         
      end                                                            
    else                                                             
      axi_arvalid <= axi_arvalid;                                    
  end   
	// Next address after ARREADY indicates previous address acceptance  
  always @(posedge M_AXI_ACLK)                                       
  begin                                                              
    if (M_AXI_ARESETN == 0)                                          
      begin                                                          
        axi_araddr <= 'b0;                                           
      end                                                            
    else if (M_AXI_ARREADY && axi_arvalid)                           
      begin                                                          
        // axi_araddr <= axi_araddr + burst_size_bytes;    
        axi_araddr <= axi_araddr + 8;             
      end                                                            
    else                                                             
      axi_araddr <= axi_araddr;                                      
  end 
	//--------------------------------
	//Read Data (and Response) Channel
	//--------------------------------
  
  assign rnext = M_AXI_RVALID && axi_rready;                               
  always @(posedge M_AXI_ACLK)                                          
  begin                                                                 
    if (M_AXI_ARESETN == 0 || axi_start_edge)                  
      begin                                                             
        read_index <= 0;                                                
      end                                                               
    else if (rnext && (read_index != Recv_BurstLen-1))              
      begin                                                             
        read_index <= read_index + 1;                                   
      end                                                               
    else                                                                
      read_index <= read_index;                                         
  end 

  always @(posedge M_AXI_ACLK)                                          
  begin                                                                 
    if (M_AXI_ARESETN == 0 || axi_start_edge == 1'b1 )                  
      begin                                                             
        axi_rready <= 1'b0;                                             
      end                                                                                       
    else if (M_AXI_RVALID)                       
      begin                                      
         if (M_AXI_RLAST && axi_rready)          
          begin                                  
            axi_rready <= 1'b0;                  
          end                                    
         else                                    
           begin                                 
             axi_rready <= 1'b1;                 
           end                                   
      end                                                    
  end           
  // Add user logic here

  // User logic ends

endmodule
