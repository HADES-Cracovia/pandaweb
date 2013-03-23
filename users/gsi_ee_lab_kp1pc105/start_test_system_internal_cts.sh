#
# set addresses

merge_serial_address.pl ~/trbsoft/daqtools/base/serials_trb3.db ~/trbsoft/daqtools/base/addresses_trb3.db  > /dev/null

./configure_trb3.sh # central hub configuration to send data via GbE

# setup tdcs on TRB3
#trbcmd w 0xfe48 0xc0 0x00000001 ## logic analyser control register
trbcmd w 0xfe48 0xc1 0x000f0005 ## trigger window enable & trigger window width
trbcmd w 0xfe48 0xc2 0x0000000f ## channel 01-31 enable
trbcmd w 0xfe48 0xc3 0x00000000 ## channel 32-63 enable

# setup tdc on TRB3 for designs after 20130320
#trbcmd w 0xfe48 0xc800 0x00000001 ## logic analyser control register
#trbcmd w 0xfe48 0xc801 0x000f0005 ## trigger window enable & trigger window width
#trbcmd w 0xfe48 0xc802 0x0000000f ## channel 01-31 enable
#trbcmd w 0xfe48 0xc803 0x00000000 ## channel 32-63 enable

trbcmd w 0x8000 0xa137 0xfffff # set pulser #1 in CTS to 95Hz

