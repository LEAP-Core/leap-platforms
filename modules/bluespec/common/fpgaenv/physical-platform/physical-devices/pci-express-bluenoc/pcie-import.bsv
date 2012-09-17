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

    CLOCK_IMPORTER pcieClockN <- mkClockImporter();
    CLOCK_IMPORTER pcieClockP <- mkClockImporter();
//    CLOCK_IMPORTER refClock <- mkClockImporter();

    // bridge expects its reset to be synchronized...

    // Buffer clocks and reset before they are used
    Clock sys_clk_buf <- mkClockIBUFDS_GTXE1(True,pcieClockP.clock, pcieClockN.clock);
    //Clock sys_clk_buf <- mkClockIBUFDS(pcieClockP.clock, pcieClockN.clock);
    // make a pretty ASync reset from the incoming rst...
    
//		MakeResetIfc refClk_reset <- mkReset(10,False,refClock.clock);

    Reg#(Bit#(8)) count <- mkReg(~0);
    MakeResetIfc localResetFast <- mkReset(0,False,clk);
    Reset combinedReset <- mkResetEither(rst, localResetFast.new_rst);
    Reset pcieReset <- mkAsyncReset(0,combinedReset,sys_clk_buf); 
    rule countDown(count > 0);
      count <= count - 1;
      if(count > 128) 
        begin
          localResetFast.assertReset();
        end
    endrule

   Reset fpga_rstn <- mkResetInverter(pcieReset, clocked_by sys_clk_buf);
//		Reset refrst = mkAsyncResetFromCR(4, refClock.clock);
//    Reset refReset <- mkAsyncReset(0,combinedReset,refClock.clock); 
		BLUENOCIfc bnoc <- mkBlueNoCCore(sys_clk_buf, fpga_rstn);//, //pcieReset,
//			clocked_by refClock.clock, reset_by refReset);
			//clocked_by refClock.clock, reset_by refClk_reset.new_rst);

		PCIE_BURY pcieBury <- mkPCIE_BURY(
				clocked_by sys_clk_buf,
				reset_by pcieReset);

//		(* fire_when_enabled, no_implicit_conditions *)	
		rule drivePCIE;
			pcieBury.txn_bsv(bnoc.pcie.txn);
			pcieBury.txp_bsv(bnoc.pcie.txp);
			bnoc.pcie.rxp(pcieBury.rxp_bsv);
			bnoc.pcie.rxn(pcieBury.rxn_bsv);
		endrule
    
		interface PCIE_DRIVER driver;

        method Action send(PCIEWord data) if(count == 0);
					bnoc.send(data);
        endmethod

        method ActionValue#(PCIEWord) receive() if(count == 0);
					let data <- bnoc.receive();
					return data;
        endmethod

    endinterface

    interface PCIE_WIRES  wires;
      method pcie_clk_n = pcieClockN.clock_wire;  
      method pcie_clk_p = pcieClockP.clock_wire;  
//      method refclk = refClock.clock_wire;  

//      method leds = bridge.leds;
			method Bit#(8) leds();
				//return led_reg;
				return 8'b11001010;
//				return {7'b1101101, pcieBury.pin_wire};
			endmethod

      //interface reset = rst;
      interface clock = clk;


			interface clockPCIE = pcieBury.clock;
      interface PCIE_EXP pcie_exp;
        method rxp = pcieBury.rxp_wire;
        method rxn = pcieBury.rxn_wire;
        method txp = pcieBury.txp_wire;
        method txn = pcieBury.txn_wire;
      endinterface
			
      //interface clockPCIE = sys_clk_buf; 

//			interface PCIE_EXP pcie_exp = bnoc.pcie;
//      interface clockPCIE = sys_clk_buf; 
		
    endinterface

endmodule

/*

%sources -t BSV -v PUBLIC Bridge.bsv
%sources -t BSV -v PUBLIC LLVirtex5PCIE.bsv
%sources -t BSV -v PUBLIC PioFifo.bsv
%sources -t BSV -v PUBLIC pcie_bury.bsv

%sources -t NGC -v PRIVATE pcie_endpoint.ngc
%sources -t XCF -v PRIVATE pcie-device.xcf
%sources -t VERILOG -v PRIVATE pcie_endpoint_old.v
%sources -t VERILOG -v PRIVATE endpoint_blk_plus_v1_14.v
%sources -t VERILOG -v PRIVATE pcie_bury.v
%sources -t UCF -v PRIVATE pcie-device.ucf


	NET "m_llpi_phys_plat_pcie_device_pcieBury_rxp_in" keep = true;
	NET "m_llpi_phys_plat_pcie_device_pcieBury_rxp_in" S = true;
	NET "m_llpi_phys_plat_pcie_device_pcieBury_rxp_out" keep = true;
	NET "m_llpi_phys_plat_pcie_device_pcieBury_rxp_out" S = true;
	NET "m_llpi_phys_plat_pcie_device_pcieBury_rxn_in" keep = true;
	NET "m_llpi_phys_plat_pcie_device_pcieBury_rxn_in" S = true;
	NET "m_llpi_phys_plat_pcie_device_pcieBury_rxn_out" keep = true;
	NET "m_llpi_phys_plat_pcie_device_pcieBury_rxn_out" S = true;

	INST "*pcieBury" keep = true;
	INST "*pcieBury" S = true;

	NET "pcieWires_pcie_exp_rxp_i" keep = true;
	NET "pcieWires_pcie_exp_rxp_i" S = true;
	NET "pcieWires_pcie_exp_rxp_i" s = true;
	NET "pcieWires_pcie_exp_rxn_i" keep = true;
	NET "pcieWires_pcie_exp_rxn_i" S = true;
	NET "pcieWires_pcie_exp_rxn_i" s = true;
*/
