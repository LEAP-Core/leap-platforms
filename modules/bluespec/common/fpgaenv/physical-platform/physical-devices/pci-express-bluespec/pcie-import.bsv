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

  interface Reset reset;
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

    Reset pcieReset <- mkAsyncReset(1,rst,sys_clk_buf); 

    // Need a real clock rate
    // We'll sneak in the clocks and convert them 
    Bridge bridge <- mkBridge(sys_clk_buf, 
                              clk,
                              pcieReset);
  
    //Create the syncfifos

    interface PCIE_DRIVER driver;

        method Action send(PCIEWord data);
            bridge.req(data);
        endmethod

        method ActionValue#(PCIEWord) receive();
           let data <- bridge.resp();
           return data;
        endmethod

    endinterface

    interface PCIE_WIRES  wires;
      method pcie_clk_n = pcieClockP.clock_wire;  

      method pcie_clk_p = pcieClockN.clock_wire;  

      method leds = bridge.leds;

      interface reset = rst;
      interface clock = clk;
      interface clockPCIE = sys_clk_buf;
      interface pcie_exp = bridge.pcie;    
    endinterface

endmodule

