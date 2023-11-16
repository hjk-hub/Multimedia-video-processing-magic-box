//
module udp_processor(

    input   wire               rst_n              ,
    input   wire               udp_data_clk       ,

    input   wire              rec_pkt_done ,
    input   wire              rec_en       ,
    input   wire  [31:0]      rec_data     ,
    input   wire  [15:0]      rec_byte_num ,

    output      wire          tx_start_en   ,
    output      wire  [15:0]  tx_byte_num   ,
    input      wire           udp_tx_done   ,
    input      wire           tx_req        ,
    output      wire  [31:0]  tx_data       ,  

  );


  assign tx_start_en = rec_pkt_done;
  assign tx_byte_num = rec_byte_num;
  /***********************************************/
  fifo_sync_32I32O the_instance_name (
  .wr_data      (rec_data        ),              // input [31:0]
  .wr_en        (rec_en          ),                  // input
  .full         (                ),                    // output
  .almost_full  (                ),      // output
  .rd_data      (tx_data         ),              // output [31:0]
  .rd_en        (tx_req          ),                  // input
  .empty        (                ),                  // output
  .almost_empty (                ),    // output
  .clk          (udp_data_clk    ),                      // input
  .rst          (~rst_n          )                       // input
);



endmodule
