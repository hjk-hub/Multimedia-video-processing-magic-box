module scaler
  (
    input sys_clk,
    input rst_n,
    //data in
    input fifo_rdempty, //缩放前 fifo 的将空标志
    output reg scaler_rd_req, //fifo 读请求
    input [7:0] data_in, //缩放前数据
    input frame_flag, //帧头标志信号
    input data_ready, //fifo 一行数据准备完成信号
    //data out
    output reg scaler_wren, //缩放后 fifo 写使能
    output reg [7:0] data_out, //缩放后数据
    //config
    input [11:0] s_width, //缩放前宽度
    input [11:0] s_height, //缩放前高度
    input [11:0] t_width, //缩放后宽度
    input [11:0] t_height, //缩放后高度
    input [15:0] k_h, //列缩放因子
    input [15:0] k_v //行缩放因子
  );

  //reg define
  reg [15:0] k_h_reg;
  reg [15:0] k_v_reg;
  reg wr_buf_sel; //ram 写切换使能
  reg [11:0] wr_lines; //读出 fifo 数据的行数
  reg [19:0] scale_map_v; //行缩放因子累加寄存器
  reg [7:0] line0_pixel_data; //将要进行行运算的像素数据
  reg [7:0] line1_pixel_data; //将要进行行运算的像素数据
  reg [11:0] ram_v_raddr; //读 ram 地址
  reg [11:0] ram_v_waddr; //ram 写地址
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
  reg fifo_line_finish ; //fifo 一行读完信号
  reg ram_v_wren ; //行 ram 写使能
  reg [11:0] scale_line; //缩放后的行计数
  reg one_line_data_ready ; //首行数据写入行 ram 的标志信号
  reg pixel_v_data_read_en ; //行 ram 数据可读使能
  reg scale_line_finish ; //行缩放完成信号
  reg calu_v_data_in_en ; //产生行运算输入使能有效信号
  reg [7:0] a_coff_v; //行加权系数输入
  reg [7:0] b_coff_v; //行加权系数输入
  reg [15:0] scale_line_finish_d;
  reg [15:0] scale_h_finish_d;
  reg [7:0] ram_h_data_in; //列 ram 输入数据
  reg ram_h_wren; //列 ram 写使能
  reg [11:0] ram_h_waddr; //列 ram 写地址
  reg pixel_h_data_read_en; //列 ram 数据可读使能
  reg [11:0] ram_h_raddr; //列 ram 读地址
  reg [19:0] scale_map_h; //列缩放因子累加寄存器
  // reg scaler_wren; //缩放后 fifo 写使能
  // reg [7:0] data_out; //缩放后数据
  reg [7:0] col0_pixel_data;
  reg [7:0] col1_pixel_data;
  reg calu_h_data_in_en; //列运算输入使能有效信号
  reg [7:0] a_coff_h; //行加权系数输入
  reg [7:0] b_coff_h; //行加权系数输入
  reg [19:0] scale_map_v_d0;
  reg [19:0] scale_map_h_d0;
  reg scaler_up; //缩放标志 1 表示放大，0 表示缩小
  reg scale_h_line_valid_cont; //有效行缩放标志持续信号
  reg scale_h_finish ; //列缩放完成信号
  reg scale_h_not_end ; //列缩放未结束信号
  reg [11:0] cnt_h_pixel; //列缩放计数
  reg rd_v_not_need_data; //行缩放不需要请求数据标志
  reg scale_v_end_line; //最后一行标志信号
  reg frame_flag_d0;
  reg calu_h_data_in_en_d0;
  // reg scaler_rd_req; //fifo 读请求
  reg [11:0] cnt_rd_req; //fifo 读请求计数

  //wire define
  wire[7:0] ram_v_data_out0; //ram0 输出数据
  wire[7:0] ram_v_data_out1; //ram1 输出数据
  wire data_en_out_calu_v; //行运算输出使能
  wire[7:0] c_v; //行运算输出数据
  wire calu_h_data_out_en; //列运算输出使能
  wire[7:0] c_h; //列运算输出数据
  wire[7:0] ram_h_data_out; //列 ram 输出数据
  wire[19:0] scale_map_h_next; //下一次列缩放因子累加寄存器
  wire scale_h_line_valid; //有效列缩放标志
  wire[19:0] scale_map_v_next; //下一次行缩放因子累加寄存器
  wire scale_v_line_valid; //有效行缩放标志

  //*****************************************************
  //** main code
  //*****************************************************

  //产生下一次行缩放因子累加寄存器
  assign scale_map_v_next = scale_map_v + {4'd0,k_v_reg};

  //产生下一次列缩放因子累加寄存器
  assign scale_map_h_next =scale_map_h + {4'd0,k_h_reg};

  //产生有效行缩放标志
  assign scale_v_line_valid = (scale_map_v[19:8] == wr_lines - 12'd1)||rd_v_not_need_data;

  //产生有效列缩放标志
  assign scale_h_line_valid = ((scale_map_h[19:8] == scale_map_h_next[19:8])
                               && scaler_up && pixel_h_data_read_en_d1) ? 1 : 0;

  //产生 fifo 读请求
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

  //对 fifo 读请求进行计数
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

  //将行列缩放因子进行寄存
  always@(posedge sys_clk )
  begin
    k_h_reg <= k_h;
    k_v_reg <= k_v;
  end

  //判断行是放大还是缩小
  always@(posedge sys_clk)
  begin
    if(k_h_reg[15:8] == 8'd0)
      scaler_up <= 1;
    else
      scaler_up <= 0;
  end

  //fifo 一行读完信号
  always@(posedge sys_clk)
  begin
    if(~rst_n)
      fifo_line_finish <= 0;
    else if((ram_v_waddr_d0 == s_width) && (ram_v_waddr_d1 == s_width - 1))
      fifo_line_finish <= 1;
    else
      fifo_line_finish <= 0;
  end

  //产生行 ram 写地址
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

  //产生行 ram 写使能
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

  //产生 ram 的写切换信号
  always@(posedge sys_clk)
  begin
    if(~rst_n || frame_flag)
      wr_buf_sel <= 1'b0;
    else if(fifo_line_finish)
      wr_buf_sel <= ~wr_buf_sel;
    else
      wr_buf_sel <= wr_buf_sel;
  end

  //对 fifo 读出数据的行数计数
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

  //对行缩放因子进行累加
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

  //产生行缩放不需要请求数据标志
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

  //对缩放后的行进行计数
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

  //产生 ram 数据首行写入使能
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

  //产生 ram 数据可读使能
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

  //产生最后一行标志信号
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

  //产生行 ram 读地址
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

  //产生行运算输入使能有效信号
  always@(posedge sys_clk)
  begin
    if(~rst_n)
      calu_v_data_in_en <= 0;
    else if(pixel_v_data_read_en_d0)
      calu_v_data_in_en <= 1;
    else
      calu_v_data_in_en <= 0;
  end

  //产生行缩放完成信号
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

  //对相邻的 2 行进行权重赋值
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

  //根据 ram 写切换使能对对应的行寄存器赋值
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

  //对读出的 fifo 数据通过 ram 进行存储
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


  //对读出的 fifo 数据通过 ram 进行存储
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

  //对行进行加权运算
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
  //产生列 ram 的写使能和数据
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

  //产生列 ram 的写地址
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

  //产生列 ram 数据可读使能

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

  //产生列 ram 的读地址
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

  //对列缩放因子进行累加
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
  //产生列运算输入使能有效信号
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

  //产生列缩放完成信号
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

  //产生列缩放未结束信号
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
  //对列运算的数据赋值
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

  //对相邻的 2 列进行权重赋值
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

  //对列运算后的信号进行输出寄存
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

  //对列运算输入使能进行计数
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

  //存放行缩放后的数据
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

  //对列进行加权运算
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
