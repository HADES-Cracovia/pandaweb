#!/bin/bash

echo "Setting addresses"
../../../tools/merge_serial_address.pl ../../../base/serials_trb3.db	dhcp/addresses_trb3.db
../../../tools/merge_serial_address.pl dhcp/serials_hub.db	dhcp/addresses_hub.db
../../../tools/merge_serial_address.pl dhcp/serials_trb2.db dhcp/addresses_start.db


 