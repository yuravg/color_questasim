#!/usr/bin/env bash

title() {
    echo "----------------------------------------------------";
    printf "\e[32m\e[1m * %s:\e[0m\n" "$*"
}


title "example_err_vopt.sv"
vlog -lint -quiet example_err_vopt.sv && vopt -quiet example_err_vopt -o example_err_opt_vopt

title "empty-project"
vopt -quiet example_err_vopt-not-project -o example_err_opt_vopt

title "example_err_vopt_lib.sv"
vlog -lint -quiet example_err_vopt_lib.sv && vopt -quiet no_lib -o prj_opt

title "example_warning.sv"
vlog -lint -quiet example_warning.sv

title "example_pkg.sv"
vlog -quiet example_pkg.sv

title "example_err_vsim.sv"
vlog -lint -quiet example_err_vsim.sv && vopt -quiet example_err_vsim -o prj_opt && vsim -c -quiet prj_opt -l example_err_vsim.log -do "run -all; exit"

title "example_err_vsim_no_lic.sv"
vlog -lint -quiet example_err_vsim_no_lic.sv && vsim -c example_err_vsim_no_lic -do 'run -all; quit'

title "rm -rf work/ && vsim -c example_err_vsim_no_lic -do 'run -all; quit'"
rm -rf work/
vsim -c example_err_vsim_no_lic -do 'run -all; quit'
