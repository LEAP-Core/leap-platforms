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
                 txn_out,
	//	pin_out
);
   input CLK;
   input RST_N;
   output CLK_OUT;
   input CLK_GATE;
	 (* S = "TRUE" *)
   input [7:0] rxp_in;
   (* S = "TRUE" *)
   input [7:0] rxn_in;
   (* S = "TRUE" *)
   input [7:0] txp_in;
   (* S = "TRUE" *)
   input [7:0] txn_in;
   (* S = "TRUE" *)
   output [7:0] rxp_out; 
   (* S = "TRUE" *)  
   output [7:0] rxn_out; 
   (* S = "TRUE" *) 
   output [7:0] txp_out; 
   (* S = "TRUE" *)  
   output [7:0] txn_out;
//   (* S = "TRUE" *)  
//   output [7:0] pin_out;
   
	 (* S = "TRUE" *)
   reg [7:0] r_rxp_out; 
   (* S = "TRUE" *)  
   reg [7:0] r_rxn_out; 
   (* S = "TRUE" *)  
	 wire [7:0] dr_rxp_out;
   (* S = "TRUE" *)  
	 wire [7:0] dr_rxn_out;

   (* S = "TRUE" *)  
	 wire [7:0] d_txp_in;
   (* S = "TRUE" *)  
	 wire [7:0] d_txn_in;
   (* S = "TRUE" *)  
	 wire [7:0] d_rxp_out;
   (* S = "TRUE" *)  
	 wire [7:0] d_rxn_out;
   
	 (* S = "TRUE" *)  
	 reg r_pin_out;
//	 assign pin_out = r_pin_out;

	 always @ (posedge CLK)
	 begin
	 	r_pin_out <= dr_rxp_out;
	 end
   
	 
	 assign CLK_OUT = RST_N;  // Do something to make xst happy
   assign rxp_out = rxp_in;  // Do something to make xst happy
   assign rxn_out = rxn_in;
   assign txp_out = txp_in;
   assign txn_out = txn_in;

	 assign d_txp_in = txp_in;
	 assign d_txn_in = txn_in;
	 assign d_rxp_out = rxp_out;
	 assign d_rxn_out = rxn_out;
	 
	 assign dr_rxp_out = rxp_out;
	 assign dr_rxn_out = rxn_out;
/*
	 assign en0 = 1;
	 assign en1 = 1;
	 assign en2 = 1;
	 assign en3 = 1;
	*/
endmodule
