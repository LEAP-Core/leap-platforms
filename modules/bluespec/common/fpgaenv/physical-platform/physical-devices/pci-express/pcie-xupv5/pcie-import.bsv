import Vector::*;
import Clocks::*;
import LevelFIFO::*;

`include "physical_platform_utils.bsh"
`include "fpga_components.bsh"

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

  method Bit#(8) leds();

//  interface Reset reset;
  interface Clock clock;
  interface Clock clockPCIE;
  interface PCIE_EXP#(1) pcie_exp;
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

    // bridge expects its reset to be synchronized...

    // Buffer clocks and reset before they are used
    Clock sys_clk_buf <- mkClockIBUFDS(pcieClockP.clock, pcieClockN.clock);

    // make a pretty ASync reset from the incoming rst...

    Reg#(Bit#(7)) count <- mkReg(~0);

    MakeResetIfc localResetFast <- mkReset(0,False,clk);
    Reset combinedReset <- mkResetEither(rst, localResetFast.new_rst);
    Reset pcieReset <- mkAsyncReset(0,combinedReset,sys_clk_buf); 
    //Reset pcieReset <- mkAsyncReset(0,combinedReset,sys_clk_buf); 


    rule countDown(count > 0);
      count <= count - 1;
      if(count > 64) 
        begin
          localResetFast.assertReset();
        end
    endrule



    (* doc = "synthesis attribute keep of m_vp_llpi_phys_plat_pcie_device_sys_clk_buf_O is \"true\";" *)
    (* doc = "synthesis attribute S of m_vp_llpi_phys_plat_pcie_device_pcieBury_rxn_in is \"true\";" *)
    (* doc = "synthesis attribute S of m_vp_llpi_phys_plat_pcie_device_pcieBury_rxp_in is \"true\";" *)
    (* doc = "synthesis attribute S of m_vp_llpi_phys_plat_pcie_device_pcieBury_txn_in is \"true\";" *)
    (* doc = "synthesis attribute S of m_vp_llpi_phys_plat_pcie_device_pcieBury_txp_in is \"true\";" *)
 
    (* doc = "synthesis attribute S of m_vp_llpi_phys_plat_pcie_device_pcieBury_rxn_out is \"true\";" *)
    (* doc = "synthesis attribute S of m_vp_llpi_phys_plat_pcie_device_pcieBury_rxp_out is \"true\";" *)
    (* doc = "synthesis attribute S of m_vp_llpi_phys_plat_pcie_device_pcieBury_txn_out is \"true\";" *)
    (* doc = "synthesis attribute S of m_vp_llpi_phys_plat_pcie_device_pcieBury_txp_out is \"true\";" *)
    // Need a real clock rate
    // We'll sneak in the clocks and convert them 
    Bridge bridge <- liftModule(mkBridge(sys_clk_buf, 
                                         clk,
                                         pcieReset));
	
   
    // build a pcie bury
    PCIE_BURY pcieBury <- mkPCIE_BURY(clocked_by sys_clk_buf, 
                                      reset_by pcieReset); 

    Reg#(Bit#(1)) txn;

    rule drivePCIE;      
      pcieBury.txn_bsv(bridge.pcie.txn);
      pcieBury.txp_bsv(bridge.pcie.txp);
      bridge.pcie.rxp(pcieBury.rxp_bsv);
      bridge.pcie.rxn(pcieBury.rxn_bsv);
    endrule

    //Create the yncfifos
    // XXX blast data out...
    //rule sendData;
    //  let data <- bridge.resp();
    //  bridge.req(data);
    //endrule

    interface PCIE_DRIVER driver;

        method Action send(PCIEWord data) if(count == 0);
           bridge.req(data);
        endmethod

        method ActionValue#(PCIEWord) receive() if(count == 0);
           let data <- bridge.resp();
           return data;
        endmethod

    endinterface

    interface PCIE_WIRES  wires;
      method pcie_clk_n = pcieClockN.clock_wire;  

      method pcie_clk_p = pcieClockP.clock_wire;  

      method leds = bridge.leds;

      //interface reset = rst;
      interface clock = clk;
      interface clockPCIE = pcieBury.clock;
      interface PCIE_EXP pcie_exp;
        method rxp = pcieBury.rxp_wire;
        method rxn = pcieBury.rxn_wire;
        method txp = pcieBury.txp_wire;
        method txn = pcieBury.txn_wire;
      endinterface
    endinterface

endmodule

