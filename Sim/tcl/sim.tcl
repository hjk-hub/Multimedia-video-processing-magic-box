# 叉掉modelsim后可能还有后台残余，关掉
if {[file exists work]} {
  file delete -force work  
}
vlib work
vmap work work

set LIB_DIR  D:/LenovoSoftstore/Install/ZiGuang/PDS_2022.1/ip/system_ip/ipsxb_hmic_s/ipsxb_hmic_eval/ipsxb_hmic_s/../../../../../arch/vendor/pango/verilog/simulation

vlib work
vlog -sv -work work -mfcu -incr -f ../file_list/sim_ddr_list.f -y $LIB_DIR +libext+.v +incdir+../../example_design/bench/mem/ 
vlog -sv -work work -mfcu -incr -f ../file_list/sim_src_list.f -y $LIB_DIR +libext+.v +incdir+../../example_design/bench/mem/ 


vsim -voptargs=+acc work.new_top

# add wave -position insertpoint sim:/new_top/u_fram_buf/mem_write_arbi_m0/*

# add wave -position insertpoint sim:/new_top/u_fram_buf/wr_buf_cmos1/*
add wave -position insertpoint sim:/new_top/*
add wave -position insertpoint sim:/new_top/u_fram_buf/*
add wave -position insertpoint sim:/new_top/u_fram_buf/u_wr_char/*
add wave -position insertpoint sim:/new_top/u_fram_buf/u_rd_char/*
add wave -position insertpoint sim:/new_top/u_fram_buf/mem_write_arbi_m0/*
# add wave -position insertpoint sim:/new_top/u_fram_buf/u_processor_inst/*
# add wave -position insertpoint sim:/new_top/u_fram_buf/u_processor_inst/u_multiCamera_ctr/*
# add wave -position insertpoint sim:/new_top/u_processor_inst/u_scale_ctr/wr_buf_cmos1/*
# add wave -position insertpoint sim:/new_top/u_processor_inst/u_scale_ctr/rd_buf_cmos1/*
# add wave -position insertpoint sim:/new_top/wr_rd_ctrl_top/*
# add wave -position insertpoint sim:/new_top/wr_rd_ctrl_top/wr_ctrl/*
# add wave -position insertpoint sim:/new_top/wr_rd_ctrl_top/wr_cmd_trans/*
# add wave -position insertpoint sim:/new_top/u_fram_buf/*

# add wave -position insertpoint sim:/new_top/u_fram_buf/u_processor_inst/*

# add wave -position insertpoint sim:/new_top/u_fram_buf/u_processor_inst/u_scale_ctr/*

# add wave -position insertpoint sim:/new_top/u_fram_buf/u_processor_inst/u_scale_ctr/wr_buf_cmos1/*

# add wave -position insertpoint sim:/new_top/u_fram_buf/u_processor_inst/u_scale_ctr/rd_buf_cmos1/*
# add wave -position insertpoint sim:/tb3/*
# add wave -position insertpoint sim:/new_top/fram_buf/wr_buf_cmos1/u_fifo_16i_256O_axiWr/*

# add wave -position insertpoint sim:/new_top/fram_buf/wr_buf_cmos1/u_fifo_4096x8_1/*

# add wave -position insertpoint sim:/new_top/u_scale_top/u_vin_scale_down_r/*

# add wave -position insertpoint sim:/new_top/u_scale_top/u_vin_scale_down_r/u_fifo_4096x8_11/*
# add wave -position insertpoint sim:/new_top/u_scale_top/u_vin_scale_down_r/u_fifo_4096x8_1/*


# add wave -position insertpoint sim:/new_top/u_scale_top/u_vin_scale_down_r/u_fifo_4096x8_1/*
# add wave -position insertpoint sim:/new_top/u_color_bar_11/*
# add wave -position insertpoint sim:/new_top/u_color_bar_12/*
# add wave -position insertpoint sim:/tb3/*
# add wave -position insertpoint sim:/tb3/u_color_bar_11/*
# add wave -position insertpoint sim:/tb3/u_sync_vg/*
# add wave -position insertpoint sim:/new_top/u_scale_top/u_vin_scale_down_r/u_fifo_4096x8_1/*
# add wave -position insertpoint sim:/tb3/u_scale_top/u_vin_scale_down_r/u_fifo_4096x8_2/*
# add wave -position insertpoint sim:/tb3/u_scale_top/*

# add wave -position insertpoint sim:/tb3/u_scale_top/u_vin_scale_down_b/*

# add wave -position insertpoint sim:/tb3/u_scale_top/u_vin_scale_down_b/u_scaler/*

# add wave -position insertpoint sim:/tb3/u_scale_top/u_vin_scale_down_b/u_scaler/calu_h/*

# add wave -position insertpoint sim:/tb3/u_scale_top/u_vin_scale_down_b/u_fifo_4096x8_1/*
# add wave -position insertpoint sim:/tb3/u_scale_top/u_vin_scale_down_b/u_fifo_4096x8_2/*
run 2ms

