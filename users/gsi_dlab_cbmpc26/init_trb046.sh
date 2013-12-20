export TRB3_SERVER=trb046:26000

pkill -f "trbnetd -i 46"
$HOME/trbsoft/trbnettools/trbnetd/server/trbnetd -i 46

