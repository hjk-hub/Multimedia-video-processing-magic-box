//****************************************Copyright (c)***********************************//
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡFPGA & STM32���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           vip
// Last modified Date:  2019/03/22 16:33:40
// Last Version:        V1.0
// Descriptions:        ����ͼ����ģ���װ��
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2019/03/22 16:33:56
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module vip(
    //module clock
    input           clk            ,   // ʱ���ź�
    input           rst_n          ,   // ��λ�źţ�����Ч��

    //ͼ����ǰ�����ݽӿ�
    input           pre_frame_vsync,
    input           pre_frame_hsync,
    input           pre_frame_de   ,
    input    [15:0] pre_rgb        /*synthesis PAP_MARK_DEBUG="1"*/,
    input    [10:0] xpos           ,
    input    [10:0] ypos           ,

    //ͼ���������ݽӿ�
    output          post_frame_vsync,  // ��ͬ���ź�
    output          post_frame_hsync,  // ��ͬ���ź�
    output          post_frame_de   ,  // ��������ʹ��
    output   [15:0] post_rgb           // RGB565��ɫ����
);

//wire define
wire   [ 7:0]         img_y;
// wire   [15:0]         post_rgb;
// wire                  post_frame_vsync;
// wire                  post_frame_hsync;
// wire                  post_frame_de;
//*****************************************************
//**                    main code
//*****************************************************

assign  post_rgb = {img_y[7:3],img_y[7:2],img_y[7:3]};

//RGBתYCbCrģ��
rgb2ycbcr u_rgb2ycbcr(
    //module clock
    .clk             (clk    ),            // ʱ���ź�
    .rst_n           (rst_n  ),            // ��λ�źţ�����Ч��
    //ͼ����ǰ�����ݽӿ�
    .pre_frame_vsync (pre_frame_vsync),    // vsync�ź�
    .pre_frame_hsync (pre_frame_hsync),    // href�ź�
    .pre_frame_de    (pre_frame_de   ),    // data enable�ź�
    .img_red         (pre_rgb[15:11] ),
    .img_green       (pre_rgb[10:5 ] ),
    .img_blue        (pre_rgb[ 4:0 ] ),
    //ͼ���������ݽӿ�
    .post_frame_vsync(post_frame_vsync),   // vsync�ź�
    .post_frame_hsync(post_frame_hsync),   // href�ź�
    .post_frame_de   (post_frame_de),      // data enable�ź�
    .img_y           (img_y),
    .img_cb          (),
    .img_cr          ()
);

endmodule
