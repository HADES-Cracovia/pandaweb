#!/bin/bash

export TRB3_SERVER=trb3069

if [ -z "$(pidof trbnetd)" ]; then
	/home/hadaq/trbsoft/trbnettools_trb3/binlocal/trbnetd
fi

. /home/hadaq/trbsoft/daqtools/users/cosy_test/trbnet_env_pexor.sh
