//****************************************Copyright (c)***********************************//
//原子哥在线教学平台:www.yuanzige.com
//技术支持:www.openedv.com
//淘宝店铺:http://openedv.taobao.com 
//关注微信公众平台微信号:"正点原子",免费获取ZYNQ & FPGA & STM32 & LINUX资料.
//版权所有,盗版必究.
//Copyright(C) 正点原子 2018-2028
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           eth_udp_loop
// Last modified Date:  2020/2/18 9:20:14
// Last Version:        V1.0
// Descriptions:        以太网通信UDP通信环回顶层模块
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2020/2/18 9:20:14
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module eth_udp_loop(
    input              sys_clk   , //系统时钟
    input              sys_rst_n , //系统复位信号,低电平有效 

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

    //以太网RGMII接口   
    input              eth_rxc   , //RGMII接收数据时钟
    input              eth_rx_ctl, //RGMII输入数据有效信号
    input       [3:0]  eth_rxd   , //RGMII输入数据
    output             eth_txc   , //RGMII发送数据时钟    
    output             eth_tx_ctl, //RGMII输出数据有效信号
    output      [3:0]  eth_txd   , //RGMII输出数据          
    output             eth_rst_n  //以太网芯片复位信号,低电平有效   
    );

//parameter define
//开发板MAC地址 00-11-22-33-44-55
parameter  BOARD_MAC = 48'h00_11_22_33_44_55;     
//开发板IP地址 192.168.1.10
parameter  BOARD_IP  = {8'd192,8'd168,8'd1,8'd10};  
//目的MAC地址 ff_ff_ff_ff_ff_ff
parameter  DES_MAC   = 48'hff_ff_ff_ff_ff_ff;    
//目的IP地址 192.168.1.102     
parameter  DES_IP    = {8'd192,8'd168,8'd1,8'd102};  
//输入数据IO延时,此处为0,即不延时(如果为n,表示延时n*78ps) 
parameter IDELAY_VALUE = 0;

//wire define
wire          clk_200m   ; //用于IO延时的时钟 
              
// wire          gmii_rx_clk; //GMII接收时钟
wire          gmii_rx_dv ; //GMII接收数据有效信号
wire  [7:0]   gmii_rxd   ; //GMII接收数据
wire          gmii_tx_clk; //GMII发送时钟
wire          gmii_tx_en ; //GMII发送数据使能信号
wire  [7:0]   gmii_txd   ; //GMII发送数据     

wire          arp_gmii_tx_en; //ARP GMII输出数据有效信号 
wire  [7:0]   arp_gmii_txd  ; //ARP GMII输出数据
wire          arp_rx_done   ; //ARP接收完成信号
wire          arp_rx_type   ; //ARP接收类型 0:请求  1:应答
wire  [47:0]  src_mac       ; //接收到目的MAC地址
wire  [31:0]  src_ip        ; //接收到目的IP地址    
wire          arp_tx_en     ; //ARP发送使能信号
wire          arp_tx_type   ; //ARP发送类型 0:请求  1:应答
wire  [47:0]  des_mac       ; //发送的目标MAC地址
wire  [31:0]  des_ip        ; //发送的目标IP地址   
wire          arp_tx_done   ; //ARP发送完成信号

wire          udp_gmii_tx_en; //UDP GMII输出数据有效信号 
wire  [7:0]   udp_gmii_txd  ; //UDP GMII输出数据

// wire          rec_pkt_done  ; //UDP单包数据接收完成信号
// wire          rec_en        ; //UDP接收的数据使能信号
// wire  [31:0]  rec_data      ; //UDP接收的数据
// wire  [15:0]  rec_byte_num  ; //UDP接收的有效字节数 单位:byte 

// wire          tx_start_en   ;  
// wire  [15:0]  tx_byte_num   ; //UDP发送的有效字节数 单位:byte 
// wire          udp_tx_done   ; //UDP发送完成信号
// wire          tx_req        ; //UDP读数据请求信号
// wire  [31:0]  tx_data       ; //UDP待发送数据

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


//GMII接口转RGMII接口
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

//ARP通信
arp                                             
   #(
    .BOARD_MAC     (BOARD_MAC),      //参数例化
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

//UDP通信
udp                                             
   #(
    .BOARD_MAC     (BOARD_MAC),      //参数例化
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

//同步FIFO
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

//以太网控制模块
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