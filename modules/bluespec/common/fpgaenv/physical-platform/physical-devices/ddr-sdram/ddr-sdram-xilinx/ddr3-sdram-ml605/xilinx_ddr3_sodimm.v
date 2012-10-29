
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

`ifdef BSV_ASSIGNMENT_DELAY
`else
 `define BSV_ASSIGNMENT_DELAY
`endif

`timescale 1ps/1ps

module xilinx_ddr3_sodimm
  (
   RESET_N,
   CLK_P,
   CLK_N,
   CKE,
   CS_N,
   RAS_N,
   CAS_N,
   WE_N,
   DM,
   BA,
   ADDR,
   DQ,
   DQS_P,
   DQS_N,
   ODT
   );

   input                  RESET_N;
   input [0:0]            CLK_P;
   input [0:0] 		  CLK_N;
   input [0:0]		  CKE;
   input [0:0]		  CS_N;
   input 		  RAS_N;
   input 		  CAS_N;
   input 		  WE_N;
   input [7:0] 		  DM;
   input [2:0] 		  BA;
   input [12:0] 	  ADDR;
   inout [63:0] 	  DQ;
   inout [7:0] 		  DQS_P;
   inout [7:0] 		  DQS_N;
   input [0:0] 		  ODT;



  parameter REFCLK_FREQ           = 200;
                                    // # = 200 when design frequency < 533 MHz,
                                    //   = 300 when design frequency >= 533 MHz.
  parameter SIM_INIT_OPTION       = "SKIP_PU_DLY";
                                    // # = "SKIP_PU_DLY" - Skip the memory
                                    //                     initilization sequence,
                                    //   = "NONE" - Complete the memory
                                    //              initilization sequence.
  parameter SIM_CAL_OPTION        = "FAST_CAL";
                                    // # = "FAST_CAL" - Skip the delay
                                    //                  Calibration process,
                                    //   = "NONE" - Complete the delay
                                    //              Calibration process.
  parameter RST_ACT_LOW           = 1;
                                    // =1 for active low reset,
                                    // =0 for active high.
  parameter IODELAY_GRP           = "IODELAY_MIG";
                                    //to phy_top
  parameter nCK_PER_CLK           = 2;
                                    // # of memory CKs per fabric clock.
                                    // # = 2, 1.
  parameter nCS_PER_RANK          = 1;
                                    // # of unique CS outputs per Rank for
                                    // phy.
  parameter DQS_CNT_WIDTH         = 3;
                                    // # = ceil(log2(DQS_WIDTH)).
  parameter RANK_WIDTH            = 1;
                                    // # = ceil(log2(RANKS)).
  parameter BANK_WIDTH            = 3;
                                    // # of memory Bank Address bits.
  parameter CK_WIDTH              = 1;
                                    // # of CK/CK# outputs to memory.
  parameter CKE_WIDTH             = 1;
                                    // # of CKE outputs to memory.
  parameter COL_WIDTH             = 10;
                                    // # of memory Column Address bits.
  parameter CS_WIDTH              = 1;
                                    // # of unique CS outputs to memory.
  parameter DM_WIDTH              = 8;
                                    // # of Data Mask bits.
  parameter DQ_WIDTH              = 64;
                                    // # of Data (DQ) bits.
  parameter DQS_WIDTH             = 8;
                                    // # of DQS/DQS# bits.
  parameter ROW_WIDTH             = 13;
                                    // # of memory Row Address bits.
  parameter BURST_MODE            = "8";
                                    // Burst Length (Mode Register 0).
                                    // # = "8", "4", "OTF".
  parameter INPUT_CLK_TYPE        = "DIFFERENTIAL";
                                    // input clock type DIFFERNTIAL or SINGLE_ENDED
  parameter BM_CNT_WIDTH          = 2;
                                    // # = ceil(log2(nBANK_MACHS)).
  parameter ADDR_CMD_MODE         = "UNBUF";
                                    // # = "UNBUF", "REG".
  parameter ORDERING              = "STRICT";
                                    // # = "NORM", "STRICT", "RELAXED".
  parameter WRLVL                 = "ON";
                                    // # = "ON" - DDR3 SDRAM
                                    //   = "OFF" - DDR2 SDRAM.
  parameter PHASE_DETECT          = "ON";
                                    // # = "ON", "OFF".
  parameter RTT_NOM               = "60";
                                    // RTT_NOM (ODT) (Mode Register 1).
                                    // # = "DISABLED" - RTT_NOM disabled,
                                    //   = "120" - RZQ/2,
                                    //   = "60" - RZQ/4,
                                    //   = "40" - RZQ/6.
   parameter RTT_WR               = "OFF";
                                       // RTT_WR (ODT) (Mode Register 2).
                                       // # = "OFF" - Dynamic ODT off,
                                       //   = "120" - RZQ/2,
                                       //   = "60" - RZQ/4,
  parameter OUTPUT_DRV            = "HIGH";
                                    // Output Driver Impedance Control (Mode Register 1).
                                    // # = "HIGH" - RZQ/7,
                                    //   = "LOW" - RZQ/6.
  parameter REG_CTRL              = "OFF";
                                    // # = "ON" - RDIMMs,
                                    //   = "OFF" - Components, SODIMMs, UDIMMs.
  parameter CLKFBOUT_MULT_F       = 6;
                                    // write PLL VCO multiplier.
  parameter DIVCLK_DIVIDE         = 2;
                                    // write PLL VCO divisor.
  parameter CLKOUT_DIVIDE         = 3;
                                    // VCO output divisor for fast (memory) clocks.
  parameter tCK                   = 2500;
                                    // memory tCK paramter.
                                    // # = Clock Period.
  parameter DEBUG_PORT            = "OFF";
                                    // # = "ON" Enable debug signals/controls.
                                    //   = "OFF" Disable debug signals/controls.
  parameter tPRDI                   = 1_000_000;
                                    // memory tPRDI paramter.
  parameter tREFI                   = 7800000;
                                    // memory tREFI paramter.
  parameter tZQI                    = 128_000_000;
                                    // memory tZQI paramter.
  parameter ADDR_WIDTH              = 27;
                                    // # = RANK_WIDTH + BANK_WIDTH
                                    //     + ROW_WIDTH + COL_WIDTH;
  parameter STARVE_LIMIT            = 2;
                                    // # = 2,3,4.
  parameter TCQ                     = 100;
  parameter ECC_TEST                = "OFF";

  //***********************************************************************//
  // Traffic Gen related parameters
  //***********************************************************************//
  parameter EYE_TEST                = "FALSE";
                                      // set EYE_TEST = "TRUE" to probe memory
                                      // signals. Traffic Generator will only
                                      // write to one single location and no
                                      // read transactions will be generated.
  parameter DATA_PATTERN            = "DGEN_ALL";
                                       // "DGEN_HAMMER", "DGEN_WALKING1",
                                       // "DGEN_WALKING0","DGEN_ADDR","
                                       // "DGEN_NEIGHBOR","DGEN_PRBS","DGEN_ALL"
  parameter CMD_PATTERN             = "CGEN_ALL";
                                       // "CGEN_RPBS","CGEN_FIXED","CGEN_BRAM",
                                       // "CGEN_SEQUENTIAL", "CGEN_ALL"

  parameter BEGIN_ADDRESS           = 32'h00000000;
  parameter PRBS_SADDR_MASK_POS     = 32'h00000000;
  parameter END_ADDRESS             = 32'h000003ff;
  parameter PRBS_EADDR_MASK_POS     = 32'hfffffc00;
  parameter SEL_VICTIM_LINE         = 11;

  //**************************************************************************//
  // Local parameters Declarations
  //**************************************************************************//
  localparam real TPROP_DQS          = 0.00;  // Delay for DQS signal during Write Operation
  localparam real TPROP_DQS_RD       = 0.00;  // Delay for DQS signal during Read Operation
  localparam real TPROP_PCB_CTRL     = 0.00;  // Delay for Address and Ctrl signals
  localparam real TPROP_PCB_DATA     = 0.00;  // Delay for data signal during Write operation
  localparam real TPROP_PCB_DATA_RD  = 0.00;  // Delay for data signal during Read operation

  localparam MEMORY_WIDTH = 16;
  localparam NUM_COMP = DQ_WIDTH/MEMORY_WIDTH;
  localparam real CLK_PERIOD = tCK;
  localparam real REFCLK_PERIOD = (1000000.0/(2*REFCLK_FREQ));
  localparam DRAM_DEVICE = "SODIMM";
                         // DRAM_TYPE: "UDIMM", "RDIMM", "COMPS"

   // VT delay change options/settings
  localparam VT_ENABLE                  = "OFF";
                                        // Enable VT delay var's
  localparam VT_RATE                    = CLK_PERIOD/500;
                                        // Size of each VT step
  localparam VT_UPDATE_INTERVAL         = CLK_PERIOD*50;
                                        // Update interval
  localparam VT_MAX                     = CLK_PERIOD/40;
                                        // Maximum VT shift
   
  //***************************************************************************
  // Instantiate memories
  //***************************************************************************

  genvar r,i,dqs_x;
  generate
      for (r = 0; r < CS_WIDTH; r = r+1) begin: mem_rnk
        if(MEMORY_WIDTH == 16) begin: mem_16
          if(DQ_WIDTH/16) begin: gen_mem
            for (i = 0; i < NUM_COMP; i = i + 1) begin: gen_mem
              ddr3_model u_comp_ddr3
                (
                 .rst_n   (RESET_N),
                 .ck      (CLK_P[(i*MEMORY_WIDTH)/72]),
                 .ck_n    (CLK_N[(i*MEMORY_WIDTH)/72]),
                 .cke     (CKE[((i*MEMORY_WIDTH)/72)+(nCS_PER_RANK*r)]),
                 .cs_n    (CS_N[((i*MEMORY_WIDTH)/72)+(nCS_PER_RANK*r)]),
                 .ras_n   (RAS_N),
                 .cas_n   (CAS_N),
                 .we_n    (WE_N),
                 .dm_tdqs (DM[(2*(i+1)-1):(2*i)]),
                 .ba      (BA),
                 .addr    (ADDR),
                 .dq      (DQ[MEMORY_WIDTH*(i+1)-1:MEMORY_WIDTH*(i)]),
                 .dqs     (DQS_P[(2*(i+1)-1):(2*i)]),
                 .dqs_n   (DQS_N[(2*(i+1)-1):(2*i)]),
                 .tdqs_n  (),
                 .odt     (ODT[((i*MEMORY_WIDTH)/72)+(nCS_PER_RANK*r)])
                 );
            end
          end
          if (DQ_WIDTH%16) begin: gen_mem_extrabits
            ddr3_model u_comp_ddr3
              (
               .rst_n   (RESET_N),
               .ck      (CLK_P[(DQ_WIDTH-1)/72]),
               .ck_n    (CLK_N[(DQ_WIDTH-1)/72]),
               .cke     (CKE[((DQ_WIDTH-1)/72)+(nCS_PER_RANK*r)]),
               .cs_n    (CS_N[((DQ_WIDTH-1)/72)+(nCS_PER_RANK*r)]),
               .ras_n   (RAS_N),
               .cas_n   (CAS_N),
               .we_n    (WE_N),
               .dm_tdqs ({DM[DM_WIDTH-1],DM[DM_WIDTH-1]}),
               .ba      (BA),
               .addr    (ADDR),
               .dq      ({DQ[DQ_WIDTH-1:(DQ_WIDTH-8)],
                          DQ[DQ_WIDTH-1:(DQ_WIDTH-8)]}),
               .dqs     ({DQS_P[DQS_WIDTH-1],
                          DQS_P[DQS_WIDTH-1]}),
               .dqs_n   ({DQS_N[DQS_WIDTH-1],
                          DQS_N[DQS_WIDTH-1]}),
               .tdqs_n  (),
               .odt     (ODT[((DQ_WIDTH-1)/72)+(nCS_PER_RANK*r)])
               );
          end
        end
        if((MEMORY_WIDTH == 8) || (MEMORY_WIDTH == 4)) begin: mem_8_4
          for (i = 0; i < NUM_COMP; i = i + 1) begin: gen_mem
            ddr3_model u_comp_ddr3
              (
               .rst_n   (RESET_N),
               .ck      (CLK_P[(i*MEMORY_WIDTH)/72]),
               .ck_n    (CLK_N[(i*MEMORY_WIDTH)/72]),
               .cke     (CKE[((i*MEMORY_WIDTH)/72)+(nCS_PER_RANK*r)]),
               .cs_n    (CS_N[((i*MEMORY_WIDTH)/72)+(nCS_PER_RANK*r)]),
               .ras_n   (RAS_N),
               .cas_n   (CAS_N),
               .we_n    (WE_N),
               .dm_tdqs (DM[i]),
               .ba      (BA),
               .addr    (ADDR),
               .dq      (DQ[MEMORY_WIDTH*(i+1)-1:MEMORY_WIDTH*(i)]),
               .dqs     (DQS_P[i]),
               .dqs_n   (DQS_N[i]),
               .tdqs_n  (),
               .odt     (ODT[((i*MEMORY_WIDTH)/72)+(nCS_PER_RANK*r)])
               );
          end // block: gen_mem
	end // block: mem_8_4
      end // block: mem_rnk
  endgenerate

endmodule // xilinx_ddr3_sodimm

     
