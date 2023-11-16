//**********************************************
module Frame_orderGen
#(
  `include"F:/Project/WorkSpace/FPGA/Video_pro/Source/top/global.vh"
 )
(

    input wire                          axi_aclk        ,
    input wire                          axi_aresetn     ,
    //图像1输入         
    input wire                          Img1_pclk       ,
    input wire                          Img1_vs         ,
    //图像2输入         
    input wire                          Img2_pclk       ,
    input wire                          Img2_vs         ,
    //图像3输入         
    input wire                          Img3_pclk       ,
    input wire                          Img3_vs         ,
    //图像4输入         
    input wire                          Img4_pclk       ,
    input wire                          Img4_vs         ,
    //
    output wire                         write_index /* synthesis PAP_MARK_DEBUG="1" */    ,
    output wire [3:0]                   write_req  /* synthesis PAP_MARK_DEBUG="1" */     ,
    input wire  [3:0]                   write_done/* synthesis PAP_MARK_DEBUG="1" */      ,

    output wire [27:0]                  write_start_addr1,
    output wire [27:0]                  write_start_addr2,
    output wire [27:0]                  write_start_addr3,
    output wire [27:0]                  write_start_addr4
    
    // input wire  [3:0]                   write_ack       ,
    // write_done即write_req与image对应关系::3:0:1,2,3,4
);

// parameter Base_addr1_1 = 28'h000_0000;
// parameter Base_addr1_2 = 28'h000_0280;
// parameter Base_addr1_3 = 28'h003_8400;
// parameter Base_addr1_4 = 28'h003_8680;

// parameter Base_addr2_1 = 28'h010_0000;
// parameter Base_addr2_2 = 28'h010_0280;
// parameter Base_addr2_3 = 28'h013_8400;
// parameter Base_addr2_4 = 28'h013_8680;

//320*40
// parameter Base_addr1_1 = 28'h000_0000;
// parameter Base_addr1_2 = 28'h000_0050;
// parameter Base_addr1_3 = 28'h000_0C80;
// parameter Base_addr1_4 = 28'h000_0CD0;

// parameter Base_addr2_1 = 28'h001_0000;
// parameter Base_addr2_2 = 28'h001_0050;
// parameter Base_addr2_3 = 28'h001_0C80;
// parameter Base_addr2_4 = 28'h001_0CD0;


localparam IDLE = 8'd0;

reg [3:0] state/* synthesis PAP_MARK_DEBUG="1" */;
reg write_index_r;
reg write_index_r_d1,write_index_r_d2;
reg   write_req1_r;
reg   write_req2_r;
reg   write_req3_r;
reg   write_req4_r;


reg Img1_vs_d1,Img1_vs_d2;
reg Img2_vs_d1,Img2_vs_d2;
reg Img3_vs_d1,Img3_vs_d2;
reg Img4_vs_d1,Img4_vs_d2;

wire Img1_vs_pos/* synthesis syn_keep=1 */;
wire Img2_vs_pos/* synthesis syn_keep=1 */;
wire Img3_vs_pos/* synthesis syn_keep=1 */;
wire Img4_vs_pos/* synthesis syn_keep=1 */;

wire write_index_pos;
wire write_index_neg;

assign Img1_vs_pos = (~Img1_vs_d2) & (Img1_vs_d1);
assign Img2_vs_pos = (~Img2_vs_d2) & (Img2_vs_d1);
assign Img3_vs_pos = (~Img3_vs_d2) & (Img3_vs_d1);
assign Img4_vs_pos = (~Img4_vs_d2) & (Img4_vs_d1);

assign write_index_pos = (~write_index_r_d2) & (write_index_r_d1);
assign write_index_neg = (write_index_r_d2) & (~write_index_r_d1);

assign write_req = {write_req1_r,write_req2_r,write_req3_r,write_req4_r};
assign write_index = write_index_r;

assign write_start_addr1 = write_index?Base_addr2_1:Base_addr1_1;
assign write_start_addr2 = write_index?Base_addr2_2:Base_addr1_2;
assign write_start_addr3 = write_index?Base_addr2_3:Base_addr1_3;
assign write_start_addr4 = write_index?Base_addr2_4:Base_addr1_4;
//输入信号打拍,同步到axi_aclk时钟域下
always@(posedge axi_aclk)
begin
	if(!axi_aresetn)
	begin
		Img1_vs_d1    <=  1'b0;
    Img2_vs_d1    <=  1'b0;
    Img3_vs_d1    <=  1'b0;
    Img4_vs_d1    <=  1'b0;

		Img1_vs_d2    <=  1'b0;
    Img2_vs_d2    <=  1'b0;
    Img3_vs_d2    <=  1'b0;
    Img4_vs_d2    <=  1'b0;

    write_index_r_d1 <= 1'b0;
    write_index_r_d1 <= 1'b0;
	end
	else
	begin
		Img1_vs_d1    <=  Img1_vs;
    Img2_vs_d1    <=  Img2_vs;
    Img3_vs_d1    <=  Img3_vs;
    Img4_vs_d1    <=  Img4_vs;

    Img1_vs_d2    <=  Img1_vs_d1;
    Img2_vs_d2    <=  Img2_vs_d1;
    Img3_vs_d2    <=  Img3_vs_d1;
    Img4_vs_d2    <=  Img4_vs_d1;

    write_index_r_d1 <= write_index_r;
    write_index_r_d2 <= write_index_r_d1;
	end 
end

always@(posedge axi_aclk)
begin
	if(!axi_aresetn)
	begin
    state <= 4'b0000;
  end
  else begin
    if(state == 4'b1111)///write_index_pos | write_index_neg)
      state <= 4'b0000;
    else
      state  <= state | write_done;
  end
end

always@(posedge axi_aclk)
begin
	if(!axi_aresetn)
	begin
    write_req1_r <= 1'b0;
  end
  else begin
    if(Img1_vs_pos & (~state[3]))
      write_req1_r <= 1'b1;
    else if(write_done[3])
      write_req1_r <= 1'b0;
    else
      write_req1_r <= write_req1_r;
  end
end

always@(posedge axi_aclk)
begin
	if(!axi_aresetn)
	begin
    write_req2_r <= 1'b0;
  end
  else begin
    if(Img2_vs_pos & (~state[2]))
      write_req2_r <= 1'b1;
    else if(write_done[2])
      write_req2_r <= 1'b0;
    else
      write_req2_r <= write_req2_r;
  end
end

always@(posedge axi_aclk)
begin
	if(!axi_aresetn)
	begin
    write_req3_r <= 1'b0;
  end
  else begin
    if(Img3_vs_pos & (~state[1]))
      write_req3_r <= 1'b1;
    else if(write_done[1])
      write_req3_r <= 1'b0;
    else
      write_req3_r <= write_req3_r;
  end
end


always@(posedge axi_aclk)
begin
	if(!axi_aresetn)
	begin
    write_req4_r <= 1'b0;
  end
  else begin
    if(Img4_vs_pos & (~state[0]))
      write_req4_r <= 1'b1;
    else if(write_done[0])
      write_req4_r <= 1'b0;
    else
      write_req4_r <= write_req4_r;
  end
end

always@(posedge axi_aclk)
begin
	if(!axi_aresetn)
	begin
    write_index_r <= 1'b0;
  end
  else begin
    if(state == 4'b1111)
      write_index_r <= ~write_index_r;
    else 
      write_index_r <= write_index_r;
  end
end


endmodule