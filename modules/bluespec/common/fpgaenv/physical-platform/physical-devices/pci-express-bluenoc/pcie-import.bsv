import Vector::*;
import Clocks::*;
import LevelFIFO::*;
import XilinxPCIE   :: *;
import XilinxCells  :: *;

`include "physical_platform_utils.bsh"
`include "fpga_components.bsh"
`include "awb/provides/bluenoc_core.bsh"

typedef Bit#(8) PCIEWord;
        
// PCIE_DRIVER

// The serial driver support sending and receiving 32-bit words across a serial
// line.

interface PCIE_DRIVER;
    method Action send(PCIEWord word);
    method ActionValue#(PCIEWord) receive();
		interface Clock clock;
		interface Reset reset;
endinterface

// PCIE_WIRES

// These are wires which are simply passed up to the toplevel,
// where the UCF file ties them to pins.
interface PCIE_WIRES;

  method Action pcie_clk_n();  

  method Action pcie_clk_p();  

//	method Action refclk();

  method Bit#(8) leds();

//  interface Reset reset;
  interface Clock clock;
  interface Clock clockPCIE;
  interface PCIE_EXP#(8) pcie_exp;
endinterface


// PCIE_DEVICE

// By convention a Device is a Driver and a Wires

interface PCIE_DEVICE;

    interface PCIE_DRIVER driver;
    interface PCIE_WIRES  wires;

endinterface


module mkPCIEDevice#(Clock rawClock, Reset rawReset) (PCIE_DEVICE);

    // should this be a clock 100?
    Clock clk <- exposeCurrentClock();
    Reset rst <- exposeCurrentReset();
		Reset rst_n <- mkResetInverter(rst, clocked_by clk);
//		Reset rawRst_n <- mkResetInverter(rawReset, clocked_by rawClock);

    CLOCK_IMPORTER pcieClockN <- mkClockImporter();
    CLOCK_IMPORTER pcieClockP <- mkClockImporter();
    // bridge expects its reset to be synchronized...

    // Buffer clocks and reset before they are used
    Clock sys_clk_buf <- mkClockIBUFDS_GTXE1(True,pcieClockP.clock, pcieClockN.clock);
    
    Reg#(Bit#(8)) count <- mkReg(~0);
    MakeResetIfc localResetFast <- mkReset(0,False,clk);
    MakeResetIfc rst_null <- mkReset(0,False,clk);
    Reset combinedReset <- mkResetEither(rst, localResetFast.new_rst);
    Reset pcieReset <- mkAsyncReset(0,combinedReset,sys_clk_buf); 
    rule countDown(count > 0);
      count <= count - 1;
      if(count > 128) 
        begin
          localResetFast.assertReset();
        end
    endrule

		Reset pcieReset_n <- mkResetInverter(pcieReset, clocked_by sys_clk_buf);
		BLUENOCIfc bnoc <- mkBlueNoCCore(sys_clk_buf, pcieReset_n,
			clocked_by clk, reset_by rst_n);
//			clocked_by clk, reset_by rst);

		PCIE_BURY pcieBury <- mkPCIE_BURY(
				clocked_by sys_clk_buf,
				reset_by pcieReset_n);
//				reset_by pcieReset);

//		(* fire_when_enabled, no_implicit_conditions *)	
		rule drivePCIE;
			pcieBury.txn_bsv(bnoc.pcie.txn);
			pcieBury.txp_bsv(bnoc.pcie.txp);
			bnoc.pcie.rxp(pcieBury.rxp_bsv);
			bnoc.pcie.rxn(pcieBury.rxn_bsv);
		endrule

		Reg#(Bit#(20)) led_vals <- mkReg(20'b10101010101010101010);
		rule tickled;
			led_vals <= led_vals + 1;
		endrule
    
		interface PCIE_DRIVER driver;

        method Action send(PCIEWord data);// if(count == 0);
					bnoc.send(data);
        endmethod

        method ActionValue#(PCIEWord) receive();// if(count == 0);
					let data <- bnoc.receive();
					return data;
        endmethod

      interface clock = bnoc.clock;
			interface reset = bnoc.reset;
    endinterface

    interface PCIE_WIRES  wires;
      method pcie_clk_n = pcieClockN.clock_wire;  
      method pcie_clk_p = pcieClockP.clock_wire;  
//      method refclk = refClock.clock_wire;  

      method leds = ?;


      //interface reset = rst;
      interface clock = clk;//bnoc.clock;


			interface clockPCIE = pcieBury.clock;
      interface PCIE_EXP pcie_exp;
        method rxp = pcieBury.rxp_wire;
        method rxn = pcieBury.rxn_wire;
        method txp = pcieBury.txp_wire;
        method txn = pcieBury.txn_wire;
      endinterface
    endinterface

endmodule
