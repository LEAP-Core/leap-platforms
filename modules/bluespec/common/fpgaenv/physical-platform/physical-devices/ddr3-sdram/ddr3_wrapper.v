
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

// This is a wrapper around the ddr3 module generated from coregen.  This fixes
// up the control signals/resets so that they are more easily used in BSV.

module ddr3_wrapper #
  (
   parameter SIM_INIT_OPTION    = "SKIP_PU_DLY",
   parameter SIM_CAL_OPTION     = "FAST_CAL",
   parameter CLK_PERIOD         = 5000
   )
  (
   // DDR3 Pins
   inout [63:0]          ddr3_dq,
   output[12:0]          ddr3_addr,
   output [2:0]          ddr3_ba,
   output                ddr3_ras_n,
   output                ddr3_cas_n,
   output                ddr3_we_n,
   output                ddr3_reset_n,
   output                ddr3_cs_n,
   output                ddr3_odt,
   output                ddr3_cke,
   output [7:0]          ddr3_dm,
   inout [7:0]           ddr3_dqs_p,
   inout [7:0]           ddr3_dqs_n,
   output                ddr3_ck_p,
   output                ddr3_ck_n,

   // Clocks & Reset & Control
   input                 clk_ref_diff,
   input                 sys_rst_n,
   output                init_done,
   output                user_clock,
   output                user_reset_n,

   // DDR2 User Interface
   input [2:0]           app_cmd,
   input                 app_enable,
   input [26:0]          app_addr,
   output                app_ready,

   input                 app_wdf_enable,
   input [255:0]         app_wdf_data,
   input [31:0]          app_wdf_mask,
   input                 app_wdf_end,
   output                app_wdf_ready,

   output                app_rd_ready,
   output [255:0]        app_rd_data
   );

   wire                  app_rdy;
   wire 		 app_wdf_rdy;
   wire 		 app_rd_data_valid;
   wire 		 phy_init_done;
     
   assign                app_ready      = app_rdy && phy_init_done;
   assign                app_wdf_ready  = app_wdf_rdy && phy_init_done;
   assign                app_rd_ready   = app_rd_data_valid && phy_init_done;
   assign                init_done      = phy_init_done;

   wire 		 app_en;
   wire 		 app_wdf_wren;

   assign 		 app_en         = app_enable;
   assign 		 app_wdf_wren   = app_wdf_enable;

   wire 		 user_reset;
   assign 		 user_reset_n   = user_reset;

   wire                  sys_rst;
   assign                sys_rst        = ~sys_rst_n;
   
   ddr3_v3_5 
   u_ddr3 (
	   .clk_sys                  (clk_ref_diff),
	   .ddr3_dq                  (ddr3_dq),
	   .ddr3_addr                (ddr3_addr),
	   .ddr3_ba                  (ddr3_ba),
	   .ddr3_ras_n               (ddr3_ras_n),
	   .ddr3_cas_n               (ddr3_cas_n),
	   .ddr3_we_n                (ddr3_we_n),
	   .ddr3_reset_n             (ddr3_reset_n),
	   .ddr3_cs_n                (ddr3_cs_n),
	   .ddr3_odt                 (ddr3_odt),
	   .ddr3_cke                 (ddr3_cke),
	   .ddr3_dm                  (ddr3_dm),
	   .ddr3_dqs_p               (ddr3_dqs_p),
	   .ddr3_dqs_n               (ddr3_dqs_n),
	   .ddr3_ck_p                (ddr3_ck_p),
	   .ddr3_ck_n                (ddr3_ck_n),
	   .app_wdf_wren             (app_wdf_wren),
	   .app_wdf_data             (app_wdf_data),
	   .app_wdf_mask             (app_wdf_mask),
	   .app_wdf_end              (app_wdf_end),
	   .app_addr                 (app_addr),
	   .app_cmd                  (app_cmd),
	   .app_en                   (app_en),
	   .app_rdy                  (app_rdy),
	   .app_wdf_rdy              (app_wdf_rdy),
	   .app_rd_data              (app_rd_data),
	   .app_rd_data_valid        (app_rd_data_valid),
	   .tb_rst_n                 (user_reset),
	   .tb_clk                   (user_clock),
	   .phy_init_done            (phy_init_done),
	   .sys_rst                  (sys_rst)
	   );

endmodule // ddr3_wrapper
