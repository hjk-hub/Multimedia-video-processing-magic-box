module para_change(
    input clk_wr, //写时钟
    input clk_rd, //读时钟
    input [2:0] change_en, //切换信号,1 为放大,2 为缩小,4 为原图

    input [10:0] s_width, //缩放前宽度
    input [10:0] s_height, //缩放前高度

    input [10:0] t_width  ,//缩放后宽度
    input [10:0] t_height , //缩放后高度
    // input [2:0] change_en,

    input rst_n, //复位信号

    input rd_vsync, //读端场信号
    input wr_vsync, //写端场信号


    output reg [10:0] t_width_wr  , //写端缩放后宽度
    output reg [10:0] t_height_wr , //写端缩放后高度
    output reg [10:0] t_width_rd  , //读端缩放后宽度
    output reg [10:0] t_height_rd , //读端缩放后高度
    output reg [15:0] h_scale_k   , //列缩放因子
    output reg [15:0] v_scale_k   , //行缩放因子

    output reg [2:0] change_en_wr, //写端切换信号
    output reg [2:0] change_en_rd, //读端切换信号
    output reg [27:0] app_addr_rd_max, //存入 DDR3 的最大读地址
    output reg [7:0] rd_bust_len , //从 DDR3 中读数据时的突发长度
    output reg [27:0] app_addr_wr_max, //存入 DDR3 的最大写地址
    output reg [7:0] wr_bust_len //从 DDR3 中写数据时的突发长度

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
  reg delay_frame; //切换后写入一帧标志信号
  reg [2:0] change_rd_en_d0;
  reg [2:0] change_rd_en_d1;
  reg delay_frame_d0;
  // reg [15:0] h_scale_k; //(s_width * 256)/ t_width
  // reg [15:0] v_scale_k; //(s_height * 256)/ t_height
  reg [3:0] cmos_ps_cnt;

  //wire define
  wire [10:0] t_width_up; //放大后图像的宽度
  wire [10:0] t_height_up; //放大后图像的高度
  wire [10:0] t_width_down; //缩小后图像的宽度
  wire [10:0] t_height_down; //缩小后图像的高度
  wire para_finish;

  //*****************************************************
  //** main code
  //*****************************************************
  //放大后图像的分辨率
  // assign t_width_up = 11'd1024;
  // assign t_height_up = 11'd768;
  // //缩小后图像的分辨率
  // assign t_width_down = 11'd560;
  // assign t_height_down = 11'd400;

  //对写端输入信号进行寄存
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

  //对读端输入信号进行寄存
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

  //产生写端切换使能
  always@(posedge clk_wr)
  begin
    if(~rst_n)
      change_en_wr <= 1'b0;
    else if(wr_vsync_d[1] && ~wr_vsync_d[0])
      change_en_wr <= change_wr_en_d0;
    else
      change_en_wr <= change_en_wr;
  end

  //写端缩放后的分辨率
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

  //产生行场缩放因子
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

  //产生切换后写入一帧标志信号
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

  //产生写端的 ddr 参数
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

  //产生读端切换使能
  always@(posedge clk_rd)
  begin
    if(~rst_n)
      change_en_rd <= 1'b0;
    else if(rd_vsync_d[1] && ~rd_vsync_d[0] && ~delay_frame_d0)
      change_en_rd <= change_rd_en_d0;
    else
      change_en_rd <= change_en_rd;
  end

  //读端缩放后的分辨率
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

  //产生读端的 ddr 参数
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
