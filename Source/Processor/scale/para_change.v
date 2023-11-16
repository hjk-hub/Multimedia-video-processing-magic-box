module para_change(
    input clk_wr, //дʱ��
    input clk_rd, //��ʱ��
    input [2:0] change_en, //�л��ź�,1 Ϊ�Ŵ�,2 Ϊ��С,4 Ϊԭͼ

    input [10:0] s_width, //����ǰ���
    input [10:0] s_height, //����ǰ�߶�

    input [10:0] t_width  ,//���ź���
    input [10:0] t_height , //���ź�߶�
    // input [2:0] change_en,

    input rst_n, //��λ�ź�

    input rd_vsync, //���˳��ź�
    input wr_vsync, //д�˳��ź�


    output reg [10:0] t_width_wr  , //д�����ź���
    output reg [10:0] t_height_wr , //д�����ź�߶�
    output reg [10:0] t_width_rd  , //�������ź���
    output reg [10:0] t_height_rd , //�������ź�߶�
    output reg [15:0] h_scale_k   , //����������
    output reg [15:0] v_scale_k   , //����������

    output reg [2:0] change_en_wr, //д���л��ź�
    output reg [2:0] change_en_rd, //�����л��ź�
    output reg [27:0] app_addr_rd_max, //���� DDR3 ��������ַ
    output reg [7:0] rd_bust_len , //�� DDR3 �ж�����ʱ��ͻ������
    output reg [27:0] app_addr_wr_max, //���� DDR3 �����д��ַ
    output reg [7:0] wr_bust_len //�� DDR3 ��д����ʱ��ͻ������

  );

  //reg define
  // reg [27:0] app_addr_rd_max;
  // reg [7:0] rd_bust_len;
  // reg [27:0] app_addr_wr_max;
  // reg [7:0] wr_bust_len;
  reg [7:0] rd_vsync_d;
  reg [7:0] wr_vsync_d;
  // reg [10:0] t_width_wr;
  // reg [10:0] t_height_wr;
  // reg [10:0] t_width_rd;
  // reg [10:0] t_height_rd;
  reg [10:0] s_width_wr;
  reg [10:0] s_height_wr;
  reg [10:0] s_width_rd;
  reg [10:0] s_height_rd;
  reg [2:0] change_wr_en_d1;
  reg [2:0] change_en_wr_d0;
  // reg [2:0] change_en_wr;
  // reg [2:0] change_en_rd;
  reg [2:0] change_wr_en_d0;
  reg delay_frame; //�л���д��һ֡��־�ź�
  reg [2:0] change_rd_en_d0;
  reg [2:0] change_rd_en_d1;
  reg delay_frame_d0;
  // reg [15:0] h_scale_k; //(s_width * 256)/ t_width
  // reg [15:0] v_scale_k; //(s_height * 256)/ t_height
  reg [3:0] cmos_ps_cnt;

  //wire define
  wire [10:0] t_width_up; //�Ŵ��ͼ��Ŀ��
  wire [10:0] t_height_up; //�Ŵ��ͼ��ĸ߶�
  wire [10:0] t_width_down; //��С��ͼ��Ŀ��
  wire [10:0] t_height_down; //��С��ͼ��ĸ߶�
  wire para_finish;

  //*****************************************************
  //** main code
  //*****************************************************
  //�Ŵ��ͼ��ķֱ���
  // assign t_width_up = 11'd1024;
  // assign t_height_up = 11'd768;
  // //��С��ͼ��ķֱ���
  // assign t_width_down = 11'd560;
  // assign t_height_down = 11'd400;

  //��д�������źŽ��мĴ�
  always@(posedge clk_wr)
  begin
    if(~rst_n)
    begin
      wr_vsync_d <= 4'd0;
      change_wr_en_d0 <= 1'b0;
      change_en_wr_d0 <= 1'b0;
      s_width_wr <= 11'b0;
      s_height_wr <= 11'b0;
    end
    else
    begin
      wr_vsync_d <= {wr_vsync_d[6:0],wr_vsync };
      s_width_wr <= s_width;
      s_height_wr <= s_height;
      change_wr_en_d0 <= change_en;
      change_wr_en_d1 <= change_wr_en_d0;
      change_en_wr_d0 <= change_en_wr;
    end
  end

  //�Զ��������źŽ��мĴ�
  always@(posedge clk_rd)
  begin
    if(~rst_n)
    begin
      rd_vsync_d <= 4'd0;
      change_rd_en_d0 <= 1'b0;
      delay_frame_d0 <= 1'b0;
      s_width_rd <= 11'b0;
      s_height_rd <= 11'b0;
    end
    else
    begin
      rd_vsync_d <= {rd_vsync_d[6:0],rd_vsync };
      s_width_rd <= s_width;
      s_height_rd <= s_height;
      change_rd_en_d0 <= change_en;
      change_rd_en_d1 <= change_rd_en_d0;
      delay_frame_d0 <= delay_frame;
    end
  end

  //����д���л�ʹ��
  always@(posedge clk_wr)
  begin
    if(~rst_n)
      change_en_wr <= 1'b0;
    else if(wr_vsync_d[1] && ~wr_vsync_d[0])
      change_en_wr <= change_wr_en_d0;
    else
      change_en_wr <= change_en_wr;
  end

  //д�����ź�ķֱ���
  always@(posedge clk_wr)
  begin
    if(~rst_n)
    begin
      t_width_wr <= 11'b0;
      t_height_wr <= 11'b0;
    end
    else if(wr_vsync_d[2] && ~wr_vsync_d[1])
    begin
      // if(change_en_wr[0])
      // begin
      //   t_width_wr <= t_width_up;
      //   t_height_wr <= t_height_up;
      // end
      // else if(change_en_wr[1])
      // begin
      //   t_width_wr <= t_width_down;
      //   t_height_wr <= t_height_down;
      // end
      // else
      begin
        // t_width_wr <= s_width;
        // t_height_wr <= s_height;
        t_width_wr <= t_width;
        t_height_wr <=t_height;
      end
    end
    else
    begin
      t_width_wr <= t_width_wr;
      t_height_wr <= t_height_wr;
    end
  end

  //�����г���������
  always@(posedge clk_wr)
  begin
    if(~rst_n)
    begin
      h_scale_k <= 16'b0;
      v_scale_k <= 16'b0;
    end
    else if(wr_vsync_d[3] && ~wr_vsync_d[2])
    begin
      // if(change_en_wr[0])
      // begin
      //   h_scale_k <= 16'd180; //(s_width * 256)/ t_width
      //   v_scale_k <= 16'd160; //(s_height * 256)/ t_height
      // end
      // else if(change_en_wr[1])
      // begin
      //   h_scale_k <= 16'd329;
      //   v_scale_k <= 16'd307;
      // end
      // else
      begin
        h_scale_k <= (s_width * 256)  / t_width    ;
        v_scale_k <= (s_height * 256) / t_height  ;

        // h_scale_k <= 16'd256;
        // v_scale_k <= 16'd256;
      end
    end
    else
    begin
      h_scale_k <= h_scale_k;
      v_scale_k <= v_scale_k;
    end
  end

  //�����л���д��һ֡��־�ź�
  always@(posedge clk_wr)
  begin
    if(~rst_n)
      delay_frame <= 1'b0;
    else if(change_wr_en_d0 != change_wr_en_d1)
      delay_frame <= 1'b1;
    else if((wr_vsync_d[5] && ~wr_vsync_d[4]) && (change_wr_en_d0 == change_en_wr))
      delay_frame <= 1'b0;
    else
      delay_frame <= delay_frame;
  end

  //����д�˵� ddr ����
  always@(posedge clk_wr)
  begin
    if(~rst_n)
    begin
      wr_bust_len <= s_width[10:3];
      app_addr_wr_max <= s_width * s_height;
    end
    else if(change_en_wr[2] )
    begin
      if(wr_vsync_d[5] && ~wr_vsync_d[4])
      begin
        wr_bust_len <= s_width_wr[10:3];
        app_addr_wr_max <= s_width_wr * s_height_wr;
      end
      else
      begin
        wr_bust_len <= wr_bust_len;
        app_addr_wr_max <= app_addr_wr_max;
      end
    end
    else
    begin
      if(wr_vsync_d[5] && ~wr_vsync_d[4])
      begin
        wr_bust_len <= t_width_wr[10:3];
        app_addr_wr_max <= t_width_wr * t_height_wr;
      end
      else
      begin
        wr_bust_len <= wr_bust_len;
        app_addr_wr_max <= app_addr_wr_max;
      end
    end
  end

  //���������л�ʹ��
  always@(posedge clk_rd)
  begin
    if(~rst_n)
      change_en_rd <= 1'b0;
    else if(rd_vsync_d[1] && ~rd_vsync_d[0] && ~delay_frame_d0)
      change_en_rd <= change_rd_en_d0;
    else
      change_en_rd <= change_en_rd;
  end

  //�������ź�ķֱ���
  always@(posedge clk_wr)
  begin
    if(~rst_n)
    begin
      t_width_rd <= 11'b0;
      t_height_rd <= 11'b0;
    end
    else if( rd_vsync_d[3] && ~rd_vsync_d[2] && ~delay_frame_d0)
    begin
      // if(change_en_rd[0] )
      // begin
      //   t_width_rd <= t_width_up;
      //   t_height_rd <= t_height_up;
      // end
      // else if(change_en_rd[1])
      // begin
      //   t_width_rd <= t_width_down;
      //   t_height_rd <= t_height_down;
      // end
      // else
      begin
        // t_width_rd <= s_width;
        // t_height_rd <= s_height;
        t_width_rd <= t_width;
        t_height_rd <=t_height;

        
      end
    end
    else
    begin
      t_width_rd <= t_width_rd;
      t_height_rd <= t_height_rd;
    end
  end

  //�������˵� ddr ����
  always@(posedge clk_rd)
  begin
    if(~rst_n)
    begin
      rd_bust_len <= s_width[10:3];
      app_addr_rd_max <= s_width * s_height;
    end
    else if(change_en_rd[2] )
    begin
      if(rd_vsync_d[5] && ~rd_vsync_d[4] && ~delay_frame_d0)
      begin
        rd_bust_len <= s_width_rd[10:3];
        app_addr_rd_max <= s_width_rd * s_height_rd;
      end
      else
      begin
        rd_bust_len <= rd_bust_len;
        app_addr_rd_max <= app_addr_rd_max;
      end
    end
    else
    begin
      if(rd_vsync_d[5] && ~rd_vsync_d[4] && ~delay_frame_d0)
      begin
        rd_bust_len <= t_width_rd[10:3];
        app_addr_rd_max <= t_width_rd * t_height_rd;
      end
      else
      begin
        rd_bust_len <= rd_bust_len;
        app_addr_rd_max <= app_addr_rd_max;
      end
    end
  end

endmodule
