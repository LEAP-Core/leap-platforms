/**
 *
 * Copyright (c) 2006-2008 The University of Texas All Rights Reserved.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * for more details.
 * 
 * The GNU Public License is available in the file LICENSE, or you can
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA, or you can find it on the World Wide Web at
 * http://www.fsf.org.
 * 
 * Authors: Eric Johnson
 * 
 * The authors are with the Department of Electrical and Computer Engineering,
 * The University of Texas at Austin, Austin, TX 78712 USA.
 * 
 * They can be reached at: dejohnso@ece.utexas.edu
 * 
 * More information about related work can be found at
 * http://users.ece.utexas.edu/~derek/FAST.html
 * 
 **/

import Vector::*;

interface FAST_BRAM#(type data_t, type index_t);
   method Action write(index_t a, data_t d);
   method Action read(index_t a);
   method data_t readval();
   method Action write2(index_t a, data_t d);
   method Action read2(index_t a);
   method data_t readval2();
endinterface: FAST_BRAM

import "BVI" FAST_BRAM =
module mkFAST_BRAM_verilog (FAST_BRAM#(data_t, index_t))
   provisos(
	    Bits#(index_t, bits_index_t),
	    Bits#(data_t, bits_data_t)
	    );
   
   parameter DATA_WIDTH = valueOf(bits_data_t);
   parameter ADDR_WIDTH = valueOf(bits_index_t);
   parameter DEPTH = valueOf(TExp#(bits_index_t));
   
   default_clock (CLK);
   schedule (readval,readval2) CF (readval,readval2);
   schedule readval SB (read,write);
   schedule readval2 SB (read2,write2);
   schedule (read,write,readval) CF (read2,write2,readval2);
   schedule (read) C (write);
   schedule (read2) C (write2);
   schedule (read) C (read);
   schedule (read2) C (read2);
   schedule (write) C (write);
   schedule (write2) C (write2);
   
   method write (WR_ADDRA, DIA) enable(WEA);
   method write2 (WR_ADDRB, DIB) enable(WEB);
   method read (RD_ADDRA) enable(REA);
   method read2 (RD_ADDRB) enable(REB);
   method DOA readval;
   method DOB readval2;
   
endmodule: mkFAST_BRAM_verilog
