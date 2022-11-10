module example_warning();

a

endmodule

// vlog -lint example_warning.sv
// OUTPUT:
// ** Warning: example_warning.sv(1): (vlog-2605) empty port name in port list.
// ** Error: (vlog-13069) example_warning.sv(5): near "endmodule": syntax error, unexpected endmodule.
// ** Error: example_warning.sv(3): (vlog-13205) Syntax error found in the scope following 'a'. Is there a missing '::'?
