module brightness_contrast(

    input                                axi_clk               ,
    input                                rst_n                 ,
    input     [7:0]                      mode/*synthesis PAP_MARK_DEBUG="1"*/                  ,

    output wire           vout_clk      ,
    output wire           vout_vs       ,
    output wire           vout_hs       ,
    output wire           vout_de       ,
    output wire  [15:0]   vout_data     ,


    input   wire          img_720_clk_i ,
    input   wire          img_720_vs_i  ,
    input   wire          img_720_hs_i  ,
    input   wire          img_720_de_i  ,
    input   wire  [15:0]  img_720_data_i
  );

  //reg define
  reg signed [11:0] brightness;
  reg signed [11:0] contrast;

  reg mode4_d1,mode4_d2;
  reg mode5_d1,mode5_d2;
  reg mode6_d1,mode6_d2;
  reg mode7_d1,mode7_d2;

  wire plus10_pos;
  wire minus10_pos;
  wire plus100_pos;
  wire minus100_pos;


  
  assign plus10_pos = mode4_d1 & (~mode4_d2);
  assign minus10_pos = mode5_d1 & (~mode5_d2);
  assign plus100_pos = mode6_d1 & (~mode6_d2);
  assign minus100_pos = mode7_d1 & (~mode7_d2);
  //wire define

  always @(posedge axi_clk)
  begin
    if(!rst_n)
    begin
      brightness <= 12'd0;
      contrast <= 12'd1;
    end
    else
    begin
      if(mode[3])
      begin
        if(plus10_pos)
          brightness <= brightness + 12'd10;
        else if(minus10_pos)
          brightness <= brightness - 12'd10;
        else if(plus100_pos)
          brightness <= brightness + 12'd50;
        else if(plus100_pos)
          brightness <= brightness - 12'd50;
        else
        begin
          brightness <= brightness;
        end
      end
      else
      begin
        if(plus10_pos)
          contrast <= contrast + 12'd10;
        else if(minus10_pos)
          contrast <= contrast - 12'd10;
        else if(plus100_pos)
          contrast <= contrast + 12'd50;
        else if(plus100_pos)
          contrast <= contrast - 12'd50;
        else
        begin
          contrast <= contrast;
        end
      end

    end
  end

  always@(posedge axi_clk)
  begin
    mode4_d1 <= mode[4];
    mode4_d2 <= mode4_d1;
    mode5_d1 <= mode[5];
    mode5_d2 <= mode5_d1;
    mode6_d1 <= mode[6];
    mode6_d2 <= mode6_d1;
    mode7_d1 <= mode[7];
    mode7_d2 <= mode7_d1;
  end







  wire signed [11:0] r_1;
  wire signed [11:0] g_1;
  wire signed [11:0] b_1;

  wire [7:0] r;
  wire [7:0] g;
  wire [7:0] b;

  assign r_1 = (contrast*{img_720_data_i[15:11],3'd0})/256 + brightness;
  assign r = (r_1 >= 255)?255:((r_1 <= 0)?0:r_1[7:0]);

  assign g_1 = (contrast*{img_720_data_i[10:5],2'd0})/256 + brightness;
  assign g = (g_1 >= 255)?255:((g_1 <= 0)?0:g_1[7:0]);

  assign b_1 = (contrast*{img_720_data_i[4:0],3'd0})/256 + brightness;
  assign b = (b_1 >= 255)?255:((b_1 <= 0)?0:b_1[7:0]);
  // always @(*) begin
  //   r = {img_720_data_i[15:11],3'd0} + brightness;
  //   r = (r - 128) * contrast / 128 + 128;

  //   if (r > 255)


  //     r = 255;
  //   else if (r < 0)
  //     r = 0;
  // end

  // always @(*) begin
  //   g = {img_720_data_i[10:5],2'd0} + brightness;
  //   g = (g - 128) * contrast / 128 + 128;

  //   if (g > 255)
  //     g = 255;
  //   else if (g < 0)
  //     g = 0;
  // end

  // always @(*) begin
  //   b = {img_720_data_i[4:0],3'd0} + brightness;
  //   b = (b - 128) * contrast / 128 + 128;

  //   if (b > 255)
  //     b = 255;
  //   else if (b < 0)
  //     b = 0;
  // end

assign vout_clk  = img_720_clk_i;
assign vout_vs  = img_720_vs_i;
assign vout_hs  = img_720_hs_i;
assign vout_de  = img_720_de_i;
assign vout_data  = {r[7:3],g[7:2],b[7:3]};

  
  
  

endmodule
