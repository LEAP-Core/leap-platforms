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

(* synthesize, no_default_clock, no_default_reset *)
module mkBridge#(Clock pci_sys_clk, Clock refclk_100, Reset pci_sys_reset_n)
                (Bridge);

   (* doc = "synthesis attribute buffer_type of piov5_pcie_ep_trn_clk is \"none\"" *)
   (* doc = "synthesis attribute keep of piov5_pcie_ep_trn2_clk is \"true\";" *)
   LLV5PCIEIfc#(1) piov5 <- buildPCIEV5(pci_sys_clk
				                       ,pci_sys_reset_n
				                       ,refclk_100);

   ReadOnly#(Bool) _isLinkUp         <- mkNullCrossing(noClock, piov5.isLinkUp);
   ReadOnly#(Bool) _isOutOfReset     <- mkNullCrossing(noClock, piov5.isOutOfReset);
   ReadOnly#(Bool) _isClockAdvancing <- mkNullCrossing(noClock, piov5.isClockAdvancing);

   interface pcie = piov5.pcie;

   method leds = zeroExtend({pack(_isClockAdvancing)
			    ,pack(_isOutOfReset)
			    ,pack(_isLinkUp)
			    });

   method req = piov5.req;
   method resp = piov5.resp;
   method dispReq = piov5.dispReq;
   method dispResp = piov5.dispResp;
endmodule: mkBridge
