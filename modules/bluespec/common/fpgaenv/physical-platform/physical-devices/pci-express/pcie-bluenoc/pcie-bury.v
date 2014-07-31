module pcie_bury(rxp_in,
		 rxn_in,
                 txp_in,
                 txn_in,
                 rxp_out,
		 rxn_out,
                 txp_out,
                 txn_out,
                 en0,
                 en1,
                 en2,
                 en3
);

    parameter WIDTH = 8;

    input [WIDTH-1:0] rxp_in;
    input [WIDTH-1:0] rxn_in;
    input [WIDTH-1:0] txp_in;
    input [WIDTH-1:0] txn_in;

    input       en0;
    input       en1;
    input       en2;
    input       en3;   
   
    output [WIDTH-1:0] rxp_out; 
    output [WIDTH-1:0] rxn_out; 
    output [WIDTH-1:0] txp_out; 
    output [WIDTH-1:0] txn_out;
   
    assign rxp_out = rxp_in;
    assign rxn_out = rxn_in;
    assign txp_out = txp_in;
    assign txn_out = txn_in;

endmodule
