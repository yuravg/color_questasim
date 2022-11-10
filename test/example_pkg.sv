package example_pkg;

`include "class_a.svh";

endpackage

// vlog example_pkg.sv
// OUTPUT:
// "** Error: (vlog-13069) ** while parsing file included at example_pkg.sv(3)"
// "** at class_a.svh(3): near "function": syntax error, unexpected function, expecting ';' or ','."
