# 基于紫光同创FPGA的多媒体视频处理魔盒（2023全国大学生FPGA创新设计竞赛，队伍编号：1008）

## .Project文件夹：PDS工程文件
## . Source：主要程序
## .Sim：modelsim仿真文件
（程序移植时请注意本工程顶层文件参数定义时使用了绝对地址，移植的话需要按照本地地址更改）


## 主要程序所在文件夹Project/source和Source，下面介绍其内含模块

### 1 Projiect/source

#### 文件夹下主要是OV5640驱动模块、HDMI驱动模块、为DDR读写写的DDR读写控制器和部分IP核

### 2 Source

#### 该文件夹主要包括视频处理模块，包含

####  2.1 AXI_arbit文件夹：内为驱动DDR读写控制器的DDR读写仲裁器

#####   2.2 Frame文件夹：内含

```
Frame_index.v：DDR读写地址控制模块
Frame_cnt.v：将720P视频缩放为360P
fram_buf.v:读写视频的顶层文件
wr_buf.v：视频写模块
rd_buf.v：视频读模块
wr_char.v：图片/字符叠加写模块
rd_char.v：图片/字符叠加读模块
```

####  2.3 HDMI文件夹：内含

```
color_bar.v:输出视频时序产生模块
```

####  2.4 Mode_choice文件夹：内含

```
btn_deb_fix.v:按键消抖
mode_choice.v：读取键值并LED显示
```

####  2.5 Processor文件夹：视频处理模块总文件夹，内含processor.v：总的视频处理模块，且包含如下子文件夹实现各处理功能

#####  2.5.1 binary文件夹：内含二值化模块

#####  2.5.2 brightness_contrast文件夹：内含亮度/对比度调节模块

#####  2.5.2 mean_filter文件夹：内含中值滤波模块

#####  2.5.3 multiCamera_ctr文件夹：内含双目摄像头融合模块

#####  2.5.4 rgb2ycbrcc文件夹：内含灰度图模块

#####  2.5.5 scale文件夹：内含任意比例缩放模块

####  2.6 top文件夹：内含顶层模块top.v，以及参数定义模块define.vh、global.vh

####  2.7 UDP文件夹：内含

#####  2.7.1 data_gen文件夹：内含以太网UDP传输视频解析模块udp_databus.v、以太网UDP传输图片/字符叠加数据解析模块udp_char.v

#####  2.7.2 其余文件实现以太网的arp、UDP协议