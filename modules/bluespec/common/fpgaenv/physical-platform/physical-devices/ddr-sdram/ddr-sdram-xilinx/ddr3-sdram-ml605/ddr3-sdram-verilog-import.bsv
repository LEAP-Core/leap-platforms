`include "awb/provides/librl_bsv_base.bsh"
`include "awb/provides/ddr_sdram_definitions.bsh"
`include "awb/provides/fpga_components.bsh"

typedef enum {
	      WRITE = 0,
	      READ  = 1,
	      VOID  = 7  // unused
	      } DDR3Command deriving(Bits, Eq);

//        
// DDR_BANK_WIRES --
//     These are wires which are simply passed up to the toplevel,
//     where the UCF file ties them to pins.
//
interface DDR_BANK_WIRES;
    //
    // wires from the mem controller to the DRAM device
    //
    
    (* always_ready *)
    method    Bit#(1)           ddr_ck_p;

    (* always_ready *)
    method    Bit#(1)           ddr_ck_n;
        
    (* always_ready *)
    method    Bit#(13)          ddr_addr;
        
    (* always_ready *)
    method    Bit#(3)           ddr_ba;

    (* always_ready *)
    method    Bit#(1)           ddr_ras_n;

    (* always_ready *)
    method    Bit#(1)           ddr_cas_n;

    (* always_ready *)
    method    Bit#(1)           ddr_we_n;
        
    (* always_ready *)        
    method    Bit#(1)           ddr_cs_n;
        
    (* always_ready *)
    method    Bit#(1)           ddr_odt;

    (* always_ready *)
    method    Bit#(1)           ddr_cke;

    (* always_ready *)
    method    Bit#(8)           ddr_dm;

    (* always_ready *)
    method    Bit#(1)           ddr_reset_n;

    (* always_ready, always_enabled *)
    interface Inout#(Bit#(64))  ddr_dq;

    (* always_ready, always_enabled *)
    interface Inout#(Bit#(8))   ddr_dqs_p;

    (* always_ready, always_enabled *)
    interface Inout#(Bit#(8))   ddr_dqs_n;
endinterface


interface XILINX_DRAM_CONTROLLER;
    
    interface DDR_BANK_WIRES wires;
        
    interface Clock controller_clock;
    interface Reset controller_reset;
     
    // application interface
    method    Bool              init_done;
    method    Action            enqueue_address(DDR3Command command, Bit#(27) address);
    method    Action            enqueue_data(Bit#(256) data, Bit#(32) mask, Bool endBurst);
    method    Bit#(256)         dequeue_data;

    // Temperature monitoring.  In multi-bank controllers these may be needed
    // to pass temperature data from controller 0 to all others.
    method    Action            device_temp_i(Bit#(12) temp);
    method    Bit#(12)          device_temp_o;

    // Debug info
    method    Bool              dbg_wrlvl_start;
    method    Bool              dbg_wrlvl_done;
    method    Bool              dbg_wrlvl_err;
    method    Bit#(2)           dbg_rdlvl_start;
    method    Bit#(2)           dbg_rdlvl_done;
    method    Bit#(2)           dbg_rdlvl_err;

    method    Bit#(1)           cmd_rdy;
    method    Bit#(1)           enq_rdy;
    method    Bit#(1)           deq_rdy;
       
endinterface


//
// Function gives the controller a chance to approve the platform's
// configuration.
//
module checkDDRControllerConfig#(DDRControllerConfigure ddrConfig) ();
endmodule


import "BVI" ddr3_wrapper =
module mkXilinxDRAMController#(Clock bsv_clk200,
                               Reset bsv_rst200,
                               Integer bankIdx)

    // interface:
        (XILINX_DRAM_CONTROLLER);
    
    default_clock no_clock;
    default_reset no_reset;
    
    // default_clock clk();                          // huh?
    // default_reset rst(sys_rst_n) clocked_by(clk); // huh?
    
    input_clock   (clk_ref_diff)      = bsv_clk200;
    
    input_reset   (sys_rst_n) clocked_by (bsv_clk200) = bsv_rst200;
    
    output_clock controller_clock(user_clock);
    output_reset controller_reset(user_reset_n) clocked_by(controller_clock);

    interface DDR_BANK_WIRES wires;
        method ddr3_ck_p            ddr_ck_p;
        method ddr3_ck_n            ddr_ck_n;
        method ddr3_addr            ddr_addr;
        method ddr3_ba              ddr_ba;
        method ddr3_ras_n           ddr_ras_n;
        method ddr3_cas_n           ddr_cas_n;
        method ddr3_we_n            ddr_we_n;
        method ddr3_cs_n            ddr_cs_n;
        method ddr3_odt             ddr_odt;
        method ddr3_cke             ddr_cke;
        method ddr3_dm              ddr_dm;
        method ddr3_reset_n         ddr_reset_n;

        ifc_inout                   ddr_dq(ddr3_dq);
        ifc_inout                   ddr_dqs_p(ddr3_dqs_p);
        ifc_inout                   ddr_dqs_n(ddr3_dqs_n);
    endinterface
      
    method init_done            init_done clocked_by (controller_clock) reset_by (controller_reset);

    method dbg_wrlvl_start      dbg_wrlvl_start clocked_by (controller_clock) reset_by (controller_reset);
    method dbg_wrlvl_done       dbg_wrlvl_done clocked_by (controller_clock) reset_by (controller_reset);
    method dbg_wrlvl_err        dbg_wrlvl_err clocked_by (controller_clock) reset_by (controller_reset);
    method dbg_rdlvl_start      dbg_rdlvl_start clocked_by (controller_clock) reset_by (controller_reset);
    method dbg_rdlvl_done       dbg_rdlvl_done clocked_by (controller_clock) reset_by (controller_reset);
    method dbg_rdlvl_err        dbg_rdlvl_err clocked_by (controller_clock) reset_by (controller_reset);
        
    method                      enqueue_address(app_cmd, app_addr) enable(app_enable) ready(app_ready) clocked_by (controller_clock) reset_by (controller_reset);
    method                      enqueue_data(app_wdf_data, app_wdf_mask, app_wdf_end) enable(app_wdf_enable) ready(app_wdf_ready) clocked_by (controller_clock) reset_by (controller_reset);
    method app_rd_data          dequeue_data ready(app_rd_ready) clocked_by (controller_clock) reset_by (controller_reset);
              
    method app_ready            cmd_rdy clocked_by (controller_clock) reset_by (controller_reset);
    method app_wdf_ready        enq_rdy clocked_by (controller_clock) reset_by (controller_reset);
    method app_rd_ready         deq_rdy clocked_by (controller_clock) reset_by (controller_reset);

    method                      device_temp_i(device_temp_i) enable((*inhigh*)en_temp) clocked_by(bsv_clk200) reset_by(no_reset);
    method device_temp_o        device_temp_o clocked_by(no_clock) reset_by(no_reset);

   
    schedule (wires.ddr_ck_p, wires.ddr_ck_n, wires.ddr_addr, wires.ddr_ba, wires.ddr_ras_n, wires.ddr_cas_n, wires.ddr_we_n, wires.ddr_cs_n, wires.ddr_odt, wires.ddr_cke, wires.ddr_dm, wires.ddr_reset_n, device_temp_o) CF
             (wires.ddr_ck_p, wires.ddr_ck_n, wires.ddr_addr, wires.ddr_ba, wires.ddr_ras_n, wires.ddr_cas_n, wires.ddr_we_n, wires.ddr_cs_n, wires.ddr_odt, wires.ddr_cke, wires.ddr_dm, wires.ddr_reset_n, device_temp_o);
   
    schedule (init_done,
              dbg_wrlvl_done, dbg_wrlvl_err, dbg_wrlvl_start, 
              dbg_rdlvl_done, dbg_rdlvl_err, dbg_rdlvl_start,
              enqueue_address, enqueue_data, dequeue_data, cmd_rdy, enq_rdy, deq_rdy) CF (init_done);
    schedule (cmd_rdy, enq_rdy, deq_rdy,
              dbg_wrlvl_done, dbg_wrlvl_err, dbg_wrlvl_start, 
              dbg_rdlvl_done, dbg_rdlvl_err, dbg_rdlvl_start) CF (dequeue_data);
    schedule (cmd_rdy, enq_rdy, deq_rdy,
              dbg_wrlvl_done, dbg_wrlvl_err, dbg_wrlvl_start, 
              dbg_rdlvl_done, dbg_rdlvl_err, dbg_rdlvl_start)
                 CF (cmd_rdy, enq_rdy, deq_rdy,
                     dbg_wrlvl_done, dbg_wrlvl_err, dbg_wrlvl_start, 
                     dbg_rdlvl_done, dbg_rdlvl_err, dbg_rdlvl_start,
                     enqueue_address, enqueue_data);
   
    schedule (enqueue_address) SB (enqueue_data);
    schedule (enqueue_address) SBR  (enqueue_address);
    schedule (enqueue_data)    SBR  (enqueue_data);
    schedule (dequeue_data)    SBR  (dequeue_data);
    schedule (dequeue_data)    CF (enqueue_address, enqueue_data);
    schedule (device_temp_i)   C  (device_temp_i);

endmodule
