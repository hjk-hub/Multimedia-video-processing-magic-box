module calu#
  (
    parameter DATA_WIDTH = 8)
  (
    input sys_clk,
    input [DATA_WIDTH - 1:0] a, //像素数据
    input [DATA_WIDTH - 1:0] b, //像素数据
    input [7:0] a_coff, //行权重系数
    input [7:0] b_coff, //行权重系数
    output [DATA_WIDTH - 1:0] c, //缩放后的像素数据
    input [7:0] a_coff_next, //下级权重系数输入
    input [7:0] b_coff_next, //下级权重系数输入
    output reg [7:0] a_coff_next_out,//下级权重系数输出
    output reg [7:0] b_coff_next_out,//下级权重系数输出
    input data_en_in, //数据有效使能输入
    input scale_en_in, //数据缩放有效使能输入
    output reg data_en_out, //数据有效使能输出
    output reg scale_en_out //数据缩放有效使能输出
  );

  //reg define
  reg[DATA_WIDTH - 1:0] a_reg;
  reg[DATA_WIDTH - 1:0] b_reg;
  reg[7:0] a_coff_reg;
  reg[7:0] b_coff_reg;
  // reg[7:0] a_coff_next_out;//下级系数
  // reg[7:0] b_coff_next_out;//下级系数
  // reg data_en_out;
  // reg scale_en_out;
  reg[15:0] a_mult0;
  reg[15:0] b_mult0;
  reg[15:0] add0;
  reg[8:0] add_tmp0;
  reg data_en_in_d0;
  reg data_en_in_d1;
  reg data_en_in_d2;
  reg scale_en_in_d0;
  reg scale_en_in_d1;
  reg scale_en_in_d2;
  reg[7:0] a_coff_next_d0;
  reg[7:0] a_coff_next_d1;
  reg[7:0] a_coff_next_d2;
  reg[7:0] b_coff_next_d0;
  reg[7:0] b_coff_next_d1;
  reg[7:0] b_coff_next_d2;


  //*****************************************************
  //** main code
  //*****************************************************

  assign c = add_tmp0[8] ? 8'hf0 : add_tmp0[7:0];

  //打拍寄存
  always@(posedge sys_clk)
  begin
    a_reg <= a;
    b_reg <= b;
    a_coff_reg <= a_coff;
    b_coff_reg <= b_coff;
    data_en_in_d0 <= data_en_in;
    scale_en_in_d0 <= scale_en_in;
    a_coff_next_d0 <= a_coff_next;
    b_coff_next_d0 <= b_coff_next;
  end

  //对像素点进行加权运算
  always@(posedge sys_clk)
  begin
    a_mult0 <= a_reg[7:0] * a_coff_reg;
    b_mult0 <= b_reg[7:0] * b_coff_reg;
    add0 <= a_mult0 + b_mult0;
    add_tmp0 <= {1'b0,add0[15:8]} + {8'd0,{(add0[7:0] > 8'h66)}};

  end

  //对信号进行延时
  always@(posedge sys_clk)
  begin
    data_en_in_d1 <= data_en_in_d0;
    scale_en_in_d1 <= scale_en_in_d0;
    a_coff_next_d1 <= a_coff_next_d0;
    b_coff_next_d1 <= b_coff_next_d0;

    data_en_in_d2 <= data_en_in_d1;
    scale_en_in_d2 <= scale_en_in_d1;
    a_coff_next_d2 <= a_coff_next_d1;
    b_coff_next_d2 <= b_coff_next_d1;

    data_en_out <= data_en_in_d2;
    scale_en_out <= scale_en_in_d2;
    a_coff_next_out <= a_coff_next_d2;
    b_coff_next_out <= b_coff_next_d2;
  end

endmodule
