//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com 
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           rgmii_rx
// Last modified Date:  2020/2/13 9:20:14
// Last Version:        V1.0
// Descriptions:        RGMII接收模块
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2020/2/13 9:20:14
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module rgmii_rx(
    input              idelay_clk  , //200Mhz时钟，IDELAY时钟
    
    //以太网RGMII接口
    input              gmii_rx_clk   , //RGMII接收时钟
    input              gmii_rx_ctl, //RGMII接收数据控制信号
    input       [3:0]  gmii_rxd   , //RGMII接收数据    

    //以太网GMII接口
    output             rgmii_clk , //GMII接收时钟
    output             mac_rx_data_valid  , //GMII接收数据有效信号
    output      [7:0]  mac_rx_data      //GMII接收数据   
    );

    reg       mac_rx_error;
    //=============================================================
    //=============================================================
    //  RGMII RX 
    //=============================================================
    wire        rgmii_rxc_ibuf;
    wire        rgmii_rxc_bufio;
    wire        rgmii_rx_ctl_ibuf;
    wire [3:0]  rgmii_rxd_ibuf;

    wire [7:0] delay_step_b ;
    wire [7:0] delay_step_gray ;
    
    assign delay_step_b = 8'hA0;   // 0~247 , 10ps/step

    wire lock;
    GTP_DLL #(
        .GRS_EN("TRUE"),
        .FAST_LOCK("TRUE"),
        .DELAY_STEP_OFFSET(0) 
    ) clk_dll (
        .DELAY_STEP(delay_step_gray),// OUTPUT[7:0]  
        .LOCK      (lock),      // OUTPUT  
        .CLKIN     (rgmii_rxc),     // INPUT  
        .PWD       (1'b0),       // INPUT  
        .RST       (1'b0),       // INPUT  
        .UPDATE_N  (1'b1)   // INPUT  
    );
    GTP_IOCLKDELAY #(
        .DELAY_STEP_VALUE   (  'd127           ),
        .DELAY_STEP_SEL     (  "PARAMETER"     ),
        .SIM_DEVICE         (  "LOGOS"         ) 
    ) rgmii_clk_delay (
        .DELAY_STEP         (  delay_step_gray ),// INPUT[7:0]     
        .CLKOUT             (  rgmii_rxc_ibuf  ),// OUTPUT         
        .DELAY_OB           (                  ),// OUTPUT         
        .CLKIN              (  rgmii_rxc       ),// INPUT          
        .DIRECTION          (  1'b0            ),// INPUT          
        .LOAD               (  1'b0            ),// INPUT          
        .MOVE               (  1'b0            ) // INPUT          
    );

    GTP_CLKBUFG GTP_CLKBUFG_RXSHFT(
        .CLKIN     (rgmii_rxc_ibuf),
        .CLKOUT    (rgmii_clk)
    );


    GTP_INBUF #(
        .IOSTANDARD("DEFAULT"),
        .TERM_DDR("ON")
    ) u_rgmii_rx_ctl_ibuf (
        .O(rgmii_rx_ctl_ibuf),// OUTPUT  
        .I(rgmii_rx_ctl) // INPUT  
    );
    
    wire  rgmii_rx_ctl_delay;
    parameter DELAY_STEP = 8'h0F;

    wire [5:0] rx_ctl_nc;
    wire       gmii_ctl;
    wire       rgmii_rx_valid_xor_error;
    GTP_ISERDES #(
        .ISERDES_MODE("IDDR"),
        .GRS_EN("TRUE"),
        .LRS_EN("TRUE") 
    ) gmii_ctl_in (
        .DO   ({rgmii_rx_valid_xor_error,gmii_ctl,rx_ctl_nc[5: 0]}),    // OUTPUT[7:0]  
        .RADDR(3'd0), // INPUT[2:0]  
        .WADDR(3'd0), // INPUT[2:0]  
        .DESCLK(rgmii_clk),// INPUT  
        .DI(rgmii_rx_ctl_ibuf),    // INPUT  
        .ICLK(1'b0),  // INPUT  
        .RCLK(rgmii_clk),  // INPUT  
        .RST(1'b0)    // INPUT  
    );

    wire [3:0] rgmii_rxd_delay;
    wire [23:0] rxd_nc;
    wire [7:0]  mac_rx_data;
    always @(posedge rgmii_clk)
    begin
        mac_rx_data <= mac_rx_data;
        mac_rx_data_valid <= gmii_ctl;
        mac_rx_error <= gmii_ctl ^ rgmii_rx_valid_xor_error;
    end

    generate 
        genvar j;
        for (j=0; j<4; j=j+1)
        begin : rgmii_rx_data

            GTP_INBUF #(
                .IOSTANDARD("DEFAULT"),
                .TERM_DDR("ON")
            ) u_rgmii_rxd_ibuf (
                .O(rgmii_rxd_ibuf[j]),// OUTPUT  
                .I(rgmii_rxd[j]) // INPUT  
            );
            
            GTP_ISERDES #(
                .ISERDES_MODE("IDDR"),
                .GRS_EN("TRUE"),
                .LRS_EN("TRUE") 
            ) gmii_rxd_in (
                .DO   ({mac_rx_data[j+4],mac_rx_data[j],rxd_nc[j*6 +: 6]}),    // OUTPUT[7:0]  
                .RADDR(3'd0), // INPUT[2:0]  
                .WADDR(3'd0), // INPUT[2:0]  
                .DESCLK(rgmii_clk),// INPUT  
                .DI(rgmii_rxd_ibuf[j]),    // INPUT  
                .ICLK(1'b0),  // INPUT  
                .RCLK(rgmii_clk),  // INPUT  
                .RST(1'b0)    // INPUT  
            );

        end
    endgenerate

endmodule