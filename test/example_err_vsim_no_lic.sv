
module example_err_vsim_no_lic;
int q0[$] = '{1, 2, 3};
int d;

initial begin
    d = q0.sum();
	$display("sum()=%0d", d);

    d = q1.sum();
  end
endmodule

// OUTPUT:
// NOTE: License Message do not shown
// vlog -lint -quiet example_err_vsim_no_lic.sv && vsim -c example_err_vsim_no_lic -do 'run -all; quit'
//
// # ** Error (suppressible): example_err_vsim_no_lic.sv(10): (vopt-7063) Failed to find 'q1' in hierarchical name 'q1.sum'.
// #         Region: example_err_vsim_no_lic
// # ** Error (suppressible): example_err_vsim_no_lic.sv(10): (vopt-7063) Failed to find 'sum' in hierarchical name 'q1.sum'.
// #         Region: example_err_vsim_no_lic
