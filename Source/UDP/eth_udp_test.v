`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/16 23:40:05
// Design Name: 
// Module Name: eth_udp_test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module eth_udp_test#(
    parameter       LOCAL_MAC = 48'h11_11_11_11_11_11,
    parameter       LOCAL_IP  = 32'hC0_A8_01_6E,//192.168.1.110
    parameter       LOCL_PORT = 16'h8080,

    parameter       DEST_IP   = 32'hC0_A8_01_69,//192.168.1.105
    parameter       DEST_PORT = 16'h8080 
)(
    input                send_en        ,
    output   reg         send_fifo_en   ,
    input    [7:0]       send_fifo_data ,
    input                send_fifo_empty,
    input    [15:0]      udp_send_data_length/*synthesis PAP_MARK_DEBUG="1"*/,
    // output               send_done,

    input                rgmii_clk,
    input                rstn,
    input                gmii_rx_dv,
    input  [7:0]         gmii_rxd,
    output reg           gmii_tx_en,
    output reg [7:0]     gmii_txd,
                 
    output               udp_rec_data_valid,         
    output [7:0]         udp_rec_rdata ,             
    output [15:0]        udp_rec_data_length         
);
    
    localparam UDP_WIDTH = 32 ;
    localparam UDP_DEPTH = 5 ;
    wire   [7:0]          ram_wr_data ;
    wire                  ram_wr_en ;
    wire                 udp_ram_data_req ;
    // wire [15:0]           udp_send_data_length/*synthesis PAP_MARK_DEBUG="1"*/;
    
      
    wire                 udp_tx_req ;
    wire                 arp_request_req ;
    wire                 mac_send_end ;
    reg                  write_end ;
    
    reg  [31:0]          wait_cnt ;
    
    wire                 mac_not_exist ;
    wire                 arp_found ;

    reg send_en_d1,send_en_d2;
    reg send_fifo_en_d1;
    reg [7:0] send_fifo_data_d1;
    
    wire send_en_pos;
    always @(posedge rgmii_clk)
    begin
        if (~rstn)begin
            send_en_d1  <=  1'b0  ;
            send_en_d2  <=  1'b0  ;
            send_fifo_en_d1 <= 1'b0  ;
            send_fifo_data_d1 <= 8'd0;
        end
        else begin
            send_en_d1  <=  send_en ;
            send_en_d2  <=  send_en_d1 ;

            send_fifo_en_d1 <= send_fifo_en  ;
            send_fifo_data_d1 <= send_fifo_data  ;
        end
    end
    assign send_en_pos = send_en_d1 & (~send_en_d2);

    assign ram_wr_en = send_fifo_en_d1 & send_fifo_en;
    assign ram_wr_data = send_fifo_data_d1;   
    
    // assign udp_send_data_length = test_cnt - 1'b1;
    //
    
    parameter IDLE          = 9'b000_000_001 ;
    parameter ARP_REQ       = 9'b000_000_010 ;
    parameter ARP_SEND      = 9'b000_000_100 ;
    parameter ARP_WAIT      = 9'b000_001_000 ;
    parameter GEN_REQ       = 9'b000_010_000 ;
    parameter WRITE_RAM     = 9'b000_100_000 ;
    parameter SEND          = 9'b001_000_000 ;
    parameter WAIT          = 9'b010_000_000 ;
    parameter CHECK_ARP     = 9'b100_000_000 ;
    parameter ONE_SECOND_CNT= 32'd125_000_000;//32'd12500;//
    
    reg [8:0]    state  ;
    reg [8:0]    state_n ;

    always @(posedge rgmii_clk)
    begin
        if (~rstn)
            state  <=  IDLE  ;
        else
            state  <= state_n ;
    end
   


    always @(*)
    begin
        case(state)
            IDLE        :
            begin
                if (send_en_pos)//if (wait_cnt == ONE_SECOND_CNT)    //1s//
                    state_n = ARP_REQ ;
                else
                    state_n = IDLE ;
            end
            ARP_REQ     :
                state_n = ARP_SEND ;
            ARP_SEND    :
            begin
                if (mac_send_end)
                    state_n = ARP_WAIT ;
                else
                    state_n = ARP_SEND ;
            end
            ARP_WAIT    :
            begin
                if (arp_found)
                    state_n = WAIT ;
                else if (wait_cnt == ONE_SECOND_CNT)
                    state_n = ARP_REQ ;
                else
                    state_n = ARP_WAIT ;
            end
            GEN_REQ     :
            begin
                if (udp_ram_data_req)
                    state_n = WRITE_RAM ;
                else
                    state_n = GEN_REQ ;
            end
            WRITE_RAM   :
            begin
                if (write_end) begin

                    // state_n = WAIT     ;
                    state_n = IDLE ;
                    
                end
                else
                    state_n = WRITE_RAM ;
            end
            SEND        :
            begin
                if (mac_send_end)
                    state_n = WAIT ;
                else
                    state_n = SEND ;
            end
            WAIT        :
            begin
    		    if (wait_cnt == ONE_SECOND_CNT)    //1s
                    state_n = CHECK_ARP ;
                else
                    state_n = WAIT ;
            end
            CHECK_ARP   :
            begin
                if (mac_not_exist)
                    state_n = ARP_REQ ;
                else
                    state_n = GEN_REQ ;
            end
            default     : state_n = IDLE ;
        endcase
    end

    reg          gmii_rx_dv_1d;
    reg  [7:0]   gmii_rxd_1d;
    wire         gmii_tx_en_tmp;
    wire [7:0]   gmii_txd_tmp;
    
    always@(posedge rgmii_clk)
    begin
        if(rstn == 1'b0)
        begin
            gmii_rx_dv_1d <= 1'b0 ;
            gmii_rxd_1d   <= 8'd0 ;
        end
        else
        begin
            gmii_rx_dv_1d <= gmii_rx_dv ;
            gmii_rxd_1d   <= gmii_rxd ;
        end
    end
      
    always@(posedge rgmii_clk)
    begin
        if(rstn == 1'b0)
        begin
            gmii_tx_en <= 1'b0 ;
            gmii_txd   <= 8'd0 ;
        end
        else
        begin
            gmii_tx_en <= gmii_tx_en_tmp ;
            gmii_txd   <= gmii_txd_tmp ;
        end
    end
    
    udp_ip_mac_top#(
        .LOCAL_MAC                (LOCAL_MAC               ),// 48'h11_11_11_11_11_11,
        .LOCAL_IP                 (LOCAL_IP                ),// 32'hC0_A8_01_6E,//192.168.1.110
        .LOCL_PORT                (LOCL_PORT               ),// 16'h8080,
                                                           
        .DEST_IP                  (DEST_IP                 ),// 32'hC0_A8_01_69,//192.168.1.105
        .DEST_PORT                (DEST_PORT               ) // 16'h8080 
)udp_ip_mac_top(
        .rgmii_clk                (  rgmii_clk             ),//input           rgmii_clk,
        .rstn                     (  rstn                  ),//input           rstn,
  
        .app_data_in_valid        (  ram_wr_en             ),//input           app_data_in_valid,
        .app_data_in              (  ram_wr_data           ),//input   [7:0]   app_data_in,      
        .app_data_length          (  udp_send_data_length  ),//input   [15:0]  app_data_length,   
        .app_data_request         (  udp_tx_req            ),//input           app_data_request, 
                                                           
        .udp_send_ack             (  udp_ram_data_req      ),//output          udp_send_ack,   
                                                           
        .arp_req                  (  arp_request_req       ),//input           arp_req,
        .arp_found                (  arp_found             ),//output          arp_found,
        .mac_not_exist            (  mac_not_exist         ),//output          mac_not_exist, 
        .mac_send_end             (  mac_send_end          ),//output          mac_send_end,
        
        .udp_rec_rdata            (  udp_rec_rdata         ),//output  [7:0]   udp_rec_rdata ,      //udp ram read data   
        .udp_rec_data_length      (  udp_rec_data_length   ),//output  [15:0]  udp_rec_data_length,     //udp data length     
        .udp_rec_data_valid       (  udp_rec_data_valid    ),//output          udp_rec_data_valid,       //udp data valid      
        
        .mac_data_valid           (  gmii_tx_en_tmp        ),//output          mac_data_valid,
        .mac_tx_data              (  gmii_txd_tmp          ),//output  [7:0]   mac_tx_data,   
                                      
        .rx_en                    (  gmii_rx_dv_1d         ),//input           rx_en,         
        .mac_rx_datain            (  gmii_rxd_1d           ) //input   [7:0]   mac_rx_datain
    );

     reg [159 : 0] test_data = {8'h77,8'h77,8'h77,8'h2E,   //{"w","w","w","."}; 
                               8'h6D,8'h65,8'h79,8'h65,   //{"m","e","y","e"}; 
                               8'h73,8'h65,8'h6D,8'h69,   //{"s","e","m","i"}; 
                               8'h2E,8'h63,8'h6F,8'h6D,   //{".","c","o","m"}; 
                               8'h20,8'h20,8'h20,8'h0A  };//{" "," "," ","\n"};

    // always@(posedge rgmii_clk)
    // begin
    //     if(rstn == 1'b0)
    // 	    udp_send_data_length <= 16'd0 ;
    // 	else
    // 	    udp_send_data_length <= 4*UDP_DEPTH ;
    //       //udp_send_data_length <=16'd20 ;
    // end
      
    assign udp_tx_req    = (state == GEN_REQ) ;
    assign arp_request_req  = (state == ARP_REQ) ;
    
    always@(posedge rgmii_clk)
    begin
        if(rstn == 1'b0)
            wait_cnt <= 0 ;
        else if ((state==IDLE||state == WAIT || state == ARP_WAIT) && state != state_n)
            wait_cnt <= 0 ;
        else if (state==IDLE||state == WAIT || state == ARP_WAIT)
            wait_cnt <= wait_cnt + 1'b1 ;
    	else
    	    wait_cnt <= 0 ;
    end
    
    reg [7:0] test_cnt;
    always@(posedge rgmii_clk)
    begin
        if(rstn == 1'b0)
        begin
            write_end  <= 1'b0;
            // ram_wr_data <= 0;
            // ram_wr_en  <= 0 ;
            test_cnt   <= 0;

            send_fifo_en <= 1'b0;
        end
        else if (state == WRITE_RAM)
        begin
            if(test_cnt == 8'd20)//if(send_fifo_empty)//
            begin
                // ram_wr_en <=1'b0;
                send_fifo_en <= 1'b0;
                write_end <= 1'b1;
            end
            else
            begin
                send_fifo_en <= 1'b1;
                // ram_wr_en <= 1'b1 ;
                write_end <= 1'b0 ;
                // ram_wr_data <= test_data[8'd159-{test_cnt[4:0],3'd0} -: 8] ;
                test_cnt <= test_cnt + 8'd1;
            end
        end
        else
        begin
            write_end  <= 1'b0;
            send_fifo_en <= 1'b0;
            // ram_wr_data <= 0;
            // ram_wr_en  <= 0 ;
            test_cnt   <= 0;
        end
    end
      
endmodule
