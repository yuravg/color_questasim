module example_err_vopt_lib();

endmodule

// vlog -lint -quiet example_err_vopt_lib.sv && vopt -quiet no_lib -o prj_opt
// OUTPUT:
// ** Warning: example_err_vopt_lib.sv(1): (vlog-2605) empty port name in port list.
// ** Error: (vopt-13130) Failed to find design unit no_lib.
//         Searched libraries:
//             work
// Optimization failed
