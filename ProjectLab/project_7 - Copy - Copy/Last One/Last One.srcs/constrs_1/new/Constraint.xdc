## File: constraints.xdc

## Clock signal
set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Reset signal (using btnC for reset)
#set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports reset]

##Pmod Header JA - Motor Control Signals
set_property -dict { PACKAGE_PIN J1   IOSTANDARD LVCMOS33 } [get_ports in1]
set_property -dict { PACKAGE_PIN L2   IOSTANDARD LVCMOS33 } [get_ports in2]
set_property -dict { PACKAGE_PIN J2   IOSTANDARD LVCMOS33 } [get_ports in3]
set_property -dict { PACKAGE_PIN G2   IOSTANDARD LVCMOS33 } [get_ports in4]
set_property -dict { PACKAGE_PIN H1   IOSTANDARD LVCMOS33 } [get_ports enA]
set_property -dict { PACKAGE_PIN K2   IOSTANDARD LVCMOS33 } [get_ports enB]

##Pmod Header JXADC - Sensor Inputs
set_property -dict { PACKAGE_PIN J3   IOSTANDARD LVCMOS33 } [get_ports Lsensor]
set_property -dict { PACKAGE_PIN L3   IOSTANDARD LVCMOS33 } [get_ports Rsensor]
set_property -dict { PACKAGE_PIN M2   IOSTANDARD LVCMOS33 } [get_ports Msensor1]
set_property -dict { PACKAGE_PIN N2   IOSTANDARD LVCMOS33 } [get_ports Msensor2]

## Configuration options, can be used for all designs
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

## SPI configuration mode options for QSPI boot, can be used for all designs
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]