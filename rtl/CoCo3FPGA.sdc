create_clock -period 1000.000 -name img_mounted[3] [get_nodes emu:emu|hps_io:hps_io|img_mounted[3]]
create_clock -period 1000.000 -name img_mounted[2] [get_nodes emu:emu|hps_io:hps_io|img_mounted[2]]
create_clock -period 1000.000 -name img_mounted[1] [get_nodes emu:emu|hps_io:hps_io|img_mounted[1]]
create_clock -period 1000.000 -name img_mounted[0] [get_nodes emu:emu|hps_io:hps_io|img_mounted[0]]
create_clock -period 1000.000 -name RESET_N [get_nodes emu:emu|coco3fpga:coco3|RESET_N]
#set_false_path -from [get_nodes sysmem_lite:sysmem|sysmem_HPS_fpga_interfaces:fpga_interfaces|clocks_resets~FF_4365]
#create_clock -period 17.46 -name PH_2 [get_nodes emu:emu|coco3fpga:coco3|PH_2_RAW]
#create_clock -period 1000.000 -name CLK_6551[4] [get_nodes emu:emu|coco3fpga:coco3|CLK_6551[4]]

