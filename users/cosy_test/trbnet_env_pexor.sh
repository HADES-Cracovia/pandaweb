#!/bin/bash

export WD="/home/hadaq/trbsoft/daqtools/users/cosy_test/"

EXTRALIB=${HOME}/usr/lib64:${HOME}/projects/install/lib
HADESLIB=${HOME}/trbsoft/trbnettools/lib

export LD_LIBRARY_PATH=${HADESLIB}:${EXTRALIB}:${LD_LIBRARY_PATH}
export PATH=${HOME}/bin:${HOME}/usr/bin:${PATH}

TRBSOFT=${HOME}/trbsoft

export DAQHOSTNAME=localhost
export TRBNETID=0

export DAQOPSERVER=${DAQHOSTNAME}:${TRBNETID}

echo "TRB Soft dir        : ${TRBSOFT}"
echo "TRBnet environment ready to use!"
echo "================================"
echo ""

#PS1=${COLOR_YELLOW}'\u@\h\[\033[01;34m\] \w$(parse_git_branch)'${COLOR_NC}' '

[ -z "$(pidof trbnetd)" ] && /home/hadaq/trbsoft/trbnettools/bin/trbnetd
