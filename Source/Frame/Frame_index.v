//**********************************************
module Frame_index
  #(
`include"F:/Project/WorkSpace/FPGA/Video_pro/Source/top/global.vh"
   )
   (

     input                               axi_aclk       ,
     input                               axi_aresetn    ,

     input wire                          cmos1_clk    ,
     input wire                          cmos1_vs     ,
     output wire                         cmos1_vs_o   ,
     //  input wire                          wr_done_cmos1,

     input wire                          cmos2_clk    ,
     input wire                          cmos2_vs     ,
     output wire                         cmos2_vs_o   ,

     input wire                          hdmi_in_clk    ,
     input wire                          hdmi_in_vs     ,
     output wire                         hdmi_in_vs_o   ,


     input wire                          udp_in_clk    ,
     input wire                          udp_in_vs     ,
     output wire                         udp_in_vs_o   ,
     //  input wire                          wr_done_cmos2,



     output wire  [27:0]                 write_BaseDdr_addr1 ,
     output wire  [27:0]                 write_BaseDdr_addr2 ,
     output wire  [27:0]                 write_BaseDdr_addr3 ,
     output wire  [27:0]                 write_BaseDdr_addr4 ,

     output wire  [27:0]                 read_BaseDdr_addr
     // input wire  [3:0]                   write_ack       ,
     // write_done即write_req与image对应关系::3:0:1,2,3,4
   );
  /*****************************************/
  //
  reg index;

  reg  [1:0] index1;
  reg  [1:0] index2;
  reg  [1:0] index3;
  reg  [1:0] index4;


  reg cmos1_vs_o_d1,cmos1_vs_o_d2,cmos1_vs_o_d3,cmos1_vs_o_d4;
  reg cmos2_vs_o_d1,cmos2_vs_o_d2,cmos2_vs_o_d3,cmos2_vs_o_d4;
  // reg wr_Img_vs_d1,wr_Img_vs_d2;
  // wire wr_Img_vs_pos;

  reg cmos1_vs_d1,cmos1_vs_d2;
  reg cmos2_vs_d1,cmos2_vs_d2;
  reg hdmi_in_vs_d1,hdmi_in_vs_d2;
  reg udp_in_vs_d1,udp_in_vs_d2;
  //
  // reg flag;

  wire cmos1_vs_pos;
  wire cmos2_vs_pos;
  wire hdmi_in_vs_pos;
  wire udp_in_vs_pos;
  //
  reg [3:0] state;
  reg [3:0] key;
  /*****************************************/
  assign cmos1_vs_o = cmos1_vs;
  assign cmos2_vs_o = cmos2_vs;
  assign hdmi_in_vs_o = hdmi_in_vs;
  assign udp_in_vs_o = udp_in_vs;
  // assign cmos1_vs_o = cmos1_vs_o_d1 | cmos1_vs_o_d2 | cmos1_vs_o_d3 | cmos1_vs_o_d4;
  // assign cmos2_vs_o = cmos2_vs_o_d1 | cmos2_vs_o_d2 | cmos2_vs_o_d3 | cmos2_vs_o_d4;
  //
  assign cmos1_vs_pos = (cmos1_vs_d1 & ~cmos1_vs_d2);
  assign cmos2_vs_pos = (cmos2_vs_d1 & ~cmos2_vs_d2);
  assign hdmi_in_vs_pos = (hdmi_in_vs_d1 & ~hdmi_in_vs_d2);
  assign udp_in_vs_pos = (udp_in_vs_d1 & ~udp_in_vs_d2);
  // assign wr_Img_vs_pos = (wr_Img_vs_d1 & ~wr_Img_vs_d2);

  assign write_BaseDdr_addr1 = (index1 == 2'b00)?Base_addr1_1:
         (index1 == 2'b01)?Base_addr2_1:
         (index1 == 2'b10)?Base_addr3_1:Base_addr4_1;

  assign write_BaseDdr_addr2 = (index2 == 2'b00)?Base_addr1_2:
         (index2 == 2'b01)?Base_addr2_2:
         (index2 == 2'b10)?Base_addr3_2:Base_addr4_2;

  assign write_BaseDdr_addr3 = (index3 == 2'b00)?Base_addr1_3:
         (index3 == 2'b01)?Base_addr2_3:
         (index3 == 2'b10)?Base_addr3_3:Base_addr4_3;

  assign write_BaseDdr_addr4 = (index4 == 2'b00)?Base_addr1_4:
         (index4 == 2'b01)?Base_addr2_4:
         (index4 == 2'b10)?Base_addr3_4:Base_addr4_4;

  // assign write_BaseDdr_addr2 = index?Base_addr1_2:Base_addr2_2;
  // assign write_BaseDdr_addr3 = index?Base_addr1_3:Base_addr2_3;
  // assign write_BaseDdr_addr4 = index?Base_addr1_4:Base_addr2_4;

  // assign read_BaseDdr_addr  = index?Base_addr2_1:Base_addr1_1;
  assign read_BaseDdr_addr = (index4 == 2'b00)?Base_addr3_1:
         (index4 == 2'b01)?Base_addr4_1:
         (index4 == 2'b10)?Base_addr1_1:Base_addr2_1;

  /*****************************************/
  //
  always @(posedge axi_aclk)
  begin
    if(!axi_aresetn)
    begin
      cmos1_vs_d1 <= 1'b0;
      cmos1_vs_d2 <= 1'b0;

      cmos2_vs_d1 <= 1'b0;
      cmos2_vs_d2 <= 1'b0;

      hdmi_in_vs_d1 <= 1'b0;
      hdmi_in_vs_d2 <= 1'b0;

      udp_in_vs_d1 <= 1'b0;
      udp_in_vs_d2 <= 1'b0;

    end
    else
    begin
      cmos1_vs_d1 <= cmos1_vs;
      cmos1_vs_d2 <= cmos1_vs_d1;

      cmos2_vs_d1 <= cmos2_vs;
      cmos2_vs_d2 <= cmos2_vs_d1;

      hdmi_in_vs_d1 <= hdmi_in_vs;
      hdmi_in_vs_d2 <= hdmi_in_vs_d1;

      udp_in_vs_d1 <= udp_in_vs;
      udp_in_vs_d2 <= udp_in_vs_d1;

    end
  end

  // always @(posedge axi_aclk)
  // begin
  //   if(!axi_aresetn)
  //   begin
  //     state <= 4'b0000;
  //     key   <= 4'b0000;
  //     cmos1_vs_o_d1 <= 1'b0;
  //     cmos2_vs_o_d1 <= 1'b0;
  //   end
  //   else
  //   begin
  //     if((~state[0]) & cmos1_vs_pos )
  //     begin
  //       state[0] <= 1'b1;
  //       cmos1_vs_o_d1 <= 1'b1;
  //     end
  //     else if(key == 4'b0011)
  //     begin
  //       state[0] <= 1'b0;
  //     end
  //     else
  //     begin
  //       state[0] <= state[0];
  //       cmos1_vs_o_d1 <= 1'b0;
  //     end
  //     //
  //     if((~state[1]) & cmos2_vs_pos )
  //     begin
  //       state[1] <= 1'b1;
  //       cmos2_vs_o_d1 <= 1'b1;
  //     end
  //     else if(key == 4'b0011)
  //     begin
  //       state[1] <= 1'b0;
  //     end
  //     else
  //     begin
  //       state[1] <= state[0];
  //       cmos2_vs_o_d1 <= 1'b0;
  //     end
  //     //

  //     if(wr_done_cmos1 & (state[0]))
  //     begin
  //       key[0] <= 1'b1;
  //     end
  //     else if(key == 4'b0011)
  //     begin
  //       key[0] <= 1'b0;
  //     end
  //     else
  //     begin
  //       key[0] <= key[0];
  //     end

  //     if(wr_done_cmos2 & (state[1]))
  //     begin
  //       key[1] <= 1'b1;
  //     end
  //     else if(key == 4'b0011)
  //     begin
  //       key[1] <= 1'b0;
  //     end
  //     else
  //     begin
  //       key[1] <= key[1];
  //     end
  //   end
  // end

  always @(posedge axi_aclk)
  begin
    if(!axi_aresetn)
    begin
      index1 <= 2'd0;
    end
    else
    begin
      if(cmos1_vs_pos)
        index1 <= index1 + 1;
      else
      begin
        index1 <= index1;
      end
    end
  end

  always @(posedge axi_aclk)
  begin
    if(!axi_aresetn)
    begin
      index2 <= 2'd0;
    end
    else
    begin
      if(cmos2_vs_pos)
        index2 <= index2 + 1;
      else
      begin
        index2 <= index2;
      end
    end
  end

  always @(posedge axi_aclk)
  begin
    if(!axi_aresetn)
    begin
      index3 <= 2'd0;
    end
    else
    begin
      if(hdmi_in_vs_pos)
        index3 <= index3 + 1;
      else
      begin
        index3 <= index3;
      end
    end
  end


  always @(posedge axi_aclk)
  begin
    if(!axi_aresetn)
    begin
      index4 <= 2'd0;
    end
    else
    begin
      if(udp_in_vs_pos)
        index4 <= index4 + 1;
      else
      begin
        index4 <= index4;
      end
    end
  end

endmodule
