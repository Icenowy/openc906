#
# Altera USB-Blaster with AJI Client Driver
# Access jtagserv.exe or jtagd on your system
#
# https://www.intel.com/content/dam/www/programmable/us/en/pdfs/literature/ug/ug_usb_blstr.pdf
#
# This is a sample configuration file for user of NIOS V
# IP core. It should work for the first NIOSV IP core
#
# For the second and subsequent core, you need to modify this
# configuration file by adding additional "vjtag create ..." and 
# corresponding "target create ... riscv ..." commands to
# match your design.

adapter driver aji_client

# if you have more than one JTAG cable on your JTAG server
# you need to specify your JTAG cable by uncommenting 
# the command below and replace {USB-BlasterII} with the
# name of your cable as reported by jtagquery.
#
#  aji_client hardware ubii2arria10 {USB-BlasterII}


# Intel (Altera) Arria10 FPGA SoC

if { [info exists CHIPNAME] } {
	set _CHIPNAME $CHIPNAME
} else {
	set _CHIPNAME arria10
}

# ARM CoreSight Debug Access Port (dap HPS)
if { [info exists DAP_TAPID] } {
	set _DAP_TAPID $DAP_TAPID
} else {
	set _DAP_TAPID 0x4ba00477
}

# Subsidiary TAP: fpga (tap)
# See Intel Arria 10 Handbook
# https://www.intel.com/content/dam/altera-www/global/en_US/pdfs/literature/hb/arria-10/a10_handbook.pdf
jtag newtap $_CHIPNAME.fpga tap -irlen 10 -expected-id 0x02ee20dd -expected-id 0x02e220dd \
	-expected-id 0x02ee30dd -expected-id 0x02e230dd -expected-id 0x02e240dd \
	-expected-id 0x02ee50dd -expected-id 0x02e250dd -expected-id 0x02ee60dd \
	-expected-id 0x02e660dd -expected-id 0x02e260dd -expected-id 0x02e060dd \
	-expected-id 0x02e620dd -expected-id 0x02e020dd -expected-id 0x02e630dd \
	-expected-id 0x02e030dd -expected-id 0x02e040dd -expected-id 0x02e650dd \
	-expected-id 0x02e050dd

#
# NIOS V target
vjtag create $_CHIPNAME.fpga.tap.vjtag -chain-position $_CHIPNAME.fpga.tap -expected-id 0x00406E00
set _TARGETNAME $_CHIPNAME.softrv
target create $_CHIPNAME.softrv riscv -chain-position $_CHIPNAME.fpga.tap.vjtag

$_TARGETNAME configure -work-area-phys 0x8000f000 -work-area-size 0x1000 -work-area-backup 0

## optional riscv parameter that is useful for slow network.
# riscv set_reset_timeout_sec 120
# riscv set_command_timeout_sec 120
