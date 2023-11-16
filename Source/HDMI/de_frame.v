// ‰»Î60HZ, ‰≥ˆ30hz
module de_frame(
    input 				  rst_n				,

    input                 video_clk_i		/*synthesis PAP_MARK_DEBUG="1"*/,
    input                 video_vs_i  	    /*synthesis PAP_MARK_DEBUG="1"*/,
    input                 video_de_i		/*synthesis PAP_MARK_DEBUG="1"*/,
    input [15:0]          video_data_i      /*synthesis PAP_MARK_DEBUG="1"*/,

    output                 video_clk_o		/*synthesis PAP_MARK_DEBUG="1"*/,
    output                 video_vs_o  	    /*synthesis PAP_MARK_DEBUG="1"*/,
    output                 video_de_o		/*synthesis PAP_MARK_DEBUG="1"*/,
    output [15:0]          video_data_o/*synthesis PAP_MARK_DEBUG="1"*/
  );
  
  reg flag=0;

//   reg video_vs_i_d1,video_vs_i_d2;
  wire video_vs_i_pos;

  reg video_vs_i_d1,video_vs_i_d2,video_vs_i_d3,video_vs_i_d4;
  //
  assign video_clk_o = video_clk_i;
  assign video_vs_i_pos = video_vs_i & (~video_vs_i_d1);
  //
  assign video_vs_o = video_vs_i;
  // assign video_vs_o = flag?video_vs_i_d4:1'b0;
  // assign video_de_o = flag?video_de_i:1'b0;
  // assign video_data_o = flag?video_data_i:15'd0;

  /*********************************************/
  always @(posedge video_clk_i)
  begin
    if(!rst_n)
    begin
    //   video_vs_i_d1 <= 1'b0;
    //   video_vs_i_d2 <= 1'b0;

	  video_vs_i_d1 <= 1'b0;
	  video_vs_i_d2 <= 1'b0;
	  video_vs_i_d3 <= 1'b0;
	  video_vs_i_d4 <= 1'b0; 
    end
    begin
    //   video_vs_i_d1 <= video_vs_i;
    //   video_vs_i_d2 <= video_vs_i_d1;

	  video_vs_i_d1 <= video_vs_i   ;
	  video_vs_i_d2 <= video_vs_i_d1;
	  video_vs_i_d3 <= video_vs_i_d2;
	  video_vs_i_d4 <= video_vs_i_d3; 

    end
  end

  always @(posedge video_clk_i)
  begin
    if(!rst_n)
    begin
      flag <= 1'b0;
    end
    else
    begin
      if(video_vs_i_pos)
      begin
        flag <= ~flag;
      end
      else
      begin
        flag <= flag;
      end
    end
  end
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
  .clk_wr         (video_clk_i         ),
  .clk_rd         (video_clk_i),//clk_145_5M       ),//
  .change_en      (2'd0            ),
  .s_width        (12'd1920         ),//?????
  .s_height       (12'd1080        ),//?????
  .t_width        (12'd640       ),//?????
  .t_height       (12'd360      ),//?????
  .rst_n          (rst_n         ),
  .rd_vsync       (video_vs_i     ),
  .wr_vsync       (video_vs_i),//Img_vs_o       ),//

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

.pixel_clk      (video_clk_i          ),
.pixel_data     (video_data_i         ),
.hs             (video_de_i           ),
.vs             (video_vs_i           ),
.de             (video_de_i           ),

.sram_clk       (video_clk_i),//clk_145_5M         ),//
.sram_data_out  (video_data_o         ),
.data_valid     (video_de_o           ),

.s_width        (12'd1920          ),
.s_height       (12'd1080          ),
.t_width        (12'd640           ),
.t_height       (12'd360           ),

.h_scale_k      (h_scale_k          ),
.v_scale_k      (v_scale_k          )


);


endmodule
