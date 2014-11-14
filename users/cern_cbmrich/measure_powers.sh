#!/usr/bin/env bash

~/trbsoft/daqtools/users/cern_cbmrich/hameg.pl meas hameg01 &
~/trbsoft/daqtools/users/cern_cbmrich/hameg.pl meas hameg02 &
~/trbsoft/daqtools/users/cern_cbmrich/hameg.pl meas hameg03 &
~/trbsoft/daqtools/users/cern_cbmrich/tdk.pl meas tdklambda &

wait