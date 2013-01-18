==Directories
config		Configuration files for scripts
web		Web-based tools
files		All temporary files created by scripts, not in CVS
jan             Jans development directory
thresholds      Tools to set, determine and retrieve thresholds
tools           General tools

==Scripts
dac_progam.pl		Programs a LTC2600 DAC with settings from a db files
merge_serial_address.pl	Generate a address list from the id- and serials databases for TrbNet
padiwa.pl		R/W of all padiwa registers

jan/adcplot.pl		Takes values (measurements from AD9222 and similar) from a TrbNet-Fifo and plots them using the HPlot library

tools/compiletime.pl	Reads the compile time of the designs loaded to FPGAs
tools/hadplot		Plot the content of any register or set of registers
tools/loadregisterdb.pl	Loads register settings from a trbnet db-file


==Config Files
config/DAC_cbmrich.db	DB file with settings for DAC on CBM-RICH board
config/DAC_config.db	Example file with settings for LTC2600 DAC chains
