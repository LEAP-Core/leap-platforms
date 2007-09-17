interface ChannelIO;
    method ActionValue#(Maybe#(Bit#(32)))   read();
    method Action                           write(Bit#(32) data);
endinterface

import "BDPI" function Action                 cio_init();
import "BDPI" function ActionValue#(Bit#(8))  cio_open(Bit#(8) programID);
import "BDPI" function ActionValue#(Bit#(32)) cio_read(Bit#(8) handle);
import "BDPI" function Action   cio_write(Bit#(8) handle, Bit#(32) data);

module mkChannelIO(ChannelIO);

    Reg#(Bit#(8))   handle  <- mkReg(0);
    Reg#(Bit#(2))   ready   <- mkReg(0);

    rule initialize(ready == 0);
        cio_init();
        ready  <= 2;
    endrule

    rule temp_rule_open_channel(ready == 2);
        Bit#(8) wire_out <- cio_open(0);
        handle <= wire_out;
        ready  <= 1;
    endrule

    method ActionValue#(Maybe#(Bit#(32))) read() if (ready == 1);
        // 0xFFFFFFFF means no data
        // The Unix channelio C module uses the MSB to indicate
        // absence of data on the pipe. We convert this to a
        // tagged union
        Bit#(32) data <- cio_read(handle);
        Maybe#(Bit#(32)) retval;
        if (data == 'hFFFFFFFF)
            retval = tagged Invalid;
        else
            retval = tagged Valid data;
        return retval;
    endmethod

    method Action write(Bit#(32) data) if (ready == 1);
        cio_write(handle, data);
    endmethod

endmodule
