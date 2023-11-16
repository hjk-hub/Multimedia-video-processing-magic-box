//**********************************************
module Frame_write
#(
  //`include"F:/Project/WorkSpace/FPGA/Video_pro/Source/top/global.vh"
//输入视频源参数
parameter BURST_LEN = 16  ,//基本突发长度,其实也是最大突发程度,紫光50H DDR IP最大突发长度为16
// parameter IMG_COL   = 640 ,//输入视频源列长度
// parameter IMG_ROW   = 40  ,//输入视频源行长度
parameter IMG_COL   = 1280 ,//输入视频源列长度
parameter IMG_ROW   = 720  ,//输入视频源行长度
parameter SCALE     = 2   ,//缩放因子,输入缩放保存,以方便拼接,此处缩一倍,组成2*2,即四视频源拼接

parameter LINE_ADDR_ADD =   8*2*IMG_COL*16/256/SCALE  ,
parameter LINE_BURST_NUM =  IMG_COL*16/SCALE/256     ,

//四路输入视频,保存基地址,两个地址交替读写,乒乓操作
parameter Base_addr1_1 = 28'h000_0000                           ,
parameter Base_addr1_2 = Base_addr1_1 + IMG_COL / 4             ,
parameter Base_addr1_3 = Base_addr1_1 + IMG_COL * IMG_ROW / 4   ,
parameter Base_addr1_4 = Base_addr1_3 + IMG_COL / 4             ,

parameter Base_addr2_1 = 28'h010_0000                           ,
parameter Base_addr2_2 = Base_addr2_1 + IMG_COL / 4             ,
parameter Base_addr2_3 = Base_addr2_1 + IMG_COL * IMG_ROW / 4   ,
parameter Base_addr2_4 = Base_addr2_3 + IMG_COL / 4             ,

//DDR 物理接口
parameter MEM_ROW_ADDR_WIDTH   = 15   ,
parameter MEM_COL_ADDR_WIDTH   = 10   ,
parameter MEM_ADDR_WIDTH       = 15   ,
parameter MEM_BADDR_WIDTH      = 3    ,
parameter MEM_DQ_WIDTH         = 32   ,
parameter MEM_DM_WIDTH         = 4    ,
parameter MEM_DQS_WIDTH        = 4    ,
parameter CTRL_ADDR_WIDTH      = 28   ,
parameter MEM_NUM              = 2,//MEM_DQ_WIDTH/16,

//1. AXI总线
parameter AXI_ADDR_WIDTH	= 28 ,
parameter AXI_DATA_WIDTH    = 256,
parameter AXI_BURST_LEN	    = 16 ,
parameter AXI_ID_WIDTH		= 8  ,
// parameter  AXI_TARGET_SLAVE_BASE_ADDR	= 32'h00000000,
parameter AXI_AWUSER_WIDTH	= 0 ,
parameter AXI_ARUSER_WIDTH	= 0 ,
parameter AXI_WUSER_WIDTH	= 0 ,
parameter AXI_RUSER_WIDTH	= 0 ,
parameter AXI_BUSER_WIDTH	= 0 ,

//FIFO宽度
parameter FIFO_ADDR_WIDTH = 11         
 )
   (
     //
     input                               axi_aclk       ,
     input                               axi_aresetn    ,

     input wire                          Img_pclk       ,
     input wire                          Img_vs         ,
     input wire                          Img_de         ,
     input wire   [15:0]                 Img_data       ,

     output wire                         wr_burst_req     /*synthesis PAP_MARK_DEBUG="1"*/,   
     output wire  [7:0]                  wr_burst_len     /*synthesis PAP_MARK_DEBUG="1"*/,
     output wire  [27:0]                 wr_burst_addr    /*synthesis PAP_MARK_DEBUG="1"*/,
     input wire                          wr_burst_data_req,//fifo_en
     output wire  [255:0]                wr_burst_data    /*synthesis PAP_MARK_DEBUG="1"*/,//fifo_data
     input wire                          wr_burst_finish  ,//done

     //指令
     input wire  [27 : 0]  		           write_addr      ,
     input wire                          write_req       ,
     output wire                         write_done/*synthesis PAP_MARK_DEBUG="1"*/    
   );

  // localparam LINE_ADDR_ADD = 8*2*IMG_COL*16/256/SCALE;
  // localparam LINE_BURST_NUM = IMG_COL*16/SCALE/256;
 


  localparam IDLE             = 8'd0;
  localparam LINE_START       = 8'd1;
  localparam LINE_CNT         = 8'd2;
  localparam LINE_WAIT        = 8'd3;
  localparam LINE_DONE        = 8'd4;
  localparam DONE             = 8'd5;
  // localparam WAIT             = 8'd2;
  // localparam DONE             = 8'd3;
  //
 reg                        wr_burst_req_r     ;
 reg [7:0]                  wr_burst_len_r     ;
 reg [27:0]                 wr_burst_addr_r/* synthesis syn_preserve = 1 */    ;
 reg [27:0]                 wr_burst_addr_r_temp;

  reg write_done_r;

  //
  reg         write_req_d1,write_req_d2 ;
  reg         Img_de_d1,Img_de_d2       ;
  wire        write_req_pose            ;
  wire        Img_de_pose               ;
  reg [15:0]  Img_de_cnt                ;

  reg [15:0]  line_cnt                  ;
  reg [15:0]  burst_cnt                 ;
  //fifo
  wire        fifo_wr_en_16i  ;
  wire [15:0] fifo_wr_data_16i;
  wire [10:0] rd_water_level  ;

  //
  reg [3:0]   state/* synthesis syn_preserve = 1 */;
  //
  assign   write_done = write_done_r;
  assign   wr_burst_req = wr_burst_req_r ;
  assign   wr_burst_len = wr_burst_len_r ;
  assign   wr_burst_addr= wr_burst_addr_r;
   
  




  assign write_req_pose = write_req_d1 & (~write_req_d2);
  assign Img_de_pose = Img_de_d1 & (~Img_de_d2);
  //
  always@(posedge axi_aclk)
  begin
    if(!axi_aresetn)
    begin
      write_req_d1    <=  1'b0;
      write_req_d2    <=  1'b0;

      Img_de_d1    <=  1'b0;
      Img_de_d2    <=  1'b0;

    end
    else
    begin
      write_req_d1    <=  write_req   ;
      write_req_d2    <=  write_req_d1;

      Img_de_d1    <=  Img_de;
      Img_de_d2    <=  Img_de_d1;
    end 
  end
//
  always@(posedge axi_aclk)
  begin
    if(!axi_aresetn)
    begin
      Img_de_cnt    <=  16'd0;
    end
    else
    begin
      if(write_req_pose)begin
        Img_de_cnt    <=  16'd0;
      end
      else if(Img_de_pose)begin
        Img_de_cnt    <=  Img_de_cnt + 16'd1;
      end
    end 
  end
//
  always@(posedge axi_aclk)
  begin
    if(!axi_aresetn)
    begin
      state    <=  IDLE;
      wr_burst_req_r  <= 1'b0;
      wr_burst_len_r  <= 8'd16;
      wr_burst_addr_r <= 28'd0;

      write_done_r <= 1'b0;

      line_cnt        <= 16'd0;
      burst_cnt       <= 16'd0;
      wr_burst_addr_r_temp <= 28'd0;
    end
    else
    begin
      case(state)
      IDLE:begin
        write_done_r <= 1'b0;
        if(write_req_pose)  begin
          state           <=  LINE_START;
          wr_burst_req_r  <= 1'b0       ;
          wr_burst_len_r  <= 8'd16      ;
          wr_burst_addr_r <= write_addr ;
          wr_burst_addr_r_temp <= write_addr;
          line_cnt        <= 16'd0      ;
          burst_cnt       <= 16'd0      ;
        end
        else begin
          state    <=  IDLE;
        end
      end
      LINE_START:begin
        // wr_burst_addr_r_temp = wr_burst_addr_r;
        burst_cnt       <= 16'd0      ;
        state           <=  LINE_CNT;
      end

      LINE_CNT:begin
        // if(rd_water_level >= LINE_BURST_NUM)begin//if(LINE_BURST_NUM <= BURST_LEN && rd_water_level >= LINE_BURST_NUM)
        //   wr_burst_req_r  <= 1'b1                ;
        //   wr_burst_len_r  <= LINE_BURST_NUM      ;
        //   wr_burst_addr_r <= wr_burst_addr_r_temp;
        //   burst_cnt <= LINE_BURST_NUM            ;
        //   state     <=  LINE_WAIT                ;          
        // end
        // else if(rd_water_level >= BURST_LEN && burst_cnt <= LINE_BURST_NUM - BURST_LEN)begin
        //   wr_burst_req_r  <= 1'b1                ;
        //   wr_burst_len_r  <= BURST_LEN           ;
        //   wr_burst_addr_r <= wr_burst_addr_r_temp + {burst_cnt[15:0],3'd0} ;
        //   burst_cnt <= burst_cnt + BURST_LEN     ;
        //   state    <=  LINE_WAIT                 ;          
        // end
        // else if(LINE_BURST_NUM - burst_cnt < BURST_LEN && LINE_BURST_NUM >= BURST_LEN
        //             && rd_water_level >= LINE_BURST_NUM - burst_cnt)begin
        //   wr_burst_req_r  <= 1'b1                                 ;
        //   wr_burst_len_r  <= LINE_BURST_NUM - burst_cnt           ;
        //   wr_burst_addr_r <= wr_burst_addr_r_temp + {burst_cnt[15:0],3'd0} ;
        //   burst_cnt <= LINE_BURST_NUM            ;
        //   state    <=  LINE_WAIT                 ; 
        // end
        // else begin
        //   state    <=  LINE_CNT                  ; 
        // end
        if(burst_cnt <= 16)begin
          if(rd_water_level >= BURST_LEN)begin
              wr_burst_req_r  <= 1'b1           ;
              wr_burst_len_r  <= BURST_LEN      ;
              wr_burst_addr_r <= wr_burst_addr_r_temp + {burst_cnt[15:0],3'd0};
              burst_cnt <= BURST_LEN  +   burst_cnt   ;
              state     <=  LINE_WAIT                ;                 
          end
          else begin
              state    <=  LINE_CNT                  ; 
          end          
        end
        else begin
          if(rd_water_level >= 8)begin
            wr_burst_req_r  <= 1'b1                ;
            wr_burst_len_r  <= 8      ;
            wr_burst_addr_r <= wr_burst_addr_r_temp + {burst_cnt[15:0],3'd0};
            burst_cnt <= LINE_BURST_NUM            ;
            state     <=  LINE_WAIT                ;                 
        end
        else begin
            state    <=  LINE_CNT                  ; 
        end            
        end
      end
      
      LINE_WAIT:begin
        // wr_burst_req_r  <= 1'b0       ;
        if(wr_burst_finish)  begin
       //   $stop;
          wr_burst_req_r  <= 1'b0       ;
          if(burst_cnt == LINE_BURST_NUM )begin
            state    <=  LINE_DONE;
            line_cnt        <= line_cnt + 16'd1      ;
            burst_cnt       <= 16'd0                 ;
          end
          else
            state    <=  LINE_CNT;
        end
        else begin
          state    <=  LINE_WAIT;
        end
      end
      LINE_DONE:begin
        if(line_cnt >= IMG_ROW/SCALE)
            state    <=  DONE;
        else begin
            // $stop;
            state    <=  LINE_START;
        end
        wr_burst_addr_r_temp <= wr_burst_addr_r_temp + LINE_ADDR_ADD;
      end
      DONE:begin
        // $stop;
        write_done_r <= 1'b1;
        state    <=  IDLE;
      end
      default:state    <=  IDLE;
      endcase
  end
end
/*
*
*/
Frame_cnt # (
  .IMG_ROW(IMG_ROW),
  .IMG_COL(IMG_COL)
)
u_Frame_cnt (
  .rst_n          (~Img_vs),
  .Img_pclk       (Img_pclk),
  .Img_de         (Img_de),
  .Img_data       (Img_data),
  .fifo_wr_en     (fifo_wr_en_16i),
  .fifo_wr_data   (fifo_wr_data_16i)
); 

fifo_16i_256O u_fifo_16i_256O_axiWr (
  .wr_clk         (Img_pclk             ),
  .wr_rst         (Img_vs               ),
  .wr_en          (fifo_wr_en_16i       ),
  .wr_data        (fifo_wr_data_16i     ),
  .wr_full        (                     ),
  .wr_water_level (                     ),
  .almost_full    (                     ),
  .rd_clk         (axi_aclk             ),
  .rd_rst         (~axi_aresetn         ),
  .rd_en          (wr_burst_data_req    ),
  .rd_data        (wr_burst_data        ),
  .rd_empty       (                     ),
  .rd_water_level (rd_water_level       ),
  .almost_empty   (                     ) 
);
/*
*
*/
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

//   repeat(10) @ (negedge Img_vs)begin
//     cnt = cnt + 1;
//     $display("cnt time %d!!!", cnt);
//     // $stop;
//   end
// end
// integer i,j;
// always @(posedge Img_pclk or negedge Img_vs)begin
//   if(Img_vs)begin
//     i <= 0;
//     j <= 0;
//   end
//   else begin
//     if(cnt == 2)begin
//       if(fifo_wr_en_16i)begin
//         j <= j + 1;
//         if(j == IMG_COL/SCALE-1)begin
//           j <= 0;
//           i <= i + 1;
//         end
//         mem1[i][j] = fifo_wr_data_16i;
//       end
//     end 
//     else begin
//       i <= 0;
//       j <= 0;
//     end
      
//   end
// end

endmodule
