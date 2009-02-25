typedef enum {
	      WRITE = 0,
	      READ  = 1,
	      VOID  = 7  // unused
	      } DDR2Command deriving(Bits, Eq);

interface XILINX_DRAM_CONTROLLER;
    
    // wires
    method    Bit#(2)           ck_p;
    method    Bit#(2)           ck_n;
    method    Bit#(13)          a;
    method    Bit#(2)           ba;
    method    Bit#(1)           ras_n;
    method    Bit#(1)           cas_n;
    method    Bit#(1)           we_n;
    method    Bit#(2)           cs_n;
    method    Bit#(2)           odt;
    method    Bit#(2)           cke;
    method    Bit#(8)           dm;
    interface Inout#(Bit#(64))  dq;
    interface Inout#(Bit#(8))   dqs;
    interface Inout#(Bit#(8))   dqs_n;
        
    // exported reset
    interface Clock clk_out;
    interface Reset rst_out;
     
    // application interface
    method    Bool              init_done;
    method    Action            enqueue_address(DDR2Command command, Bit#(31) address);
    method    Action            enqueue_data(Bit#(128) data, Bit#(16) mask);
    method    Bit#(128)         dequeue_data;
       
endinterface

import "BVI" ddr2_sdram =
module mkXilinxDRAMController#(Clock bsv_clk125,
                               Clock bsv_clk200,
                               Reset bsv_rst125)

    // interface:
        (XILINX_DRAM_CONTROLLER);
    
    default_clock no_clock;
    default_reset no_reset;
    
    // default_clock clk();                          // huh?
    // default_reset rst(sys_rst_n) clocked_by(clk); // huh?
    
    input_clock   (sys_clk)      = bsv_clk125;
    input_clock   (idly_clk_200) = bsv_clk200;
    
    input_reset   (sys_rst_n) clocked_by (bsv_clk125) = bsv_rst125;
    
    output_clock clk_out(clk0_tb);
    output_reset rst_out(rst0_n_tb) clocked_by (clk_out);
    
    method ddr2_ck              ck_p;
    method ddr2_ck_n            ck_n;
    method ddr2_a               a;
    method ddr2_ba              ba;
    method ddr2_ras_n           ras_n;
    method ddr2_cas_n           cas_n;
    method ddr2_we_n            we_n;
    method ddr2_cs_n            cs_n;
    method ddr2_odt             odt;
    method ddr2_cke             cke;
    method ddr2_dm              dm;
      
    method phy_init_done        init_done clocked_by (clk_out) reset_by (rst_out);
        
    method                      enqueue_address(app_af_cmd, app_af_addr) enable(app_af_wren) ready(app_af_afull_n) clocked_by (clk_out) reset_by (rst_out);
    method                      enqueue_data(app_wdf_data, app_wdf_mask_data) enable(app_wdf_wren) ready(app_wdf_afull_n) clocked_by (clk_out) reset_by (rst_out);
    method rd_data_fifo_out     dequeue_data ready(rd_data_valid) clocked_by (clk_out) reset_by (rst_out);
              
    ifc_inout                   dq(ddr2_dq);
    ifc_inout                   dqs(ddr2_dqs);
    ifc_inout                   dqs_n(ddr2_dqs_n);
   
    schedule (ck_p, ck_n, a, ba, ras_n, cas_n, we_n, cs_n, odt, cke, dm) CF
             (ck_p, ck_n, a, ba, ras_n, cas_n, we_n, cs_n, odt, cke, dm);
   
    schedule (init_done, enqueue_address, enqueue_data, dequeue_data) CF (init_done);
   
    schedule (enqueue_address) SB (enqueue_data);
    schedule (enqueue_address) SBR  (enqueue_address);
    schedule (enqueue_data)    SBR  (enqueue_data);
    schedule (dequeue_data)    SBR  (dequeue_data);
    schedule (dequeue_data)    CF (enqueue_address, enqueue_data);

endmodule
