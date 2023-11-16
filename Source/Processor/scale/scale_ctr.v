module scale_ctr
  #(
`include"F:/Project/WorkSpace/FPGA/Video_pro/Source/top/global.vh"
   )
   (
     input                                axi_clk               ,
     input                                rst_n                 ,
     input     [7:0]                      mode/*synthesis PAP_MARK_DEBUG="1"*/                  ,

     output wire           vout_clk      ,
     output wire           vout_vs       ,
     output wire           vout_hs       ,
     output wire           vout_de       ,
     output wire  [15:0]   vout_data     ,


     input   wire          img_720_clk_i ,
     input   wire          img_720_vs_i  ,
     input   wire          img_720_hs_i  ,
     input   wire          img_720_de_i  ,
     input   wire  [15:0]  img_720_data_i,

     input   wire          img_1080_clk_i ,
     input   wire          img_1080_vs_i  ,
     input   wire          img_1080_hs_i  ,
     input   wire          img_1080_de_i  ,

     output wire  						            wr_burst_req      ,
     output wire   [LEN_WIDTH - 1:0] 	    wr_burst_len      ,
     output wire   [AXI_ADDR_WIDTH-1:0]   wr_burst_addr     ,
     input  wire   					              wr_burst_data_req ,
     output wire   [AXI_DATA_WIDTH - 1:0] wr_burst_data     ,
     input  wire   						            wr_burst_finish   ,

     output wire  						            rd_burst_req        ,
     output wire   [LEN_WIDTH - 1:0] 	    rd_burst_len        ,
     output wire   [AXI_ADDR_WIDTH-1:0]   rd_burst_addr       ,
     input  wire   						            rd_burst_data_valid ,
     input  wire   [AXI_DATA_WIDTH - 1:0] rd_burst_data       ,
     input  wire   						            rd_burst_finish
   );
  //  localparam  s_width = 600;  
  //  localparam  s_height = 40;  

   localparam  width = COL_720P; 
   localparam  height = ROW_720P; 
//    width 
// height
  //  s_height <= 12'd720;

   reg   [11:0] s_width  /*synthesis PAP_MARK_DEBUG="1"*/;
   reg   [11:0] s_height /*synthesis PAP_MARK_DEBUG="1"*/;


  wire Is720P;

  wire img_clk ;
  wire img_vs  ;
  wire img_hs  ;
  wire img_de  ;
  wire [15:0] img_data_i;


  wire [15:0] video_data_o;
  wire        video_de_o;
  //
  // reg   [11:0] s_width  ;
  // reg   [11:0] s_height ;

  //mode[3]控制操作行,还是宽,1为行,0为宽
  reg mode4_d1,mode4_d2;
  reg mode5_d1,mode5_d2;
  reg mode6_d1,mode6_d2;
  reg mode7_d1,mode7_d2;

  wire plus10_pos;
  wire minus10_pos;
  wire plus100_pos;
  wire minus100_pos;

  reg [1:0] write_index;
  reg img_720_vs_i_d1,img_720_vs_i_d2;
  wire img_720_vs_i_pos;

  wire  [27:0]    write_addr;
  wire  [27:0]    read_addr ;

  //
  assign img_720_vs_i_pos = img_720_vs_i_d1 & (~img_720_vs_i_d2);
  //
  assign img_clk = (s_width > COL_720P ||  s_height > ROW_720P)?img_1080_clk_i:img_720_clk_i;
  assign img_de = (s_width > COL_720P ||  s_height > ROW_720P)?img_1080_de_i:img_720_de_i;
  assign img_vs = (s_width > COL_720P ||  s_height > ROW_720P)?img_1080_vs_i:img_720_vs_i;
  assign img_hs = (s_width > COL_720P ||  s_height > ROW_720P)?img_1080_vs_i:img_720_vs_i;

  assign Is720P = (s_width > COL_720P ||  s_height > ROW_720P)?1'b0:1'b1;

  assign plus10_pos = mode4_d1 & (~mode4_d2);
  assign minus10_pos = mode5_d1 & (~mode5_d2);
  assign plus100_pos = mode6_d1 & (~mode6_d2);
  assign minus100_pos = mode7_d1 & (~mode7_d2);

  always @(posedge axi_clk)
  begin
    if(!rst_n)
    begin
      mode4_d1 <= 1'b0;
      mode4_d2 <= 1'b0;
      mode5_d1 <= 1'b0;
      mode5_d2 <= 1'b0;
      mode6_d1 <= 1'b0;
      mode6_d2 <= 1'b0;
      mode7_d1 <= 1'b0;
      mode7_d2 <= 1'b0;

      img_720_vs_i_d1 <= 1'b0;
      img_720_vs_i_d2 <= 1'b0;
    end
    else
    begin
      mode4_d1 <= mode[4];
      mode4_d2 <= mode4_d1;
      mode5_d1 <= mode[5];
      mode5_d2 <= mode5_d1;
      mode6_d1 <= mode[6];
      mode6_d2 <= mode6_d1;
      mode7_d1 <= mode[7];
      mode7_d2 <= mode7_d1;

      img_720_vs_i_d1 <= img_720_vs_i;
      img_720_vs_i_d2 <= img_720_vs_i_d1;

    end
  end

  always @(posedge axi_clk)
  begin
    if(!rst_n)
    begin
      s_width <= 12'd640;
      s_height <= 12'd320;
    end
    else
    begin
      if(mode[3])
      begin
        if(plus10_pos)
          s_width <= s_width + 12'd10;
        else if(minus10_pos)
          s_width <= s_width - 12'd10;
        else if(plus100_pos)
          s_width <= s_width + 12'd100;
        else if(plus100_pos)
          s_width <= s_width - 12'd100;
        else
        begin
          s_width <= s_width;
        end
      end
      else
      begin
        if(plus10_pos)
          s_height <= s_height + 12'd10;
        else if(minus10_pos)
          s_height <= s_height - 12'd10;
        else if(plus100_pos)
          s_height <= s_height + 12'd100;
        else if(plus100_pos)
          s_height <= s_height - 12'd100;
        else
        begin
          s_height <= s_height;
        end
      end

    end
  end

  always @(posedge axi_clk)
  begin
    if(!rst_n)
    begin
      write_index <= 2'd0;
    end
    else
    begin
      if(img_720_vs_i_pos)
        write_index <= write_index + 1'b1;
      else
      begin
        write_index <= write_index;
      end

    end
  end
  assign write_addr = (write_index == 2'b00)?Process_addr_1:
                                (write_index == 2'b01)?Process_addr_2:
                                (write_index == 2'b10)?Process_addr_3:Process_addr_4;

  // assign write_addr = write_index == ?Process_addr_1:Process_addr_2;
  assign read_addr = (write_index == 2'b00)?Process_addr_3:
                      (write_index == 2'b01)?Process_addr_4:
                      (write_index == 2'b10)?Process_addr_1:Process_addr_2;
  //

  // reg   [11:0] s_width  ;
  // reg   [11:0] s_height ;

  wr_scale wr_buf_cmos1 (
             .ddr_clk          (  axi_clk          ),
             .ddr_rstn         (  rst_n         ),
             .write_BaseDdr_addr(write_addr) ,

             .wr_clk           (  img_clk               ),
             .wr_fsync         (  img_720_vs_i          ),
             .wr_en            (  video_de_o            ),
             .wr_data          (  video_data_o          ),

             .ddr_wreq         (  wr_burst_req      ),
             .ddr_waddr        (  wr_burst_addr     ),
             .ddr_wr_len       (  wr_burst_len      ),
             .ddr_wdone        (  wr_burst_finish   ),
             .ddr_wdata        (  wr_burst_data     ),
             .ddr_wdata_req    (  wr_burst_data_req )
           );

  rd_scale rd_buf_cmos1 (
             .Is720P(Is720P),

             .ddr_clk          (  axi_clk          ),
             .ddr_rstn         (  rst_n         ),
             .read_BaseDdr_addr(read_addr) ,

             .s_width (s_width ),
             .s_height(s_height),

             .o_clk (vout_clk ),
             .o_vs  (vout_vs  ),
             .o_hs  (vout_hs  ),
             .o_de  (vout_de  ),
             .o_data(vout_data),

            .img_clk (img_clk),
            .img_vs  (img_vs ),
            .img_hs  (img_hs ),
            .img_de  (img_de ),
            // .vout_data(),


            //  .wr_clk           (  img_clk               ),
            //  .wr_fsync         (  img_720_vs_i          ),
            //  .wr_en            (  video_de_o            ),
            //  .wr_data          (  video_data_o          ),

             .ddr_rreq         (  rd_burst_req      ),
             .ddr_raddr        (  rd_burst_addr     ),
             .ddr_rd_len       (  rd_burst_len      ),
             .ddr_rdone        (  rd_burst_finish   ),
             .ddr_rdata        (  rd_burst_data     ),
             .ddr_rdata_en    (  rd_burst_data_valid )
           );

  /*
  *
  */
  wire [10:0] t_width_wr ;
  wire [10:0] t_height_wr;
  wire [10:0] t_width_rd ;
  wire [10:0] t_height_rd;
  wire [15:0] h_scale_k  ;
  wire [15:0] v_scale_k  ;

  para_change  u_para_change (
                 .clk_wr         (img_720_clk_i         ),
                 .clk_rd         (img_clk),//clk_145_5M       ),//
                 .change_en      (2'd0           ),
                 .s_width        (width  ),//12'd1280       ),//?????
                 .s_height       (height ),//12'd720        ),//?????
                 .t_width        (s_width        ),//?????
                 .t_height       (s_height       ),//?????
                 .rst_n          (rst_n          ),
                 .rd_vsync       (img_vs         ),
                 .wr_vsync       (img_720_vs_i   ),//Img_vs_o       ),//

                 .t_width_wr     (t_width_wr     ),
                 .t_height_wr    (t_height_wr    ),
                 .t_width_rd     (t_width_rd     ),
                 .t_height_rd    (t_height_rd    ),
                 .h_scale_k      (h_scale_k      ),
                 .v_scale_k      (v_scale_k      )

                 //  .change_en_wr   (change_en_wr   ),
                 //  .change_en_rd   (change_en_rd   ),
                 //  .app_addr_rd_max(app_addr_rd_max),
                 //  .rd_bust_len    (rd_bust_len    ),
                 //  .app_addr_wr_max(app_addr_wr_max),
                 //  .wr_bust_len    (wr_bust_len    )
               );
  scale_top  u_scale_top (
               .sys_rst_n      (rst_n          ),

               .pixel_clk      (img_720_clk_i          ),
               .pixel_data     (img_720_data_i         ),
               .hs             (img_720_hs_i           ),
               .vs             (img_720_vs_i           ),
               .de             (img_720_de_i           ),

               .sram_clk       (img_clk),//clk_145_5M         ),//
               .sram_data_out  (video_data_o         ),
               .data_valid     (video_de_o           ),

               .s_width        (width  ),//12'd1280          ),
               .s_height       (height ),//12'd720          ),
               .t_width        (s_width           ),
               .t_height       (s_height           ),

               .h_scale_k      (h_scale_k          ),
               .v_scale_k      (v_scale_k          )


             );






endmodule
