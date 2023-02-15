#!/usr/bin/env bash

title() {
    echo "----------------------------------------------------";
    printf "\e[32m\e[1m * %s:\e[0m\n" "$*"
}


title "example_err_vsim_no_lic.sv"
vlog -lint -quiet example_err_vsim_no_lic.sv && vsim -c example_err_vsim_no_lic -do 'run -all; quit'

title "rm -rf work/ && vsim -c example_err_vsim_no_lic -do 'run -all; quit'"
rm -rf work/
vsim -c example_err_vsim_no_lic -do 'run -all; quit'
