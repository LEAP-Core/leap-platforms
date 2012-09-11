`include "clocks_device.bsh"

import Xilinx::*;
import XilinxPCIE::*;
import Clocks::*;
import DefaultValue::*;

import LLVirtex5PCIE::*;

interface Bridge;
   (* prefix="PCIE" *)
   interface PCIE_EXP#(1) pcie;
   (* always_ready *)
   method Bit#(8) leds();
   method Action req(Bit#(8) r);
   method ActionValue#(Bit#(8)) resp;
   method Action dispReq(Bit#(8) r);
   method ActionValue#(Bit#(8)) dispResp;
endinterface

//(* synthesize *)
module [Module] mkBridge#(Clock pci_sys_clk, Clock refclk_100, Reset pci_sys_reset_n)
                (Bridge);

   (* doc = "synthesis attribute keep of CLK_pci_sys_clk is \"true\";" *)
   (* doc = "synthesis attribute buffer_type of piov5_pcie_ep_trn_clk is \"none\"" *)
   (* doc = "synthesis attribute keep of piov5_pcie_ep_trn2_clk is \"true\";" *)
   LLV5PCIEIfc#(1) piov5 <- buildPCIEV5(pci_sys_clk
				                       ,pci_sys_reset_n
				                       ,refclk_100);


   // Let's blink some lights for fun
   Reg#(Bit#(32)) count <- mkReg(0);
   Reg#(Bit#(1)) led <- mkReg(0); 

   let ledsWire <- mkNullCrossingWire(noClock,zeroExtend({led
                            ,pack(piov5.isLinkUp)
			    ,pack(piov5.isOutOfReset)
			    ,pack(piov5.isClockAdvancing)               
			    }));

   rule tick;
     if(count == `MODEL_CLOCK_FREQ*1000000) 
       begin
         led <= ~led;
         count <= 0;
       end
     else
       begin
         count <= count + 1;
       end
   endrule

   interface pcie = piov5.pcie;

   method leds = ledsWire;

   method req = piov5.req;
   method resp = piov5.resp;
   method dispReq = piov5.dispReq;
   method dispResp = piov5.dispResp;
endmodule: mkBridge
