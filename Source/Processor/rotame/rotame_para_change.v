module rotame_para_change(
    input clk_wr, //写时钟
    input clk_rd, //读时钟
    input [3:0] change_en, //1：旋转 90 2：旋转 180 4：旋转 270 8: 不旋转
    input rst_n, //复位信号


    input rd_vsync, //读端场信号
    input wr_vsync, //写端场信号
    input [10:0] s_width, //原图宽度
    input [10:0] s_height, //原图高度

    output [10:0] t_width_wr, //写端宽度
    output [10:0] t_height_wr, //写端高度
    output [10:0] t_width_rd, //读端缩放后宽度
    output [10:0] t_height_rd, //读端缩放后高度
    output [3:0] change_en_wr, //写端切换信号
    output [3:0] change_en_rd, //读端切换信号
    output [27:0] app_addr_rd_max, //存入 DDR3 的最大读地址
    output [7:0] rd_bust_len , //从 DDR3 中读数据时的突发长度
    output [27:0] app_addr_wr_max, //存入 DDR3 的最大写地址
    output [7:0] wr_bust_len, //从 DDR3 中写数据时的突发长度
    output wr_vsync_out, //写端场信号输出
    output rd_vsync_out //读端场信号输出

  );

  //reg define
  reg [27:0] app_addr_rd_max;
  reg [7:0] rd_bust_len;
  reg [7:0] rd_vsync_d;
  reg [7:0] wr_vsync_d;
  reg [10:0] t_width_rd;
  reg [10:0] t_height_rd;
  reg [10:0] s_width_wr;
  reg [10:0] s_height_wr;
  reg [10:0] s_width_rd;
  reg [10:0] s_height_rd;
  reg [3:0] change_wr_en_d1;
  reg [3:0] change_en_wr_d0;
  reg [3:0] change_en_wr;
  reg [3:0] change_en_rd;
  reg [3:0] change_wr_en_d0;
  reg delay_frame; //切换后写入一帧标志信号
  reg [3:0] change_rd_en_d0;
  reg [3:0] change_rd_en_d1;
  reg delay_frame_d0;

  reg [3:0] cmos_ps_cnt;

  //wire define
  wire wr_vsync_out;
  wire rd_vsync_out;
  wire [10:0] t_width_wr;
  wire [10:0] t_height_wr;
  wire [27:0] app_addr_wr_max;
  wire [7:0] wr_bust_len;

  //*****************************************************
  //** main code
  //*****************************************************

  assign wr_vsync_out = wr_vsync_d[7];
  assign rd_vsync_out = rd_vsync_d[7];
  assign t_width_wr = s_width_wr;
  assign t_height_wr = s_height_wr;
  assign app_addr_wr_max = s_width_wr * s_height_wr;
  assign wr_bust_len = s_width_wr[10:3];


  //对写端输入信号进行寄存
  always@(posedge clk_wr )
  begin
    wr_vsync_d <= {wr_vsync_d[6:0],wr_vsync };
    change_wr_en_d0 <= change_en;
    change_wr_en_d1 <= change_wr_en_d0;
    change_en_wr_d0 <= change_en_wr;
    s_width_wr <= s_width;
    s_height_wr <= s_height;
  end

  //对读端输入信号进行寄存
  always@(posedge clk_rd )
  begin
    rd_vsync_d <= {rd_vsync_d[6:0],rd_vsync };
    change_rd_en_d0 <= change_en;
    change_rd_en_d1 <= change_rd_en_d0;
    delay_frame_d0 <= delay_frame;
    s_width_rd <= s_width;
    s_height_rd <= s_height;
  end


  //产生写端切换使能
  always@(posedge clk_wr or negedge rst_n)
  begin
    if(~rst_n)
      change_en_wr <= 4'd8;
    else if(wr_vsync_d[1] && ~wr_vsync_d[0])
      change_en_wr <= change_wr_en_d0;
    else
      change_en_wr <= change_en_wr;
  end

  //产生切换后写入一帧标志信号
  always@(posedge clk_wr or negedge rst_n)
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

  //产生读端切换使能
  always@(posedge clk_rd or negedge rst_n)
  begin
    if(~rst_n)
      change_en_rd <= 4'd8;
    else if(rd_vsync_d[1] && ~rd_vsync_d[0] && ~delay_frame_d0)
      change_en_rd <= change_rd_en_d0;
    else
      change_en_rd <= change_en_rd;
  end

  //读端旋转的分辨率
  always@(posedge clk_wr or negedge rst_n)
  begin
    if(~rst_n)
    begin
      t_width_rd <= s_width_rd;
      t_height_rd <= s_height_rd;
    end
    else if( rd_vsync_d[3] && ~rd_vsync_d[2] && ~delay_frame_d0)
    begin
      if(change_en_wr[0] || change_en_wr[2])
      begin

        t_width_rd <= s_height_rd;
        t_height_rd <= s_width_rd;
      end
      else
      begin
        t_width_rd <= s_width_rd;
        t_height_rd <= s_height_rd;
      end
    end
    else
    begin
      t_width_rd <= t_width_rd;
      t_height_rd <= t_height_rd;
    end
  end

  //产生读端的 ddr 参数
  always@(posedge clk_rd or negedge rst_n)
  begin
    if(~rst_n)
    begin
      rd_bust_len <= t_width_rd[10:3];
      app_addr_rd_max <= t_width_rd * t_height_rd;
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
