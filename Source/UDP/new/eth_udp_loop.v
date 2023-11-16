//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨:www.yuanzige.com
//����֧��:www.openedv.com
//�Ա�����:http://openedv.taobao.com 
//��ע΢�Ź���ƽ̨΢�ź�:"����ԭ��",��ѻ�ȡZYNQ & FPGA & STM32 & LINUX����.
//��Ȩ����,����ؾ�.
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           eth_udp_loop
// Last modified Date:  2020/2/18 9:20:14
// Last Version:        V1.0
// Descriptions:        ��̫��ͨ��UDPͨ�Ż��ض���ģ��
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2020/2/18 9:20:14
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module eth_udp_loop(
    input              sys_clk   , //ϵͳʱ��
    input              sys_rst_n , //ϵͳ��λ�ź�,�͵�ƽ��Ч 

    //
    output   wire          gmii_rx_clk  ,
    output   wire          rec_pkt_done ,
    output   wire          rec_en       ,
    output   wire  [31:0]  rec_data     ,
    output   wire  [15:0]  rec_byte_num ,

    input      wire           tx_start_en,
    input       wire  [15:0]  tx_byte_num,
    output      wire          udp_tx_done,
    output      wire          tx_req     ,
    input       wire  [31:0]  tx_data    ,  

    //��̫��RGMII�ӿ�   
    input              eth_rxc   , //RGMII��������ʱ��
    input              eth_rx_ctl, //RGMII����������Ч�ź�
    input       [3:0]  eth_rxd   , //RGMII��������
    output             eth_txc   , //RGMII��������ʱ��    
    output             eth_tx_ctl, //RGMII���������Ч�ź�
    output      [3:0]  eth_txd   , //RGMII�������          
    output             eth_rst_n  //��̫��оƬ��λ�ź�,�͵�ƽ��Ч   
    );

//parameter define
//������MAC��ַ 00-11-22-33-44-55
parameter  BOARD_MAC = 48'h00_11_22_33_44_55;     
//������IP��ַ 192.168.1.10
parameter  BOARD_IP  = {8'd192,8'd168,8'd1,8'd10};  
//Ŀ��MAC��ַ ff_ff_ff_ff_ff_ff
parameter  DES_MAC   = 48'hff_ff_ff_ff_ff_ff;    
//Ŀ��IP��ַ 192.168.1.102     
parameter  DES_IP    = {8'd192,8'd168,8'd1,8'd102};  
//��������IO��ʱ,�˴�Ϊ0,������ʱ(���Ϊn,��ʾ��ʱn*78ps) 
parameter IDELAY_VALUE = 0;

//wire define
wire          clk_200m   ; //����IO��ʱ��ʱ�� 
              
// wire          gmii_rx_clk; //GMII����ʱ��
wire          gmii_rx_dv ; //GMII����������Ч�ź�
wire  [7:0]   gmii_rxd   ; //GMII��������
wire          gmii_tx_clk; //GMII����ʱ��
wire          gmii_tx_en ; //GMII��������ʹ���ź�
wire  [7:0]   gmii_txd   ; //GMII��������     

wire          arp_gmii_tx_en; //ARP GMII���������Ч�ź� 
wire  [7:0]   arp_gmii_txd  ; //ARP GMII�������
wire          arp_rx_done   ; //ARP��������ź�
wire          arp_rx_type   ; //ARP�������� 0:����  1:Ӧ��
wire  [47:0]  src_mac       ; //���յ�Ŀ��MAC��ַ
wire  [31:0]  src_ip        ; //���յ�Ŀ��IP��ַ    
wire          arp_tx_en     ; //ARP����ʹ���ź�
wire          arp_tx_type   ; //ARP�������� 0:����  1:Ӧ��
wire  [47:0]  des_mac       ; //���͵�Ŀ��MAC��ַ
wire  [31:0]  des_ip        ; //���͵�Ŀ��IP��ַ   
wire          arp_tx_done   ; //ARP��������ź�

wire          udp_gmii_tx_en; //UDP GMII���������Ч�ź� 
wire  [7:0]   udp_gmii_txd  ; //UDP GMII�������

// wire          rec_pkt_done  ; //UDP�������ݽ�������ź�
// wire          rec_en        ; //UDP���յ�����ʹ���ź�
// wire  [31:0]  rec_data      ; //UDP���յ�����
// wire  [15:0]  rec_byte_num  ; //UDP���յ���Ч�ֽ��� ��λ:byte 

// wire          tx_start_en   ;  
// wire  [15:0]  tx_byte_num   ; //UDP���͵���Ч�ֽ��� ��λ:byte 
// wire          udp_tx_done   ; //UDP��������ź�
// wire          tx_req        ; //UDP�����������ź�
// wire  [31:0]  tx_data       ; //UDP����������

//*****************************************************
//**                    main code
//*****************************************************

// assign tx_start_en = rec_pkt_done;
// assign tx_byte_num = rec_byte_num;

assign des_mac = src_mac;
assign des_ip = src_ip;
assign eth_rst_n = sys_rst_n;

//MMCM/PLL
// clk_wiz u_clk_wiz
// (
//     .clk_in1   (sys_clk   ),
//     .clk_out1  (clk_200m  ),    
//     .reset     (~sys_rst_n), 
//     .locked    (locked)
// );
pll_200M u_pll_200M(
    .pll_rst        (~sys_rst_n),
    .clkin1         (sys_clk    ),
    .clkout0        (clk_200m   ),
    
    .pll_lock       (locked     )
    );


//GMII�ӿ�תRGMII�ӿ�
gmii_to_rgmii 
    #(
     .IDELAY_VALUE (IDELAY_VALUE)
     )
    u_gmii_to_rgmii(
    .idelay_clk    (clk_200m    ),

    .gmii_rx_clk   (gmii_rx_clk ),
    .gmii_rx_dv    (gmii_rx_dv  ),
    .gmii_rxd      (gmii_rxd    ),
    .gmii_tx_clk   (gmii_tx_clk ),
    .gmii_tx_en    (gmii_tx_en  ),
    .gmii_txd      (gmii_txd    ),
    
    .rgmii_rxc     (eth_rxc     ),
    .rgmii_rx_ctl  (eth_rx_ctl  ),
    .rgmii_rxd     (eth_rxd     ),
    .rgmii_txc     (eth_txc     ),
    .rgmii_tx_ctl  (eth_tx_ctl  ),
    .rgmii_txd     (eth_txd     )
    );

//ARPͨ��
arp                                             
   #(
    .BOARD_MAC     (BOARD_MAC),      //��������
    .BOARD_IP      (BOARD_IP ),
    .DES_MAC       (DES_MAC  ),
    .DES_IP        (DES_IP   )
    )
   u_arp(
    .rst_n         (sys_rst_n  ),
                    
    .gmii_rx_clk   (gmii_rx_clk),
    .gmii_rx_dv    (gmii_rx_dv ),
    .gmii_rxd      (gmii_rxd   ),
    .gmii_tx_clk   (gmii_tx_clk),
    .gmii_tx_en    (arp_gmii_tx_en ),
    .gmii_txd      (arp_gmii_txd),
                    
    .arp_rx_done   (arp_rx_done),
    .arp_rx_type   (arp_rx_type),
    .src_mac       (src_mac    ),
    .src_ip        (src_ip     ),
    .arp_tx_en     (arp_tx_en  ),
    .arp_tx_type   (arp_tx_type),
    .des_mac       (des_mac    ),
    .des_ip        (des_ip     ),
    .tx_done       (arp_tx_done)
    );

//UDPͨ��
udp                                             
   #(
    .BOARD_MAC     (BOARD_MAC),      //��������
    .BOARD_IP      (BOARD_IP ),
    .DES_MAC       (DES_MAC  ),
    .DES_IP        (DES_IP   )
    )
   u_udp(
    .rst_n         (sys_rst_n   ),  
    
    .gmii_rx_clk   (gmii_rx_clk ),           
    .gmii_rx_dv    (gmii_rx_dv  ),         
    .gmii_rxd      (gmii_rxd    ),                   
    .gmii_tx_clk   (gmii_tx_clk ), 
    .gmii_tx_en    (udp_gmii_tx_en),         
    .gmii_txd      (udp_gmii_txd),  

    .rec_pkt_done  (rec_pkt_done),    
    .rec_en        (rec_en      ),     
    .rec_data      (rec_data    ),         
    .rec_byte_num  (rec_byte_num),      
    .tx_start_en   (tx_start_en ),        
    .tx_data       (tx_data     ),         
    .tx_byte_num   (tx_byte_num ),  
    .des_mac       (des_mac     ),
    .des_ip        (des_ip      ),    
    .tx_done       (udp_tx_done ),        
    .tx_req        (tx_req      )           
    ); 

//ͬ��FIFO
// sync_fifo_2048x32b u_sync_fifo_2048x32b (
//     .clk      (gmii_rx_clk),  // input wire clk
//     .rst      (~sys_rst_n),  // input wire rst
//     .din      (rec_data  ),  // input wire [31 : 0] din
//     .wr_en    (rec_en    ),  // input wire wr_en
//     .rd_en    (tx_req    ),  // input wire rd_en
//     .dout     (tx_data   ),  // output wire [31 : 0] dout
//     .full     (),            // output wire full
//     .empty    ()             // output wire empty
//     );    

//��̫������ģ��
eth_ctrl u_eth_ctrl(
    .clk            (gmii_rx_clk),
    .rst_n          (sys_rst_n),

    .arp_rx_done    (arp_rx_done   ),
    .arp_rx_type    (arp_rx_type   ),
    .arp_tx_en      (arp_tx_en     ),
    .arp_tx_type    (arp_tx_type   ),
    .arp_tx_done    (arp_tx_done   ),
    .arp_gmii_tx_en (arp_gmii_tx_en),
    .arp_gmii_txd   (arp_gmii_txd  ),
                     
    .udp_gmii_tx_en (udp_gmii_tx_en),
    .udp_gmii_txd   (udp_gmii_txd  ),
                     
    .gmii_tx_en     (gmii_tx_en    ),
    .gmii_txd       (gmii_txd      )
    );

endmodule