//
module udp_char(

    input   wire               rst_n              ,
    input   wire               udp_data_clk       ,

    // output                     udp_send_en        ,
    // input   wire               udp_send_fifo_en   ,
    // output   wire    [7:0]     udp_send_fifo_data ,
    // output   wire              udp_send_fifo_empty,
    // output   wire  [15:0]      udp_send_data_length   ,

    input   wire               udp_rec_data_valid ,
    input   wire [7:0]         udp_rec_rdata      ,
    input   wire [15:0]        udp_rec_data_length,



    output                    udp_clk          ,
    output  reg               udp_vs/* synthesis syn_preserve = 1 */,
    output  wire              udp_de          ,
    output  wire [15:0]       udp_data

  );
  localparam IDLE             = 4'd0;
  localparam GEN_VS           = 4'd1;
  localparam GEN_DE_1         = 4'd2;
  localparam GEN_DE_2         = 4'd3;
  localparam GEN_DE_3         = 4'd4;
  // localparam LINE_WAIT        = 4'd3;
  // localparam LINE_DONE        = 4'd4;
  // localparam DONE             = 4'd5;
  //
  reg udp_rec_data_valid_d1,udp_rec_data_valid_d2,udp_rec_data_valid_d3,udp_rec_data_valid_d4;
  wire udp_rec_data_valid_neg;
  wire udp_rec_data_valid_pos;


  reg    [15:0] rd_cnt       ;

  reg           rd_en/* synthesis syn_preserve = 1 */;
  reg           rd_en_d1;
  wire   [15:0] rd_data/*synthesis PAP_MARK_DEBUG="1"*/;
  
  // reg    rd_empty      ;
  wire    [13:0] rd_water_level/*synthesis PAP_MARK_DEBUG="1"*/;
  // reg    almost_empty  ;

  //
  reg [3:0] state/* synthesis syn_preserve = 1 */;
  reg [11:0] cnt;

  /************************************************************/
  assign udp_clk = udp_data_clk;

  assign udp_send_data_length = udp_rec_data_length;
  assign udp_rec_data_valid_neg = udp_rec_data_valid_d4 & (~udp_rec_data_valid_d3);
  // assign udp_rec_data_valid_pos = udp_rec_data_valid_d1 & (~udp_rec_data_valid_d2);

  assign udp_send_en = 1'b0;

  assign udp_de = rd_en_d1;
  assign udp_data = rd_data;
//   always @(posedge udp_data_clk)
//   begin
//     if (~rst_n)
//     begin
//         udp_send_en  <=  1'b0  ;
//         // udp_send_data_length <= 'd0;
//     end
//     else
//     begin
//       if((~udp_send_en)& udp_rec_data_valid_neg) begin
//         udp_send_en  <=  1'b1  ;    
//       end
//       else if(udp_send_en & udp_send_fifo_empty) begin
//         udp_send_en  <=  1'b0  ;
//       end
//       else begin
//         udp_send_en  <=  udp_send_en  ;
//       end

//       // if(udp_rec_data_valid_pos)
//       // begin
//       //   udp_send_data_length <= udp_rec_data_length;
//       // end
//       // else begin
//       //   udp_send_data_length <= udp_send_data_length;
//       // end
//   end
// end

  always @(posedge udp_data_clk)
  begin
    if (~rst_n)
    begin
      udp_rec_data_valid_d1  <=  1'b0  ;
      udp_rec_data_valid_d2  <=  1'b0  ;
      udp_rec_data_valid_d2 <= 1'b0  ;
      udp_rec_data_valid_d2 <= 1'b0  ;
      rd_en_d1   <= 1'b0;
    end
    else
    begin
      udp_rec_data_valid_d1 <= udp_rec_data_valid  ;
      udp_rec_data_valid_d2 <= udp_rec_data_valid_d1  ;
      udp_rec_data_valid_d3 <= udp_rec_data_valid_d2  ;
      udp_rec_data_valid_d4 <= udp_rec_data_valid_d3  ;

      rd_en_d1 <= rd_en;
    end
  end



  //
  always @(posedge udp_data_clk)
  begin
    if(!rst_n)
    begin
      state    <=  IDLE;
      cnt      <= 12'd0;
      udp_vs   <= 1'b0;
      rd_cnt   <= 16'd0;
      rd_en    <= 1'b0;
    end
    else
    begin
      case(state)
      IDLE:begin
        udp_vs          <= 1'b0;
        rd_en           <= 1'b0; 
        cnt             <= 12'd0; 
        if((udp_rec_data_valid_neg==1'b1)&&(udp_rec_data_length == 16'd4))  begin
          state           <=  GEN_VS;           
        end
        else begin
          state    <=  IDLE;
        end
      end
      GEN_VS:begin
        cnt             <= cnt + 12'd1;
        udp_vs          <= 1'b1;
        if(cnt >= 12'd20)  begin
          state           <=  GEN_DE_1;
          cnt             <= 12'd0;  
          rd_cnt          <= 16'd0;    
        end
        else begin
          state    <=  GEN_VS;
        end
      end
      GEN_DE_1:begin
        udp_vs          <= 1'b0;

        if(cnt >= 12'd720)begin
          state    <=   IDLE;
        end
        else if(rd_water_level >= 14'd1280)begin
            state    <=  GEN_DE_2;
            rd_cnt   <= 16'd0;
        end
        else begin
          state    <=  GEN_DE_1;
        end
      end

      GEN_DE_2:begin
        udp_vs          <= 1'b0;
        rd_cnt          <= rd_cnt + 16'd1;

        if(rd_cnt <= 16'd1280 - 1)begin
          state    <=  GEN_DE_2;
          rd_en    <= 1'b1;
        end
        else begin
          state    <=  GEN_DE_3;
          rd_en    <= 1'b0;
          rd_cnt   <= 16'd0;
        end
      end
      GEN_DE_3:begin
        rd_cnt          <= rd_cnt + 16'd1;
        rd_en    <= 1'b0;
        if(rd_cnt <= 16'd4)begin
          state    <=  GEN_DE_3;
        end
        else begin
          state    <=  GEN_DE_1;
          cnt      <= cnt + 12'd1;
        end
      end

      default:state    <=  IDLE;
      endcase
    end
  end
  //

  fifo_8i_16o_14a u_fifo_8i_16o_14a (
    .wr_clk         (udp_data_clk  ),                    // input
    .wr_rst         (udp_vs         ),                    // input
    .wr_en          (udp_rec_data_valid          ),                      // input
    .wr_data        (udp_rec_rdata  ),                  // input [7:0]
    .wr_full        (               ),                  // output
    .wr_water_level (               ),    // output [14:0]
    .almost_full    (               ),          // output

    .rd_clk         (udp_clk         ),                    // input
    .rd_rst         (udp_vs         ),                    // input
    .rd_en          (rd_en          ),                      // input
    .rd_data        (rd_data        ),                  // output [15:0]
    .rd_empty       (               ),                // output
    .rd_water_level (rd_water_level ),    // output [13:0]
    .almost_empty   (               )         // output
  );



endmodule
