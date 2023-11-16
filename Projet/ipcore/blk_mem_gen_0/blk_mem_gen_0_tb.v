// Created by IP Generator (Version 2022.1 build 99559)



//////////////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2014 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
//
// THE SOURCE CODE CONTAINED HEREIN IS PROPRIETARY TO PANGO MICROSYSTEMS, INC.
// IT SHALL NOT BE REPRODUCED OR DISCLOSED IN WHOLE OR IN PART OR USED BY
// PARTIES WITHOUT WRITTEN AUTHORIZATION FROM THE OWNER.
//
//////////////////////////////////////////////////////////////////////////////
//
// Library:
// Filename:TB blk_mem_gen_0_tb.v
//////////////////////////////////////////////////////////////////////////////

`timescale   1ns / 1ps

module  blk_mem_gen_0_tb ();

    localparam T_CLK_PERIOD = 10  ; //clock a half perid
    localparam T_RST_TIME   = 200 ; //reset time

    localparam ADDR_WIDTH   = 10 ; //@IPC int 4,10

    localparam DATA_WIDTH   = 8 ; //@IPC int 1,256

    localparam RST_TYPE     = "SYNC" ; //@IPC enum ASYNC,SYNC

    localparam OUT_REG      = 0 ; //@IPC bool

    localparam INIT_ENABLE  = 0 ; //@IPC bool

    localparam INIT_FILE    = "NONE" ; //@IPC string

    localparam FILE_FORMAT  = "BIN" ; //@IPC enum BIN,HEX



// variable declaration
    reg                       wr_clk_tb  ;
    reg                       rd_clk_tb  ;
    reg                       check_err  ;
    reg   [2:0]               results_cnt;
    reg                       tb_rst     ;
    reg   [ADDR_WIDTH-1:0]    tb_waddr   ;
    reg   [ADDR_WIDTH-1:0]    tb_raddr   ;
    reg   [DATA_WIDTH-1:0]    tb_wrdata  ;
    wire  [DATA_WIDTH-1:0]    tb_rddata  ;
    reg                       tb_wr_en   ;


//************************************************************ CGU ****************************************************************************
//generate clk_tb
initial
begin

    wr_clk_tb = 0;
    forever #(T_CLK_PERIOD/2)  wr_clk_tb = ~wr_clk_tb;
end
initial
begin

    rd_clk_tb = 0;
    forever #(T_CLK_PERIOD/4)  rd_clk_tb = ~rd_clk_tb;
end

//************************************************************ DGU ******************************************************************************



initial begin

   tb_waddr    = 0;
   tb_raddr    = 0;
   tb_wrdata   = 0;
   tb_wr_en    = 0;

   tb_rst        = 1;
   #T_RST_TIME     ;
   tb_rst        = 0;
   #10             ;
   if(INIT_FILE == "NONE") begin
      $display("writing sdpram");
      write_sdpram;
      #10;

      $display("reading sdpram");
      read_sdpram;
      #10;

      $display("sdpram simulation done");
   end
   else begin
      $display("reading initialized sdpram");
      read_sdpram;
      #10;

      $display("sdpram simulation done");
   end
   if (|results_cnt)
       $display("Simulation Failed due to Error Found.") ;
   else
       $display("Simulation Success.") ;
   #500 ;
   $finish ;
end


//***************************************************************** DUT  INST **************************************************************************************
always@(posedge rd_clk_tb or posedge tb_rst) begin
    if(tb_rst)
        check_err <=0;
    else if(INIT_FILE == "NONE")
    begin
        if(tb_wr_en == 1'b0 && OUT_REG == 0)
        begin
            if(tb_raddr > 2 && tb_raddr%2 == 0 && tb_rddata != 0)
                check_err <=1;
            else
                check_err <=0;
        end
        else if(tb_wr_en == 1'b0 && OUT_REG == 1)
        begin
            if(tb_raddr > 2 && tb_raddr%2 == 0 && tb_rddata == 0)
                check_err <=1;
            else
                check_err <=0;
        end
    end
    else
        check_err <=0;
end

always @(posedge rd_clk_tb or posedge tb_rst)
begin
    if (tb_rst)
        results_cnt <= 3'b000 ;
    else if (&results_cnt)
        results_cnt <= 3'b100 ;
    else if (check_err)
        results_cnt <= results_cnt + 3'd1 ;
end

integer  result_fid;
initial begin
     result_fid = $fopen ("sim_results.log","a");
     $fmonitor(result_fid,"err_chk=%b",check_err);
end

GTP_GRS GRS_INST(
.GRS_N(1'b1)
);
blk_mem_gen_0  U_blk_mem_gen_0 (
    .wr_data   (tb_wrdata)     ,
    .wr_addr   (tb_waddr )     ,
    .rd_addr   (tb_raddr )     ,
    .wr_clk    (wr_clk_tb)     ,
    .rd_clk    (rd_clk_tb)     ,
    .wr_en     (tb_wr_en )     ,
    .rst       (tb_rst   )     ,
    .rd_data   (tb_rddata)
);

//***************************************************************** task **************************************************************************************

task write_sdpram;

   integer i;
   begin
     tb_wr_en    = 0;
     tb_wrdata   = 0;
     tb_waddr    = 0;
     i           = 0;
     while ( i < 2**ADDR_WIDTH )
     begin
        @(posedge wr_clk_tb);
        tb_wr_en = 1'b1;
        tb_wrdata= ~tb_wrdata;
        tb_waddr = tb_waddr + 1'b1;
        i        = i + 1'b1;
     end

     tb_wr_en = 1'b0;

   end
endtask

task read_sdpram;
   integer init_fid;
   integer j;
   begin
     tb_wr_en = 0;
     tb_raddr = 0;
     j        = 0;
     init_fid = $fopen ("init_results.dat","a");
     while (j < 2**ADDR_WIDTH )
     begin
        @(posedge rd_clk_tb);
         tb_wr_en = 1'b0;
         tb_raddr = tb_raddr + 1'b1;
         j        = j + 1'b1;
         $fmonitor(init_fid,"%b",tb_rddata);
     end
   end
endtask

endmodule

