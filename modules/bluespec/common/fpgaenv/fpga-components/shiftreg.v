// This module infers a parameteric Xilinx shift register.

module shiftreg (CLK, RST_N, writeData, writeEnable, readData);
   parameter LENGTH = 32;
   parameter WIDTH = 32;
   input CLK;
   input RST_N;
   input writeData;   
   input writeEnable;
   output readData;

   reg [LENGTH - 1:0] tmp;

     always @(posedge CLK)
       begin
	        if (writeEnable)
		  begin
		     tmp = tmp << 1;
		     tmp[0] = writeData;
		  end
       end
   assign readData  = tmp[LENGTH - 1];

endmodule