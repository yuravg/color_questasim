import uvm_pkg::*;
`include "uvm_macros.svh"


class a_component extends uvm_component;
  `uvm_component_utils(a_component)

  function new(string name = "a_component", uvm_component parent);
    super.new(name, parent);
  endfunction : new

  task run_phase(uvm_phase phase);
    `uvm_info("INFO_ID", "Some info message", UVM_LOW)
    `uvm_error("ERROR_ID", "Some error message")
  endtask : run_phase
endclass : a_component


class my_test extends uvm_test;
  `uvm_component_utils(my_test)

  a_component a;

  function new(string name = "my_test", uvm_component parent); super.new(name, parent); a =
    a_component::type_id::create("a", this); endfunction : new

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    $display("%s.run_phase: raise", get_name());
    #1;
    $display("%s.run_phase: drop", get_name());
    phase.drop_objection(this);
  endtask : run_phase

  function void report_phase(uvm_phase phase);
    static uvm_coreservice_t cs_ = uvm_coreservice_t::get();
    uvm_report_server svr;
    svr = cs_.get_report_server();

    $display("%s.report_phase", get_name());
    `uvm_info("INFO_RPT", $sformatf("Info counter=%0d, Error counter=%0d",
                                    svr.get_severity_count(UVM_INFO),
                                    svr.get_severity_count(UVM_ERROR)), UVM_LOW)
  endfunction : report_phase

  function void final_phase(uvm_phase phase);
    $display("%s.final_phase", get_name());
  endfunction : final_phase
endclass : my_test


module example_uvm_tb();
  initial begin
    run_test("my_test");
  end
endmodule : example_uvm_tb
