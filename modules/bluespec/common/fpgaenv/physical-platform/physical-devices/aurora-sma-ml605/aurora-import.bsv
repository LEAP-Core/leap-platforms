//
// Copyright (C) 2011 Massachusetts Institute of Technology
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//

// This module interfaces to the SMA cables on the
// XUPV5. However only certain of the generated verilog and ucf files
// are needed to characterize this interface, and it can be used a model 
// for high-speed board to board serial on other development boards. The 
// device interface consists of a simple FIFO with guaranteed transport to
// the other device. This module is slightly complicated by the need to 
// instantiate dummy serial modules to route clock to the SMA GTP.

import Clocks::*;
import FIFOF::*;
import FIFO::*;
import LevelFIFO::*;
import Connectable::*;
import GetPut::*;
import Vector::*;
import XilinxCells  :: *;

`include "awb/provides/ml605_aurora_device.bsh" 
`include "awb/provides/fpga_components.bsh"

interface AURORA_WIRES;
	method Action aurora_clk_n((* port="AURORA_GTXQ_IN" *) Bit#(1) clk_n);
	method Action aurora_clk_p((* port="AURORA_GTXQ_IN" *) Bit#(1) clk_p);

//	method Action gtxq_p();
//	method Action gtxq_n();

	method Action rxp_in(Bit#(1) i);
	method Action rxn_in(Bit#(1) i);
	method Bit#(1) txp_out();
	method Bit#(1) txn_out();
	interface Clock aurora_clk;
endinterface

interface AURORA_DRIVER;
	method ActionValue#(Bit#(16)) read;
	method Action write(Bit#(16) d);
    
		// Debugging interface
    method Bit#(1) channel_up;
    method Bit#(1) lane_up;
    method Bit#(1) hard_err;
    method Bit#(1) soft_err;
    method Bit#(32) status;
    method Bit#(32) rx_count;
    method Bit#(32) tx_count;
    method Bit#(32) error_count;
    method UInt#(5) rx_fifo_count;
    method UInt#(5) tx_fifo_count;
endinterface

interface AURORA_DEVICE;
    interface AURORA_WIRES wires;
    interface AURORA_DRIVER driver;
endinterface      

module mkAURORA_DEVICE#(Clock rawClock, Reset rawReset)(AURORA_DEVICE);
	let clk <- exposeCurrentClock();
	let rst <- exposeCurrentReset();


	Reg#(Bit#(32)) rx_fifo_count_r <- mkReg(0);
	Reg#(Bit#(32)) tx_fifo_count_r <- mkReg(0);
	Reg#(Bit#(32)) rx_count_r <- mkReg(0);
	Reg#(Bit#(32)) tx_count_r <- mkReg(0);

	let ug_device <- mkAURORA_SINGLE_UG(rawClock, rawReset, clocked_by clk, reset_by rst);
	let aurora_clk = ug_device.aurora_clk;
	let aurora_rst = ug_device.aurora_rst;
    
	SyncFIFOCountIfc#(Bit#(16),8) serdes_rxfifo <- mkSyncFIFOCount( aurora_clk, aurora_rst, clk);
	SyncFIFOCountIfc#(Bit#(16),8) serdes_txfifo <- mkSyncFIFOCount( clk, rst, aurora_clk);
	/*
	rule tx_move;
		ug_device.tx_data_out(serdes_txfifo.first());
		serdes_txfifo.deq();
	endrule
	rule rx_move;
		let rx_value <- ug_device.rx_data_in();
		serdes_rxfifo.enq(rx_value);
	endrule
*/
	rule echo;
		serdes_rxfifo.enq(serdes_txfifo.first());
		serdes_txfifo.deq();
	endrule


	ReadOnly#(Bool) resetAssertedCast <- isResetAsserted(clocked_by aurora_clk, reset_by aurora_rst);
	ReadOnly#(Bool) resetAssertedCastN <- isResetAsserted(clocked_by aurora_clk, reset_by ug_device.aurora_rst_n);
//	pack(resetAssertedCast._read());
	 ReadOnly#(Bool) resetCrossing <- mkNullCrossingWire(clk,resetAssertedCast._read, clocked_by aurora_clk, reset_by aurora_rst);
	 ReadOnly#(Bool) resetCrossing2 <- mkNullCrossingWire(clk,resetAssertedCast._read, clocked_by aurora_clk, reset_by ug_device.aurora_rst_n);
	 ReadOnly#(Bool) resetCrossingN <- mkNullCrossingWire(clk,resetAssertedCastN._read, clocked_by aurora_clk, reset_by ug_device.aurora_rst);
	 ReadOnly#(Bool) resetCrossingN2 <- mkNullCrossingWire(clk,resetAssertedCastN._read, clocked_by aurora_clk, reset_by ug_device.aurora_rst_n);

	Reg#(Bit#(32)) debugint <- mkReg(0);
	FIFOF#(Bit#(16)) debugfifo <- mkFIFOF();
	rule debug_loop;
		if ( debugint >= 1024 * 1024*4 ) begin
			let debugv = {rx_fifo_count_r[3:0], tx_fifo_count_r[3:0],
			pack( resetCrossing._read), 
			pack( resetCrossing2._read), 
			pack(resetCrossingN._read),
			pack(resetCrossingN2._read),
			
			{ug_device.channel_up,
		ug_device.lane_up,
		ug_device.hard_err,
		ug_device.soft_err}};
				debugfifo.enq(debugv);
			debugint <= 0;
		end
		else begin
			debugint <= debugint + 1;
		end
	endrule
	
	Reg#(Bit#(32)) aurcnt <- mkReg(0, clocked_by aurora_clk, reset_by aurora_rst);
	rule aurcnt_rule;
		if ( aurcnt > 1024 * 1024 ) begin
			serdes_rxfifo.enq(16'hbeef);
			aurcnt <= 0;
		end else begin
			aurcnt <= aurcnt + 1;
		end
	endrule

/*
	let sys_rst <- mkAsyncReset(4, rst, sys_clk_buf);
	Reg#(Bit#(32)) aurcnt <- mkReg(0, clocked_by sys_clk_buf, reset_by sys_rst);
	SyncFIFOCountIfc#(Bit#(16),8) serdes_systorxfifo <- mkSyncFIFOCount( sys_clk_buf, sys_rst, clk);
	rule aurcnt_rule;
		if ( aurcnt > 1024 * 1024 ) begin
			serdes_systorxfifo.enq(16'hbeef);
			aurcnt <= 0;
		end else begin
			aurcnt <= aurcnt + 1;
		end
	endrule
	rule mvtodeeeee;
		debugfifo.enq(serdes_systorxfifo.first());
		serdes_systorxfifo.deq();
	endrule
*/

	interface AURORA_WIRES wires;
method aurora_clk_p = ug_device.gtxq_p;
method aurora_clk_n = ug_device.gtxq_n;

		method rxp_in = ug_device.rxp_in;
		method rxn_in = ug_device.rxn_in;
		method txp_out = ug_device.txp_out;
		method txn_out = ug_device.txn_out;
		interface Clock aurora_clk = ug_device.aurora_clk;
	endinterface
	interface AURORA_DRIVER driver;
	/*
		method ActionValue#(Bit#(16)) read(); // = ug_device.rx_data_in;
			return 88;
		endmethod
		method Action write(Bit#(16) d);// = ug_device.tx_data_out;
			noAction;
		endmethod

		method Bit#(1) channel_up();
			return 0;
		endmethod
		method Bit#(1) lane_up() ;
			return 0;
		endmethod
		method Bit#(1) hard_err();
			return 0;
		endmethod
		method Bit#(1) soft_err();
			return 0;
		endmethod
		*/

		method ActionValue#(Bit#(16)) read(); // = ug_device.rx_data_in;
			let rv = debugfifo.first();
			if ( !debugfifo.notEmpty() ) begin
				serdes_rxfifo.deq();
				rv = serdes_rxfifo.first();
				rx_fifo_count_r <= rx_fifo_count_r + 1;
			end else begin
				debugfifo.deq();
			end
			return rv;
		endmethod
		method Action write(Bit#(16) d);// = ug_device.tx_data_out;
			tx_fifo_count_r <= tx_fifo_count_r + 1;
			serdes_txfifo.enq(d);
		endmethod

		method channel_up = ug_device.channel_up;
		method lane_up = ug_device.lane_up;
		method hard_err = ug_device.hard_err;
		method soft_err = ug_device.soft_err;

		method Bit#(32) status(); //= ug_device.status;
			return  0;//zeroExtend(0);
		endmethod
		method Bit#(32) rx_count(); //= ug_device.rx_count;
			return 0;//zeroExtend(0);
		endmethod
		method Bit#(32) tx_count(); //= ug_device.tx_count;
			return 0;//zeroExtend(0);
		endmethod
		method Bit#(32) error_count(); //= ug_device.error_count;
			return 0;//zeroExtend(0);
		endmethod
		method UInt#(5) rx_fifo_count();
			return 0;//zeroExtend(0);
		endmethod
		method UInt#(5) tx_fifo_count();
			return 0;//zeroExtend(0);
		endmethod

	endinterface
endmodule



/*























*/
