typedef enum {
	      WRITE = 0,
	      READ  = 1,
	      VOID  = 7  // unused
	      } DDR3Command deriving(Bits, Eq);

interface XILINX_DRAM_CONTROLLER;
    
    // wires
    method    Bit#(1)           ddr3_ck_p;
    method    Bit#(1)           ddr3_ck_n;
    method    Bit#(13)          ddr3_addr;
    method    Bit#(3)           ddr3_ba;
    method    Bit#(1)           ddr3_ras_n;
    method    Bit#(1)           ddr3_cas_n;
    method    Bit#(1)           ddr3_we_n;
    method    Bit#(1)           ddr3_cs_n;
    method    Bit#(1)           ddr3_odt;
    method    Bit#(1)           ddr3_cke;
    method    Bit#(1)           ddr3_reset_n;
    method    Bit#(8)           ddr3_dm;
    interface Inout#(Bit#(64))  ddr3_dq;
    interface Inout#(Bit#(8))   ddr3_dqs_p;
    interface Inout#(Bit#(8))   ddr3_dqs_n;
        
    interface Clock controller_clock;
    interface Reset controller_reset;
     
    // application interface
    method    Bool              init_done;
    method    Action            enqueue_address(DDR3Command command, Bit#(27) address);
    method    Action            enqueue_data(Bit#(256) data, Bit#(32) mask, Bool endBurst);
    method    Bit#(256)         dequeue_data;

    method    Bit#(1)           cmd_rdy;
    method    Bit#(1)           enq_rdy;
    method    Bit#(1)           deq_rdy;

       
endinterface

import "BVI" ddr3_wrapper =
module mkXilinxDRAMController#(Clock bsv_clk200,
                               Reset bsv_rst200)

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

    method ddr3_ck_p            ddr3_ck_p;
    method ddr3_ck_n            ddr3_ck_n;
    method ddr3_addr            ddr3_addr;
    method ddr3_ba              ddr3_ba;
    method ddr3_ras_n           ddr3_ras_n;
    method ddr3_cas_n           ddr3_cas_n;
    method ddr3_we_n            ddr3_we_n;
    method ddr3_cs_n            ddr3_cs_n;
    method ddr3_odt             ddr3_odt;
    method ddr3_cke             ddr3_cke;
    method ddr3_dm              ddr3_dm;
    method ddr3_reset_n         ddr3_reset_n;
      
    method init_done            init_done clocked_by (controller_clock) reset_by (controller_reset);
        
    method                      enqueue_address(app_cmd, app_addr) enable(app_enable) ready(app_ready) clocked_by (controller_clock) reset_by (controller_reset);
    method                      enqueue_data(app_wdf_data, app_wdf_mask, app_wdf_end) enable(app_wdf_enable) ready(app_wdf_ready) clocked_by (controller_clock) reset_by (controller_reset);
    method app_rd_data          dequeue_data ready(app_rd_ready) clocked_by (controller_clock) reset_by (controller_reset);
              
    method app_ready            cmd_rdy clocked_by (controller_clock) reset_by (controller_reset);
    method app_wdf_ready        enq_rdy clocked_by (controller_clock) reset_by (controller_reset);
    method app_rd_ready         deq_rdy clocked_by (controller_clock) reset_by (controller_reset);


    ifc_inout                   ddr3_dq(ddr3_dq);
    ifc_inout                   ddr3_dqs_p(ddr3_dqs_p);
    ifc_inout                   ddr3_dqs_n(ddr3_dqs_n);
   
    schedule (ddr3_ck_p, ddr3_ck_n, ddr3_addr, ddr3_ba, ddr3_ras_n, ddr3_cas_n, ddr3_we_n, ddr3_cs_n, ddr3_odt, ddr3_cke, ddr3_dm, ddr3_reset_n) CF
             (ddr3_ck_p, ddr3_ck_n, ddr3_addr, ddr3_ba, ddr3_ras_n, ddr3_cas_n, ddr3_we_n, ddr3_cs_n, ddr3_odt, ddr3_cke, ddr3_dm, ddr3_reset_n);
   
    schedule (init_done, enqueue_address, enqueue_data, dequeue_data, cmd_rdy, enq_rdy, deq_rdy) CF (init_done);
    schedule (cmd_rdy, enq_rdy, deq_rdy) CF (dequeue_data);
    schedule (cmd_rdy, enq_rdy, deq_rdy) CF (cmd_rdy, enq_rdy, deq_rdy, enqueue_address, enqueue_data);
   
    schedule (enqueue_address) SB (enqueue_data);
    schedule (enqueue_address) SBR  (enqueue_address);
    schedule (enqueue_data)    SBR  (enqueue_data);
    schedule (dequeue_data)    SBR  (dequeue_data);
    schedule (dequeue_data)    CF (enqueue_address, enqueue_data);

endmodule
