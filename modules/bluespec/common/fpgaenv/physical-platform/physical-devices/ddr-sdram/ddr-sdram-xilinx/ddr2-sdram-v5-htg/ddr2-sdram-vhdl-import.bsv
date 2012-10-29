typedef enum {
	      WRITE = 0,
	      READ  = 1,
	      VOID  = 7  // unused
	      } DDR2Command deriving(Bits, Eq);


//        
// DDR_WIRES --
//     These are wires which are simply passed up to the toplevel,
//     where the UCF file ties them to pins.
//
interface DDR_WIRES;
    //
    // wires from the mem controller to the DRAM device
    //
    
    (* always_ready *)
    method    Bit#(2)           ddr_ck_p;

    (* always_ready *)
    method    Bit#(2)           ddr_ck_n;
        
    (* always_ready *)
    method    Bit#(13)          ddr_addr;
        
    (* always_ready *)
    method    Bit#(2)           ddr_ba;

    (* always_ready *)
    method    Bit#(1)           ddr_ras_n;

    (* always_ready *)
    method    Bit#(1)           ddr_cas_n;

    (* always_ready *)
    method    Bit#(1)           ddr_we_n;
        
    (* always_ready *)        
    method    Bit#(2)           ddr_cs_n;
        
    (* always_ready *)
    method    Bit#(2)           ddr_odt;

    (* always_ready *)
    method    Bit#(2)           ddr_cke;

    (* always_ready *)
    method    Bit#(8)           ddr_dm;

    (* always_ready, always_enabled *)
    interface Inout#(Bit#(64))  ddr_dq;

    (* always_ready, always_enabled *)
    interface Inout#(Bit#(8))   ddr_dqs;

    (* always_ready, always_enabled *)
    interface Inout#(Bit#(8))   ddr_dqs_n;
endinterface


interface XILINX_DRAM_CONTROLLER;
    
    // wires
    interface DDR_WIRES wires;
        
    // exported reset
    interface Clock controller_clock;
    interface Reset controller_reset;
     
    // application interface
    method    Bool              init_done;
    method    Action            enqueue_address(DDR2Command command, Bit#(31) address);
    method    Action            enqueue_data(Bit#(128) data, Bit#(16) mask, Bool endBurst);
    method    Bit#(128)         dequeue_data;
       
endinterface

import "BVI" ddr2_sdram =
module mkXilinxDRAMController#(Clock bsv_clkTop,
                               Reset bsv_rstTop)

    // interface:
        (XILINX_DRAM_CONTROLLER);
    
    DDR2_PLL pll <- mkDDR2PLL(clocked_by bsv_clkTop, reset_by bsv_rstTop);
    let bsv_clk150 = pll.clk_150;
    let bsv_clk200 = pll.clk_200;
    let bsv_rst150 = pll.rst;

    default_clock no_clock;
    default_reset no_reset;
    
    // default_clock clk();                          // huh?
    // default_reset rst(sys_rst_n) clocked_by(clk); // huh?
    
    input_clock   (sys_clk)      = bsv_clk150;
    input_clock   (idly_clk_200) = bsv_clk200;
    
    input_reset   (sys_rst_n) clocked_by (bsv_clk150) = bsv_rst150;
    
    output_clock controller_clock(clk0_tb);
    output_reset controller_reset(rst0_n_tb) clocked_by (controller_clock);
    
    interface DDR_WIRES wires;
        method ddr2_ck              ddr_ck_p;
        method ddr2_ck_n            ddr_ck_n;
        method ddr2_a               ddr_addr;
        method ddr2_ba              ddr_ba;
        method ddr2_ras_n           ddr_ras_n;
        method ddr2_cas_n           ddr_cas_n;
        method ddr2_we_n            ddr_we_n;
        method ddr2_cs_n            ddr_cs_n;
        method ddr2_odt             ddr_odt;
        method ddr2_cke             ddr_cke;
        method ddr2_dm              ddr_dm;

        ifc_inout                   ddr_dq(ddr2_dq);
        ifc_inout                   ddr_dqs(ddr2_dqs);
        ifc_inout                   ddr_dqs_n(ddr2_dqs_n);
    endinterface
   
    method phy_init_done        init_done clocked_by (controller_clock) reset_by (controller_reset);
        
    method                      enqueue_address(app_af_cmd, app_af_addr) enable(app_af_wren) ready(app_af_afull_n) clocked_by (controller_clock) reset_by (controller_reset);
    method                      enqueue_data(app_wdf_data, app_wdf_mask_data, app_wdf_end_burst) enable(app_wdf_wren) ready(app_wdf_afull_n) clocked_by (controller_clock) reset_by (controller_reset);
    method rd_data_fifo_out     dequeue_data ready(rd_data_valid) clocked_by (controller_clock) reset_by (controller_reset);
              
    schedule (wires.ddr_ck_p, wires.ddr_ck_n, wires.ddr_addr, wires.ddr_ba, wires.ddr_ras_n, wires.ddr_cas_n, wires.ddr_we_n, wires.ddr_cs_n, wires.ddr_odt, wires.ddr_cke, wires.ddr_dm) CF
             (wires.ddr_ck_p, wires.ddr_ck_n, wires.ddr_addr, wires.ddr_ba, wires.ddr_ras_n, wires.ddr_cas_n, wires.ddr_we_n, wires.ddr_cs_n, wires.ddr_odt, wires.ddr_cke, wires.ddr_dm);
   
    schedule (init_done, enqueue_address, enqueue_data, dequeue_data) CF (init_done);
   
    schedule (enqueue_address) SB (enqueue_data);
    schedule (enqueue_address) SBR  (enqueue_address);
    schedule (enqueue_data)    SBR  (enqueue_data);
    schedule (dequeue_data)    SBR  (dequeue_data);
    schedule (dequeue_data)    CF (enqueue_address, enqueue_data);

endmodule
