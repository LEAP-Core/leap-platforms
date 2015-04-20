
// Copyright (c) 2000-2009 Bluespec, Inc.

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// $Revision$
// $Date$

`include "awb/provides/ddr_sdram_xilinx_v23_config_params.bsh"

// This is a wrapper around the ddr3 module generated from coregen.  

module ddr3_wrapper_0 #
  (
   parameter SIM_BYPASS_INIT_CAL   = "OFF",
   parameter SIMULATION            = "FALSE",
   parameter DQ_WIDTH              = 64,
   parameter DQS_WIDTH             = 8,
   parameter ROW_WIDTH             = 16,
   parameter BANK_WIDTH            = 3,
   parameter DM_WIDTH              = 8,
   parameter ADDR_WIDTH            = 30,
   parameter nCK_PER_CLK           = 4,
   parameter PAYLOAD_WIDTH         = 64
   )
  (
   // Inouts
   inout [DQ_WIDTH-1:0]                         ddr3_dq,
   inout [DQS_WIDTH-1:0]                        ddr3_dqs_n,
   inout [DQS_WIDTH-1:0]                        ddr3_dqs_p,

   // Outputs
   output [ROW_WIDTH-1:0]                       ddr3_addr,
   output [BANK_WIDTH-1:0]                      ddr3_ba,
   output                                       ddr3_ras_n,
   output                                       ddr3_cas_n,
   output                                       ddr3_we_n,
   output                                       ddr3_reset_n,
   output                                       ddr3_ck_p,
   output                                       ddr3_ck_n,
   output                                       ddr3_cke,
   output                                       ddr3_cs_n,
   output [DM_WIDTH-1:0]                        ddr3_dm,
   output                                       ddr3_odt,

   // Inputs
   // Single-ended system clock
   input                                        sys_clk_i,
   
   // user interface signals
   input [ADDR_WIDTH-1:0]                       app_addr,
   input [2:0]                                  app_cmd,
   input                                        app_en,
   input [(nCK_PER_CLK*2*PAYLOAD_WIDTH)-1:0]    app_wdf_data,
   input                                        app_wdf_end,
   input [((nCK_PER_CLK*2*PAYLOAD_WIDTH)/8)-1:0]  app_wdf_mask,
   input                                        app_wdf_wren,
   output [(nCK_PER_CLK*2*PAYLOAD_WIDTH)-1:0]   app_rd_data,
   output                                       app_rd_data_end,
   output                                       app_rd_data_valid,
   output                                       app_rdy,
   output                                       app_wdf_rdy,
   input                                        app_sr_req,
   output                                       app_sr_active,
   input                                        app_ref_req,
   output                                       app_ref_ack,
   input                                        app_zq_req,
   output                                       app_zq_ack,
   output                                       ui_clk,
   output                                       ui_clk_sync_rst,
   
   output                                       init_calib_complete,

   // Multi-bank designs may need to share temperature monitors.  We always
   // describe the monitor input/output wires but connect them below only
   // when they are available in the driver.
   input [11:0]                                 device_temp_i,
   output [11:0]                                device_temp_o,

   // System reset
   input                                        sys_rst   
   );

`ifndef DRAM_SHARE_TEMP_MON
   assign device_temp_o = 'b0;
`endif

   mig_7series_0_mig #
     (
      .SIM_BYPASS_INIT_CAL (SIM_BYPASS_INIT_CAL),
      .SIMULATION          (SIMULATION)
      )

   u_ddr3_v2_3
     (
      // Memory interface ports
       .ddr3_addr                      (ddr3_addr),
       .ddr3_ba                        (ddr3_ba),
       .ddr3_cas_n                     (ddr3_cas_n),
       .ddr3_ck_n                      (ddr3_ck_n),
       .ddr3_ck_p                      (ddr3_ck_p),
       .ddr3_cke                       (ddr3_cke),
       .ddr3_ras_n                     (ddr3_ras_n),
       .ddr3_reset_n                   (ddr3_reset_n),
       .ddr3_we_n                      (ddr3_we_n),
       .ddr3_dq                        (ddr3_dq),
       .ddr3_dqs_n                     (ddr3_dqs_n),
       .ddr3_dqs_p                     (ddr3_dqs_p),
       .init_calib_complete            (init_calib_complete),
      
       .ddr3_cs_n                      (ddr3_cs_n),
       .ddr3_dm                        (ddr3_dm),
       .ddr3_odt                       (ddr3_odt),
      // Application interface ports
       .app_addr                       (app_addr),
       .app_cmd                        (app_cmd),
       .app_en                         (app_en),
       .app_wdf_data                   (app_wdf_data),
       .app_wdf_end                    (app_wdf_end),
       .app_wdf_wren                   (app_wdf_wren),
       .app_rd_data                    (app_rd_data),
       .app_rd_data_end                (app_rd_data_end),
       .app_rd_data_valid              (app_rd_data_valid),
       .app_rdy                        (app_rdy),
       .app_wdf_rdy                    (app_wdf_rdy),
       .app_sr_req                     (1'b0),
       .app_sr_active                  (),
       .app_ref_req                    (1'b0),
       .app_ref_ack                    (),
       .app_zq_req                     (1'b0),
       .app_zq_ack                     (),
       .ui_clk                         (ui_clk),
       .ui_clk_sync_rst                (ui_clk_sync_rst),

       .app_wdf_mask                   (app_wdf_mask),

`ifdef DRAM_SHARE_TEMP_MON
       .device_temp_i                  (device_temp_i),
       .device_temp_o                  (device_temp_o),
`endif

      // System Clock Ports
       .sys_clk_i                      (sys_clk_i),

       .sys_rst                        (sys_rst)
      );

endmodule // ddr3_wrapper
