`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Myminieye
// Engineer: Mill
// 
// Create Date: 2020-06-19 20:31  
// Design Name:  
// Module Name:  btn_deb_fix ;QQ Group: 808770961
// Project Name: 
// Target Devices: Gowin
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

`define UD #1
module btn_deb_fix#(
    parameter                  BTN_WIDTH = 4'd8
)
(
    input                      clk,  //12MHz
    input      [BTN_WIDTH-1:0] btn_in,
    
    output reg [BTN_WIDTH-1:0] btn_deb_fix
);

    //16'h3ad43;
    reg [17:0]          cnt[BTN_WIDTH-1:0];
    reg [BTN_WIDTH-1:0] flag;
   
    reg [BTN_WIDTH-1:0] btn_in_reg;

    always @(posedge clk)
    begin
    	btn_in_reg <= `UD btn_in;
    end 

    genvar i;
    generate
    begin
        for(i=0;i<BTN_WIDTH;i=i+1)
        begin
            always @(posedge clk)
            begin
            	if (btn_in_reg[i] ^ btn_in[i]) //取按键边沿开始抖动区间标识
            		flag[i] <= `UD 1'b1;
            	else if (cnt[i]==18'h3ad43)    //持续20ms后归零
            		flag[i] <= `UD 1'b0;
                else
                    flag[i] <= `UD flag[i];
            end 
            
            always @(posedge clk)
            begin
            	if(cnt[i]==18'h3ad43)       //计数20ms时归零
            		cnt[i] <= `UD 18'd0;
            	else if(flag[i])            //抖动区间有效时计数
            		cnt[i] <= `UD cnt[i] + 1'b1;
            	else                        //非抖动区间保持0
            		cnt[i] <= `UD 18'd0;
            end 

            always @(posedge clk)
            begin
            	if(flag[i])                 //抖动区间，消抖输出保持
            		btn_deb_fix[i] <= `UD btn_deb_fix[i];
            	else                        //非抖动区间，按键状态传递到消抖输出
            		btn_deb_fix[i] <= `UD btn_in[i];
            end 
        end
    end
    endgenerate

endmodule
