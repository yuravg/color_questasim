
interface data_if;
	logic clk;
	logic d;
endinterface

module example_err_vopt_if();

	data_if dif();
	initial begin
		#100;
		dif.k = 1'b1;
	end
endmodule

// vlog -lint -quiet example_err_vopt_if.sv && vopt -quiet example_err_vopt_if -o example_err_opt
// OUTPUT:
// ** Error (suppressible): example_err_vopt_if.sv(12): (vopt-7063) Failed to find 'k' in hierarchical name 'dif.k'.
//         Region: example_err_vopt_if
