module key_ctrl(
    //input
    input sys_clk, //ʱ���ź� 50Mhz
    input sys_rst_n, //��λ�ź�
    input touch_key, //����

    //output
    output reg [2:0] change_en //�л��ź�
  );

  //reg define
  reg touch_key_d0;
  reg touch_key_d1;
  reg vs_in_d0;
  reg touch_en;
  reg [23:0] cnt_time;
  // reg [2:0] change_en ;

  //*****************************************************
  //** main code
  //*****************************************************

  //�Դ��������˿ڵ������ӳ�����ʱ������
  always @ (posedge sys_clk or negedge sys_rst_n)
  begin
    if(!sys_rst_n)
    begin
      touch_key_d0 <= 1'b0;
      touch_key_d1 <= 1'b0;
    end
    else
    begin
      touch_key_d0 <= touch_key;
      touch_key_d1 <= touch_key_d0;
    end
  end

  //�����л��ź�
  always @ (posedge sys_clk or negedge sys_rst_n)
  begin
    if(!sys_rst_n)
    begin
      change_en <= 3'd4;
    end
    else
    begin
      if(cnt_time == 500000)
        if(change_en == 3'b100)
          change_en <= 3'b1;
        else
          change_en <= {change_en[1:0],1'b0};
      else
        change_en <= change_en ;
    end
  end

  //�԰����ĵ͵�ƽʱ����м���
  always @ (posedge sys_clk or negedge sys_rst_n)
  begin
    if(!sys_rst_n)
    begin
      cnt_time <= 24'b0;
    end
    else
    begin
      if(touch_key_d1)
        cnt_time <= 24'b0;
      else if(cnt_time >= 2500000)
        cnt_time <= cnt_time;
      else
        cnt_time <= cnt_time + 1;
    end
  end

endmodule
