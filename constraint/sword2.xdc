## Timing Assertions Section

# Primary Clock
set_property -dict {PACKAGE_PIN AC18 IOSTANDARD LVDS} [get_ports clk_200m_p]
set_property -dict {PACKAGE_PIN AD18 IOSTANDARD LVDS} [get_ports clk_200m_n]
create_clock -period 5.000 -name clk_200m -waveform {0.000 2.500} [get_nets {clk_200m}]

# Generated Clock
#create_generated_clock -name 100mhz_clk -source [get_pins {clk_div_unit/clk}] -divide_by 2 [get_pins {clk_div_unit/clk_div_counter[0]}]
#create_generated_clock -name vga_clk -source [get_pins {clk_div_unit/clk}] -divide_by 8 [get_pins {clk_div_unit/clk_div_counter[2]}]

## Physical Constrains Section

# Buttons
# Reset Button (Active Low)
set_property -dict {PACKAGE_PIN W13 IOSTANDARD LVCMOS18} [get_ports reset_n]
# Other Buttons (Active High)
# Button Matrix
#set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {btn_y[4]}]
#set_property -dict {PACKAGE_PIN W14 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {btn_y[3]}]
#set_property -dict {PACKAGE_PIN V14 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {btn_y[2]}]
#set_property -dict {PACKAGE_PIN V19 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {btn_y[1]}]
#set_property -dict {PACKAGE_PIN V18 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {btn_y[0]}]
#set_property -dict {PACKAGE_PIN W15 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {btn_x[3]}]
#set_property -dict {PACKAGE_PIN W19 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {btn_x[2]}]
#set_property -dict {PACKAGE_PIN W18 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {btn_x[1]}]
#set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {btn_x[0]}]
# Single Row Button
#set_property -dict {PACKAGE_PIN W16 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {bvcc}]
#set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {btn[4]}]
#set_property -dict {PACKAGE_PIN W14 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {btn[3]}]
#set_property -dict {PACKAGE_PIN V14 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {btn[2]}]
#set_property -dict {PACKAGE_PIN V19 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {btn[1]}]
#set_property -dict {PACKAGE_PIN V18 IOSTANDARD LVCMOS18 PULLUP true} [get_ports {btn[0]}]


# LEDs
#set_property -dict {PACKAGE_PIN N26 IOSTANDARD LVCMOS33} [get_ports led_clk]
#set_property -dict {PACKAGE_PIN N24 IOSTANDARD LVCMOS33} [get_ports led_clr]
#set_property -dict {PACKAGE_PIN M26 IOSTANDARD LVCMOS33} [get_ports led_dt]
#set_property -dict {PACKAGE_PIN R25 IOSTANDARD LVCMOS33} [get_ports led_en]

# 7-Segment Display
#set_property -dict {PACKAGE_PIN M24 IOSTANDARD LVCMOS33} [get_ports seg_clk]
#set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS33} [get_ports seg_pen]
#set_property -dict {PACKAGE_PIN P19 IOSTANDARD LVCMOS33} [get_ports seg_clrn]
#set_property -dict {PACKAGE_PIN L24 IOSTANDARD LVCMOS33} [get_ports seg_sout]

# switches
#set_property -dict {PACKAGE_PIN AA10 IOSTANDARD LVCMOS15} [get_ports {sw[0]}]
#set_property -dict {PACKAGE_PIN AB10 IOSTANDARD LVCMOS15} [get_ports {sw[1]}]
#set_property -dict {PACKAGE_PIN AA13 IOSTANDARD LVCMOS15} [get_ports {sw[2]}]
#set_property -dict {PACKAGE_PIN AA12 IOSTANDARD LVCMOS15} [get_ports {sw[3]}]
#set_property -dict {PACKAGE_PIN Y13 IOSTANDARD LVCMOS15} [get_ports {sw[4]}]
#set_property -dict {PACKAGE_PIN Y12 IOSTANDARD LVCMOS15} [get_ports {sw[5]}]
#set_property -dict {PACKAGE_PIN AD11 IOSTANDARD LVCMOS15} [get_ports {sw[6]}]
#set_property -dict {PACKAGE_PIN AD10 IOSTANDARD LVCMOS15} [get_ports {sw[7]}]
#set_property -dict {PACKAGE_PIN AE10 IOSTANDARD LVCMOS15} [get_ports {sw[8]}]
#set_property -dict {PACKAGE_PIN AE12 IOSTANDARD LVCMOS15} [get_ports {sw[9]}]
#set_property -dict {PACKAGE_PIN AF12 IOSTANDARD LVCMOS15} [get_ports {sw[10]}]
#set_property -dict {PACKAGE_PIN AE8 IOSTANDARD LVCMOS15} [get_ports {sw[11]}]
#set_property -dict {PACKAGE_PIN AF8 IOSTANDARD LVCMOS15} [get_ports {sw[12]}]
#set_property -dict {PACKAGE_PIN AE13 IOSTANDARD LVCMOS15} [get_ports {sw[13]}]
#set_property -dict {PACKAGE_PIN AF13 IOSTANDARD LVCMOS15} [get_ports {sw[14]}]
#set_property -dict {PACKAGE_PIN AF10 IOSTANDARD LVCMOS15} [get_ports {sw[15]}]

# VGA Ports
set_property -dict {PACKAGE_PIN T20 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports {blue[0]}]
set_property -dict {PACKAGE_PIN R20 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports {blue[1]}]
set_property -dict {PACKAGE_PIN T22 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports {blue[2]}]
set_property -dict {PACKAGE_PIN T23 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports {blue[3]}]
set_property -dict {PACKAGE_PIN R22 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports {green[0]}]
set_property -dict {PACKAGE_PIN R23 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports {green[1]}]
set_property -dict {PACKAGE_PIN T24 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports {green[2]}]
set_property -dict {PACKAGE_PIN T25 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports {green[3]}]
set_property -dict {PACKAGE_PIN N21 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports {red[0]}]
set_property -dict {PACKAGE_PIN N22 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports {red[1]}]
set_property -dict {PACKAGE_PIN R21 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports {red[2]}]
set_property -dict {PACKAGE_PIN P21 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports {red[3]}]
set_property -dict {PACKAGE_PIN M22 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports h_sync]
set_property -dict {PACKAGE_PIN M21 IOSTANDARD LVCMOS33 SLEW FAST} [get_ports v_sync]

# Serial Port
#set_property -dict {PACKAGE_PIN L25 IOSTANDARD LVCMOS33 PULLUP true} [get_ports uart_rx]
#set_property -dict {PACKAGE_PIN P24 IOSTANDARD LVCMOS33 DRIVE 16 SLEW FAST PULLUP true} [get_ports uart_tx]

# PS/2
#set_property -dict {PACKAGE_PIN N18 IOSTANDARD LVCMOS33 PULLUP true} [get_ports ps2_clk]
#set_property -dict {PACKAGE_PIN M19 IOSTANDARD LVCMOS33 PULLUP true} [get_ports ps2_data]