module pcie_bury(rxp_in,
		 rxn_in,
                 txp_in,
                 txn_in,
                 rxp_out,
		 rxn_out,
                 txp_out,
                 txn_out,
);

    input [7:0] rxp_in;
    input [7:0] rxn_in;
    input [7:0] txp_in;
    input [7:0] txn_in;

    output [7:0] rxp_out; 
    output [7:0] rxn_out; 
    output [7:0] txp_out; 
    output [7:0] txn_out;
   
    assign rxp_out = rxp_in;
    assign rxn_out = rxn_in;
    assign txp_out = txp_in;
    assign txn_out = txn_in;

endmodule
