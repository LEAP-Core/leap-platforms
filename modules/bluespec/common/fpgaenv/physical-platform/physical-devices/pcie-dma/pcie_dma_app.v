////////////////////////////////////////////////////////////////////////////////
// Filename      : pcie_dma_app.v
// Brief         : DMA logic driving Xilinx ip core for PCIe
// Author        : rfadeev
// Mail to       : roman.fadeev@intel.com
//
// Copyright (C) 2011 Intel Corporation
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

`define PCI_EXP_EP_OUI                           24'h000A35
`define PCI_EXP_EP_DSN_1                         {{8'h1},`PCI_EXP_EP_OUI}
`define PCI_EXP_EP_DSN_2                         32'h00000001

`define HOST_MWR_MAX_PAYLOAD                     10'd32 //Maximum length for write requests from FPGA in DWords.
`define HOST_MWR_ADDR32_INC                      32'h80 //Address increment in sequential 32-bit addressing write requests from FPGA.

`define FPGA_MAX_MRD_SIZE                        10'd32 //Maximum length for read request from FPGA in DWords.
`define HOST_MRD_ADDR32_INC                      32'h80 //Address increment in sequential 32-bit addressing read requests from FPGA.

module pcie_dma_app
(
    // Bluespec interface
    input                 model_clk,
    input                 model_rst_n,

    input                 EN_read,
    output                RDY_read,
    output [ 63 : 0 ]     DATA_read,

    input                 EN_write,
    output                RDY_write,
    input  [ 63 : 0 ]     DATA_write,

    output                SOFT_reset,

    // Common Transaction Interface
    input                 trn_clk,
    input                 trn_reset_n,
    input                 trn_lnk_up_n,

    // Common Transaction Interface: Flow Control Interface
    input  [  7 : 0 ]     trn_fc_ph,
    input  [ 11 : 0 ]     trn_fc_pd,
    input  [  7 : 0 ]     trn_fc_nph,
    input  [ 11 : 0 ]     trn_fc_npd,
    input  [  7 : 0 ]     trn_fc_cplh,
    input  [ 11 : 0 ]     trn_fc_cpld,
    output [  2 : 0 ]     trn_fc_sel,

    // Transaction Transmit Interface
    output reg            trn_tsof_n,
    output reg            trn_teof_n,
    output reg [ 63 : 0 ] trn_td,
    output reg            trn_trem_n,
    output reg            trn_tsrc_rdy_n,
    input                 trn_tdst_rdy_n,
    output                trn_tsrc_dsc_n,
    input  [  5 : 0 ]     trn_tbuf_av,
    input                 trn_terr_drop_n,
    output                trn_tstr_n,
    input                 trn_tcfg_req_n,
    output                trn_tcfg_gnt_n,
    output                trn_terrfwd_n,

    // Transaction Receive Interface
    input                 trn_rsof_n_i,
    input                 trn_reof_n_i,
    input  [ 63 : 0 ]     trn_rd_i,
    input                 trn_rrem_n_i,
    input                 trn_rerrfwd_n_i,
    input                 trn_rsrc_rdy_n_i,
    output                trn_rdst_rdy_n,
    input                 trn_rsrc_dsc_n_i,
    output                trn_rnp_ok_n,
    input  [  6 : 0 ]     trn_rbar_hit_n_i,

    // Physical Layer Interface
    input  [  2 : 0 ]     pl_initial_link_width,
    input  [  1 : 0 ]     pl_lane_reversal_mode,
    input                 pl_link_gen2_capable,
    input                 pl_link_partner_gen2_supported,
    input                 pl_link_upcfg_capable,
    input                 pl_sel_link_rate,
    input  [  1 : 0 ]     pl_sel_link_width,
    input  [  5 : 0 ]     pl_ltssm_state,
    output                pl_directed_link_auton,
    output [  1 : 0 ]     pl_directed_link_change,
    output [  1 : 0 ]     pl_directed_link_width,
    output                pl_directed_link_speed,
    output                pl_upstream_prefer_deemph,
    input                 pl_received_hot_rst,

    // Configuration Interface
    input  [ 31 : 0 ]     cfg_do,
    input                 cfg_rd_wr_done_n,
    output [ 31 : 0 ]     cfg_di,
    output [  9 : 0 ]     cfg_dwaddr,
    output [  3 : 0 ]     cfg_byte_en_n,
    output                cfg_wr_en_n,
    output                cfg_rd_en_n,
    input  [ 15 : 0 ]     cfg_status,
    input  [ 15 : 0 ]     cfg_command,
    input  [ 15 : 0 ]     cfg_dstatus,
    input  [ 15 : 0 ]     cfg_dcommand,
    input  [ 15 : 0 ]     cfg_dcommand2,
    input  [ 15 : 0 ]     cfg_lstatus,
    input  [ 15 : 0 ]     cfg_lcommand,
    input  [  2 : 0 ]     cfg_pcie_link_state_n,
    output                cfg_trn_pending_n,
    output [ 63 : 0 ]     cfg_dsn,
    input  [  7 : 0 ]     cfg_bus_number,
    input  [  4 : 0 ]     cfg_device_number,
    input  [  2 : 0 ]     cfg_function_number,
    input                 cfg_to_turnoff_n,
    output                cfg_turnoff_ok_n,
    output                cfg_pm_wake_n,

    // Configuration Interface: Interrupt Interface
    output                cfg_interrupt_n,
    input                 cfg_interrupt_rdy_n,
    output                cfg_interrupt_assert_n,
    output [  7 : 0 ]     cfg_interrupt_di,
    input  [  7 : 0 ]     cfg_interrupt_do,
    input  [  2 : 0 ]     cfg_interrupt_mmenable,
    input                 cfg_interrupt_msienable,
    input                 cfg_interrupt_msixenable,
    input                 cfg_interrupt_msixfm,

    // Configuration Interface: User Application Error-Reporting Interface
    output                cfg_err_ecrc_n,
    output                cfg_err_ur_n,
    output                cfg_err_cpl_timeout_n,
    output                cfg_err_cpl_unexpect_n,
    output                cfg_err_cpl_abort_n,
    output                cfg_err_posted_n,
    output                cfg_err_cor_n,
    output [ 47 : 0 ]     cfg_err_tlp_cpl_header,
    input                 cfg_err_cpl_rdy_n,
    output                cfg_err_locked_n

);

////////////////////////////////////////////////////////////////////////////////
// Transaction Receive Interface outputs of pcie core are triggered to avoid timing violations of design.
// Probably it's not the best solution, but there is no other for now.
////////////////////////////////////////////////////////////////////////////////

reg            trn_rsof_n;
reg            trn_reof_n;
reg [ 63 : 0 ] trn_rd;
reg            trn_rrem_n;
reg            trn_rerrfwd_n;
reg            trn_rsrc_rdy_n;
reg            trn_rsrc_dsc_n;
reg [  6 : 0 ] trn_rbar_hit_n;

always @ (posedge trn_clk)
    if (!trn_reset_n) { trn_rsof_n, trn_reof_n, trn_rd, trn_rrem_n, trn_rerrfwd_n, trn_rsrc_rdy_n, trn_rsrc_dsc_n, trn_rbar_hit_n    } <= { 2'b11, 64'b0, 4'b1111, 7'b1111111 };
    else { trn_rsof_n,   trn_reof_n,   trn_rd,   trn_rrem_n,   trn_rerrfwd_n,   trn_rsrc_rdy_n,   trn_rsrc_dsc_n,   trn_rbar_hit_n   } <=
         { trn_rsof_n_i, trn_reof_n_i, trn_rd_i, trn_rrem_n_i, trn_rerrfwd_n_i, trn_rsrc_rdy_n_i, trn_rsrc_dsc_n_i, trn_rbar_hit_n_i };

////////////////////////////////////////////////////////////////////////////////
// Tie off inputs of pcie core.
////////////////////////////////////////////////////////////////////////////////

// Common Transaction Interface: Flow Control Interface
assign trn_fc_sel                = 3'b0;

// Transaction Transmit Interface
assign trn_tsrc_dsc_n            = 1'b1;
assign trn_tstr_n                = 1'b0;
assign trn_tcfg_gnt_n            = 1'b0;
assign trn_terrfwd_n             = 1'b1;

// Transaction Receive Interface
assign trn_rdst_rdy_n            = 1'b0;
assign trn_rnp_ok_n              = 1'b0;

// Physical Layer Interface
assign pl_directed_link_auton    = 1'b0;
assign pl_directed_link_change   = 1'b0;
assign pl_directed_link_speed    = 1'b0;
assign pl_directed_link_width    = 2'b11;
assign pl_upstream_prefer_deemph = 1'b1;

// Configuration Interface
assign cfg_di                    = 32'b0;
assign cfg_dwaddr                = 10'b0;
assign cfg_byte_en_n             = 4'hf;
assign cfg_wr_en_n               = 1'b1;
assign cfg_rd_en_n               = 1'b1;
assign cfg_trn_pending_n         = 1'b1;
assign cfg_dsn                   = {`PCI_EXP_EP_DSN_2, `PCI_EXP_EP_DSN_1};
assign cfg_turnoff_ok_n          = 1'b1;
assign cfg_pm_wake_n             = 1'b1;

// Configuration Interface: Interrupt Interface
assign cfg_interrupt_n           = 1'b1;
assign cfg_interrupt_assert_n    = 1'b1;
assign cfg_interrupt_di          = 8'b0;

// Configuration Interface: User Application Error-Reporting Interface
assign cfg_err_ecrc_n            = 1'b1;
assign cfg_err_ur_n              = 1'b1;
assign cfg_err_cpl_timeout_n     = 1'b1;
assign cfg_err_cpl_unexpect_n    = 1'b1;
assign cfg_err_cpl_abort_n       = 1'b1;
assign cfg_err_posted_n          = 1'b0;
assign cfg_err_cor_n             = 1'b1;
assign cfg_err_tlp_cpl_header    = 47'h0;
assign cfg_err_locked_n          = 1'b1;

////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////
//Logic of DMA machine
////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// Fifos to save received data from pcie core and from model.
////////////////////////////////////////////////////////////////////////////////

//Host to FPGA fifo
wire [ 63 : 0 ] fifoH2F_sD_IN;
wire            fifoH2F_sENQ;
wire            fifoH2F_dDEQ;
wire [ 63 : 0 ] fifoH2F_dD_OUT;
wire            fifoH2F_sFULL_N;
wire            fifoH2F_dEMPTY_N;
wire [  9 : 0 ] fifoH2F_sCOUNT;
wire            fifoH2F_sFULL;
wire            fifoH2F_dEMPTY;

assign fifoH2F_sFULL_N  = !fifoH2F_sFULL;
assign fifoH2F_dEMPTY_N = !fifoH2F_dEMPTY;

Xilinx_SyncFIFOLevel_512x64 fifoH2F
(
    .wr_clk(trn_clk),
    .wr_rst(~trn_reset_n || SOFT_reset),
    .rd_clk(model_clk),
    .rd_rst(~trn_reset_n || SOFT_reset),
    .din(fifoH2F_sD_IN),
    .wr_en(fifoH2F_sENQ),
    .rd_en(fifoH2F_dDEQ),
    .dout(fifoH2F_dD_OUT),
    .full(fifoH2F_sFULL),
    .empty(fifoH2F_dEMPTY),
    .rd_data_count(),
    .wr_data_count(fifoH2F_sCOUNT)
);

wire [  9 : 0 ] fifoH2F_empty_slots;
wire [ 10 : 0 ] fifoH2F_empty_DW_count;

assign fifoH2F_empty_slots    = 10'd512 - fifoH2F_sCOUNT;
assign fifoH2F_empty_DW_count = fifoH2F_empty_slots << 1;

//FPGA to Host fifo
wire [ 63 : 0 ] fifoF2H_sD_IN;
wire            fifoF2H_sENQ;
wire            fifoF2H_dDEQ;
wire [ 63 : 0 ] fifoF2H_dD_OUT;
wire            fifoF2H_sFULL_N;
wire            fifoF2H_dEMPTY_N;
wire [  9 : 0 ] fifoF2H_dCOUNT;
wire            fifoF2H_sFULL;
wire            fifoF2H_dEMPTY;

assign fifoF2H_sFULL_N  = !fifoF2H_sFULL;
assign fifoF2H_dEMPTY_N = !fifoF2H_dEMPTY;

Xilinx_SyncFIFOLevel_512x64 fifoF2H
(
    .wr_clk(model_clk),
    .wr_rst(~trn_reset_n || SOFT_reset),
    .rd_clk(trn_clk),
    .rd_rst(~trn_reset_n || SOFT_reset),
    .din(fifoF2H_sD_IN),
    .wr_en(fifoF2H_sENQ),
    .rd_en(fifoF2H_dDEQ),
    .dout(fifoF2H_dD_OUT),
    .full(fifoF2H_sFULL),
    .empty(fifoF2H_dEMPTY),
    .rd_data_count(fifoF2H_dCOUNT),
    .wr_data_count()
);

wire [ 10 : 0 ] fifoF2H_DW_count;
assign fifoF2H_DW_count = fifoF2H_dCOUNT << 1;

wire [ 63 : 0 ] rbo_fifoF2H_dD_OUT;
assign rbo_fifoF2H_dD_OUT = { fifoF2H_dD_OUT [ 7 : 0 ],   fifoF2H_dD_OUT [ 15 : 8 ],  fifoF2H_dD_OUT [ 23 : 16 ], fifoF2H_dD_OUT [ 31 : 24 ],
                              fifoF2H_dD_OUT [ 39 : 32 ], fifoF2H_dD_OUT [ 47 : 40 ], fifoF2H_dD_OUT [ 55 : 48 ], fifoF2H_dD_OUT [ 63 : 56 ] };

//Save entry from fifoF2H with reversed byte order
reg [ 63 : 0 ] rbo_fifoF2H_entry;
always @ (posedge trn_clk)
    if (!trn_reset_n) rbo_fifoF2H_entry <= 64'b0;
    else rbo_fifoF2H_entry <= rbo_fifoF2H_dD_OUT;

////////////////////////////////////////////////////////////////////
//State machine to recieve PIO data
////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////
//Recieved header parameters
////////////////////////////////////////////////////////////////////
reg [ 15 : 0 ] fpga_id;
always @ (posedge trn_clk)
    if (!trn_reset_n) fpga_id <= 16'b0;
    else fpga_id <= { cfg_bus_number, cfg_device_number, cfg_function_number };

reg [ 63 : 0 ] rd_header;
always @ (posedge trn_clk)
    if (!trn_reset_n) rd_header <= 64'b0;
    else if (!trn_rsof_n) rd_header <= trn_rd;

wire nd_3dw;
wire wd_3dw;
wire nd_4dw;
wire wd_4dw;

assign nd_3dw = (rd_header [ 63 : 61 ] == 3'b000);
assign nd_4dw = (rd_header [ 63 : 61 ] == 3'b001);
assign wd_3dw = (rd_header [ 63 : 61 ] == 3'b010);
assign wd_4dw = (rd_header [ 63 : 61 ] == 3'b011);

wire mwr32;
wire mwr64;
wire mrd32;
wire mrd64;
wire cpld;

assign mwr32 = (rd_header [ 63 : 56 ] == 8'h40);
assign mwr64 = (rd_header [ 63 : 56 ] == 8'h60);
assign mrd32 = (rd_header [ 63 : 56 ] == 8'h00);
assign mrd64 = (rd_header [ 63 : 56 ] == 8'h20);
assign cpld  = (rd_header [ 63 : 56 ] == 8'h4A);

wire [  9 : 0 ] length;
wire [ 15 : 0 ] req_id;
wire [  7 : 0 ] req_tag;

assign length  = rd_header [ 41 : 32 ];
assign req_id  = rd_header [ 31 : 16 ];
assign req_tag = rd_header [ 15 : 8  ];

wire bar0_hit;
wire bar1_hit;

assign bar0_hit = (trn_rbar_hit_n [ 1 : 0 ] == 2'b10);
assign bar1_hit = (trn_rbar_hit_n [ 1 : 0 ] == 2'b01);

wire [ 31 : 0 ] trn_rd_low;
wire [ 31 : 0 ] trn_rd_high;

assign trn_rd_low  = trn_rd [ 31 : 0  ];
assign trn_rd_high = trn_rd [ 63 : 32 ];

wire [ 31 : 0 ] rbo_trn_rd_low;
wire [ 31 : 0 ] rbo_trn_rd_high;

assign rbo_trn_rd_low  = { trn_rd_low  [ 7 : 0 ], trn_rd_low  [ 15 : 8 ], trn_rd_low  [ 23 : 16 ], trn_rd_low  [ 31 : 24 ]};
assign rbo_trn_rd_high = { trn_rd_high [ 7 : 0 ], trn_rd_high [ 15 : 8 ], trn_rd_high [ 23 : 16 ], trn_rd_high [ 31 : 24 ]};

//this register indicates, that current TLP is first after RX start of frame
reg fasof;
always @ (posedge trn_clk)
    if (!trn_reset_n) fasof <= 1'b0;
    else if (!trn_rsof_n) fasof <= 1'b1;
    else fasof <= 1'b0;

// Write strobe for high bits of H->F 2DW write request
reg dbg_mwr_addr_wr;
reg dbg_mrd_addr_wr;

always @ (posedge trn_clk)
    if (!trn_reset_n) { dbg_mwr_addr_wr, dbg_mrd_addr_wr } <= 2'b0;
    else if (bar0_hit && fasof && wd_3dw)
        case (trn_rd [ 39 : 34 ])
            6'b010010 : dbg_mwr_addr_wr <= 1'b1;
            6'b010100 : dbg_mrd_addr_wr <= 1'b1;
        endcase
    else { dbg_mwr_addr_wr, dbg_mrd_addr_wr } <= 2'b0;

//BAR0 read only regs
reg [ 31 : 0 ] vers;
reg [ 31 : 0 ] fifosz;

wire [ 31 : 0 ] rbo_vers;
wire [ 31 : 0 ] rbo_fifosz;

assign rbo_vers   = { vers   [ 7 : 0 ], vers   [ 15 : 8 ], vers   [ 23 : 16 ], vers   [ 31 : 24 ]};
assign rbo_fifosz = { fifosz [ 7 : 0 ], fifosz [ 15 : 8 ], fifosz [ 23 : 16 ], fifosz [ 31 : 24 ]};

// BAR0 write only regs
// Important: address registers for memory write/read requests from FPGA are 64-bit wide,
// however software side guarantees, that 32 high bits of these registers will be always zero.
// So, FPGA will always send 32-bit addressing memory write/read requests.
reg [ 31 : 0 ] ctrl;
reg [ 31 : 0 ] dbg_mwr_len;
reg [ 31 : 0 ] dbg_mrd_len;
reg [ 63 : 0 ] dbg_mwr_addr;
reg [ 63 : 0 ] dbg_mrd_addr;

always @ (posedge trn_clk)
    if (!trn_reset_n) vers <= 32'hDDDDDDD1;

// Current version of DMA logic doesn't support write/read lenght greater than 512 QWords.
// Since the actual depth of Xilinx Coregen fifo is 513 and ViCo driver issues requests according to fifosz register this hack is implemented.
// So on software side number of filled entries in FPGA to host fifo will always be less or equal to 512.
always @ (posedge trn_clk)
    if (!trn_reset_n) fifosz <= 32'h00000200;
    else if (fifoF2H_dCOUNT == 10'd513) fifosz <= { 6'b0, 10'd512, 6'b0, fifoH2F_empty_slots };
    else fifosz <= { 6'b0, fifoF2H_dCOUNT, 6'b0, fifoH2F_empty_slots };

wire mwr_start;
wire mrd_start;

//BAR0 H->F 1DW payload write request handler
always @ (posedge trn_clk)
    if (!trn_reset_n) { ctrl, dbg_mwr_len, dbg_mrd_len } <= {3{32'b0}};
    else if (bar0_hit && !trn_reof_n && wd_3dw && (length == 10'h1)) begin
        $display("PCIe dma device : Recieved BAR0 1DW write request with address = 8'h%h", trn_rd [ 39 : 32 ]);
        case (trn_rd [ 39 : 34 ])
            6'b000100 : ctrl        <= rbo_trn_rd_low;
            6'b001110 : dbg_mwr_len <= rbo_trn_rd_low;
            6'b010000 : dbg_mrd_len <= rbo_trn_rd_low;
        endcase
    end
    else if (bar1_hit && !trn_reof_n && wd_3dw) $display("PCIe dma device : Recieved BAR1 write request with data = 32'h%h", trn_rd [ 31 : 0 ]);
    else if (mwr_start) ctrl [1] <= 1'b0;
    else if (mrd_start) ctrl [2] <= 1'b0;

//BAR0 H->F 2DW payload write request handler
always @ (posedge trn_clk)
    if (!trn_reset_n) { dbg_mwr_addr, dbg_mrd_addr } <= { 64'h0, 64'h0 };
    else if (bar0_hit && fasof && wd_3dw && (length == 10'h2)) begin //capture data between sof and eof
        $display("PCIe dma device : Recieved BAR0 2DW write request with address = 8'h%h", trn_rd [ 39 : 32 ]);
        case (trn_rd [ 39 : 34 ])
            6'b010010 : dbg_mwr_addr [ 31 : 0 ] <= rbo_trn_rd_low;
            6'b010100 : dbg_mrd_addr [ 31 : 0 ] <= rbo_trn_rd_low;
        endcase
    end
    else if (bar0_hit && !trn_reof_n && wd_3dw && dbg_mwr_addr_wr) dbg_mwr_addr [ 63 : 32  ] <= rbo_trn_rd_high;
    else if (bar0_hit && !trn_reof_n && wd_3dw && dbg_mrd_addr_wr) dbg_mrd_addr [ 63 : 32  ] <= rbo_trn_rd_high;

//In this register we save payload between rsof and reof to enqueue it into H2F fifo then
reg [ 31 : 0 ] fifoH2F_lo_reg;
always @ (posedge trn_clk)
    if (!trn_reset_n) fifoH2F_lo_reg <= 32'h00000000;
    else if (bar1_hit && fasof && wd_3dw && (length == 10'h2)) fifoH2F_lo_reg <= rbo_trn_rd_low;
    else fifoH2F_lo_reg <= 32'h00000000;

//BAR0 H->F read request handler
reg [ 5 : 0 ] bar0_rd_addr;
always @ (posedge trn_clk)
    if (!trn_reset_n) bar0_rd_addr <= 6'b0;
    else if (bar0_hit && !trn_reof_n && nd_3dw) begin
        bar0_rd_addr <= trn_rd [ 39 : 34 ];
        $display("PCIe dma device : Recieved BAR0 read request with address = 8'h%h", trn_rd [ 39 : 32 ]);
    end

////////////////////////////////////////////////////////////////////
//FSM to monitor TRN RX interface
////////////////////////////////////////////////////////////////////
localparam PIO_IDLE          = 5'd00;
localparam PIO_BAR0_CPLD_SOF = 5'd01;
localparam PIO_BAR0_CPLD_EOF = 5'd02;
localparam PIO_BAR1_CPLD_SOF = 5'd03;
localparam PIO_BAR1_CPLD_QW2 = 5'd04;
localparam PIO_BAR1_CPLD_EOF = 5'd05;
localparam DMA_F2H_MWR32_SOF = 5'd06;
localparam DMA_F2H_MWR32_ADR = 5'd07;
localparam DMA_F2H_MWR32_EOF = 5'd08;
localparam DMA_F2H_MRD32_SOF = 5'd09;
localparam DMA_F2H_MRD32_EOF = 5'd10;

reg [  9 : 0 ] mwr_len;
reg [  9 : 0 ] mrd_len;
reg [  9 : 0 ] mwr_len_rem;  //Number of remaining dwords for current FPGA to host write burst
reg [  9 : 0 ] mrd_len_rem;  //Number of remaining dwords for current FPGA to host read burst
reg [  9 : 0 ] cpld_len_rem; //Number of remaining dwords recieved from host
reg [ 31 : 0 ] mwr_addr;
reg [ 31 : 0 ] mrd_addr;
reg [  4 : 0 ] pio_state;

reg bar0_read;
reg dma_wr_stream;
reg dma_rd_stream;

reg mrd_done;
reg mrd_sent;
reg mwr_sent;

assign mwr_start = (pio_state == DMA_F2H_MWR32_SOF);
assign mrd_start = (pio_state == DMA_F2H_MRD32_SOF);

// According to PCIe Base Specification, Rev. 2.1, requests must not specify an Adress/Length combination, which causes a Memory space
// access to cross a 4-KB boundary. That's why write/read request crossing 4-KB boundary should be detected, splitted and aligned accordingly.
// For example, if current mwr_addr during DMA burst is  64'h0000000000041F88 and mwr_len_rem is more or equal to `HOST_MWR_MAX_PAYLOAD,
// DMA engine sends memory write request with address 32'b00041F88 and length (13'h1000 - 12'hF88) >> 2 = 10'h1E, less than max payload.
// Next memory write request will be with address 32'b00042000. Read requests are handled in the same way.

wire [ 12 : 0 ] mwr_addr_shift;
wire            mwr_cross_4kb_bound;
wire [  9 : 0 ] mwr_cross_4kb_len;

assign mwr_addr_shift      = ((mwr_len_rem != 10'b0) && (mwr_len_rem < 10'd32)) ? mwr_addr [ 11 : 0 ] + (mwr_len_rem << 2) - 12'b1 : mwr_addr [ 11 : 0 ] + `HOST_MWR_ADDR32_INC - 12'b1;
assign mwr_cross_4kb_bound = mwr_addr_shift [12];
assign mwr_cross_4kb_len   = (13'h1000 - mwr_addr [ 11 : 0 ]) >> 2;

wire [ 12 : 0 ] mrd_addr_shift;
wire            mrd_cross_4kb_bound;
wire [  9 : 0 ] mrd_cross_4kb_len;

assign mrd_addr_shift      = ((mrd_len_rem != 10'b0) && (mrd_len_rem < 10'd32)) ? mrd_addr [ 11 : 0 ] + (mrd_len_rem << 2) - 12'b1 : mrd_addr [ 11 : 0 ] + `HOST_MRD_ADDR32_INC - 12'b1;
assign mrd_cross_4kb_bound = mrd_addr_shift [12];
assign mrd_cross_4kb_len   = (13'h1000 - mrd_addr [ 11 : 0 ]) >> 2;

always @ (posedge trn_clk)
    if (!trn_reset_n) begin
        trn_td         <= 64'b0;
        trn_tsof_n     <= 1'b1;
        trn_teof_n     <= 1'b1;
        trn_tsrc_rdy_n <= 1'b1;
        trn_trem_n     <= 1'b0;

        mwr_len        <= 10'd0;
        mrd_len        <= 10'd0;
        mwr_len_rem    <= 10'd0;
        mrd_len_rem    <= 10'b0;
        mwr_addr       <= 32'h0;
        mrd_addr       <= 32'h0;

        dma_wr_stream  <= 1'b0;
        dma_rd_stream  <= 1'b0;

        pio_state      <= PIO_IDLE;
    end
    else
        case (pio_state)

        PIO_IDLE          : begin
            trn_tsof_n     <= 1'b1;
            trn_teof_n     <= 1'b1;
            trn_tsrc_rdy_n <= 1'b1;
            trn_trem_n     <= 1'b0;
            trn_td         <= 64'h0;

            if ((bar0_hit && !trn_rsof_n && (trn_rd [ 63 : 61 ] == 3'b000)) || bar0_read) begin
                pio_state <= PIO_BAR0_CPLD_SOF;
                $display("PCIe dma device : Recieved BAR0 read request");
            end
            else if (bar1_hit && !trn_rsof_n && (trn_rd [ 63 : 61 ] == 3'b000) && fifoF2H_dEMPTY_N) begin
                pio_state <= PIO_BAR1_CPLD_SOF;
                $display("PCIe dma device : Recieved BAR1 read request");
            end
            else if (ctrl[1] && (dbg_mwr_len <= fifoF2H_DW_count)) begin
                $display("PCIe dma device : DMA : Beginning F->H DMA MWR32 process");
                pio_state <= DMA_F2H_MWR32_SOF;
            end
            else if (ctrl[2]) begin
                $display("PCIe dma device : DMA : Beginning F->H DMA MRD32 process");
                pio_state <= DMA_F2H_MRD32_SOF;
            end

            mwr_len_rem    <= dbg_mwr_len [ 9 : 0 ];
            mrd_len_rem    <= dbg_mrd_len [ 9 : 0 ];
            mwr_addr       <= dbg_mwr_addr [ 31 : 0 ];
            mrd_addr       <= dbg_mrd_addr [ 31 : 0 ];
        end

        PIO_BAR0_CPLD_SOF : begin
            if (!trn_tdst_rdy_n) begin
                trn_tsof_n     <= 1'b0;
                trn_teof_n     <= 1'b1;
                trn_tsrc_rdy_n <= 1'b0;
                trn_trem_n     <= 1'b0;
                trn_td         <= { 32'h4A000001, fpga_id, 16'h0004 };
                $display("PCIe dma device : SOF : Sending CplD to BAR0 read request = 64'h4A000001_01A00004");
                pio_state      <= PIO_BAR0_CPLD_EOF;
            end
        end

        PIO_BAR0_CPLD_EOF : begin
            if (!trn_tdst_rdy_n) begin
                trn_tsof_n     <= 1'b1;
                trn_teof_n     <= 1'b0;
                trn_tsrc_rdy_n <= 1'b0;
                trn_trem_n     <= 1'b0;
                case (bar0_rd_addr)
                    6'b000000 : trn_td <= { req_id, req_tag, 8'h10, rbo_vers };
                    6'b000010 : trn_td <= { req_id, req_tag, 8'h10, rbo_fifosz };
                    6'b010110 : trn_td <= { req_id, req_tag, 8'h10, 5'b0, mrd_done, mrd_sent, mwr_sent, 24'b0 };
                endcase
                $display("PCIe dma device : EOF : Sending CplD to BAR0 read request to address 8'h%h", bar0_rd_addr);
                if (dma_wr_stream) pio_state <= DMA_F2H_MWR32_SOF;
                else if (dma_rd_stream) pio_state <= DMA_F2H_MRD32_SOF;
                else pio_state <= PIO_IDLE;
           end
        end

        PIO_BAR1_CPLD_SOF : begin
            trn_tsof_n     <= 1'b0;
            trn_teof_n     <= 1'b1;
            trn_tsrc_rdy_n <= 1'b0;
            trn_trem_n     <= 1'b0;
            trn_td         <= { 32'h4A000002, fpga_id, 16'h0008 };
            $display("PCIe dma device : SOF : Sending CplD to BAR1 read request = 64'h4A000002_01A00008");
            pio_state      <= PIO_BAR1_CPLD_QW2;
        end

        PIO_BAR1_CPLD_QW2 : begin
            trn_tsof_n     <= 1'b1;
            trn_teof_n     <= 1'b1;
            trn_tsrc_rdy_n <= 1'b0;
            trn_trem_n     <= 1'b0;
            trn_td         <= { req_id, req_tag, 8'h10, rbo_fifoF2H_dD_OUT [ 63 : 32 ] };
            $display("PCIe dma device : Between SOF & EOF : Sending CplD to BAR1 read request = 64'h%h", { req_id, req_tag, 8'h10, rbo_fifoF2H_dD_OUT [ 63 : 32 ] });
            pio_state      <= PIO_BAR1_CPLD_EOF;
        end

        PIO_BAR1_CPLD_EOF : begin
            trn_tsof_n     <= 1'b1;
            trn_teof_n     <= 1'b0;
            trn_tsrc_rdy_n <= 1'b0;
            trn_trem_n     <= 1'b1;
            trn_td         <= { rbo_fifoF2H_dD_OUT [ 31 : 0 ], 32'h0 };
            $display("PCIe dma device : EOF : Sending CplD to BAR1 read request = 32'h%h", rbo_fifoF2H_dD_OUT [ 31 : 0 ]);
            pio_state      <= PIO_IDLE;
        end

        DMA_F2H_MWR32_SOF : begin
            if (!trn_tdst_rdy_n) begin
                trn_tsof_n     <= 1'b0;
                trn_teof_n     <= 1'b1;
                trn_tsrc_rdy_n <= 1'b0;
                trn_trem_n     <= 1'b0;

                if (mwr_cross_4kb_bound) begin
                    trn_td  <= { 16'h4000, 6'b0, mwr_cross_4kb_len, 32'h01A000FF };
                    mwr_len <= mwr_cross_4kb_len;
                    $display("PCIe dma device : DMA : SOF : Sending write request at 4Kb boundary cross with length = %d", mwr_cross_4kb_len);
                end
                else if ((mwr_len_rem >= `HOST_MWR_MAX_PAYLOAD) || (mwr_len_rem == 10'b0)) begin
                    trn_td  <= { 16'h4000, 6'b0, `HOST_MWR_MAX_PAYLOAD, 32'h01A000FF };
                    mwr_len <= `HOST_MWR_MAX_PAYLOAD;
                    $display("PCIe dma device : DMA : SOF : Sending write request with length = %d",`HOST_MWR_MAX_PAYLOAD);
                end
                else begin
                    trn_td  <= { 16'h4000, 6'b0, mwr_len_rem, 32'h01A000FF };
                    mwr_len <= mwr_len_rem;
                    $display("PCIe dma device : DMA : SOF : Sending write request with length = %d", mwr_len_rem);
                end

                dma_wr_stream  <= 1'b1;
                pio_state      <= DMA_F2H_MWR32_ADR;
            end
        end

        DMA_F2H_MWR32_ADR : begin
            if (!trn_tdst_rdy_n) begin
                trn_tsof_n     <= 1'b1;
                trn_teof_n     <= 1'b1;
                trn_tsrc_rdy_n <= 1'b0;
                trn_td         <= { mwr_addr, rbo_fifoF2H_dD_OUT [ 63 : 32 ] };
                mwr_addr       <= mwr_addr + (mwr_len << 2);
                mwr_len        <= mwr_len - 10'd1;
                mwr_len_rem    <= mwr_len_rem  - mwr_len;
                $display("PCIe dma device : DMA : First after SOF : Sending write request with address = 32'h%h, payload = 32'h%h", mwr_addr, rbo_fifoF2H_dD_OUT [ 63 : 32 ] );
                pio_state      <= DMA_F2H_MWR32_EOF;
            end
        end

        DMA_F2H_MWR32_EOF : begin
            if (!trn_tdst_rdy_n) begin
                trn_tsof_n     <= 1'b1;
                trn_tsrc_rdy_n <= 1'b0;
                trn_td         <= { rbo_fifoF2H_entry [ 31 : 0 ], rbo_fifoF2H_dD_OUT [ 63 : 32 ] }; 

                if (mwr_len == 10'd1) begin
                    trn_teof_n <= 1'b0;
                    trn_trem_n <= 1'b1;
                    mwr_len    <= mwr_len - 10'd1;
                    $display("PCIe dma device : DMA : EOF : Sending write request with payload = 64'h%h", { rbo_fifoF2H_entry [ 31 : 0 ], rbo_fifoF2H_dD_OUT [ 63 : 32 ] });
                    if (mwr_len_rem == 10'b0) begin
                        pio_state     <= PIO_IDLE;
                        dma_wr_stream <= 1'b0;
                    end
                    else if (bar0_read) pio_state <= PIO_BAR0_CPLD_SOF;
                    else pio_state <= DMA_F2H_MWR32_SOF;
                end
                else begin
                    mwr_len <= mwr_len - 10'd2;
                    $display("PCIe dma device : DMA : Between SOF & EOF : Sending write request with payload = 64'h%h", { rbo_fifoF2H_entry [ 31 : 0 ], rbo_fifoF2H_dD_OUT [ 63 : 32 ] });
                end
            end
        end

        DMA_F2H_MRD32_SOF : begin
            if (!trn_tdst_rdy_n) begin
                trn_tsof_n     <= 1'b0;
                trn_teof_n     <= 1'b1;
                trn_tsrc_rdy_n <= 1'b0;

                if (mrd_cross_4kb_bound) begin
                    trn_td  <= { 16'h0000, 6'b0, mrd_cross_4kb_len, fpga_id, 16'h00FF };
                    mrd_len <= mrd_cross_4kb_len;
                    $display("PCIe dma device : DMA : SOF : Sending read request at 4Kb boundary cross with length = %d", mrd_cross_4kb_len);
                end
                else if ((mrd_len_rem >= `FPGA_MAX_MRD_SIZE) || (mrd_len_rem == 10'b0)) begin
                    trn_td  <= { 16'h0000, 6'b0, `FPGA_MAX_MRD_SIZE, fpga_id, 16'h00FF };
                    mrd_len <= `FPGA_MAX_MRD_SIZE;
                    $display("PCIe dma device : DMA : SOF : Sending 32-bit addressing read request with length = %d", `FPGA_MAX_MRD_SIZE);
                end
                else begin
                    trn_td  <= { 16'h0000, 6'b0, mrd_len_rem, fpga_id, 16'h00FF };
                    mrd_len <= mrd_len_rem;
                    $display("PCIe dma device : DMA : SOF : Sending 32-bit addressing read request with length = %d", mrd_len_rem);
                end

                dma_rd_stream  <= 1'b1;
                pio_state      <= DMA_F2H_MRD32_EOF;
            end
        end

        DMA_F2H_MRD32_EOF : begin
            if (!trn_tdst_rdy_n) begin
                trn_tsof_n     <= 1'b1;
                trn_teof_n     <= 1'b0;
                trn_tsrc_rdy_n <= 1'b0;
                trn_trem_n     <= 1'b1;
                trn_td         <= { mrd_addr, 32'b0 };
                mrd_addr       <= mrd_addr + (mrd_len << 2);
                mrd_len_rem    <= mrd_len_rem - mrd_len;
                $display("PCIe dma device : DMA : EOF : Sending 32-bit addressing read request with address = 32'h%h", mrd_addr);

                if (mrd_len_rem == mrd_len) begin
                    pio_state     <= PIO_IDLE;
                    dma_rd_stream <= 1'b0;
                end
                else if (bar0_read) pio_state <= PIO_BAR0_CPLD_SOF;
                else pio_state <= DMA_F2H_MRD32_SOF;
            end
        end

        endcase

////////////////////////////////////////////////////////////////////
//FSM to monitor TRN RX interface
////////////////////////////////////////////////////////////////////

localparam DMA_H2F_IDLE     = 4'd0;
localparam DMA_H2F_CPLD_SOF = 4'd1;
localparam DMA_H2F_CPLD_QW2 = 4'd2;
localparam DMA_H2F_CPLD_EOF = 4'd3;

reg [ 31 : 0 ] h2f_cpld_hi;
reg [  3 : 0 ] dma_h2f_state;
reg [  9 : 0 ] cpld_len;
reg [  7 : 0 ] cpld_tag;

always @ (posedge trn_clk)
    if (!trn_reset_n) begin
        h2f_cpld_hi   <= 32'b0;
        dma_h2f_state <= DMA_H2F_IDLE;
        cpld_len      <= 10'd0;
        cpld_tag      <= 8'b0;
    end
    else
        case (dma_h2f_state)
        DMA_H2F_IDLE     : begin
            if (!trn_rsof_n && !trn_rsrc_rdy_n && (trn_rd [ 63 : 56] == 8'h4A) && (trn_rd [ 41 : 32 ] <= fifoH2F_empty_DW_count)) begin
                $display("PCIe dma device : DMA : SOF : Recieved completion with data");
                cpld_len      <= trn_rd [ 41 : 32 ];
                dma_h2f_state <= DMA_H2F_CPLD_QW2;
            end
        end

        DMA_H2F_CPLD_QW2 : begin
            cpld_tag      <= trn_rd [ 47 : 40 ];
            h2f_cpld_hi   <= rbo_trn_rd_low;
            cpld_len      <= cpld_len - 1'd1;
            $display("PCIe dma device : DMA : First after SOF : Recieved completion with data, tag = 8'h%h, payload = 32'h%h", trn_rd [ 47 : 40 ], trn_rd [ 31 : 0 ]);
            dma_h2f_state <= DMA_H2F_CPLD_EOF;
        end

        DMA_H2F_CPLD_EOF : begin
            h2f_cpld_hi <= rbo_trn_rd_low;
            cpld_len    <= cpld_len - 2'd2;
            $display("PCIe dma device : DMA : Between SOF & EOF : Recieved completion with data, payload = 64'h%h", trn_rd);
            if (!trn_reof_n && (cpld_len == 10'd1)) begin
                $display("PCIe dma device : DMA : EOF : Recieved last completion with data");
                dma_h2f_state <= DMA_H2F_IDLE;
            end
        end

        endcase

////////////////////////////////////////////////////////////////////
//DMA status tracking
////////////////////////////////////////////////////////////////////

wire   ctrl_wrtn;
assign ctrl_wrtn = (bar0_hit && !trn_reof_n && wd_3dw && (length == 10'h1) && (trn_rd [ 39 : 34 ] == 6'b000100));

always @ (posedge trn_clk)
    if (!trn_reset_n) cpld_len_rem <= 10'd0;
    else if (ctrl_wrtn) cpld_len_rem <= dbg_mrd_len [ 9 : 0 ];
    else if (dma_h2f_state == DMA_H2F_CPLD_QW2) cpld_len_rem <= cpld_len_rem - cpld_len;

always @ (posedge trn_clk)
    if (!trn_reset_n) begin
        mwr_sent <= 1'b0;
        mrd_sent <= 1'b0;
        mrd_done <= 1'b0;
    end
    else begin
        if (((pio_state == DMA_F2H_MWR32_EOF) && (mwr_len == 10'd1)) && (mwr_len_rem == 10'b0)) mwr_sent <= 1'b1;
        else if (ctrl_wrtn) mwr_sent <= 1'b0;
        if ((pio_state == PIO_IDLE) && ctrl[2]) mrd_sent <= 1'b1;
        else if (ctrl_wrtn) mrd_sent <= 1'b0;
        if ((dma_h2f_state == DMA_H2F_CPLD_EOF) && !trn_reof_n && (cpld_len == 10'd1) && (cpld_len_rem == 10'd0)) mrd_done <= 1'b1;
        else if (ctrl_wrtn) mrd_done <= 1'b0;
    end

////////////////////////////////////////////////////////////////////
//Fifos control
////////////////////////////////////////////////////////////////////

assign fifoH2F_sD_IN = (bar1_hit && mwr32 && !trn_reof_n) ? { rbo_trn_rd_high, fifoH2F_lo_reg } : (cpld) ? { rbo_trn_rd_high, h2f_cpld_hi } : 64'bx;
assign fifoH2F_sENQ  = (bar1_hit && mwr32 && !trn_reof_n && fifoH2F_sFULL_N) || ((dma_h2f_state == DMA_H2F_CPLD_EOF) && fifoH2F_sFULL_N);

assign fifoF2H_dDEQ  = (((pio_state == PIO_BAR1_CPLD_EOF) ||
                         (pio_state == DMA_F2H_MWR32_ADR) ||
                         (pio_state == DMA_F2H_MWR32_EOF)) &&
                         (mwr_len != 10'd1) && fifoF2H_dEMPTY_N);

assign fifoH2F_dDEQ  = EN_read;
assign DATA_read     = fifoH2F_dD_OUT;
assign RDY_read      = fifoH2F_dEMPTY_N;

assign fifoF2H_sD_IN = DATA_write;
assign fifoF2H_sENQ  = EN_write;
assign RDY_write     = fifoF2H_sFULL_N;

////////////////////////////////////////////////////////////////////
//Soft reset event handler
////////////////////////////////////////////////////////////////////

reg soft_reset_event;
always @ (posedge trn_clk)
    if (!trn_reset_n) soft_reset_event <= 1'b0;
    else if (bar0_hit && !trn_reof_n && wd_3dw && (length == 10'b1) && (trn_rd [ 39 : 34 ] == 6'b100010) && (rbo_trn_rd_low == 32'b1)) begin
        $display("PCIe dma device : Recieved BAR0 write request with soft reset address");
        soft_reset_event <= 1'b1;
    end
    else soft_reset_event <= 1'b0;

SyncPulse soft_reset_sync
(
    .sCLK(trn_clk),
    .sRST_N(trn_reset_n),
    .dCLK(model_clk),
    .sEN(soft_reset_event),
    .dPulse(SOFT_reset)
);

////////////////////////////////////////////////////////////////////
// Overlapped BAR0 and DMA handler
////////////////////////////////////////////////////////////////////

always @ (posedge trn_clk)
    if (!trn_reset_n) bar0_read <= 1'b0;
    else if (bar0_hit && !trn_rsof_n && (trn_rd [ 63 : 61 ] == 3'b000)) bar0_read <= 1'b1;
    else if (pio_state == PIO_BAR0_CPLD_SOF) bar0_read <= 1'b0;

endmodule
