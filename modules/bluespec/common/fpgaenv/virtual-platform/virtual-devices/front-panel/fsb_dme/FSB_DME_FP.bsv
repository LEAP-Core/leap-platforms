import low_level_platform_interface::*;
import physical_platform::*;
import fsb_dme_device::*;

interface FrontPanel;
  method Action putData(Bit#(256) data, Bool begin_xfer, Bool end_xfer);
  method ActionValue#(Tuple3#(Bit#(256), Bool, Bool)) getData();
  method Action putCmd(Bit#(75) cmd);
  method ActionValue#(Bit#(75)) getCmd();
endinterface

module mkFrontPanel#(LowLevelPlatformInterface pint) (FrontPanel);

  method Action putData(Bit#(256) data, Bool begin_xfer, Bool end_xfer);
    pint.physicalDrivers.dmeDriver.putData(data, begin_xfer, end_xfer);
  endmethod
  
  method Action putCmd(Bit#(75) cmd);
    pint.physicalDrivers.dmeDriver.putCmd(cmd);
  endmethod
  
  method ActionValue#(Tuple3#(Bit#(256), Bool, Bool)) getData();
    let r <- pint.physicalDrivers.dmeDriver.getData();
    return r;
  endmethod
  
  method ActionValue#(Bit#(75)) getCmd();
    let r <- pint.physicalDrivers.dmeDriver.getCmd();
    return r;
  endmethod
  
endmodule
