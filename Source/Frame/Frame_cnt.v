//**********************************************
//用以判断写入fifo ，实现缩小一倍
module Frame_cnt
  #(
    parameter FLAG = 1280,
`include"F:/Project/WorkSpace/FPGA/Video_pro/Source/top/global.vh"
   )
   (
     input wire                          rst_n          ,
     input wire                          Img_pclk       ,
     // input wire                          Img_vs         ,
     input wire                          Img_de         ,
     input wire   [15:0]                 Img_data       ,

     output                              fifo_wr_en     ,
     output wire  [15:0]                 fifo_wr_data

   );

   localparam img_col = FLAG;

  reg [31:0] x;
  reg [31:0] y;

  reg [1:0] flag_x;
  reg [1:0] flag_y;

  //
  always @(posedge Img_pclk)
  begin
    if(!rst_n)
    begin
      x <= 32'd0;
      flag_x <= 2'b00;
    end
    else
    begin
      if(Img_de)
      begin
        if(x < img_col -1)
        begin
          x <= x + 32'd1  ;
          if(flag_x == 2'b10)
            flag_x <= 2'b00;
          else
            flag_x <= flag_x + 1'b1;
        end
        else
        begin
          x <= 32'd0      ;
          flag_x <= 2'b00;
        end
      end
      else
      begin
        x <= 32'd0      ;
        flag_x <= 2'b00;
      end

    end
  end

  always @(posedge Img_pclk)
  begin
    if(!rst_n)
    begin
      y <= 32'd0;
      flag_y <= 2'b00;
    end
    else if(x == img_col -1)
    begin
      y <= y + 32'd1  ;
      if(flag_y == 2'b10)
        flag_y <= 2'b00;
      else
        flag_y <= flag_y + 1'b1;
    end
    else
    begin
      y <= y          ;
      flag_y <= flag_y;
    end
  end


  generate
    if (img_col == 1280)
    begin
      assign fifo_wr_en = ((~x[0])&(~y[0])&(Img_de))?1'b1:1'b0;
      assign fifo_wr_data = Img_data;
    end
  endgenerate

  generate
    if (img_col == 1920)
    begin
      assign fifo_wr_en = ((flag_x == 2'b00)&&(flag_y == 2'b00)&&(Img_de==1'b1))?1'b1:1'b0;//Img_de;//
      assign fifo_wr_data = Img_data;
    end
  endgenerate

endmodule
