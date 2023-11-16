//**********************************************
module Frame_read
  #(
    `include"F:/Project/WorkSpace/FPGA/Video_pro/Source/top/global.vh"
   )
   (
     //
     input                               axi_aclk       ,
     input                               axi_aresetn    ,

     input wire                          Img_pclk_i       ,
     input wire                          Img_vs_i         ,
     input wire                          Img_de_i         ,

     output wire                         Img_pclk_o       ,
     output wire                         Img_vs_o         ,
     output wire                         Img_de_o         ,
     output wire   [15:0]                Img_data_o       ,

     output wire                         rd_burst_req     ,   
     output wire  [7:0]                  rd_burst_len     ,
     output wire  [27:0]                 rd_burst_addr    ,
     input wire                          rd_burst_data_valid,//fifo_en
     input wire  [255:0]                 rd_burst_data    ,//fifo_data
     input wire                          rd_burst_finish  ,//done

     //指令
     input wire            		           write_index       
   );
   
   //
   localparam IDLE             = 8'd0;
   localparam START            = 8'd1;
   localparam WAIT             = 8'd2;
   localparam LINE_WAIT        = 8'd3;
   localparam LINE_DONE        = 8'd4;
   localparam DONE             = 8'd5;
/*
*
*/
reg Img_de_i_d1 ;

reg                         rd_burst_req_r   ; 
reg  [7:0]                  rd_burst_len_r   ; 
reg  [27:0]                 rd_burst_addr_r  ; 
// wire                          rd_burst_data_valid
// wire  [255:0]                 rd_burst_data    
// wire                          rd_burst_finish  
//
  wire        fifo_rd_en_16o  ;
  wire [15:0] fifo_rd_data_16o;
  wire        empty           ;
  wire [10:0] wr_water_level  ; 

  //
  reg Img_vs_i_d1,Img_vs_i_d2;
  wire Img_vs_i_pose;
  wire Img_vs_i_neg;
//
  reg [7:0] state;
  // reg [27:0] addr
/*
*
*/
assign Img_pclk_o = Img_pclk_i;
assign Img_vs_o   = Img_vs_i;
assign Img_de_o   = Img_de_i_d1;

assign Img_vs_i_pose = Img_vs_i_d1 & (~Img_vs_i_d2);
assign Img_vs_i_neg = (~Img_vs_i_d1) & (Img_vs_i_d2);

assign rd_burst_req   = rd_burst_req_r  ;
assign rd_burst_len   = rd_burst_len_r  ;
assign rd_burst_addr  = rd_burst_addr_r ;

//debug
/*
*
*/
reg fifo_rd_en_16o_d1;
assign fifo_rd_en_16o = empty?1'b0:1'b1;

always @(posedge Img_pclk_i)begin
  if(Img_vs_i)begin
    fifo_rd_en_16o_d1 <= 16'd0;
  end
  else begin
    fifo_rd_en_16o_d1 <= fifo_rd_en_16o;
  end
end

always @(posedge Img_pclk_i)begin
  if(Img_vs_i)begin
    Img_de_i_d1 <= 1'b0;
  end
  else begin
    Img_de_i_d1 <= Img_de_i;
  end
end
//debug
// reg [31:0] cnt;
  
// reg [15:0] mem1 [0:IMG_ROW] [0:IMG_COL];

// integer m,n;
// initial
// begin
//   cnt = 0;
//   for (m=0; m<=IMG_ROW; m=m+1)
//     for (n=0; n<=IMG_COL; n=n+1)
//         mem1[m][n] =0;

//   repeat(10) @ (negedge Img_vs_i)begin
//     cnt = cnt + 1;
//     $display("cnt time %d!!!", cnt);
//     // $stop;
//   end
// end
// integer i,j;
// always @(posedge Img_pclk_i)begin
//   if(Img_vs_i)begin
//     i <= 0;
//     j <= 0;
//   end
//   else begin
//     if(cnt >= 2)begin
//       if(Img_de_o)begin//fifo_rd_en_16o_d1)begin
//         j <= j + 1;
//         if(j == IMG_COL-1)begin
//           j <= 0;
//           i <= i + 1;
//         end
//         mem1[i][j] = Img_data_o;//fifo_rd_data_16o;
//       end
//     end 
//     else begin
//       i <= 0;
//       j <= 0;
//     end
      
//   end
// end

//
always@(posedge axi_aclk)
begin
  if(!axi_aresetn)
  begin
    Img_vs_i_d1    <=  1'b0;
    Img_vs_i_d2    <=  1'b0;
  end
  else
  begin
    Img_vs_i_d1    <=  Img_vs_i;
    Img_vs_i_d2    <=  Img_vs_i_d1;
  end 
end

always@(posedge axi_aclk)
begin
  if((!axi_aresetn) | Img_vs_i_pose)
  begin
    rd_burst_req_r <= 1'b0;
    rd_burst_len_r <= 8'd16;
    rd_burst_addr_r<= 28'd0;

    state    <=  IDLE;
  end
  else
    begin
      case(state)
      IDLE:begin
        if(Img_vs_i_neg)begin
          if(~write_index)begin
            rd_burst_req_r <= 1'b0;
            rd_burst_len_r <= 8'd16;
            rd_burst_addr_r<= Base_addr2_1;
          end
          else begin
            rd_burst_req_r <= 1'b0;
            rd_burst_len_r <= 8'd16;
            rd_burst_addr_r<= Base_addr1_1;            
          end
          state    <=  START;
        end
        else begin       
          state    <=  IDLE;
        end
      end
      START:begin
        if(wr_water_level <= 32)begin
          rd_burst_req_r <= 1'b1;
          rd_burst_len_r <= 8'd16;
          rd_burst_addr_r<= rd_burst_addr_r;  
          state    <=  WAIT;
        end
        else begin
          // rd_burst_req_r <= 1'b0;
          state    <=  START;
        end
      end
      WAIT:begin
        if(rd_burst_finish)begin
          // $stop;
          rd_burst_req_r <= 1'b0;
          rd_burst_len_r <= 8'd16;
          rd_burst_addr_r<= rd_burst_addr_r + 128;  
          state    <=  START;
        end
        else begin
          // rd_burst_req_r <= 1'b0;
          state    <=  WAIT;
        end
      end
      default:state    <=  IDLE;
    endcase
   end
end
/*
*
*/
fifo_256i_16O u_fifo_256i_16O_axiRd (
  .wr_clk         (axi_aclk             ),
  .wr_rst         (~axi_aresetn  | Img_vs_i_pose),
  .wr_en          (rd_burst_data_valid    ),
  .wr_data        (rd_burst_data        ),
  .wr_full        (                     ),
  .wr_water_level (wr_water_level       ),
  .almost_full    (                     ),
  .rd_clk         (Img_pclk_i           ),
  .rd_rst         (Img_vs_i             ),
  .rd_en          (Img_de_i             ),//fifo_rd_en_16o),//
  .rd_data        (Img_data_o           ),//fifo_rd_data_16o),//
  .rd_empty       (empty                ),
  .rd_water_level (                     ),
  .almost_empty   (                     ) 
);




endmodule
