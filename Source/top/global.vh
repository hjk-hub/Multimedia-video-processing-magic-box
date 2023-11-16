`include "F:/Project/WorkSpace/FPGA/Video_pro/Source/top/define.vh" 
//输入视频源参数
// parameter BURST_LEN = 16  ,//基本突发长度,其实也是最大突发程度,紫光50H DDR IP最大突发长度为16
// parameter IMG_COL   = 320 ,//输入视频源列长度
// parameter IMG_ROW   = 40  ,//输入视频源行长度
// parameter IMG_COL   = 1280 ,//输入视频源列长度
// parameter IMG_ROW   = 720  ,//输入视频源行长度
// parameter SCALE     = 2   ,//缩放因子,输入缩放保存,以方便拼接,此处缩一倍,组成2*2,即四视频源拼接
// `define	  SRC

// parameter LINE_ADDR_ADD =   8*2*IMG_COL*16/256/SCALE  ,
// parameter LINE_BURST_NUM =  IMG_COL*16/SCALE/256     ,
`ifdef  SIM
parameter IMG_COL   = 640 ,//输入视频源列长度
parameter IMG_ROW   = 40  ,//输入视频源行长度
`endif
`ifdef  SRC
parameter IMG_COL   = 1280 ,//输入视频源列长度
parameter IMG_ROW   = 720  ,//输入视频源行长度
`endif

// frame_buf
parameter   H_NUM       = IMG_COL  ,
parameter   V_NUM       = IMG_ROW  ,
parameter   PIX_WIDTH   = 16,//24   ,

parameter LEN_WIDTH       = 32,
parameter LINE_ADDR_WIDTH = 22,//19;//1440 * 1080 = 1 555 200 = 21'h17BB00
parameter FRAME_CNT_WIDTH = 28 - LINE_ADDR_WIDTH,

//四路输入视频,保存基地址,两个地址交替读写,乒乓操作
parameter Base_addr1_1 = 28'h000_0000                           ,
parameter Base_addr1_2 = Base_addr1_1 + IMG_COL / 4             ,
parameter Base_addr1_3 = Base_addr1_1 + IMG_COL * IMG_ROW / 4   ,
parameter Base_addr1_4 = Base_addr1_3 + IMG_COL / 4             ,

parameter Base_addr2_1 = 28'h010_0000                           ,
parameter Base_addr2_2 = Base_addr2_1 + IMG_COL / 4             ,
parameter Base_addr2_3 = Base_addr2_1 + IMG_COL * IMG_ROW / 4   ,
parameter Base_addr2_4 = Base_addr2_3 + IMG_COL / 4             ,

parameter Base_addr3_1 = 28'h020_0000                           ,
parameter Base_addr3_2 = Base_addr3_1 + IMG_COL / 4             ,
parameter Base_addr3_3 = Base_addr3_1 + IMG_COL * IMG_ROW / 4   ,
parameter Base_addr3_4 = Base_addr3_3 + IMG_COL / 4             ,

parameter Base_addr4_1 = 28'h030_0000                           ,
parameter Base_addr4_2 = Base_addr4_1 + IMG_COL / 4             ,
parameter Base_addr4_3 = Base_addr4_1 + IMG_COL * IMG_ROW / 4   ,
parameter Base_addr4_4 = Base_addr4_3 + IMG_COL / 4             ,


//
parameter Process_addr_1 = 28'h040_0000                           ,
parameter Process_addr_2 = 28'h050_0000                           ,
parameter Process_addr_3 = 28'h060_0000                           ,
parameter Process_addr_4 = 28'h070_0000                           ,
//
parameter Base_Char_addr = 28'h080_0000                           ,
//DDR 物理接口
parameter MEM_ROW_ADDR_WIDTH   = 15   ,
parameter MEM_COL_ADDR_WIDTH   = 10   ,
parameter MEM_ADDR_WIDTH       = 15   ,
parameter MEM_BADDR_WIDTH      = 3    ,
parameter MEM_DQ_WIDTH         = 32   ,
parameter MEM_DM_WIDTH         = 4    ,
parameter MEM_DQS_WIDTH        = 4    ,
parameter CTRL_ADDR_WIDTH      = 28   ,
parameter MEM_NUM              = 2,//MEM_DQ_WIDTH/16,

//1. AXI总线
parameter AXI_ADDR_WIDTH	= 28 ,
parameter AXI_DATA_WIDTH    = 256,
parameter AXI_BURST_LEN	    = 16 ,
parameter AXI_ID_WIDTH		= 8  ,
// parameter  AXI_TARGET_SLAVE_BASE_ADDR	= 32'h00000000,
parameter AXI_AWUSER_WIDTH	= 0 ,
parameter AXI_ARUSER_WIDTH	= 0 ,
parameter AXI_WUSER_WIDTH	= 0 ,
parameter AXI_RUSER_WIDTH	= 0 ,
parameter AXI_BUSER_WIDTH	= 0 ,

//FIFO宽度

parameter COL_720P = 1280         , 
parameter ROW_720P = 760         , 
parameter COL_1080P = 1920         , 
parameter ROW_1080P = 1080         , 
//FIFO宽度
parameter FIFO_ADDR_WIDTH = 8         ,     
parameter FIFO_DATACOUNT_WIDTH = 8   

// parameter FIFO_ADDR_WIDTH = 11              

//AXI_BURST_LEN因为每个模块不同,比如DDR可以设置大,视频处///理就只能设置小,所以不统一,单独赋
// `define    AXI_ADDR_WIDTH              28
// `define    AXI_DATA_WIDTH              256
// `define    AXI_ID_WIDTH                4
// `define    AXI_AWUSER_WIDTH            1
// `define    AXI_ID_ARUSER_WIDTH         1
// `define    AXI_ID_WUSER_WIDTH	       1
// `define    AXI_ID_RUSER_WIDTH	       1
// `define    AXI_ID_BUSER_WIDTH	       1
// //AXI INTERCONECT
// `define    S_COUNT                  4//上层master数量
// `define    M_COUNT                  1//下层slaver数量
// `define    DATA_WIDTH               256
// `define    ADDR_WIDTH               28
// `define    STRB_WIDTH               32
// `define    ID_WIDTH                 4
// `define    AWUSER_ENABLE            0
// `define    AWUSER_WIDTH             1
// `define    WUSER_ENABLE             0
// `define    WUSER_WIDTH              1
// `define    BUSER_ENABLE             0
// `define    BUSER_WIDTH              1
// `define    ARUSER_ENABLE            0
// `define    ARUSER_WIDTH             1
// `define    RUSER_ENABLE             0
// `define    RUSER_WIDTH              1
// `define    FORWARD_ID               1
// `define    M_REGIONS                1
// `define    M_BASE_ADDR              {28'h000_0000}
// `define    M_ADDR_WIDTH             {1{{1{32'd24}}}}
// `define    M_CONNECT_READ           {1{{1{1'b1}}}}
// `define    M_CONNECT_WRITE          {1{{1{1'b1}}}}
// `define    M_SECURE                 {1{1'b0}}

// //DDR物理连接
// `define DFI_CLK_PERIOD        10000     
// `define MEM_ROW_WIDTH         15        
// `define MEM_COLUMN_WIDTH      10        
// `define MEM_BANK_WIDTH        3         
// `define MEM_DQ_WIDTH          32       
// `define MEM_DM_WIDTH          4        
// `define MEM_DQS_WIDTH         4        
// `define REGION_NUM            3        
// `define CTRL_ADDR_WIDTH       28

//
//
//2.OV5640摄像头




//DDR3地址分配
//输入四帧缓存,乒乓输出
//1.COMS1输入 按照rgb565 1920*1080:2200*1125*16/32  28'h012E1FC
// `define    ADDR_CMOS1_FRAME1        28'h000_0000
// `define    ADDR_CMOS1_FRAME2        28'h012_E1FB
// `define    ADDR_CMOS1_FRAME3        28'h025_C3F8
// `define    ADDR_CMOS1_FRAME4        28'h038_A5F3

// `define    ADDR_CMOS2_FRAME1        28'h04B_87EF
// `define    ADDR_CMOS2_FRAME2        28'h05E_69EB
// `define    ADDR_CMOS2_FRAME3        28'h071_4BE7
// `define    ADDR_CMOS2_FRAME4        28'h084_2DE3

// `define    ADDR_HDMI_IN_FRAME1      28'h097_0FDF
// `define    ADDR_HDMI_IN_FRAME2      28'h0A9_F1DB
// `define    ADDR_HDMI_IN_FRAME3      28'h0BC_D3D7
// `define    ADDR_HDMI_IN_FRAME4      28'h0CF_B5D3

// //缩放地址
// `define    ADDR_Scale_FRAME1      28'h0E2_97CF
// `define    ADDR_Scale_FRAME2      28'h0F5_79CB
// `define    ADDR_Scale_FRAME3      28'h108_5BC7
// `define    ADDR_Scale_FRAME4      28'h11B_3DC3

// //旋转地址
// `define    ADDR_Scale_FRAME1      28'h12E_1FBF
// `define    ADDR_Scale_FRAME2      28'h141_01BB
// `define    ADDR_Scale_FRAME3      28'h153_E3B7
// `define    ADDR_Scale_FRAME4      28'h166_C5B3

// '0012E1FB'
//     '0025C3F7'
//     '0038A5F3'
//     '004B87EF'
//     '005E69EB'
//     '00714BE7'
//     '00842DE3'
//     '00970FDF'
//     '00A9F1DB'
//     '00BCD3D7'
//     '00CFB5D3'
//     '00E297CF'
//     '00F579CB'
//     '01085BC7'
//     '011B3DC3'
//     '012E1FBF'
//     '014101BB'
//     '0153E3B7'
//     '0166C5B3'
//     '0179A7AF'
//     '018C89AB'
//     '019F6BA7'
//     '01B24DA3'
//     '01C52F9F'
//     '01D8119B'
//     '01EAF397'
//     '01FDD593'
//     '0210B78F'
//     '0223998B'
//     '02367B87'
