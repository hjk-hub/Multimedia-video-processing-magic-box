//使用AXI时钟，100Mhz
module mode_choice(

    input wire              clk     ,
    input wire              rst_n   ,

    input wire     [7:0]    key   ,
    output reg     [7:0]    led
  );

  localparam T_1ms = 100_000;

  reg [15:0] cnt;
  reg [7:0] flag;

  wire [7:0] key_val;
  reg [7:0] key_val_d1,key_val_d2;
  wire [7:0] key_pos;

  genvar i;
  generate
    for (i = 0 ; i < 8; i=i+1 )
    begin
      assign key_pos[i] = key_val_d1[i] & (~key_val_d2[i]);

    end

  endgenerate
  /***********************************/
  btn_deb_fix
    #(.BTN_WIDTH(4'd8))
    u_btn_deb_fix
    (
      .clk            (clk),  //12MHz
      .btn_in         (key),

      .btn_deb_fix    (key_val)
    );

  always @(posedge clk)
  begin
    if(!rst_n)
    begin
      key_val_d1 <= 8'd0;
      key_val_d2 <= 8'd0;
    end
    else
    begin
      key_val_d1 <= key_val;
      key_val_d2 <= key_val_d1;
    end
  end

    genvar j;
    generate
      for (j = 0 ; j < 8; j=j+1 )
      begin
        always @(posedge clk)
        begin
          if(!rst_n)
          begin
            led[j] <= 1'b0;
          end
          else if(led == 8'd255)
            led[j] <= 1'b0;
          else
          begin
            if(key_pos[j])
            begin
              led[j] <= ~led[j];
            end
            else
            begin
              led[j] <= led[j];
            end
          end
        end
      end
  endgenerate

  //   genvar i;
  //   generate
  //     for (i = 0 ; i < 8; i=i+1 )
  //     begin
  //       always @(posedge clk)
  //       begin
  //         if(!rst_n)
  //         begin
  //           flag[i] <= 1'b0;
  //         end
  //         else
  //         begin
  //           if((~key[i])&(~flag))
  //           begin
  //             flag[i] <= 1'b1;
  //           end
  //           else if(cnt >= T_1ms)
  //           begin
  //             led[i] <= ~led[i];
  //             flag[i] <= 1'b0;
  //           end
  //         end
  //       end
  //     end
  // endgenerate

  //     //   if((~key[i])&(~flag))
  //     //   begin
  //     //     flag[i] <= 1'b1;
  //     //   end
  //     //   else if(cnt == T_1ms)
  //     //   begin
  //     //     led[i] <= ~led[i];
  //     //     flag[i] <= 1'b0;
  //     //   end
  //     // end



  //   always @(posedge clk)
  //   begin
  //     if(!rst_n)
  //     begin
  //       //led <= 8'd0;
  //       //flag <= 8'd0;
  //       cnt <= 16'd0;
  //     end
  //     else
  //     begin
  //       if(flag == 8'd0)
  //       begin
  //         cnt <= 16'd0;
  //       end
  //       else
  //       begin
  //         cnt <= cnt + 16'd1;
  //       end
  //     end
  //   end



endmodule
