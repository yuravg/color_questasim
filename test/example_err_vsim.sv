
module example_err_vsim();
	initial begin
		#10;
		$display("Message");
		#10;
		$info("Info message");
		#10;
		$warning("Warning message");
		#10;
		$error("Error message");
		#10;
		$fatal(1, "Fatal message");
		$finish(1);
	end
endmodule

// vlog -lint -quiet example_err_vsim.sv && vopt -quiet example_err_vsim -o prj_opt && vsim -c -quiet prj_opt -do "run 100; exit"
// OUTPUT:
// # Message
// # ** Info: Info message
// #    Time: 20 ns  Scope: example_err_vsim File: example_err_vsim.sv Line: 7
// # ** Warning: Warning message
// #    Time: 30 ns  Scope: example_err_vsim File: example_err_vsim.sv Line: 9
// # ** Error: Error message
// #    Time: 40 ns  Scope: example_err_vsim File: example_err_vsim.sv Line: 11
// # ** Warning: (vsim-PLI-8496) $fatal : Argument number 1 is invalid. Expecting 0, 1, or 2. Using default value of 1
// #    Time: 50 ns  Iteration: 0  Process: /example_err_vsim/#INITIAL#3 File: example_err_vsim.sv Line: 13
// # ** Fatal: Fatal message
// #    Time: 50 ns  Scope: example_err_vsim File: example_err_vsim.sv Line: 13
// # ** Note: $finish    : example_err_vsim.sv(13)
// #    Time: 50 ns  Iteration: 0  Instance: /example_err_vsim
// # End time: 18:12:18 on Nov 10,2022, Elapsed time: 0:00:00
// # Errors: 2, Warnings: 2
