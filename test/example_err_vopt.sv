
module example_err_vopt();

	logic clk;
	example example(clk);
	initial begin
		#100;
	end
endmodule

// vlog -lint -quiet example_err_vopt.sv && vopt -quiet example_err_vopt -o example_err_opt_vopt
// OUTPUT:
// ** Warning: example_err_vopt.sv(2): (vlog-2605) empty port name in port list.
// ** Error: example_err_vopt.sv(5): Module 'example' is not defined.
