#create_clock -period 20.000 -name CLK50MHZ [get_ports CLK*]
#derive_pll_clocks
#derive_clock_uncertainty
#set_input_delay -fall -clock CLK50MHZ 12 [get_ports RAM0_DATA*]
#set_input_delay -fall -clock CLK50MHZ 12 [get_ports RAM1_DATA*]
#set_output_delay -fall -clock CLK50MHZ 1 [get_ports RAM0_ADDRESS*]
#set_output_delay -fall -clock CLK50MHZ 1 [get_ports RAM1_ADDRESS*]
#set_output_delay -fall -clock CLK50MHZ 1 [get_ports RAM0_BE*]
#set_output_delay -fall -clock CLK50MHZ 1 [get_ports RAM1_BE*]
#set_output_delay -fall -clock CLK50MHZ 1 [get_ports RAM0_RW*]
#set_output_delay -fall -clock CLK50MHZ 1 [get_ports RAM1_RW*]
#set_output_delay -fall -clock CLK50MHZ 1 [get_ports PH_2_RAW]

create_clock -period 20.000 -name CLK50MHZ [get_ports CLK*]
derive_pll_clocks
derive_clock_uncertainty
# RAM0 mainly for the new SRAM
set_input_delay -fall -max -clock CLK50MHZ 10 [get_ports RAM0_DATA*]
set_input_delay -fall -min -clock CLK50MHZ 10 [get_ports RAM0_DATA*]
set_output_delay -fall -min -clock CLK50MHZ -0.5 [get_ports RAM0_DATA*]
set_output_delay -fall -max -clock CLK50MHZ -0.5 [get_ports RAM0_DATA*]
set_output_delay -fall -clock CLK50MHZ 1 [get_ports RAM0_ADDRESS*]
set_output_delay -fall -clock CLK50MHZ 3 [get_ports RAM0_RW*]
set_output_delay -fall -clock CLK50MHZ 3 [get_ports RAM0_BE*]
# RAM1 for the Analog Board
set_input_delay -fall -clock CLK50MHZ 10 [get_ports RAM1_DATA*]
set_output_delay -fall -clock CLK50MHZ 1 [get_ports RAM1_ADDRESS*]
set_output_delay -fall -clock CLK50MHZ 1 [get_ports RAM1_RW*]
set_output_delay -fall -clock CLK50MHZ 4 [get_ports RAM1_BE*]
# System Clock
set_output_delay -fall -clock CLK50MHZ 1 [get_ports PH_2]
