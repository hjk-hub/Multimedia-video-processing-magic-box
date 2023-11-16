module scaler
  (
    input sys_clk,
    input rst_n,
    //data in
    input fifo_rdempty, //����ǰ fifo �Ľ��ձ�־
    output reg scaler_rd_req, //fifo ������
    input [7:0] data_in, //����ǰ����
    input frame_flag, //֡ͷ��־�ź�
    input data_ready, //fifo һ������׼������ź�
    //data out
    output reg scaler_wren, //���ź� fifo дʹ��
    output reg [7:0] data_out, //���ź�����
    //config
    input [11:0] s_width, //����ǰ���
    input [11:0] s_height, //����ǰ�߶�
    input [11:0] t_width, //���ź���
    input [11:0] t_height, //���ź�߶�
    input [15:0] k_h, //����������
    input [15:0] k_v //����������
  );

  //reg define
  reg [15:0] k_h_reg;
  reg [15:0] k_v_reg;
  reg wr_buf_sel; //ram д�л�ʹ��
  reg [11:0] wr_lines; //���� fifo ���ݵ�����
  reg [19:0] scale_map_v; //�����������ۼӼĴ���
  reg [7:0] line0_pixel_data; //��Ҫ�������������������
  reg [7:0] line1_pixel_data; //��Ҫ�������������������
  reg [11:0] ram_v_raddr; //�� ram ��ַ
  reg [11:0] ram_v_waddr; //ram д��ַ
  reg [11:0] ram_v_waddr_d0;
  reg [11:0] ram_v_waddr_d1;
  reg [11:0] ram_v_raddr_d0;
  reg [11:0] ram_v_raddr_d1;
  reg [11:0] ram_h_waddr_d0;
  reg [11:0] ram_h_waddr_d1;
  reg [11:0] ram_h_raddr_d0;
  reg [11:0] ram_h_raddr_d1;
  reg pixel_h_data_read_en_d0;
  reg pixel_h_data_read_en_d1;
  reg pixel_v_data_read_en_d0;
  reg pixel_v_data_read_en_d1;
  reg fifo_line_finish ; //fifo һ�ж����ź�
  reg ram_v_wren ; //�� ram дʹ��
  reg [11:0] scale_line; //���ź���м���
  reg one_line_data_ready ; //��������д���� ram �ı�־�ź�
  reg pixel_v_data_read_en ; //�� ram ���ݿɶ�ʹ��
  reg scale_line_finish ; //����������ź�
  reg calu_v_data_in_en ; //��������������ʹ����Ч�ź�
  reg [7:0] a_coff_v; //�м�Ȩϵ������
  reg [7:0] b_coff_v; //�м�Ȩϵ������
  reg [15:0] scale_line_finish_d;
  reg [15:0] scale_h_finish_d;
  reg [7:0] ram_h_data_in; //�� ram ��������
  reg ram_h_wren; //�� ram дʹ��
  reg [11:0] ram_h_waddr; //�� ram д��ַ
  reg pixel_h_data_read_en; //�� ram ���ݿɶ�ʹ��
  reg [11:0] ram_h_raddr; //�� ram ����ַ
  reg [19:0] scale_map_h; //�����������ۼӼĴ���
  // reg scaler_wren; //���ź� fifo дʹ��
  // reg [7:0] data_out; //���ź�����
  reg [7:0] col0_pixel_data;
  reg [7:0] col1_pixel_data;
  reg calu_h_data_in_en; //����������ʹ����Ч�ź�
  reg [7:0] a_coff_h; //�м�Ȩϵ������
  reg [7:0] b_coff_h; //�м�Ȩϵ������
  reg [19:0] scale_map_v_d0;
  reg [19:0] scale_map_h_d0;
  reg scaler_up; //���ű�־ 1 ��ʾ�Ŵ�0 ��ʾ��С
  reg scale_h_line_valid_cont; //��Ч�����ű�־�����ź�
  reg scale_h_finish ; //����������ź�
  reg scale_h_not_end ; //������δ�����ź�
  reg [11:0] cnt_h_pixel; //�����ż���
  reg rd_v_not_need_data; //�����Ų���Ҫ�������ݱ�־
  reg scale_v_end_line; //���һ�б�־�ź�
  reg frame_flag_d0;
  reg calu_h_data_in_en_d0;
  // reg scaler_rd_req; //fifo ������
  reg [11:0] cnt_rd_req; //fifo ���������

  //wire define
  wire[7:0] ram_v_data_out0; //ram0 �������
  wire[7:0] ram_v_data_out1; //ram1 �������
  wire data_en_out_calu_v; //���������ʹ��
  wire[7:0] c_v; //�������������
  wire calu_h_data_out_en; //���������ʹ��
  wire[7:0] c_h; //�������������
  wire[7:0] ram_h_data_out; //�� ram �������
  wire[19:0] scale_map_h_next; //��һ�������������ۼӼĴ���
  wire scale_h_line_valid; //��Ч�����ű�־
  wire[19:0] scale_map_v_next; //��һ�������������ۼӼĴ���
  wire scale_v_line_valid; //��Ч�����ű�־

  //*****************************************************
  //** main code
  //*****************************************************

  //������һ�������������ۼӼĴ���
  assign scale_map_v_next = scale_map_v + {4'd0,k_v_reg};

  //������һ�������������ۼӼĴ���
  assign scale_map_h_next =scale_map_h + {4'd0,k_h_reg};

  //������Ч�����ű�־
  assign scale_v_line_valid = (scale_map_v[19:8] == wr_lines - 12'd1)||rd_v_not_need_data;

  //������Ч�����ű�־
  assign scale_h_line_valid = ((scale_map_h[19:8] == scale_map_h_next[19:8])
                               && scaler_up && pixel_h_data_read_en_d1) ? 1 : 0;

  //���� fifo ������
  always@(posedge sys_clk)
  begin
    if(~rst_n || frame_flag)
      scaler_rd_req <= 0;
    else if(cnt_rd_req>= s_width - 1)
      scaler_rd_req <= 0;
    else if(data_ready)
      if(!rd_v_not_need_data)
        scaler_rd_req <= 1;
      else
        scaler_rd_req <= 0;
    else
      scaler_rd_req <= scaler_rd_req;
  end

  //�� fifo ��������м���
  always@(posedge sys_clk)
  begin
    if(~rst_n || frame_flag)
      cnt_rd_req <= 0;
    else if(scaler_rd_req)
      cnt_rd_req <= cnt_rd_req + 1;
    else
      cnt_rd_req <= 0;
  end

  always@(posedge sys_clk)
  begin
    if(!rst_n)
    begin
      ram_v_waddr_d0 <= 0;
      ram_v_waddr_d1 <= 0;
      ram_v_raddr_d0 <= 0;
      ram_v_raddr_d1 <= 0;
      ram_h_waddr_d0 <= 0;
      ram_h_waddr_d1 <= 0;
      ram_h_raddr_d0 <= 0;
      ram_h_raddr_d1 <= 0;
      pixel_v_data_read_en_d0 <= 0;
      pixel_v_data_read_en_d1 <= 0;
      pixel_h_data_read_en_d0 <= 0;
      pixel_h_data_read_en_d1 <= 0;
      scale_line_finish_d <= 0;
      scale_h_finish_d <= 0;
      scale_map_v_d0 <= 0;
      frame_flag_d0 <= 0;
    end
    else
    begin
      ram_v_waddr_d0 <= ram_v_waddr;
      ram_v_waddr_d1 <= ram_v_waddr_d0;
      ram_v_raddr_d0 <= ram_v_raddr;
      ram_v_raddr_d1 <= ram_v_raddr_d0;
      ram_h_waddr_d0 <= ram_h_waddr;
      ram_h_waddr_d1 <= ram_h_waddr_d0;
      ram_h_raddr_d0 <= ram_h_raddr;
      ram_h_raddr_d1 <= ram_h_raddr_d0;
      pixel_v_data_read_en_d0 <= pixel_v_data_read_en;
      pixel_h_data_read_en_d0 <= pixel_h_data_read_en;
      pixel_h_data_read_en_d1 <= pixel_h_data_read_en_d0;
      pixel_v_data_read_en_d1 <= pixel_v_data_read_en_d0;
      scale_line_finish_d <= {scale_line_finish_d[14:0],scale_line_finish};
      scale_h_finish_d <= {scale_h_finish_d[14:0],scale_h_finish};
      scale_map_v_d0 <= scale_map_v;

      scale_map_h_d0 <= scale_map_h;
      frame_flag_d0 <= frame_flag;
    end
  end

  //�������������ӽ��мĴ�
  always@(posedge sys_clk )
  begin
    k_h_reg <= k_h;
    k_v_reg <= k_v;
  end

  //�ж����ǷŴ�����С
  always@(posedge sys_clk)
  begin
    if(k_h_reg[15:8] == 8'd0)
      scaler_up <= 1;
    else
      scaler_up <= 0;
  end

  //fifo һ�ж����ź�
  always@(posedge sys_clk)
  begin
    if(~rst_n)
      fifo_line_finish <= 0;
    else if((ram_v_waddr_d0 == s_width) && (ram_v_waddr_d1 == s_width - 1))
      fifo_line_finish <= 1;
    else
      fifo_line_finish <= 0;
  end

  //������ ram д��ַ
  always@(posedge sys_clk)
  begin
    if(~rst_n)
      ram_v_waddr <= 0;
    else if(frame_flag || fifo_line_finish)
      ram_v_waddr <= 0;
    else if(ram_v_wren)
      ram_v_waddr <= ram_v_waddr + 1;
    else
      ram_v_waddr <= ram_v_waddr;
  end

  //������ ram дʹ��
  always@(posedge sys_clk)
  begin
    if(~rst_n)
      ram_v_wren <= 0;
    else if(frame_flag || fifo_line_finish)
      ram_v_wren <= 0;
    else if(scaler_rd_req)
      ram_v_wren <= 1;
    else
      ram_v_wren <= 0;
  end

  //���� ram ��д�л��ź�
  always@(posedge sys_clk)
  begin
    if(~rst_n || frame_flag)
      wr_buf_sel <= 1'b0;
    else if(fifo_line_finish)
      wr_buf_sel <= ~wr_buf_sel;
    else
      wr_buf_sel <= wr_buf_sel;
  end

  //�� fifo �������ݵ���������
  always@(posedge sys_clk)
  begin
    if(~rst_n)
      wr_lines <= 12'd0;
    else if(frame_flag)
      wr_lines <= 12'd0;
    else if(fifo_line_finish)
      wr_lines <= wr_lines + 12'd1;
    else
      wr_lines <= wr_lines;
  end

  //�����������ӽ����ۼ�
  always@(posedge sys_clk)
  begin
    if(~rst_n)
      scale_map_v <= 20'd0;
    else if(frame_flag )
      scale_map_v <= 20'd0;
    else if(scale_line_finish && (scale_line < t_height - 1))

      scale_map_v <= scale_map_v + {4'd0,k_v_reg};
    else
      scale_map_v <= scale_map_v;
  end

  //���������Ų���Ҫ�������ݱ�־
  always@(posedge sys_clk)
  begin
    if(~rst_n)
      rd_v_not_need_data <= 1'd0;
    else if(frame_flag )
      rd_v_not_need_data <= 1'd0;
    else if(scale_line_finish && one_line_data_ready && ~scale_v_end_line)
      if(scale_map_v[19:8] == scale_map_v_next[19:8])
        rd_v_not_need_data <= 1;
      else
        rd_v_not_need_data <= 0;
    else
      rd_v_not_need_data <= rd_v_not_need_data;
  end

  //�����ź���н��м���
  always@(posedge sys_clk)
  begin
    if(~rst_n)
      scale_line <= 12'd0;
    else if( frame_flag )
      scale_line <= 12'd0;
    else if(scale_line_finish)
      scale_line <= scale_line + 12'd1;
    else
      scale_line <= scale_line;
  end

  //���� ram ��������д��ʹ��
  always@(posedge sys_clk)
  begin
    if(~rst_n)
      one_line_data_ready <= 0;
    else if(frame_flag)
      one_line_data_ready <= 0;
    else if(fifo_line_finish)
      one_line_data_ready <= 1;
    else

      one_line_data_ready <= one_line_data_ready;
  end

  //���� ram ���ݿɶ�ʹ��
  always@(posedge sys_clk)
  begin
    if(~rst_n)
      pixel_v_data_read_en <= 0;
    else if(frame_flag)
      pixel_v_data_read_en <= 0;
    else if(scale_h_not_end && scaler_up)
      pixel_v_data_read_en <= 0;
    else if(((ram_v_waddr >= ram_v_raddr + 2) && scale_v_line_valid )
            || (rd_v_not_need_data && ram_v_raddr< s_width - 1)
            || (scale_v_end_line && scale_v_line_valid && (ram_v_raddr< s_width - 1)))
      pixel_v_data_read_en <= 1;
    else
      pixel_v_data_read_en <= 0;
  end

  //�������һ�б�־�ź�
  always@(posedge sys_clk)
  begin
    if(~rst_n)
      scale_v_end_line <= 0;
    else if(frame_flag )
      scale_v_end_line <= 0;
    else if((scale_line == t_height - 1) && scale_line_finish_d[10] )
      scale_v_end_line <= 1;
    else
      scale_v_end_line <= scale_v_end_line;

  end

  //������ ram ����ַ
  always@(posedge sys_clk)
  begin
    if(~rst_n)
      ram_v_raddr <= 0;
    else if(frame_flag || (scale_line_finish_d[8] && ~scale_v_end_line))
      ram_v_raddr <= 0;
    else if(pixel_v_data_read_en )
      ram_v_raddr <= ram_v_raddr + 1;
    else
      ram_v_raddr <= ram_v_raddr;
  end

  //��������������ʹ����Ч�ź�
  always@(posedge sys_clk)
  begin
    if(~rst_n)
      calu_v_data_in_en <= 0;
    else if(pixel_v_data_read_en_d0)
      calu_v_data_in_en <= 1;
    else
      calu_v_data_in_en <= 0;
  end

  //��������������ź�
  always@(posedge sys_clk)
  begin
    if(~rst_n)
      scale_line_finish <= 0;
    else if(frame_flag )
      scale_line_finish <= 0;
    else if((ram_v_raddr_d0 == s_width - 1) && (ram_v_raddr_d1 == s_width - 2))
      scale_line_finish <= 1;
    else
      scale_line_finish <= 0;
  end

  //�����ڵ� 2 �н���Ȩ�ظ�ֵ
  always@(posedge sys_clk)
  begin
    if(~rst_n)
    begin
      a_coff_v <= 0;
      b_coff_v <= 0;
    end
    else
    begin
      a_coff_v <= scale_map_v[7:0];
      b_coff_v <= ~scale_map_v[7:0];
    end
  end

  //���� ram д�л�ʹ�ܶԶ�Ӧ���мĴ�����ֵ
  always@(posedge sys_clk)
  begin
    if(~rst_n)
    begin
      line0_pixel_data <= 0;

      line1_pixel_data <= 0;
    end
    else if(wr_buf_sel)
    begin
      line0_pixel_data <= ram_v_data_out0;
      line1_pixel_data <= ram_v_data_out1;
    end
    else
    begin
      line0_pixel_data <= ram_v_data_out1;
      line1_pixel_data <= ram_v_data_out0;
    end
  end

  //�Զ����� fifo ����ͨ�� ram ���д洢
/*  ram_scaler u_ram_scaler_v_0(
               .clka (sys_clk),
               .wea (ram_v_wren & wr_buf_sel),
               .addra (ram_v_waddr),
               .dina (data_in),
               .clkb (sys_clk),
               .addrb (ram_v_raddr),
               .doutb (ram_v_data_out0)
             );*/
//ram_8i8o_2048
ram_8i8o_2048 u_ram_scaler_v_0 (
  .wr_data(data_in),    // input [7:0]
  .wr_addr(ram_v_waddr),    // input [9:0]
  .rd_addr(ram_v_raddr),    // input [9:0]
  .wr_clk(sys_clk),      // input
  .rd_clk(sys_clk),      // input
  .wr_en(ram_v_wren & wr_buf_sel),        // input
  .wr_rst(~rst_n),
  .rd_rst(~rst_n),           // input
  .rd_data(ram_v_data_out0)     // output [7:0]
);


  //�Զ����� fifo ����ͨ�� ram ���д洢
/*
  ram_scaler u_ram_scaler_v_1(
               .clka (sys_clk),
               .wea (ram_v_wren & ~wr_buf_sel),
               .addra (ram_v_waddr),
               .dina (data_in),
               .clkb (sys_clk),
               .addrb (ram_v_raddr),
               .doutb (ram_v_data_out1)
             );*/
ram_8i8o_2048 u_ram_scaler_v_1 (
  .wr_data(data_in),    // input [7:0]
  .wr_addr(ram_v_waddr),    // input [9:0]
  .rd_addr(ram_v_raddr),    // input [9:0]
  .wr_clk(sys_clk),      // input
  .rd_clk(sys_clk),      // input
  .wr_en(ram_v_wren & ~wr_buf_sel),        // input
  .wr_rst(~rst_n),
  .rd_rst(~rst_n),           // input
  .rd_data(ram_v_data_out1)     // output [7:0]
);

  //���н��м�Ȩ����
  calu calu_v(
         .sys_clk(sys_clk),
         .a(line0_pixel_data),
         .b(line1_pixel_data),
         .a_coff(a_coff_v),
         .b_coff(b_coff_v),
         .c(c_v),
         .data_en_in(calu_v_data_in_en),
         .data_en_out(data_en_out_calu_v)
       );
  //������ ram ��дʹ�ܺ�����
  always@(posedge sys_clk)
  begin
    if(~rst_n)
    begin
      ram_h_data_in <= 0;
      ram_h_wren <= 0;
    end
    else if(frame_flag_d0)
    begin
      ram_h_data_in <= 0;
      ram_h_wren <= 0;
    end
    else if(data_en_out_calu_v)
    begin
      ram_h_data_in <= c_v;
      ram_h_wren <= data_en_out_calu_v;
    end
    else
    begin
      ram_h_data_in <= 0;
      ram_h_wren <= 0;
    end
  end

  //������ ram ��д��ַ
  always@(posedge sys_clk)
  begin
    if(~rst_n)
      ram_h_waddr <= 0;
    else if(frame_flag_d0)
      ram_h_waddr <= 0;
    else if(scale_h_finish )
      ram_h_waddr <= 0;
    else if(ram_h_wren )
      ram_h_waddr <= ram_h_waddr + 1;
    else
      ram_h_waddr <= ram_h_waddr;
  end

  //������ ram ���ݿɶ�ʹ��

  always@(posedge sys_clk)
  begin
    if(~rst_n)
      pixel_h_data_read_en <= 0;
    else if(frame_flag_d0)
      pixel_h_data_read_en <= 0;
    else if(scale_h_finish )
      pixel_h_data_read_en <= 0;
    else if(ram_h_waddr >= ram_h_raddr + 2)
      pixel_h_data_read_en <= 1;
    else
      pixel_h_data_read_en <= 0;
  end

  //������ ram �Ķ���ַ
  always@(posedge sys_clk)
  begin
    if(~rst_n)
      ram_h_raddr <= 0;
    else if(frame_flag_d0 || scale_h_finish )
      ram_h_raddr <= 0;
    else if((pixel_h_data_read_en == 1) && (pixel_h_data_read_en_d0 == 0))
      ram_h_raddr <= 0;
    else if(scale_h_line_valid && scaler_up)
      ram_h_raddr <= ram_h_raddr;
    else if(pixel_h_data_read_en)
      ram_h_raddr <= ram_h_raddr + 1;
    else
      ram_h_raddr <= ram_h_raddr;
  end

  //�����������ӽ����ۼ�
  always@(posedge sys_clk)
  begin
    if(~rst_n)
      scale_map_h <= 20'd0;
    else if(frame_flag_d0 || scale_h_finish)
      scale_map_h <= 20'd0;
    else if(pixel_h_data_read_en_d1 && (ram_h_raddr> scale_map_h[19:8]))
      scale_map_h <= scale_map_h + {4'd0,k_h_reg};
    else
      scale_map_h <= scale_map_h;
  end
  //��������������ʹ����Ч�ź�
  always@(posedge sys_clk)
  begin
    if(~rst_n)
      calu_h_data_in_en <= 1'd0;
    else if(frame_flag_d0 )
      calu_h_data_in_en <= 1'd0;
    else if(ram_h_raddr >= s_width && !scaler_up && cnt_h_pixel>= t_width - 1)
      calu_h_data_in_en <= 1'd0;
    else if(pixel_h_data_read_en_d0 && (cnt_h_pixel <= t_width - 1)
            && (((scale_map_h[19:8] + 1) == ram_h_raddr) && !scaler_up) )
      calu_h_data_in_en <= 1;
    else if(pixel_h_data_read_en_d0 && (cnt_h_pixel <= t_width - 2) && scaler_up )
      calu_h_data_in_en <= 1;
    else
      calu_h_data_in_en <= 0;
  end

  //��������������ź�
  always@(posedge sys_clk)
  begin
    if(~rst_n)
      scale_h_finish <= 0;
    else if(frame_flag_d0 )
      scale_h_finish <= 0;
    else if((ram_h_raddr_d0 == s_width-1) && (ram_h_raddr_d1 == s_width - 2))
      scale_h_finish <= 1;
    else
      scale_h_finish <= 0;
  end

  //����������δ�����ź�
  always@(posedge sys_clk)
  begin
    if(~rst_n)
      scale_h_not_end <= 0;
    else if(frame_flag_d0 || scale_h_finish_d[4])
      scale_h_not_end <= 0;
    else if(ram_h_waddr == s_width - 1 )
      scale_h_not_end <= 1;
    else
      scale_h_not_end <= scale_h_not_end;
  end
  //������������ݸ�ֵ
  always@(posedge sys_clk)
  begin
    if(~rst_n)
    begin
      col0_pixel_data <= 0;
      col1_pixel_data <= 0;
      calu_h_data_in_en_d0 <= 0;
    end
    else
    begin
      col0_pixel_data <= ram_h_data_out;
      col1_pixel_data <= col0_pixel_data;
      calu_h_data_in_en_d0 <= calu_h_data_in_en;
    end
  end

  //�����ڵ� 2 �н���Ȩ�ظ�ֵ
  always@(posedge sys_clk)
  begin
    if(~rst_n)
    begin
      a_coff_h <= 0;
      b_coff_h <= 0;
    end
    else
    begin
      a_coff_h <= scale_map_h[7:0];
      b_coff_h <= ~scale_map_h[7:0];
    end
  end

  //�����������źŽ�������Ĵ�
  always@(posedge sys_clk)
  begin
    if(~rst_n)
    begin
      scaler_wren <= 0;
      data_out <= 0;
    end
    else
    begin
      scaler_wren <= calu_h_data_out_en;
      data_out <= c_h;
    end
  end

  //������������ʹ�ܽ��м���
  always@(posedge sys_clk)
  begin
    if(~rst_n || frame_flag_d0)
    begin
      cnt_h_pixel <= 0;
    end
    else
    begin
      if(scale_h_finish)
        cnt_h_pixel <= 0;
      else if(calu_h_data_in_en)
        cnt_h_pixel <= cnt_h_pixel + 1;
      else
        cnt_h_pixel <= cnt_h_pixel;
    end
  end

  //��������ź������
/*  ram_scaler u_ram_scaler_h(
               .clka (sys_clk),
               .wea (ram_h_wren),
               .addra (ram_h_waddr),
               .dina (ram_h_data_in),
               .clkb (sys_clk),
               .addrb (ram_h_raddr),
               .doutb (ram_h_data_out)
             );*/

ram_8i8o_2048 u_ram_scaler_h (
  .wr_data(ram_h_data_in),    // input [7:0]
  .wr_addr(ram_h_waddr),    // input [9:0]
  .rd_addr(ram_h_raddr),    // input [9:0]
  .wr_clk(sys_clk),      // input
  .rd_clk(sys_clk),      // input
  .wr_en(ram_h_wren),        // input
  .wr_rst(~rst_n),
  .rd_rst(~rst_n),           // input
  .rd_data(ram_h_data_out)     // output [7:0]
);

  //���н��м�Ȩ����
  calu calu_h(
         .sys_clk(sys_clk),
         .a(col0_pixel_data),
         .b(col1_pixel_data),
         .a_coff(a_coff_h),
         .b_coff(b_coff_h),
         .c(c_h),
         .data_en_in(calu_h_data_in_en_d0),
         .data_en_out(calu_h_data_out_en)
       );

endmodule
