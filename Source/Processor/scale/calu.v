module calu#
  (
    parameter DATA_WIDTH = 8)
  (
    input sys_clk,
    input [DATA_WIDTH - 1:0] a, //��������
    input [DATA_WIDTH - 1:0] b, //��������
    input [7:0] a_coff, //��Ȩ��ϵ��
    input [7:0] b_coff, //��Ȩ��ϵ��
    output [DATA_WIDTH - 1:0] c, //���ź����������
    input [7:0] a_coff_next, //�¼�Ȩ��ϵ������
    input [7:0] b_coff_next, //�¼�Ȩ��ϵ������
    output reg [7:0] a_coff_next_out,//�¼�Ȩ��ϵ�����
    output reg [7:0] b_coff_next_out,//�¼�Ȩ��ϵ�����
    input data_en_in, //������Чʹ������
    input scale_en_in, //����������Чʹ������
    output reg data_en_out, //������Чʹ�����
    output reg scale_en_out //����������Чʹ�����
  );

  //reg define
  reg[DATA_WIDTH - 1:0] a_reg;
  reg[DATA_WIDTH - 1:0] b_reg;
  reg[7:0] a_coff_reg;
  reg[7:0] b_coff_reg;
  // reg[7:0] a_coff_next_out;//�¼�ϵ��
  // reg[7:0] b_coff_next_out;//�¼�ϵ��
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

  //���ļĴ�
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

  //�����ص���м�Ȩ����
  always@(posedge sys_clk)
  begin
    a_mult0 <= a_reg[7:0] * a_coff_reg;
    b_mult0 <= b_reg[7:0] * b_coff_reg;
    add0 <= a_mult0 + b_mult0;
    add_tmp0 <= {1'b0,add0[15:8]} + {8'd0,{(add0[7:0] > 8'h66)}};

  end

  //���źŽ�����ʱ
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
