module pcie_bury(CLK, 
                 RST_N,
		 CLK_OUT,
		 CLK_GATE,
                 rxp_in,
		 rxn_in,
                 txp_in,
                 txn_in,
                 rxp_out,
		 rxn_out,
                 txp_out,
                 txn_out);
   input CLK;
   input RST_N;
   output CLK_OUT;
   input CLK_GATE;
   (* S = "TRUE" *)
   input rxp_in;
   (* S = "TRUE" *)
   input rxn_in;
   (* S = "TRUE" *)
   input txp_in;
   (* S = "TRUE" *)
   input txn_in;
   (* S = "TRUE" *)
   output rxp_out; 
   (* S = "TRUE" *)  
   output rxn_out; 
   (* S = "TRUE" *) 
   output txp_out; 
   (* S = "TRUE" *)  
   output txn_out;
   
   
   assign CLK_OUT = RST_N;  // Do something to make xst happy
   //assign rxp_out = rxp_in;  // Do something to make xst happy
   //assign rxn_out = rxn_in;
   //assign txp_out = txp_in;
   //assign txn_out = txn_in;
   
endmodule