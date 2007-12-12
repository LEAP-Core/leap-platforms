import low_level_platform_interface::*;
import physical_platform::*;
import fsb_afu::*;

interface FrontPanel;
  method Action makeResponse(Bit#(256) data);
  method ActionValue#(Bit#(256)) getRequest();
endinterface

module mkFrontPanel#(LowLevelPlatformInterface pint) (FrontPanel);

  method Action makeResponse(Bit#(256) data);
    pint.physicalDrivers.afuDriver.makeResponse(data);
  endmethod
  
  method ActionValue#(Bit#(256)) getRequest();
    let r <- pint.physicalDrivers.afuDriver.getRequest();
    return r;
  endmethod
  
endmodule
