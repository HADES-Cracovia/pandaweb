#!/bin/bash
(echo -n -e "\n"; sleep .1; echo -n -e "*IDN?\nOUTPUT:GENERAL OFF\nMEAS:CURR?\n"; sleep 1.7; echo -n -e "OUTPUT:GENERAL ON\nMEAS:CURR?\n";) | socat  - /dev/HAMEG_HO732_VCP023842636
