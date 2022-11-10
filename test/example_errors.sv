
virtual class A;
  int a1 = 10;
  int a2 = 20;

  // A virtual method in an abstract class should be overridden with the same arguments and return type,
  // otherwise the compiler will return an error:
  // Error: Sub-class 'B' does not override all virtual methods of abstract superclass 'A'.
  pure virtual function int get_data();
endclass : A


class B extends A;
  function new(int a1, int a2);
    this.a1 = a1;
    this.a2 = a2
  endfunction : new

  // Use 'virtual' keyword to show that the method should be the same in child class
  virtual function int get_data();
    return a1;
  endfunction : get_data
endclass : B


module example_errors();

  // A a;
  B b;

  initial begin
    a = new();
    b = new(100, "msg");
    $display("b.a1=%0d, b.a2=%0d", b.a1, b.a2);
    $display("b.get_data()=%0d", b.get_data());
    $display("d=%0d", k)
  end

endmodule : example_errors

// vlog -lint example_errors.sv
// OUTPUT:
// ** Error: (vlog-13069) example_errors.sv(17): near "endfunction": syntax error, unexpected endfunction, expecting ';'.
// ** Error: (vlog-13069) example_errors.sv(22): near "get_data": syntax error, unexpected IDENTIFIER, expecting "SystemVerilog keyword 'new'".
// ** Error: example_errors.sv(31): Illegal declaration after the statement near line '26'.  Declarations must precede statements.  Look for stray semicolons.
// ** Error: example_errors.sv(33): (vlog-2730) Undefined variable: 'b'.
// ** Error (suppressible): example_errors.sv(33): (vlog-2388) 'b' already declared in this scope (work).
