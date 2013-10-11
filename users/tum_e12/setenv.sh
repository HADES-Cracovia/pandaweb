#!/bin/bash

. /etc/e12functions.sh 

BASEDIR=/home/rich/TRB/trbsoft

expath ${BASEDIR}/trbnettools/bin

export PERL5LIB=${BASEDIR}/trbnettools/perllib/usr/local/lib64/perl5:${BASEDIR}/daqtools/web/CtsPlugins:${BASEDIR}/daqtools/web/include

export TRB3_SERVER=trb3
#export DAQOPSERVER=bia:12
export DAQOPSERVER=bia


export TRBNETID=12
