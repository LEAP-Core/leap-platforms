//
// Copyright (c) 2014, Intel Corporation
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// Neither the name of the Intel Corporation nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//

//
// Wrap the Bluespec-default Virtex-7 DDR3 driver with a LEAP standard DDR
// interface.
//
// The Bluespec-provided wrapper doesn't export the bare BVI wrapper.
// Instead, it is copied to this file.
//

import Clocks::*;
import DefaultValue::*;

`include "awb/provides/librl_bsv_base.bsh"
`include "awb/provides/ddr_sdram_definitions.bsh"
`include "awb/provides/fpga_components.bsh"


//        
// DDR_BANK_WIRES --
//     These are wires which are simply passed up to the toplevel,
//     where the UCF file ties them to pins.
//
typedef DDR3_Pins_V7 DDR_BANK_WIRES;

// The smallest addressable word:
typedef `DRAM_WORD_WIDTH FPGA_DDR_WORD_SZ;
typedef Bit#(FPGA_DDR_WORD_SZ) FPGA_DDR_WORD;

typedef `DRAM_BEAT_WIDTH FPGA_DDR_DUALEDGE_BEAT_SZ;
typedef Bit#(FPGA_DDR_DUALEDGE_BEAT_SZ) FPGA_DDR_DUALEDGE_BEAT;

typedef TDiv#(FPGA_DDR_DUALEDGE_BEAT_SZ, FPGA_DDR_WORD_SZ) FPGA_DDR_WORDS_PER_BEAT;
typedef TDiv#(FPGA_DDR_DUALEDGE_BEAT_SZ, 8) FPGA_DDR_BYTES_PER_BEAT;
typedef TDiv#(FPGA_DDR_WORD_SZ, 8) FPGA_DDR_BYTES_PER_WORD;

typedef Bit#(FPGA_DDR_BYTES_PER_WORD) FPGA_DDR_WORD_MASK;
typedef Bit#(FPGA_DDR_BYTES_PER_BEAT) FPGA_DDR_DUALEDGE_BEAT_MASK;

interface XILINX_DRAM_CONTROLLER;
    
    interface DDR_BANK_WIRES wires;
        
    interface Clock controller_clock;
    interface Reset controller_reset;
     
    // application interface
    method    Bool                    init_done;
    method    Action                  enqueue_address(DDR3Command command, Bit#(28) address);
    method    Action                  enqueue_data(FPGA_DDR_DUALEDGE_BEAT data, FPGA_DDR_DUALEDGE_BEAT_MASK mask, Bool endBurst);
    method    FPGA_DDR_DUALEDGE_BEAT  dequeue_data;

    // Debug info
    method    Bit#(1)                 cmd_rdy;
    method    Bit#(1)                 enq_rdy;
    method    Bit#(1)                 deq_rdy;
       
    method    Bool                    dbg_wrlvl_start;
    method    Bool                    dbg_wrlvl_done;
    method    Bool                    dbg_wrlvl_err;
    method    Bit#(2)                 dbg_rdlvl_start;
    method    Bit#(2)                 dbg_rdlvl_done;
    method    Bit#(2)                 dbg_rdlvl_err;

endinterface


//
// Function gives the controller a chance to approve the platform's
// configuration.
//
module checkDDRControllerConfig#(DDRControllerConfigure ddrConfig) ();
endmodule


module mkXilinxDRAMController#(Clock clk200,
                               Reset rst200)

    // Interface:
    (XILINX_DRAM_CONTROLLER);

    // Instantiate the Bluespec-standard DDR3 controller
    DDR3_Configure_V7 cfg = defaultValue();
    let ddr3ctrl <- vMkVirtex7DDR3Controller(cfg,
                                             clocked_by clk200,
                                             reset_by rst200);

    Clock user_clock    = ddr3ctrl.user.clock;
    Reset user_reset0_n <- mkResetInverter(ddr3ctrl.user.reset);
    Reset user_reset_n  <- mkAsyncReset(2, user_reset0_n, user_clock);

    PulseWire pwAppEn      <- mkPulseWire(clocked_by user_clock, reset_by user_reset_n);
    PulseWire pwAppWdfWren <- mkPulseWire(clocked_by user_clock, reset_by user_reset_n);
    PulseWire pwAppWdfEnd  <- mkPulseWire(clocked_by user_clock, reset_by user_reset_n);

    Wire#(DDR3Command) wAppCmd     <- mkDWire(WRITE, clocked_by user_clock, reset_by user_reset_n);
    Wire#(Bit#(28))    wAppAddr    <- mkDWire(0, clocked_by user_clock, reset_by user_reset_n);
    Wire#(FPGA_DDR_DUALEDGE_BEAT_MASK)    wAppWdfMask <- mkDWire(0, clocked_by user_clock, reset_by user_reset_n);
    Wire#(FPGA_DDR_DUALEDGE_BEAT)   wAppWdfData <- mkDWire(0, clocked_by user_clock, reset_by user_reset_n);

    (* fire_when_enabled, no_implicit_conditions *)
    rule drive_enables;
        ddr3ctrl.user.app_en(pwAppEn);
        ddr3ctrl.user.app_wdf_wren(pwAppWdfWren);
        ddr3ctrl.user.app_wdf_end(pwAppWdfEnd);
    endrule

    (* fire_when_enabled, no_implicit_conditions *)
    rule drive_data_signals;
        ddr3ctrl.user.app_cmd(wAppCmd);
        ddr3ctrl.user.app_addr(wAppAddr);
        ddr3ctrl.user.app_wdf_data(wAppWdfData);
        ddr3ctrl.user.app_wdf_mask(wAppWdfMask);
    endrule
   

    // Exposed top-level wires
    interface DDR_BANK_WIRES wires = ddr3ctrl.ddr3;
        
    // Clock/Reset for the interface, generated in the controller from
    // the incoming 200MHz clock.
    interface Clock controller_clock = user_clock;
    interface Reset controller_reset = user_reset_n;
     
    method Bool init_done() = ddr3ctrl.user.init_done();

    method Action enqueue_address(DDR3Command command, Bit#(28) address) if (ddr3ctrl.user.app_rdy);
        // Signal that command is being sent
        pwAppEn.send();
        wAppCmd <= command;
        wAppAddr <= address;
    endmethod

    method Action enqueue_data(FPGA_DDR_DUALEDGE_BEAT data, FPGA_DDR_DUALEDGE_BEAT_MASK mask, Bool endBurst) if (ddr3ctrl.user.app_wdf_rdy);
        // Signal that write data is being sent
        pwAppWdfWren.send();
        wAppWdfData <= data;
        wAppWdfMask <= mask;
        if (endBurst) pwAppWdfEnd.send();
    endmethod

    method FPGA_DDR_DUALEDGE_BEAT dequeue_data() if (ddr3ctrl.user.app_rd_data_valid);
        return ddr3ctrl.user.app_rd_data;
    endmethod


    //
    // Debug info is not currently exported by the standard Bluespec driver.
    //
    method Bit#(1) cmd_rdy = error("Virtex-7 DDR debug not implemented");
    method Bit#(1) enq_rdy = error("Virtex-7 DDR debug not implemented");
    method Bit#(1) deq_rdy = error("Virtex-7 DDR debug not implemented");
       
    method Bool dbg_wrlvl_start = error("Virtex-7 DDR debug not implemented");
    method Bool dbg_wrlvl_done = error("Virtex-7 DDR debug not implemented");
    method Bool dbg_wrlvl_err = error("Virtex-7 DDR debug not implemented");
    method Bit#(2) dbg_rdlvl_start = error("Virtex-7 DDR debug not implemented");
    method Bit#(2) dbg_rdlvl_done = error("Virtex-7 DDR debug not implemented");
    method Bit#(2) dbg_rdlvl_err = error("Virtex-7 DDR debug not implemented");
endmodule



//
// This is just a local copy of the standard Bluespec Virtex-7 DDR3
// controller wrapper.  It is here only because Bluespec doesn't export
// the wrapper from the XilinxVirtex7DDR3 package.
//

////////////////////////////////////////////////////////////////////////////////
/// Types
////////////////////////////////////////////////////////////////////////////////
typedef struct {
   Bit#(64)    byteen;
   Bit#(28)    address;
   Bit#(512)   data;
} DDR3Request deriving (Bits, Eq);

typedef struct {
   Bit#(512)   data;
} DDR3Response deriving (Bits, Eq);	       

typedef enum {
   WRITE     = 0,
   READ      = 1
} DDR3Command deriving (Eq);

instance Bits#(DDR3Command, 3);
   function Bit#(3) pack(DDR3Command x);
      case(x) 
	 WRITE:   return 0;
	 READ:    return 1;
      endcase
   endfunction
   
   function DDR3Command unpack(Bit#(3) x);
      DDR3Command cmd;
      case(x)
	 0:       cmd = WRITE;
	 1:       cmd = READ;
	 default: cmd = READ;
      endcase
      return cmd;
   endfunction
endinstance

typedef struct {
   Bool               fast_train_sim_only;
   Integer            num_reads_in_flight;
} DDR3_Configure_V7;

instance DefaultValue#(DDR3_Configure_V7);
   defaultValue = DDR3_Configure_V7 {
      fast_train_sim_only:    False,
      num_reads_in_flight:    2
      };
endinstance

////////////////////////////////////////////////////////////////////////////////
/// Interfaces
////////////////////////////////////////////////////////////////////////////////
(* always_enabled, always_ready *)
interface DDR3_Pins_V7;
   (* prefix = "", result = "CLK_P" *)
   method    Bit#(1)           clk_p;
   (* prefix = "", result = "CLK_N" *)
   method    Bit#(1)           clk_n;
   (* prefix = "", result = "A" *)
   method    Bit#(14)          a;
   (* prefix = "", result = "BA" *)
   method    Bit#(3)           ba;
   (* prefix = "", result = "RAS_N" *)
   method    Bit#(1)           ras_n;
   (* prefix = "", result = "CAS_N" *)
   method    Bit#(1)           cas_n;
   (* prefix = "", result = "WE_N" *)
   method    Bit#(1)           we_n;
   (* prefix = "", result = "RESET_N" *)
   method    Bit#(1)           reset_n;
   (* prefix = "", result = "CS_N" *)
   method    Bit#(1)           cs_n;
   (* prefix = "", result = "ODT" *)
   method    Bit#(1)           odt;
   (* prefix = "", result = "CKE" *)
   method    Bit#(1)           cke;
   (* prefix = "", result = "DM" *)
   method    Bit#(8)           dm;
   (* prefix = "DQ" *)
   interface Inout#(Bit#(64))  dq;
   (* prefix = "DQS_P" *)
   interface Inout#(Bit#(8))   dqs_p;
   (* prefix = "DQS_N" *)
   interface Inout#(Bit#(8))   dqs_n;
endinterface   

interface DDR3_User_V7;
   interface Clock             	     clock;
   interface Reset             	     reset_n;
   method    Bool              	     init_done;
   method    Action                  request(Bit#(28) addr, Bit#(64) mask, Bit#(512) data);
   method    ActionValue#(Bit#(512)) read_data;
endinterface

interface DDR3_Controller_V7;
   (* prefix = "" *)
   interface DDR3_Pins_V7      ddr3;
   (* prefix = "" *)
   interface DDR3_User_V7      user;
endinterface

(* always_ready, always_enabled *)
interface VDDR3_User_V7;
   interface Clock             clock;
   interface Reset             reset;
   method    Bool              init_done;
   method    Action            app_addr(Bit#(28) i);
   method    Action            app_cmd(DDR3Command i);
   method    Action            app_en(Bool i);
   method    Action            app_wdf_data(FPGA_DDR_DUALEDGE_BEAT i);
   method    Action            app_wdf_end(Bool i);
   method    Action            app_wdf_mask(FPGA_DDR_DUALEDGE_BEAT_MASK i);
   method    Action            app_wdf_wren(Bool i);
   method    FPGA_DDR_DUALEDGE_BEAT         app_rd_data;
   method    Bool              app_rd_data_end;
   method    Bool              app_rd_data_valid;
   method    Bool              app_rdy;
   method    Bool              app_wdf_rdy;
endinterface

interface VDDR3_Controller_V7;
   (* prefix = "" *)
   interface DDR3_Pins_V7      ddr3;
   (* prefix = "" *)
   interface VDDR3_User_V7     user;
endinterface   

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
///
/// Implementation
///
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
import "BVI" ddr3_wrapper =
module vMkVirtex7DDR3Controller#(DDR3_Configure_V7 cfg)(VDDR3_Controller_V7);
   default_clock clk(sys_clk_i);
   default_reset rst(sys_rst);
   
   parameter SIM_BYPASS_INIT_CAL = (cfg.fast_train_sim_only) ? "FAST" : "OFF";
   parameter SIMULATION          = (cfg.fast_train_sim_only) ? "TRUE" : "FALSE";
   
   interface DDR3_Pins_V7 ddr3;
      ifc_inout   dq(ddr3_dq)          clocked_by(no_clock)  reset_by(no_reset);
      ifc_inout   dqs_p(ddr3_dqs_p)    clocked_by(no_clock)  reset_by(no_reset);
      ifc_inout   dqs_n(ddr3_dqs_n)    clocked_by(no_clock)  reset_by(no_reset);
      method      ddr3_ck_p    clk_p   clocked_by(no_clock)  reset_by(no_reset);
      method      ddr3_ck_n    clk_n   clocked_by(no_clock)  reset_by(no_reset);
      method      ddr3_cke     cke     clocked_by(no_clock)  reset_by(no_reset);
      method      ddr3_cs_n    cs_n    clocked_by(no_clock)  reset_by(no_reset);
      method      ddr3_ras_n   ras_n   clocked_by(no_clock)  reset_by(no_reset);
      method      ddr3_cas_n   cas_n   clocked_by(no_clock)  reset_by(no_reset);
      method      ddr3_we_n    we_n    clocked_by(no_clock)  reset_by(no_reset);
      method      ddr3_reset_n reset_n clocked_by(no_clock)  reset_by(no_reset);
      method      ddr3_dm      dm      clocked_by(no_clock)  reset_by(no_reset);
      method      ddr3_ba      ba      clocked_by(no_clock)  reset_by(no_reset);
      method      ddr3_addr    a       clocked_by(no_clock)  reset_by(no_reset);
      method      ddr3_odt     odt     clocked_by(no_clock)  reset_by(no_reset);
   endinterface
   
   interface VDDR3_User_V7 user;
      output_clock    clock(ui_clk);
      output_reset    reset(ui_clk_sync_rst);
      method init_calib_complete      init_done    clocked_by(no_clock) reset_by(no_reset);
      method          		      app_addr(app_addr) enable((*inhigh*)en0) clocked_by(user_clock) reset_by(no_reset);
      method                          app_cmd(app_cmd)   enable((*inhigh*)en00) clocked_by(user_clock) reset_by(no_reset);
      method          		      app_en(app_en)     enable((*inhigh*)en1) clocked_by(user_clock) reset_by(no_reset);
      method          		      app_wdf_data(app_wdf_data) enable((*inhigh*)en2) clocked_by(user_clock) reset_by(no_reset);
      method          		      app_wdf_end(app_wdf_end)   enable((*inhigh*)en3) clocked_by(user_clock) reset_by(no_reset);
      method          		      app_wdf_mask(app_wdf_mask) enable((*inhigh*)en4) clocked_by(user_clock) reset_by(no_reset);
      method          		      app_wdf_wren(app_wdf_wren) enable((*inhigh*)en5) clocked_by(user_clock) reset_by(no_reset);
      method app_rd_data              app_rd_data clocked_by(user_clock) reset_by(no_reset);
      method app_rd_data_end          app_rd_data_end clocked_by(user_clock) reset_by(no_reset);
      method app_rd_data_valid        app_rd_data_valid clocked_by(user_clock) reset_by(no_reset);
      method app_rdy                  app_rdy clocked_by(user_clock) reset_by(no_reset);
      method app_wdf_rdy              app_wdf_rdy clocked_by(user_clock) reset_by(no_reset);
   endinterface
   
   schedule
   (
    ddr3_clk_p, ddr3_clk_n, ddr3_cke, ddr3_cs_n, ddr3_ras_n, ddr3_cas_n, ddr3_we_n, 
    ddr3_reset_n, ddr3_dm, ddr3_ba, ddr3_a, ddr3_odt, user_init_done
    )
   CF
   (
    ddr3_clk_p, ddr3_clk_n, ddr3_cke, ddr3_cs_n, ddr3_ras_n, ddr3_cas_n, ddr3_we_n, 
    ddr3_reset_n, ddr3_dm, ddr3_ba, ddr3_a, ddr3_odt, user_init_done
    );
   
   schedule 
   (
    user_app_addr, user_app_en, user_app_wdf_data, user_app_wdf_end, user_app_wdf_mask, user_app_wdf_wren, user_app_rd_data, 
    user_app_rd_data_end, user_app_rd_data_valid, user_app_rdy, user_app_wdf_rdy, user_app_cmd
    )
   CF
   (
    user_app_addr, user_app_en, user_app_wdf_data, user_app_wdf_end, user_app_wdf_mask, user_app_wdf_wren, user_app_rd_data, 
    user_app_rd_data_end, user_app_rd_data_valid, user_app_rdy, user_app_wdf_rdy, user_app_cmd
    );

endmodule
