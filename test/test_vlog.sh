#!/usr/bin/env bash

title() {
    echo "----------------------------------------------------";
    printf "\e[32m\e[1m * %s:\e[0m\n" "$*"
}


title "missing_file.sv"
vlog -lint -quiet example_missing_file.sv

title "example_warning.sv"
vlog -lint example_warning.sv

title "example_pkg.sv"
vlog -quiet example_pkg.sv
