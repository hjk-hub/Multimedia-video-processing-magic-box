module rotame_dispose(
    input cam_pclk,
    input rst_n,
    input [3:0] change_en, //1：旋转 90 2：旋转 180 4：旋转 270 8: 不旋转
    input [9:0] t_width, //宽度
    input [9:0] t_high, //高度
    //图像输入信号
    input cmos_frame_vsync, //输入场信号
    input cmos_frame_href, //输入行信号
    input cmos_frame_valid, //输入数据有效信号
    input [15:0] cmos_frame_data, //输入数据

    //图像输出信号
    output frame_valid_out, //输出数据有效信号
    output [15:0] frame_data_out //输出数据
  );

  //reg define
  reg cmos_frame_vsync_d0;
  reg cmos_frame_href_d0;
  reg cmos_frame_vsync_d1;
  reg cmos_frame_href_d1;
  reg [3:0] change_en_d0;
  reg rd_en_d0;
  reg [13:0] waddr; //ram 写地址
  reg [13:0] raddr; //ram 读地址
  reg [15:0] frame_data_out; //输出数据有效信号
  reg frame_valid_out; //输出数据
  reg rd_en; //读使能信号

  //wire define
  wire hs_nege; //行信号下降沿
  wire vs_nege; //场信号下降沿
  wire rd_en_nege; //读使能信号下降沿
  wire [15:0] ram_dout; //ram 输出数据

  //*****************************************************
  //** main code
  //*****************************************************

  //行信号下降沿
  assign hs_nege = ~cmos_frame_href_d0 && cmos_frame_href_d1;

  //场信号下降沿
  assign vs_nege = ~cmos_frame_vsync_d0 && cmos_frame_vsync_d1;

  //读使能信号下降沿
  assign rd_en_nege = ~rd_en && rd_en_d0;

  //输入打拍
  always @(posedge cam_pclk or negedge rst_n)
  begin
    if(!rst_n)
    begin
      cmos_frame_vsync_d0 <= 1'b0;
      cmos_frame_href_d0 <= 1'b0;
      cmos_frame_vsync_d1 <= 1'b0;
      cmos_frame_href_d1 <= 1'b0;
      change_en_d0 <= 4'b0;
      rd_en_d0 <= 1'b0;
    end
    else
    begin
      cmos_frame_vsync_d0 <= cmos_frame_vsync;
      cmos_frame_href_d0 <= cmos_frame_href;
      cmos_frame_vsync_d1 <= cmos_frame_vsync_d0;
      cmos_frame_href_d1 <= cmos_frame_href_d0;
      change_en_d0 <= change_en;
      rd_en_d0 <= rd_en;
    end
  end

  //产生写地址
  always @(posedge cam_pclk or negedge rst_n)
  begin
    if(!rst_n)
      waddr <= 14'b0;
    else
    begin
      if(vs_nege)
        waddr[9:0] <= 10'b0;
      else if(cmos_frame_href)
      begin
        if(cmos_frame_valid)
          waddr[9:0] <= waddr[9:0] + 1; //存同一行数据
        else
          waddr[9:0] <= waddr[9:0];
      end
      else
      begin
        waddr[9:0] <= 0;
      end

      if(vs_nege)
        waddr[12:10] <= 3'b0;
      else if(hs_nege)
      begin
        if(waddr[12:10] == 3'd7)
          waddr[12:10] <= 0;
        else
          waddr[12:10] <= waddr[12:10] + 1; //区分 8 行数据
      end
      else
      begin
        waddr[12:10] <= waddr[12:10];
      end

      if(vs_nege)
        waddr[13] <= 0;
      else if(hs_nege)
      begin
        if(waddr[12:10] == 3'd7)
          waddr[13] <= ~waddr[13]; //乒乓操作
        else
          waddr[13] <= waddr[13];
      end
      else
      begin
        waddr[13] <= waddr[13];
      end
    end
  end

  //产生读使能信号
  always @(posedge cam_pclk or negedge rst_n)
  begin
    if(!rst_n)
      rd_en <= 1'b0;
    else
    begin
      if(vs_nege)
        rd_en <= 0; //一行读完拉低读使能
      else if( (raddr[9:0] == t_width - 1) && change_en_d0 == 4'd8 )
        rd_en <= 0; //八行读完拉低读使能
      else if(change_en_d0==4'd1 && raddr[12:10]==3'd0 && (raddr[9:0]==t_width - 1))
        rd_en <= 0; //八行读完拉低读使能
      else if(change_en_d0 == 4'd4 && raddr[12:10] == 3'd7 && (raddr[9:0] == 0))
        rd_en <= 0; //一行读完拉低读使能
      else if(change_en_d0 == 4'd2 && raddr[9:0] == 0)
        rd_en <= 0;
      else if(hs_nege)
        if(change_en_d0 == 4'd1 || change_en_d0 == 4'd4)
          if(waddr[12:10] == 3'd7 ) //写满 8 行拉高读使能
            rd_en <= 1;
          else
            rd_en <= rd_en;
        else
          rd_en <= 1; //写完一行拉高读使能
      else
        rd_en <= rd_en;
    end
  end

  //产生读地址
  always @(posedge cam_pclk or negedge rst_n)
  begin
    if(!rst_n)
      raddr <= 14'b0;
    else
    begin
      case(change_en_d0)
        4'd1 :
        begin //旋转 90
          if(vs_nege)
            raddr[9:0] <= 10'b0;
          else if(rd_en)
          begin
            if(raddr[12:10] == 3'd0)
              raddr[9:0] <= raddr[9:0] + 1; //存同一行数据
            else
              raddr[9:0] <= raddr[9:0];
          end
          else
          begin
            raddr[9:0] <= 0;
          end

          if(vs_nege)
            raddr[12:10] <= 7;
          else if(rd_en)
          begin
            raddr[12:10] <= raddr[12:10] - 1;//每次读每行的同一列数据
          end
          else
          begin
            raddr[12:10] <= 7;
          end

          if(vs_nege)
            raddr[13] <= 1;
          else if(hs_nege)
          begin
            if(waddr[12:10] == 3'd7)
              raddr[13] <= ~raddr[13]; //乒乓操作
            else
              raddr[13] <= raddr[13];
          end
          else
          begin
            raddr[13] <= raddr[13];
          end

        end
        4'd2 :
        begin //旋转 180
          if(vs_nege)
            raddr[9:0] <= t_width - 1;
          else if(rd_en)
          begin
            raddr[9:0] <= raddr[9:0] - 1; //倒读一行数据
          end
          else
          begin
            raddr[9:0] <= t_width - 1;
          end

          if(vs_nege)
            raddr[13:10] <= 4'b0;
          else if(rd_en_nege)
          begin
            if(raddr[13:10] == 4'd15)
              raddr[13:10] <= 0;
            else
              raddr[13:10] <= raddr[13:10] + 1; //区分 8 行
          end
          else
          begin
            raddr[13:10] <= raddr[13:10];
          end

        end
        4'd4 :
        begin //旋转 270
          if(vs_nege)
            raddr[9:0] <= t_width - 1;
          else if(rd_en)
          begin
            if(raddr[12:10] == 3'd7)
              raddr[9:0] <= raddr[9:0] - 1; //存同一行数据
            else
              raddr[9:0] <= raddr[9:0];
          end
          else
          begin
            raddr[9:0] <= t_width - 1;
          end


          if(vs_nege)
            raddr[12:10] <= 0;
          else if(rd_en)
          begin
            raddr[12:10] <= raddr[12:10] + 1;//每次读每行的同一列数据
          end
          else
          begin
            raddr[12:10] <= 0;
          end


          if(vs_nege)
            raddr[13] <= 1;
          else if(hs_nege)
          begin
            if(waddr[12:10] == 3'd7)
              raddr[13] <= ~raddr[13]; //乒乓操作
            else
              raddr[13] <= raddr[13];
          end
          else
          begin
            raddr[13] <= raddr[13];
          end
        end
        4'd8 :
        begin //原图
          if(vs_nege)
            raddr[9:0] <= 10'b0;
          else if(rd_en)
          begin
            raddr[9:0] <= raddr[9:0] + 1; //读同一行数据
          end
          else
          begin
            raddr[9:0] <= 0;
          end

          if(vs_nege)
            raddr[13:10] <= 4'b0;
          else if(rd_en_nege)
          begin
            if(raddr[13:10] == 4'd15)
              raddr[13:10] <= 0;
            else
              raddr[13:10] <= raddr[13:10] + 1; //区分 8 行
          end
          else
          begin
            raddr[13:10] <= raddr[13:10];
          end
        end
        default :
          ;
      endcase
    end
  end

  //产生输出信号
  always @(posedge cam_pclk or negedge rst_n)
  begin
    if(!rst_n)
    begin
      frame_data_out <= 10'b0;
      frame_valid_out <= 10'b0;
    end
    else
    begin
      frame_data_out <= ram_dout;
      frame_valid_out <= rd_en_d0;
    end
  end


  ram_16384x16 u_ram_16384x16 (
                 .clka(cam_pclk),
                 .wea(cmos_frame_valid),
                 .addra(waddr),
                 .dina(cmos_frame_data),
                 .clkb(cam_pclk),
                 .addrb(raddr),
                 .doutb(ram_dout)
               );

endmodule
