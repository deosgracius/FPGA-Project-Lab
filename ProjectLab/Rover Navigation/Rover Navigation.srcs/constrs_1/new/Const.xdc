
## Clock signal
set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

# Motor control and Servo (JXADC)
set_property -dict { PACKAGE_PIN J3   IOSTANDARD LVCMOS33 } [get_ports pwm_servo]
set_property -dict { PACKAGE_PIN L3   IOSTANDARD LVCMOS33 } [get_ports enB]
set_property -dict { PACKAGE_PIN M2   IOSTANDARD LVCMOS33 } [get_ports in4]
set_property -dict { PACKAGE_PIN N2   IOSTANDARD LVCMOS33 } [get_ports in2]
set_property -dict { PACKAGE_PIN K3   IOSTANDARD LVCMOS33 } [get_ports enA]
set_property -dict { PACKAGE_PIN M1   IOSTANDARD LVCMOS33 } [get_ports in3]
set_property -dict { PACKAGE_PIN N1   IOSTANDARD LVCMOS33 } [get_ports in1]

## IPS Sensors, Proximity sensors and MOSFET (JC)
set_property -dict { PACKAGE_PIN K17  IOSTANDARD LVCMOS33 } [get_ports prox1]
set_property -dict { PACKAGE_PIN M18  IOSTANDARD LVCMOS33 } [get_ports sensor_T]
set_property -dict { PACKAGE_PIN N17  IOSTANDARD LVCMOS33 } [get_ports sensor_right]
set_property -dict { PACKAGE_PIN P18  IOSTANDARD LVCMOS33 } [get_ports sensor_left]
set_property -dict { PACKAGE_PIN L17  IOSTANDARD LVCMOS33 } [get_ports mosfet]
set_property -dict { PACKAGE_PIN M19  IOSTANDARD LVCMOS33 } [get_ports prox3]
set_property -dict { PACKAGE_PIN P17  IOSTANDARD LVCMOS33 } [get_ports prox2]


## LEDs
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
set_property -dict { PACKAGE_PIN E19   IOSTANDARD LVCMOS33 } [get_ports {led[1]}]
set_property -dict { PACKAGE_PIN U19   IOSTANDARD LVCMOS33 } [get_ports {led[2]}]
set_property -dict { PACKAGE_PIN V19   IOSTANDARD LVCMOS33 } [get_ports {led[3]}]
set_property -dict { PACKAGE_PIN W18   IOSTANDARD LVCMOS33 } [get_ports {led[4]}]
set_property -dict { PACKAGE_PIN U15   IOSTANDARD LVCMOS33 } [get_ports {led[5]}]
set_property -dict { PACKAGE_PIN U14   IOSTANDARD LVCMOS33 } [get_ports {led[6]}]
set_property -dict { PACKAGE_PIN V14   IOSTANDARD LVCMOS33 } [get_ports {led[7]}]
set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33 } [get_ports {led[8]}]
set_property -dict { PACKAGE_PIN V3    IOSTANDARD LVCMOS33 } [get_ports {led[9]}]
set_property -dict { PACKAGE_PIN W3    IOSTANDARD LVCMOS33 } [get_ports {led[10]}]
set_property -dict { PACKAGE_PIN U3    IOSTANDARD LVCMOS33 } [get_ports {led[11]}]
set_property -dict { PACKAGE_PIN P3    IOSTANDARD LVCMOS33 } [get_ports {led[12]}]
set_property -dict { PACKAGE_PIN N3    IOSTANDARD LVCMOS33 } [get_ports {led[13]}]
set_property -dict { PACKAGE_PIN P1    IOSTANDARD LVCMOS33 } [get_ports {led[14]}]
set_property -dict { PACKAGE_PIN L1    IOSTANDARD LVCMOS33 } [get_ports {led[15]}]


## Seven Segment Display
set_property -dict { PACKAGE_PIN W7   IOSTANDARD LVCMOS33 } [get_ports {seg[0]}]
set_property -dict { PACKAGE_PIN W6   IOSTANDARD LVCMOS33 } [get_ports {seg[1]}]
set_property -dict { PACKAGE_PIN U8   IOSTANDARD LVCMOS33 } [get_ports {seg[2]}]
set_property -dict { PACKAGE_PIN V8   IOSTANDARD LVCMOS33 } [get_ports {seg[3]}]
set_property -dict { PACKAGE_PIN U5   IOSTANDARD LVCMOS33 } [get_ports {seg[4]}]
set_property -dict { PACKAGE_PIN V5   IOSTANDARD LVCMOS33 } [get_ports {seg[5]}]
set_property -dict { PACKAGE_PIN U7   IOSTANDARD LVCMOS33 } [get_ports {seg[6]}]    


set_property -dict { PACKAGE_PIN U2   IOSTANDARD LVCMOS33 } [get_ports {an[0]}]
set_property -dict { PACKAGE_PIN U4   IOSTANDARD LVCMOS33 } [get_ports {an[1]}]
set_property -dict { PACKAGE_PIN V4   IOSTANDARD LVCMOS33 } [get_ports {an[2]}]
set_property -dict { PACKAGE_PIN W4   IOSTANDARD LVCMOS33 } [get_ports {an[3]}]