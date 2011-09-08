///////////////////////////////////////////////////////////////////////////////
// Filename      : dma_sgl_loader.v
// Brief         : Control of scatter-gather list for fpga to host read requests
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

module  dma_sgl_loader #
(
    parameter         SGL_LOAD_TAG  = 8'h1
)
(
    input             trn_clk,
    input             trn_reset_n,
    input  [ 63 : 0 ] trn_rd,
    input             trn_rsof_n,
    input             trn_reof_n,
    input             trn_rsrc_rdy_n,
    input  [ 31 : 0 ] rbo_trn_rd_high,
    input  [ 31 : 0 ] rbo_trn_rd_low,

    input  [  9 : 0 ] sgl_len,

    output [ 39 : 0 ] sgl_dma_addr,
    output [  9 : 0 ] sgl_dma_len,

    input             next_entry,
    input             dma_en,
    input             start_sgl_load,
    output reg        sgl_ready,
    output            last_entry

);

// At the moment SGL is filled via DMA: at first, host writes SGL address and length (in QWs) registers, then
// pcie_app sends read request with this address and lenght (tagged with SGL_LOAD_TAG) to host and then
// dma_sgl_loader awaits completions with data on TRN RX interface. Since width of SGL is 72 bits, it was
// decided to fill it in the following way: every 9th recieved QW starting with 1st is splitted into 8 pieces.
// Each of them presents 8 high bits of SGL entry. Between every 9th QW are 64 bit SGl payloads.

// To simplify logic reversed low part trn_rd is saved with one clock delay.
reg             sgl_wr;
reg  [  8 : 0 ] sgl_addr;
reg  [ 63 : 0 ] sgl_din;
//wire [ 63 : 0 ] sgl_dout; [rfadeev][FIXME]

reg  [ 31 : 0 ] rbo_trn_rd_low_t;
reg  [  9 : 0 ] rcvd_qw_num;
wire sgl_load_last_qw;
reg  sgl_load_done;
reg  sgl_ready_t;


localparam SGL_LOAD_IDLE     = 4'd0;
localparam SGL_LOAD_CPLD_SOF = 4'd1;
localparam SGL_LOAD_CPLD_QW2 = 4'd2;
localparam SGL_LOAD_CPLD_EOF = 4'd3;

reg [ 3 : 0 ] sgl_load_state;
reg [ 9 : 0 ] cpld_len;
reg [ 7 : 0 ] cpld_tag;

////////////////////////////////////////////////////////////////////
//BRAM-based Scatter-Gather list
////////////////////////////////////////////////////////////////////

wire [ 63 : 0 ] sgl_bram_dout;
reg  [ 63 : 0 ] sgl_dout;

always @ (posedge trn_clk) sgl_dout <= sgl_bram_dout;

BRAM64x512 sgl_mem
(
    .clka(trn_clk),
    .rsta(!trn_reset_n),
    .wea(sgl_wr),
    .addra(sgl_addr),
    .dina(sgl_din),
    .douta(sgl_bram_dout)
);

////////////////////////////////////////////////////////////////////
// Control logic for writing Scatter-Gather list
////////////////////////////////////////////////////////////////////

assign sgl_load_last_qw = (rcvd_qw_num == sgl_len);

always @ (posedge trn_clk)
    if (!trn_reset_n) sgl_load_done <= 1'b0;
    else if (sgl_load_last_qw) sgl_load_done <= 1'b1;
    else sgl_load_done <= 1'b0;

always @ (posedge trn_clk)
    if (!trn_reset_n) rbo_trn_rd_low_t <= 32'b0;
    else rbo_trn_rd_low_t <= rbo_trn_rd_low;

always @ (posedge trn_clk)
    if (!trn_reset_n) sgl_wr <= 1'b0;
    else if ((sgl_load_state == SGL_LOAD_CPLD_EOF) && !trn_rsrc_rdy_n) sgl_wr <= 1'b1;
    else sgl_wr <= 1'b0;

always @ (posedge trn_clk)
    if (!trn_reset_n) sgl_addr <= 9'b0;
    else if (sgl_load_last_qw || start_sgl_load) sgl_addr <= 9'b0;
    else if (sgl_wr || next_entry) sgl_addr <= sgl_addr + 1'b1;

always @ (posedge trn_clk)
    if (!trn_reset_n) sgl_din <= 64'b0;
    else if ((sgl_load_state == SGL_LOAD_CPLD_EOF) && !trn_rsrc_rdy_n) sgl_din <= { rbo_trn_rd_high, rbo_trn_rd_low_t };
    else sgl_din <= 64'hx;

always @ (posedge trn_clk)
    if (!trn_reset_n) rcvd_qw_num <= 10'b0;
    else if (sgl_load_last_qw) rcvd_qw_num <= 10'b0;
    else if (sgl_load_state == SGL_LOAD_CPLD_EOF) rcvd_qw_num <= rcvd_qw_num + 10'b1;

// Since BRAM has 1 clock delay, we have to skip 1 tick to have valid address and lenght for the first entry

always @ (posedge trn_clk)
    if (!trn_reset_n) sgl_ready_t <= 1'b0;
    else if (start_sgl_load) sgl_ready_t <= 1'b0;
    else if (sgl_load_done) sgl_ready_t <= 1'b1;

always @ (posedge trn_clk)
    if (!trn_reset_n) sgl_ready <= 1'b0;
    else sgl_ready <= sgl_ready_t;

// Since SGL is filled via DMA, dma_loader stores all completions with SGL_LOAD_TAG accordingly

////////////////////////////////////////////////////////////////////
// FSM to monitor TRN RX interface
////////////////////////////////////////////////////////////////////

always @ (posedge trn_clk)
    if (!trn_reset_n) begin
        sgl_load_state <= SGL_LOAD_IDLE;
        cpld_len       <= 10'd0;
        cpld_tag       <= 8'b0;
    end
    else
        case (sgl_load_state)
        SGL_LOAD_IDLE     : begin
            if (!trn_rsof_n && !trn_rsrc_rdy_n && (trn_rd [ 63 : 56] == 8'h4A) && !sgl_ready) begin //sgl_ready predicate CHECK - tag checking probably should be moved to SPL_LOAD_CPLD_QW2 stage
                $display("SGL loader : DMA : SOF : Recieved completion with data");
                cpld_len       <= trn_rd [ 41 : 32 ];
                sgl_load_state <= SGL_LOAD_CPLD_QW2;
            end
        end

        SGL_LOAD_CPLD_QW2 : begin
            cpld_tag       <= trn_rd [ 47 : 40 ];
            cpld_len       <= cpld_len - 1'd1;
            $display("SGL loader : DMA : First after SOF : Recieved completion with data, tag = 8'h%h, payload = 32'h%h", trn_rd [ 47 : 40 ], trn_rd [ 31 : 0 ]);
            sgl_load_state <= SGL_LOAD_CPLD_EOF;
        end

        SGL_LOAD_CPLD_EOF : begin
            if (cpld_tag == SGL_LOAD_TAG) begin
                cpld_len    <= cpld_len - 2'd2;
                $display("SGL loader : DMA : Between SOF & EOF : Recieved completion with data, payload = 64'h%h", trn_rd);
                if (!trn_reof_n && (cpld_len == 10'd1)) begin
                    $display("SGL loader : DMA : EOF : Recieved last completion with data");
                    sgl_load_state <= SGL_LOAD_IDLE;
                end
            end
            else begin
                $display("SGL loader : DMA : Recieved completion with data with incorrect tag = 8'h%h, completion aborted", cpld_tag);
                sgl_load_state <= SGL_LOAD_IDLE;
            end
        end

        endcase

////////////////////////////////////////////////////////////////////
// Control logic for reading Scatter-Gather list
////////////////////////////////////////////////////////////////////

assign sgl_dma_addr = sgl_dout [ 39 : 0  ];
assign sgl_dma_len  = sgl_dout [ 49 : 40 ];

assign last_entry = (sgl_addr == (sgl_len - 1'b1));

endmodule
