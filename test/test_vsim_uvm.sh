#!/usr/bin/env bash

title() {
    echo "----------------------------------------------------";
    printf "\e[32m\e[1m * %s:\e[0m\n" "$*"
}


title "example_uvm_tb.sv"
vlog -incr -lint -sv +acc -timescale 1ns/1ps -quiet example_uvm_tb.sv && vsim -c example_uvm_tb -do 'run -all; quit'

title "incorrect options"
vlog -incr -lint -sv +acc -timescale 1ns/1ps -quiet example_uvm_tb.sv && vsim +UVM_VERBOSITY=TMP -c example_uvm_tb -do 'run -all; quit'

title "example_uvm_tb.sv with +uvm_no_relnotes"
vlog -incr -lint -sv +acc -timescale 1ns/1ps -quiet example_uvm_tb.sv && vsim +UVM_NO_RELNOTES -c example_uvm_tb -do 'run -all; quit'
