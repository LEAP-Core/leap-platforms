//megafunction wizard: %Altera SOPC Builder%
//GENERATION: STANDARD
//VERSION: WM1.0


//Legal Notice: (C)2010 Altera Corporation. All rights reserved.  Your
//use of Altera Corporation's design tools, logic functions and other
//software and tools, and its AMPP partner logic functions, and any
//output files any of the foregoing (including device programming or
//simulation files), and any associated documentation or information are
//expressly subject to the terms and conditions of the Altera Program
//License Subscription Agreement or other applicable license agreement,
//including, without limitation, that your use is for the sole purpose
//of programming logic devices manufactured by Altera and sold by Altera
//or its authorized distributors.  Please refer to the applicable
//agreement for further details.

// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

module jtag_uart_0_avalon_jtag_slave_arbitrator (
                                                  // inputs:
                                                   clk,
                                                   jtag_uart_0_avalon_jtag_slave_dataavailable,
                                                   jtag_uart_0_avalon_jtag_slave_readdata,
                                                   jtag_uart_0_avalon_jtag_slave_readyfordata,
                                                   jtag_uart_0_avalon_jtag_slave_waitrequest,
                                                   mkAvalonWrapperInstance_0_avalon_master_address_to_slave,
                                                   mkAvalonWrapperInstance_0_avalon_master_read,
                                                   mkAvalonWrapperInstance_0_avalon_master_write,
                                                   mkAvalonWrapperInstance_0_avalon_master_writedata,
                                                   mkAvalonWrapperInstance_0_latency_counter,
                                                   reset_n,

                                                  // outputs:
                                                   d1_jtag_uart_0_avalon_jtag_slave_end_xfer,
                                                   jtag_uart_0_avalon_jtag_slave_address,
                                                   jtag_uart_0_avalon_jtag_slave_chipselect,
                                                   jtag_uart_0_avalon_jtag_slave_dataavailable_from_sa,
                                                   jtag_uart_0_avalon_jtag_slave_read_n,
                                                   jtag_uart_0_avalon_jtag_slave_readdata_from_sa,
                                                   jtag_uart_0_avalon_jtag_slave_readyfordata_from_sa,
                                                   jtag_uart_0_avalon_jtag_slave_reset_n,
                                                   jtag_uart_0_avalon_jtag_slave_waitrequest_from_sa,
                                                   jtag_uart_0_avalon_jtag_slave_write_n,
                                                   jtag_uart_0_avalon_jtag_slave_writedata,
                                                   mkAvalonWrapperInstance_0_granted_jtag_uart_0_avalon_jtag_slave,
                                                   mkAvalonWrapperInstance_0_qualified_request_jtag_uart_0_avalon_jtag_slave,
                                                   mkAvalonWrapperInstance_0_read_data_valid_jtag_uart_0_avalon_jtag_slave,
                                                   mkAvalonWrapperInstance_0_requests_jtag_uart_0_avalon_jtag_slave
                                                )
;

  output           d1_jtag_uart_0_avalon_jtag_slave_end_xfer;
  output           jtag_uart_0_avalon_jtag_slave_address;
  output           jtag_uart_0_avalon_jtag_slave_chipselect;
  output           jtag_uart_0_avalon_jtag_slave_dataavailable_from_sa;
  output           jtag_uart_0_avalon_jtag_slave_read_n;
  output  [ 31: 0] jtag_uart_0_avalon_jtag_slave_readdata_from_sa;
  output           jtag_uart_0_avalon_jtag_slave_readyfordata_from_sa;
  output           jtag_uart_0_avalon_jtag_slave_reset_n;
  output           jtag_uart_0_avalon_jtag_slave_waitrequest_from_sa;
  output           jtag_uart_0_avalon_jtag_slave_write_n;
  output  [ 31: 0] jtag_uart_0_avalon_jtag_slave_writedata;
  output           mkAvalonWrapperInstance_0_granted_jtag_uart_0_avalon_jtag_slave;
  output           mkAvalonWrapperInstance_0_qualified_request_jtag_uart_0_avalon_jtag_slave;
  output           mkAvalonWrapperInstance_0_read_data_valid_jtag_uart_0_avalon_jtag_slave;
  output           mkAvalonWrapperInstance_0_requests_jtag_uart_0_avalon_jtag_slave;
  input            clk;
  input            jtag_uart_0_avalon_jtag_slave_dataavailable;
  input   [ 31: 0] jtag_uart_0_avalon_jtag_slave_readdata;
  input            jtag_uart_0_avalon_jtag_slave_readyfordata;
  input            jtag_uart_0_avalon_jtag_slave_waitrequest;
  input   [ 31: 0] mkAvalonWrapperInstance_0_avalon_master_address_to_slave;
  input            mkAvalonWrapperInstance_0_avalon_master_read;
  input            mkAvalonWrapperInstance_0_avalon_master_write;
  input   [ 31: 0] mkAvalonWrapperInstance_0_avalon_master_writedata;
  input            mkAvalonWrapperInstance_0_latency_counter;
  input            reset_n;

  reg              d1_jtag_uart_0_avalon_jtag_slave_end_xfer;
  reg              d1_reasons_to_wait;
  reg              enable_nonzero_assertions;
  wire             end_xfer_arb_share_counter_term_jtag_uart_0_avalon_jtag_slave;
  wire             in_a_read_cycle;
  wire             in_a_write_cycle;
  wire             jtag_uart_0_avalon_jtag_slave_address;
  wire             jtag_uart_0_avalon_jtag_slave_allgrants;
  wire             jtag_uart_0_avalon_jtag_slave_allow_new_arb_cycle;
  wire             jtag_uart_0_avalon_jtag_slave_any_bursting_master_saved_grant;
  wire             jtag_uart_0_avalon_jtag_slave_any_continuerequest;
  wire             jtag_uart_0_avalon_jtag_slave_arb_counter_enable;
  reg              jtag_uart_0_avalon_jtag_slave_arb_share_counter;
  wire             jtag_uart_0_avalon_jtag_slave_arb_share_counter_next_value;
  wire             jtag_uart_0_avalon_jtag_slave_arb_share_set_values;
  wire             jtag_uart_0_avalon_jtag_slave_beginbursttransfer_internal;
  wire             jtag_uart_0_avalon_jtag_slave_begins_xfer;
  wire             jtag_uart_0_avalon_jtag_slave_chipselect;
  wire             jtag_uart_0_avalon_jtag_slave_dataavailable_from_sa;
  wire             jtag_uart_0_avalon_jtag_slave_end_xfer;
  wire             jtag_uart_0_avalon_jtag_slave_firsttransfer;
  wire             jtag_uart_0_avalon_jtag_slave_grant_vector;
  wire             jtag_uart_0_avalon_jtag_slave_in_a_read_cycle;
  wire             jtag_uart_0_avalon_jtag_slave_in_a_write_cycle;
  wire             jtag_uart_0_avalon_jtag_slave_master_qreq_vector;
  wire             jtag_uart_0_avalon_jtag_slave_non_bursting_master_requests;
  wire             jtag_uart_0_avalon_jtag_slave_read_n;
  wire    [ 31: 0] jtag_uart_0_avalon_jtag_slave_readdata_from_sa;
  wire             jtag_uart_0_avalon_jtag_slave_readyfordata_from_sa;
  reg              jtag_uart_0_avalon_jtag_slave_reg_firsttransfer;
  wire             jtag_uart_0_avalon_jtag_slave_reset_n;
  reg              jtag_uart_0_avalon_jtag_slave_slavearbiterlockenable;
  wire             jtag_uart_0_avalon_jtag_slave_slavearbiterlockenable2;
  wire             jtag_uart_0_avalon_jtag_slave_unreg_firsttransfer;
  wire             jtag_uart_0_avalon_jtag_slave_waitrequest_from_sa;
  wire             jtag_uart_0_avalon_jtag_slave_waits_for_read;
  wire             jtag_uart_0_avalon_jtag_slave_waits_for_write;
  wire             jtag_uart_0_avalon_jtag_slave_write_n;
  wire    [ 31: 0] jtag_uart_0_avalon_jtag_slave_writedata;
  wire             mkAvalonWrapperInstance_0_avalon_master_arbiterlock;
  wire             mkAvalonWrapperInstance_0_avalon_master_arbiterlock2;
  wire             mkAvalonWrapperInstance_0_avalon_master_continuerequest;
  wire             mkAvalonWrapperInstance_0_granted_jtag_uart_0_avalon_jtag_slave;
  wire             mkAvalonWrapperInstance_0_qualified_request_jtag_uart_0_avalon_jtag_slave;
  wire             mkAvalonWrapperInstance_0_read_data_valid_jtag_uart_0_avalon_jtag_slave;
  wire             mkAvalonWrapperInstance_0_requests_jtag_uart_0_avalon_jtag_slave;
  wire             mkAvalonWrapperInstance_0_saved_grant_jtag_uart_0_avalon_jtag_slave;
  wire    [ 31: 0] shifted_address_to_jtag_uart_0_avalon_jtag_slave_from_mkAvalonWrapperInstance_0_avalon_master;
  wire             wait_for_jtag_uart_0_avalon_jtag_slave_counter;
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          d1_reasons_to_wait <= 0;
      else 
        d1_reasons_to_wait <= ~jtag_uart_0_avalon_jtag_slave_end_xfer;
    end


  assign jtag_uart_0_avalon_jtag_slave_begins_xfer = ~d1_reasons_to_wait & ((mkAvalonWrapperInstance_0_qualified_request_jtag_uart_0_avalon_jtag_slave));
  //assign jtag_uart_0_avalon_jtag_slave_readdata_from_sa = jtag_uart_0_avalon_jtag_slave_readdata so that symbol knows where to group signals which may go to master only, which is an e_assign
  assign jtag_uart_0_avalon_jtag_slave_readdata_from_sa = jtag_uart_0_avalon_jtag_slave_readdata;

  assign mkAvalonWrapperInstance_0_requests_jtag_uart_0_avalon_jtag_slave = ({mkAvalonWrapperInstance_0_avalon_master_address_to_slave[31 : 3] , 3'b0} == 32'h0) & (mkAvalonWrapperInstance_0_avalon_master_read | mkAvalonWrapperInstance_0_avalon_master_write);
  //assign jtag_uart_0_avalon_jtag_slave_dataavailable_from_sa = jtag_uart_0_avalon_jtag_slave_dataavailable so that symbol knows where to group signals which may go to master only, which is an e_assign
  assign jtag_uart_0_avalon_jtag_slave_dataavailable_from_sa = jtag_uart_0_avalon_jtag_slave_dataavailable;

  //assign jtag_uart_0_avalon_jtag_slave_readyfordata_from_sa = jtag_uart_0_avalon_jtag_slave_readyfordata so that symbol knows where to group signals which may go to master only, which is an e_assign
  assign jtag_uart_0_avalon_jtag_slave_readyfordata_from_sa = jtag_uart_0_avalon_jtag_slave_readyfordata;

  //assign jtag_uart_0_avalon_jtag_slave_waitrequest_from_sa = jtag_uart_0_avalon_jtag_slave_waitrequest so that symbol knows where to group signals which may go to master only, which is an e_assign
  assign jtag_uart_0_avalon_jtag_slave_waitrequest_from_sa = jtag_uart_0_avalon_jtag_slave_waitrequest;

  //jtag_uart_0_avalon_jtag_slave_arb_share_counter set values, which is an e_mux
  assign jtag_uart_0_avalon_jtag_slave_arb_share_set_values = 1;

  //jtag_uart_0_avalon_jtag_slave_non_bursting_master_requests mux, which is an e_mux
  assign jtag_uart_0_avalon_jtag_slave_non_bursting_master_requests = mkAvalonWrapperInstance_0_requests_jtag_uart_0_avalon_jtag_slave;

  //jtag_uart_0_avalon_jtag_slave_any_bursting_master_saved_grant mux, which is an e_mux
  assign jtag_uart_0_avalon_jtag_slave_any_bursting_master_saved_grant = 0;

  //jtag_uart_0_avalon_jtag_slave_arb_share_counter_next_value assignment, which is an e_assign
  assign jtag_uart_0_avalon_jtag_slave_arb_share_counter_next_value = jtag_uart_0_avalon_jtag_slave_firsttransfer ? (jtag_uart_0_avalon_jtag_slave_arb_share_set_values - 1) : |jtag_uart_0_avalon_jtag_slave_arb_share_counter ? (jtag_uart_0_avalon_jtag_slave_arb_share_counter - 1) : 0;

  //jtag_uart_0_avalon_jtag_slave_allgrants all slave grants, which is an e_mux
  assign jtag_uart_0_avalon_jtag_slave_allgrants = |jtag_uart_0_avalon_jtag_slave_grant_vector;

  //jtag_uart_0_avalon_jtag_slave_end_xfer assignment, which is an e_assign
  assign jtag_uart_0_avalon_jtag_slave_end_xfer = ~(jtag_uart_0_avalon_jtag_slave_waits_for_read | jtag_uart_0_avalon_jtag_slave_waits_for_write);

  //end_xfer_arb_share_counter_term_jtag_uart_0_avalon_jtag_slave arb share counter enable term, which is an e_assign
  assign end_xfer_arb_share_counter_term_jtag_uart_0_avalon_jtag_slave = jtag_uart_0_avalon_jtag_slave_end_xfer & (~jtag_uart_0_avalon_jtag_slave_any_bursting_master_saved_grant | in_a_read_cycle | in_a_write_cycle);

  //jtag_uart_0_avalon_jtag_slave_arb_share_counter arbitration counter enable, which is an e_assign
  assign jtag_uart_0_avalon_jtag_slave_arb_counter_enable = (end_xfer_arb_share_counter_term_jtag_uart_0_avalon_jtag_slave & jtag_uart_0_avalon_jtag_slave_allgrants) | (end_xfer_arb_share_counter_term_jtag_uart_0_avalon_jtag_slave & ~jtag_uart_0_avalon_jtag_slave_non_bursting_master_requests);

  //jtag_uart_0_avalon_jtag_slave_arb_share_counter counter, which is an e_register
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          jtag_uart_0_avalon_jtag_slave_arb_share_counter <= 0;
      else if (jtag_uart_0_avalon_jtag_slave_arb_counter_enable)
          jtag_uart_0_avalon_jtag_slave_arb_share_counter <= jtag_uart_0_avalon_jtag_slave_arb_share_counter_next_value;
    end


  //jtag_uart_0_avalon_jtag_slave_slavearbiterlockenable slave enables arbiterlock, which is an e_register
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          jtag_uart_0_avalon_jtag_slave_slavearbiterlockenable <= 0;
      else if ((|jtag_uart_0_avalon_jtag_slave_master_qreq_vector & end_xfer_arb_share_counter_term_jtag_uart_0_avalon_jtag_slave) | (end_xfer_arb_share_counter_term_jtag_uart_0_avalon_jtag_slave & ~jtag_uart_0_avalon_jtag_slave_non_bursting_master_requests))
          jtag_uart_0_avalon_jtag_slave_slavearbiterlockenable <= |jtag_uart_0_avalon_jtag_slave_arb_share_counter_next_value;
    end


  //mkAvalonWrapperInstance_0/avalon_master jtag_uart_0/avalon_jtag_slave arbiterlock, which is an e_assign
  assign mkAvalonWrapperInstance_0_avalon_master_arbiterlock = jtag_uart_0_avalon_jtag_slave_slavearbiterlockenable & mkAvalonWrapperInstance_0_avalon_master_continuerequest;

  //jtag_uart_0_avalon_jtag_slave_slavearbiterlockenable2 slave enables arbiterlock2, which is an e_assign
  assign jtag_uart_0_avalon_jtag_slave_slavearbiterlockenable2 = |jtag_uart_0_avalon_jtag_slave_arb_share_counter_next_value;

  //mkAvalonWrapperInstance_0/avalon_master jtag_uart_0/avalon_jtag_slave arbiterlock2, which is an e_assign
  assign mkAvalonWrapperInstance_0_avalon_master_arbiterlock2 = jtag_uart_0_avalon_jtag_slave_slavearbiterlockenable2 & mkAvalonWrapperInstance_0_avalon_master_continuerequest;

  //jtag_uart_0_avalon_jtag_slave_any_continuerequest at least one master continues requesting, which is an e_assign
  assign jtag_uart_0_avalon_jtag_slave_any_continuerequest = 1;

  //mkAvalonWrapperInstance_0_avalon_master_continuerequest continued request, which is an e_assign
  assign mkAvalonWrapperInstance_0_avalon_master_continuerequest = 1;

  assign mkAvalonWrapperInstance_0_qualified_request_jtag_uart_0_avalon_jtag_slave = mkAvalonWrapperInstance_0_requests_jtag_uart_0_avalon_jtag_slave & ~((mkAvalonWrapperInstance_0_avalon_master_read & ((mkAvalonWrapperInstance_0_latency_counter != 0))));
  //local readdatavalid mkAvalonWrapperInstance_0_read_data_valid_jtag_uart_0_avalon_jtag_slave, which is an e_mux
  assign mkAvalonWrapperInstance_0_read_data_valid_jtag_uart_0_avalon_jtag_slave = mkAvalonWrapperInstance_0_granted_jtag_uart_0_avalon_jtag_slave & mkAvalonWrapperInstance_0_avalon_master_read & ~jtag_uart_0_avalon_jtag_slave_waits_for_read;

  //jtag_uart_0_avalon_jtag_slave_writedata mux, which is an e_mux
  assign jtag_uart_0_avalon_jtag_slave_writedata = mkAvalonWrapperInstance_0_avalon_master_writedata;

  //master is always granted when requested
  assign mkAvalonWrapperInstance_0_granted_jtag_uart_0_avalon_jtag_slave = mkAvalonWrapperInstance_0_qualified_request_jtag_uart_0_avalon_jtag_slave;

  //mkAvalonWrapperInstance_0/avalon_master saved-grant jtag_uart_0/avalon_jtag_slave, which is an e_assign
  assign mkAvalonWrapperInstance_0_saved_grant_jtag_uart_0_avalon_jtag_slave = mkAvalonWrapperInstance_0_requests_jtag_uart_0_avalon_jtag_slave;

  //allow new arb cycle for jtag_uart_0/avalon_jtag_slave, which is an e_assign
  assign jtag_uart_0_avalon_jtag_slave_allow_new_arb_cycle = 1;

  //placeholder chosen master
  assign jtag_uart_0_avalon_jtag_slave_grant_vector = 1;

  //placeholder vector of master qualified-requests
  assign jtag_uart_0_avalon_jtag_slave_master_qreq_vector = 1;

  //jtag_uart_0_avalon_jtag_slave_reset_n assignment, which is an e_assign
  assign jtag_uart_0_avalon_jtag_slave_reset_n = reset_n;

  assign jtag_uart_0_avalon_jtag_slave_chipselect = mkAvalonWrapperInstance_0_granted_jtag_uart_0_avalon_jtag_slave;
  //jtag_uart_0_avalon_jtag_slave_firsttransfer first transaction, which is an e_assign
  assign jtag_uart_0_avalon_jtag_slave_firsttransfer = jtag_uart_0_avalon_jtag_slave_begins_xfer ? jtag_uart_0_avalon_jtag_slave_unreg_firsttransfer : jtag_uart_0_avalon_jtag_slave_reg_firsttransfer;

  //jtag_uart_0_avalon_jtag_slave_unreg_firsttransfer first transaction, which is an e_assign
  assign jtag_uart_0_avalon_jtag_slave_unreg_firsttransfer = ~(jtag_uart_0_avalon_jtag_slave_slavearbiterlockenable & jtag_uart_0_avalon_jtag_slave_any_continuerequest);

  //jtag_uart_0_avalon_jtag_slave_reg_firsttransfer first transaction, which is an e_register
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          jtag_uart_0_avalon_jtag_slave_reg_firsttransfer <= 1'b1;
      else if (jtag_uart_0_avalon_jtag_slave_begins_xfer)
          jtag_uart_0_avalon_jtag_slave_reg_firsttransfer <= jtag_uart_0_avalon_jtag_slave_unreg_firsttransfer;
    end


  //jtag_uart_0_avalon_jtag_slave_beginbursttransfer_internal begin burst transfer, which is an e_assign
  assign jtag_uart_0_avalon_jtag_slave_beginbursttransfer_internal = jtag_uart_0_avalon_jtag_slave_begins_xfer;

  //~jtag_uart_0_avalon_jtag_slave_read_n assignment, which is an e_mux
  assign jtag_uart_0_avalon_jtag_slave_read_n = ~(mkAvalonWrapperInstance_0_granted_jtag_uart_0_avalon_jtag_slave & mkAvalonWrapperInstance_0_avalon_master_read);

  //~jtag_uart_0_avalon_jtag_slave_write_n assignment, which is an e_mux
  assign jtag_uart_0_avalon_jtag_slave_write_n = ~(mkAvalonWrapperInstance_0_granted_jtag_uart_0_avalon_jtag_slave & mkAvalonWrapperInstance_0_avalon_master_write);

  assign shifted_address_to_jtag_uart_0_avalon_jtag_slave_from_mkAvalonWrapperInstance_0_avalon_master = mkAvalonWrapperInstance_0_avalon_master_address_to_slave;
  //jtag_uart_0_avalon_jtag_slave_address mux, which is an e_mux
  assign jtag_uart_0_avalon_jtag_slave_address = shifted_address_to_jtag_uart_0_avalon_jtag_slave_from_mkAvalonWrapperInstance_0_avalon_master >> 2;

  //d1_jtag_uart_0_avalon_jtag_slave_end_xfer register, which is an e_register
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          d1_jtag_uart_0_avalon_jtag_slave_end_xfer <= 1;
      else 
        d1_jtag_uart_0_avalon_jtag_slave_end_xfer <= jtag_uart_0_avalon_jtag_slave_end_xfer;
    end


  //jtag_uart_0_avalon_jtag_slave_waits_for_read in a cycle, which is an e_mux
  assign jtag_uart_0_avalon_jtag_slave_waits_for_read = jtag_uart_0_avalon_jtag_slave_in_a_read_cycle & jtag_uart_0_avalon_jtag_slave_waitrequest_from_sa;

  //jtag_uart_0_avalon_jtag_slave_in_a_read_cycle assignment, which is an e_assign
  assign jtag_uart_0_avalon_jtag_slave_in_a_read_cycle = mkAvalonWrapperInstance_0_granted_jtag_uart_0_avalon_jtag_slave & mkAvalonWrapperInstance_0_avalon_master_read;

  //in_a_read_cycle assignment, which is an e_mux
  assign in_a_read_cycle = jtag_uart_0_avalon_jtag_slave_in_a_read_cycle;

  //jtag_uart_0_avalon_jtag_slave_waits_for_write in a cycle, which is an e_mux
  assign jtag_uart_0_avalon_jtag_slave_waits_for_write = jtag_uart_0_avalon_jtag_slave_in_a_write_cycle & jtag_uart_0_avalon_jtag_slave_waitrequest_from_sa;

  //jtag_uart_0_avalon_jtag_slave_in_a_write_cycle assignment, which is an e_assign
  assign jtag_uart_0_avalon_jtag_slave_in_a_write_cycle = mkAvalonWrapperInstance_0_granted_jtag_uart_0_avalon_jtag_slave & mkAvalonWrapperInstance_0_avalon_master_write;

  //in_a_write_cycle assignment, which is an e_mux
  assign in_a_write_cycle = jtag_uart_0_avalon_jtag_slave_in_a_write_cycle;

  assign wait_for_jtag_uart_0_avalon_jtag_slave_counter = 0;

//synthesis translate_off
//////////////// SIMULATION-ONLY CONTENTS
  //jtag_uart_0/avalon_jtag_slave enable non-zero assertions, which is an e_register
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          enable_nonzero_assertions <= 0;
      else 
        enable_nonzero_assertions <= 1'b1;
    end



//////////////// END SIMULATION-ONLY CONTENTS

//synthesis translate_on

endmodule



// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

module mkAvalonWrapperInstance_0_avalon_master_arbitrator (
                                                            // inputs:
                                                             clk,
                                                             d1_jtag_uart_0_avalon_jtag_slave_end_xfer,
                                                             jtag_uart_0_avalon_jtag_slave_readdata_from_sa,
                                                             jtag_uart_0_avalon_jtag_slave_waitrequest_from_sa,
                                                             mkAvalonWrapperInstance_0_avalon_master_address,
                                                             mkAvalonWrapperInstance_0_avalon_master_read,
                                                             mkAvalonWrapperInstance_0_avalon_master_write,
                                                             mkAvalonWrapperInstance_0_avalon_master_writedata,
                                                             mkAvalonWrapperInstance_0_granted_jtag_uart_0_avalon_jtag_slave,
                                                             mkAvalonWrapperInstance_0_qualified_request_jtag_uart_0_avalon_jtag_slave,
                                                             mkAvalonWrapperInstance_0_read_data_valid_jtag_uart_0_avalon_jtag_slave,
                                                             mkAvalonWrapperInstance_0_requests_jtag_uart_0_avalon_jtag_slave,
                                                             reset_n,

                                                            // outputs:
                                                             mkAvalonWrapperInstance_0_avalon_master_address_to_slave,
                                                             mkAvalonWrapperInstance_0_avalon_master_readdata,
                                                             mkAvalonWrapperInstance_0_avalon_master_readdatavalid,
                                                             mkAvalonWrapperInstance_0_avalon_master_waitrequest,
                                                             mkAvalonWrapperInstance_0_latency_counter
                                                          )
;

  output  [ 31: 0] mkAvalonWrapperInstance_0_avalon_master_address_to_slave;
  output  [ 31: 0] mkAvalonWrapperInstance_0_avalon_master_readdata;
  output           mkAvalonWrapperInstance_0_avalon_master_readdatavalid;
  output           mkAvalonWrapperInstance_0_avalon_master_waitrequest;
  output           mkAvalonWrapperInstance_0_latency_counter;
  input            clk;
  input            d1_jtag_uart_0_avalon_jtag_slave_end_xfer;
  input   [ 31: 0] jtag_uart_0_avalon_jtag_slave_readdata_from_sa;
  input            jtag_uart_0_avalon_jtag_slave_waitrequest_from_sa;
  input   [ 31: 0] mkAvalonWrapperInstance_0_avalon_master_address;
  input            mkAvalonWrapperInstance_0_avalon_master_read;
  input            mkAvalonWrapperInstance_0_avalon_master_write;
  input   [ 31: 0] mkAvalonWrapperInstance_0_avalon_master_writedata;
  input            mkAvalonWrapperInstance_0_granted_jtag_uart_0_avalon_jtag_slave;
  input            mkAvalonWrapperInstance_0_qualified_request_jtag_uart_0_avalon_jtag_slave;
  input            mkAvalonWrapperInstance_0_read_data_valid_jtag_uart_0_avalon_jtag_slave;
  input            mkAvalonWrapperInstance_0_requests_jtag_uart_0_avalon_jtag_slave;
  input            reset_n;

  reg              active_and_waiting_last_time;
  reg     [ 31: 0] mkAvalonWrapperInstance_0_avalon_master_address_last_time;
  wire    [ 31: 0] mkAvalonWrapperInstance_0_avalon_master_address_to_slave;
  reg              mkAvalonWrapperInstance_0_avalon_master_read_last_time;
  wire    [ 31: 0] mkAvalonWrapperInstance_0_avalon_master_readdata;
  wire             mkAvalonWrapperInstance_0_avalon_master_readdatavalid;
  wire             mkAvalonWrapperInstance_0_avalon_master_run;
  wire             mkAvalonWrapperInstance_0_avalon_master_waitrequest;
  reg              mkAvalonWrapperInstance_0_avalon_master_write_last_time;
  reg     [ 31: 0] mkAvalonWrapperInstance_0_avalon_master_writedata_last_time;
  wire             mkAvalonWrapperInstance_0_latency_counter;
  wire             pre_flush_mkAvalonWrapperInstance_0_avalon_master_readdatavalid;
  wire             r_0;
  //r_0 master_run cascaded wait assignment, which is an e_assign
  assign r_0 = 1 & (mkAvalonWrapperInstance_0_qualified_request_jtag_uart_0_avalon_jtag_slave | ~mkAvalonWrapperInstance_0_requests_jtag_uart_0_avalon_jtag_slave) & ((~mkAvalonWrapperInstance_0_qualified_request_jtag_uart_0_avalon_jtag_slave | ~(mkAvalonWrapperInstance_0_avalon_master_read | mkAvalonWrapperInstance_0_avalon_master_write) | (1 & ~jtag_uart_0_avalon_jtag_slave_waitrequest_from_sa & (mkAvalonWrapperInstance_0_avalon_master_read | mkAvalonWrapperInstance_0_avalon_master_write)))) & ((~mkAvalonWrapperInstance_0_qualified_request_jtag_uart_0_avalon_jtag_slave | ~(mkAvalonWrapperInstance_0_avalon_master_read | mkAvalonWrapperInstance_0_avalon_master_write) | (1 & ~jtag_uart_0_avalon_jtag_slave_waitrequest_from_sa & (mkAvalonWrapperInstance_0_avalon_master_read | mkAvalonWrapperInstance_0_avalon_master_write))));

  //cascaded wait assignment, which is an e_assign
  assign mkAvalonWrapperInstance_0_avalon_master_run = r_0;

  //optimize select-logic by passing only those address bits which matter.
  assign mkAvalonWrapperInstance_0_avalon_master_address_to_slave = {29'b0,
    mkAvalonWrapperInstance_0_avalon_master_address[2 : 0]};

  //latent slave read data valids which may be flushed, which is an e_mux
  assign pre_flush_mkAvalonWrapperInstance_0_avalon_master_readdatavalid = 0;

  //latent slave read data valid which is not flushed, which is an e_mux
  assign mkAvalonWrapperInstance_0_avalon_master_readdatavalid = 0 |
    pre_flush_mkAvalonWrapperInstance_0_avalon_master_readdatavalid |
    mkAvalonWrapperInstance_0_read_data_valid_jtag_uart_0_avalon_jtag_slave;

  //mkAvalonWrapperInstance_0/avalon_master readdata mux, which is an e_mux
  assign mkAvalonWrapperInstance_0_avalon_master_readdata = jtag_uart_0_avalon_jtag_slave_readdata_from_sa;

  //actual waitrequest port, which is an e_assign
  assign mkAvalonWrapperInstance_0_avalon_master_waitrequest = ~mkAvalonWrapperInstance_0_avalon_master_run;

  //latent max counter, which is an e_assign
  assign mkAvalonWrapperInstance_0_latency_counter = 0;


//synthesis translate_off
//////////////// SIMULATION-ONLY CONTENTS
  //mkAvalonWrapperInstance_0_avalon_master_address check against wait, which is an e_register
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          mkAvalonWrapperInstance_0_avalon_master_address_last_time <= 0;
      else 
        mkAvalonWrapperInstance_0_avalon_master_address_last_time <= mkAvalonWrapperInstance_0_avalon_master_address;
    end


  //mkAvalonWrapperInstance_0/avalon_master waited last time, which is an e_register
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          active_and_waiting_last_time <= 0;
      else 
        active_and_waiting_last_time <= mkAvalonWrapperInstance_0_avalon_master_waitrequest & (mkAvalonWrapperInstance_0_avalon_master_read | mkAvalonWrapperInstance_0_avalon_master_write);
    end


  //mkAvalonWrapperInstance_0_avalon_master_address matches last port_name, which is an e_process
  always @(posedge clk)
    begin
      if (active_and_waiting_last_time & (mkAvalonWrapperInstance_0_avalon_master_address != mkAvalonWrapperInstance_0_avalon_master_address_last_time))
        begin
          $write("%0d ns: mkAvalonWrapperInstance_0_avalon_master_address did not heed wait!!!", $time);
          $stop;
        end
    end


  //mkAvalonWrapperInstance_0_avalon_master_read check against wait, which is an e_register
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          mkAvalonWrapperInstance_0_avalon_master_read_last_time <= 0;
      else 
        mkAvalonWrapperInstance_0_avalon_master_read_last_time <= mkAvalonWrapperInstance_0_avalon_master_read;
    end


  //mkAvalonWrapperInstance_0_avalon_master_read matches last port_name, which is an e_process
  always @(posedge clk)
    begin
      if (active_and_waiting_last_time & (mkAvalonWrapperInstance_0_avalon_master_read != mkAvalonWrapperInstance_0_avalon_master_read_last_time))
        begin
          $write("%0d ns: mkAvalonWrapperInstance_0_avalon_master_read did not heed wait!!!", $time);
          $stop;
        end
    end


  //mkAvalonWrapperInstance_0_avalon_master_write check against wait, which is an e_register
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          mkAvalonWrapperInstance_0_avalon_master_write_last_time <= 0;
      else 
        mkAvalonWrapperInstance_0_avalon_master_write_last_time <= mkAvalonWrapperInstance_0_avalon_master_write;
    end


  //mkAvalonWrapperInstance_0_avalon_master_write matches last port_name, which is an e_process
  always @(posedge clk)
    begin
      if (active_and_waiting_last_time & (mkAvalonWrapperInstance_0_avalon_master_write != mkAvalonWrapperInstance_0_avalon_master_write_last_time))
        begin
          $write("%0d ns: mkAvalonWrapperInstance_0_avalon_master_write did not heed wait!!!", $time);
          $stop;
        end
    end


  //mkAvalonWrapperInstance_0_avalon_master_writedata check against wait, which is an e_register
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          mkAvalonWrapperInstance_0_avalon_master_writedata_last_time <= 0;
      else 
        mkAvalonWrapperInstance_0_avalon_master_writedata_last_time <= mkAvalonWrapperInstance_0_avalon_master_writedata;
    end


  //mkAvalonWrapperInstance_0_avalon_master_writedata matches last port_name, which is an e_process
  always @(posedge clk)
    begin
      if (active_and_waiting_last_time & (mkAvalonWrapperInstance_0_avalon_master_writedata != mkAvalonWrapperInstance_0_avalon_master_writedata_last_time) & mkAvalonWrapperInstance_0_avalon_master_write)
        begin
          $write("%0d ns: mkAvalonWrapperInstance_0_avalon_master_writedata did not heed wait!!!", $time);
          $stop;
        end
    end



//////////////// END SIMULATION-ONLY CONTENTS

//synthesis translate_on

endmodule



// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

module avalon_jtag_reset_clk_0_domain_synch_module (
                                                     // inputs:
                                                      clk,
                                                      data_in,
                                                      reset_n,

                                                     // outputs:
                                                      data_out
                                                   )
;

  output           data_out;
  input            clk;
  input            data_in;
  input            reset_n;

  reg              data_in_d1 /* synthesis ALTERA_ATTRIBUTE = "{-from \"*\"} CUT=ON ; PRESERVE_REGISTER=ON ; SUPPRESS_DA_RULE_INTERNAL=R101"  */;
  reg              data_out /* synthesis ALTERA_ATTRIBUTE = "PRESERVE_REGISTER=ON ; SUPPRESS_DA_RULE_INTERNAL=R101"  */;
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          data_in_d1 <= 0;
      else 
        data_in_d1 <= data_in;
    end


  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
          data_out <= 0;
      else 
        data_out <= data_in_d1;
    end



endmodule



// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

module avalon_jtag (
                     // 1) global signals:
                      clk_0,
                      reset_n,

                     // the_mkAvalonWrapperInstance_0
                      masterInverseWires_address_to_the_mkAvalonWrapperInstance_0,
                      masterInverseWires_read_to_the_mkAvalonWrapperInstance_0,
                      masterInverseWires_readdata_from_the_mkAvalonWrapperInstance_0,
                      masterInverseWires_readdatavalid_from_the_mkAvalonWrapperInstance_0,
                      masterInverseWires_waitrequest_from_the_mkAvalonWrapperInstance_0,
                      masterInverseWires_write_to_the_mkAvalonWrapperInstance_0,
                      masterInverseWires_writedata_to_the_mkAvalonWrapperInstance_0
                   )
;

  output  [ 31: 0] masterInverseWires_readdata_from_the_mkAvalonWrapperInstance_0;
  output           masterInverseWires_readdatavalid_from_the_mkAvalonWrapperInstance_0;
  output           masterInverseWires_waitrequest_from_the_mkAvalonWrapperInstance_0;
  input            clk_0;
  input   [ 31: 0] masterInverseWires_address_to_the_mkAvalonWrapperInstance_0;
  input            masterInverseWires_read_to_the_mkAvalonWrapperInstance_0;
  input            masterInverseWires_write_to_the_mkAvalonWrapperInstance_0;
  input   [ 31: 0] masterInverseWires_writedata_to_the_mkAvalonWrapperInstance_0;
  input            reset_n;

  wire             clk_0_reset_n;
  wire             d1_jtag_uart_0_avalon_jtag_slave_end_xfer;
  wire             jtag_uart_0_avalon_jtag_slave_address;
  wire             jtag_uart_0_avalon_jtag_slave_chipselect;
  wire             jtag_uart_0_avalon_jtag_slave_dataavailable;
  wire             jtag_uart_0_avalon_jtag_slave_dataavailable_from_sa;
  wire             jtag_uart_0_avalon_jtag_slave_irq;
  wire             jtag_uart_0_avalon_jtag_slave_read_n;
  wire    [ 31: 0] jtag_uart_0_avalon_jtag_slave_readdata;
  wire    [ 31: 0] jtag_uart_0_avalon_jtag_slave_readdata_from_sa;
  wire             jtag_uart_0_avalon_jtag_slave_readyfordata;
  wire             jtag_uart_0_avalon_jtag_slave_readyfordata_from_sa;
  wire             jtag_uart_0_avalon_jtag_slave_reset_n;
  wire             jtag_uart_0_avalon_jtag_slave_waitrequest;
  wire             jtag_uart_0_avalon_jtag_slave_waitrequest_from_sa;
  wire             jtag_uart_0_avalon_jtag_slave_write_n;
  wire    [ 31: 0] jtag_uart_0_avalon_jtag_slave_writedata;
  wire    [ 31: 0] masterInverseWires_readdata_from_the_mkAvalonWrapperInstance_0;
  wire             masterInverseWires_readdatavalid_from_the_mkAvalonWrapperInstance_0;
  wire             masterInverseWires_waitrequest_from_the_mkAvalonWrapperInstance_0;
  wire    [ 31: 0] mkAvalonWrapperInstance_0_avalon_master_address;
  wire    [ 31: 0] mkAvalonWrapperInstance_0_avalon_master_address_to_slave;
  wire             mkAvalonWrapperInstance_0_avalon_master_read;
  wire    [ 31: 0] mkAvalonWrapperInstance_0_avalon_master_readdata;
  wire             mkAvalonWrapperInstance_0_avalon_master_readdatavalid;
  wire             mkAvalonWrapperInstance_0_avalon_master_waitrequest;
  wire             mkAvalonWrapperInstance_0_avalon_master_write;
  wire    [ 31: 0] mkAvalonWrapperInstance_0_avalon_master_writedata;
  wire             mkAvalonWrapperInstance_0_granted_jtag_uart_0_avalon_jtag_slave;
  wire             mkAvalonWrapperInstance_0_latency_counter;
  wire             mkAvalonWrapperInstance_0_qualified_request_jtag_uart_0_avalon_jtag_slave;
  wire             mkAvalonWrapperInstance_0_read_data_valid_jtag_uart_0_avalon_jtag_slave;
  wire             mkAvalonWrapperInstance_0_requests_jtag_uart_0_avalon_jtag_slave;
  wire             reset_n_sources;
  jtag_uart_0_avalon_jtag_slave_arbitrator the_jtag_uart_0_avalon_jtag_slave
    (
      .clk                                                                       (clk_0),
      .d1_jtag_uart_0_avalon_jtag_slave_end_xfer                                 (d1_jtag_uart_0_avalon_jtag_slave_end_xfer),
      .jtag_uart_0_avalon_jtag_slave_address                                     (jtag_uart_0_avalon_jtag_slave_address),
      .jtag_uart_0_avalon_jtag_slave_chipselect                                  (jtag_uart_0_avalon_jtag_slave_chipselect),
      .jtag_uart_0_avalon_jtag_slave_dataavailable                               (jtag_uart_0_avalon_jtag_slave_dataavailable),
      .jtag_uart_0_avalon_jtag_slave_dataavailable_from_sa                       (jtag_uart_0_avalon_jtag_slave_dataavailable_from_sa),
      .jtag_uart_0_avalon_jtag_slave_read_n                                      (jtag_uart_0_avalon_jtag_slave_read_n),
      .jtag_uart_0_avalon_jtag_slave_readdata                                    (jtag_uart_0_avalon_jtag_slave_readdata),
      .jtag_uart_0_avalon_jtag_slave_readdata_from_sa                            (jtag_uart_0_avalon_jtag_slave_readdata_from_sa),
      .jtag_uart_0_avalon_jtag_slave_readyfordata                                (jtag_uart_0_avalon_jtag_slave_readyfordata),
      .jtag_uart_0_avalon_jtag_slave_readyfordata_from_sa                        (jtag_uart_0_avalon_jtag_slave_readyfordata_from_sa),
      .jtag_uart_0_avalon_jtag_slave_reset_n                                     (jtag_uart_0_avalon_jtag_slave_reset_n),
      .jtag_uart_0_avalon_jtag_slave_waitrequest                                 (jtag_uart_0_avalon_jtag_slave_waitrequest),
      .jtag_uart_0_avalon_jtag_slave_waitrequest_from_sa                         (jtag_uart_0_avalon_jtag_slave_waitrequest_from_sa),
      .jtag_uart_0_avalon_jtag_slave_write_n                                     (jtag_uart_0_avalon_jtag_slave_write_n),
      .jtag_uart_0_avalon_jtag_slave_writedata                                   (jtag_uart_0_avalon_jtag_slave_writedata),
      .mkAvalonWrapperInstance_0_avalon_master_address_to_slave                  (mkAvalonWrapperInstance_0_avalon_master_address_to_slave),
      .mkAvalonWrapperInstance_0_avalon_master_read                              (mkAvalonWrapperInstance_0_avalon_master_read),
      .mkAvalonWrapperInstance_0_avalon_master_write                             (mkAvalonWrapperInstance_0_avalon_master_write),
      .mkAvalonWrapperInstance_0_avalon_master_writedata                         (mkAvalonWrapperInstance_0_avalon_master_writedata),
      .mkAvalonWrapperInstance_0_granted_jtag_uart_0_avalon_jtag_slave           (mkAvalonWrapperInstance_0_granted_jtag_uart_0_avalon_jtag_slave),
      .mkAvalonWrapperInstance_0_latency_counter                                 (mkAvalonWrapperInstance_0_latency_counter),
      .mkAvalonWrapperInstance_0_qualified_request_jtag_uart_0_avalon_jtag_slave (mkAvalonWrapperInstance_0_qualified_request_jtag_uart_0_avalon_jtag_slave),
      .mkAvalonWrapperInstance_0_read_data_valid_jtag_uart_0_avalon_jtag_slave   (mkAvalonWrapperInstance_0_read_data_valid_jtag_uart_0_avalon_jtag_slave),
      .mkAvalonWrapperInstance_0_requests_jtag_uart_0_avalon_jtag_slave          (mkAvalonWrapperInstance_0_requests_jtag_uart_0_avalon_jtag_slave),
      .reset_n                                                                   (clk_0_reset_n)
    );

  jtag_uart_0 the_jtag_uart_0
    (
      .av_address     (jtag_uart_0_avalon_jtag_slave_address),
      .av_chipselect  (jtag_uart_0_avalon_jtag_slave_chipselect),
      .av_irq         (jtag_uart_0_avalon_jtag_slave_irq),
      .av_read_n      (jtag_uart_0_avalon_jtag_slave_read_n),
      .av_readdata    (jtag_uart_0_avalon_jtag_slave_readdata),
      .av_waitrequest (jtag_uart_0_avalon_jtag_slave_waitrequest),
      .av_write_n     (jtag_uart_0_avalon_jtag_slave_write_n),
      .av_writedata   (jtag_uart_0_avalon_jtag_slave_writedata),
      .clk            (clk_0),
      .dataavailable  (jtag_uart_0_avalon_jtag_slave_dataavailable),
      .readyfordata   (jtag_uart_0_avalon_jtag_slave_readyfordata),
      .rst_n          (jtag_uart_0_avalon_jtag_slave_reset_n)
    );

  mkAvalonWrapperInstance_0_avalon_master_arbitrator the_mkAvalonWrapperInstance_0_avalon_master
    (
      .clk                                                                       (clk_0),
      .d1_jtag_uart_0_avalon_jtag_slave_end_xfer                                 (d1_jtag_uart_0_avalon_jtag_slave_end_xfer),
      .jtag_uart_0_avalon_jtag_slave_readdata_from_sa                            (jtag_uart_0_avalon_jtag_slave_readdata_from_sa),
      .jtag_uart_0_avalon_jtag_slave_waitrequest_from_sa                         (jtag_uart_0_avalon_jtag_slave_waitrequest_from_sa),
      .mkAvalonWrapperInstance_0_avalon_master_address                           (mkAvalonWrapperInstance_0_avalon_master_address),
      .mkAvalonWrapperInstance_0_avalon_master_address_to_slave                  (mkAvalonWrapperInstance_0_avalon_master_address_to_slave),
      .mkAvalonWrapperInstance_0_avalon_master_read                              (mkAvalonWrapperInstance_0_avalon_master_read),
      .mkAvalonWrapperInstance_0_avalon_master_readdata                          (mkAvalonWrapperInstance_0_avalon_master_readdata),
      .mkAvalonWrapperInstance_0_avalon_master_readdatavalid                     (mkAvalonWrapperInstance_0_avalon_master_readdatavalid),
      .mkAvalonWrapperInstance_0_avalon_master_waitrequest                       (mkAvalonWrapperInstance_0_avalon_master_waitrequest),
      .mkAvalonWrapperInstance_0_avalon_master_write                             (mkAvalonWrapperInstance_0_avalon_master_write),
      .mkAvalonWrapperInstance_0_avalon_master_writedata                         (mkAvalonWrapperInstance_0_avalon_master_writedata),
      .mkAvalonWrapperInstance_0_granted_jtag_uart_0_avalon_jtag_slave           (mkAvalonWrapperInstance_0_granted_jtag_uart_0_avalon_jtag_slave),
      .mkAvalonWrapperInstance_0_latency_counter                                 (mkAvalonWrapperInstance_0_latency_counter),
      .mkAvalonWrapperInstance_0_qualified_request_jtag_uart_0_avalon_jtag_slave (mkAvalonWrapperInstance_0_qualified_request_jtag_uart_0_avalon_jtag_slave),
      .mkAvalonWrapperInstance_0_read_data_valid_jtag_uart_0_avalon_jtag_slave   (mkAvalonWrapperInstance_0_read_data_valid_jtag_uart_0_avalon_jtag_slave),
      .mkAvalonWrapperInstance_0_requests_jtag_uart_0_avalon_jtag_slave          (mkAvalonWrapperInstance_0_requests_jtag_uart_0_avalon_jtag_slave),
      .reset_n                                                                   (clk_0_reset_n)
    );

  //reset is asserted asynchronously and deasserted synchronously
  avalon_jtag_reset_clk_0_domain_synch_module avalon_jtag_reset_clk_0_domain_synch
    (
      .clk      (clk_0),
      .data_in  (1'b1),
      .data_out (clk_0_reset_n),
      .reset_n  (reset_n_sources)
    );

  //reset sources mux, which is an e_mux
  assign reset_n_sources = ~(~reset_n |
    0);

  mkAvalonWrapperInstance_0 the_mkAvalonWrapperInstance_0
    (
      .CLK                              (clk_0),
      .RST_N                            (clk_0_reset_n),
      .masterInverseWires_address       (masterInverseWires_address_to_the_mkAvalonWrapperInstance_0),
      .masterInverseWires_read          (masterInverseWires_read_to_the_mkAvalonWrapperInstance_0),
      .masterInverseWires_readdata      (masterInverseWires_readdata_from_the_mkAvalonWrapperInstance_0),
      .masterInverseWires_readdatavalid (masterInverseWires_readdatavalid_from_the_mkAvalonWrapperInstance_0),
      .masterInverseWires_waitrequest   (masterInverseWires_waitrequest_from_the_mkAvalonWrapperInstance_0),
      .masterInverseWires_write         (masterInverseWires_write_to_the_mkAvalonWrapperInstance_0),
      .masterInverseWires_writedata     (masterInverseWires_writedata_to_the_mkAvalonWrapperInstance_0),
      .masterWires_address              (mkAvalonWrapperInstance_0_avalon_master_address),
      .masterWires_read                 (mkAvalonWrapperInstance_0_avalon_master_read),
      .masterWires_readdata             (mkAvalonWrapperInstance_0_avalon_master_readdata),
      .masterWires_readdatavalid        (mkAvalonWrapperInstance_0_avalon_master_readdatavalid),
      .masterWires_waitrequest          (mkAvalonWrapperInstance_0_avalon_master_waitrequest),
      .masterWires_write                (mkAvalonWrapperInstance_0_avalon_master_write),
      .masterWires_writedata            (mkAvalonWrapperInstance_0_avalon_master_writedata)
    );


endmodule


//synthesis translate_off



// <ALTERA_NOTE> CODE INSERTED BETWEEN HERE

// AND HERE WILL BE PRESERVED </ALTERA_NOTE>


// If user logic components use Altsync_Ram with convert_hex2ver.dll,
// set USE_convert_hex2ver in the user comments section above

// `ifdef USE_convert_hex2ver
// `else
// `define NO_PLI 1
// `endif

`include "/opt/altera9.1/quartus/eda/sim_lib/altera_mf.v"
`include "/opt/altera9.1/quartus/eda/sim_lib/220model.v"
`include "/opt/altera9.1/quartus/eda/sim_lib/sgate.v"
`include "mkAvalonWrapperInstance.v"
`include "mkAvalonWrapperInstance_0.v"
`include "jtag_uart_0.v"

`timescale 1ns / 1ps

module test_bench 
;


  wire             clk;
  reg              clk_0;
  wire             jtag_uart_0_avalon_jtag_slave_dataavailable_from_sa;
  wire             jtag_uart_0_avalon_jtag_slave_irq;
  wire             jtag_uart_0_avalon_jtag_slave_readyfordata_from_sa;
  wire    [ 31: 0] masterInverseWires_address_to_the_mkAvalonWrapperInstance_0;
  wire             masterInverseWires_read_to_the_mkAvalonWrapperInstance_0;
  wire    [ 31: 0] masterInverseWires_readdata_from_the_mkAvalonWrapperInstance_0;
  wire             masterInverseWires_readdatavalid_from_the_mkAvalonWrapperInstance_0;
  wire             masterInverseWires_waitrequest_from_the_mkAvalonWrapperInstance_0;
  wire             masterInverseWires_write_to_the_mkAvalonWrapperInstance_0;
  wire    [ 31: 0] masterInverseWires_writedata_to_the_mkAvalonWrapperInstance_0;
  reg              reset_n;


// <ALTERA_NOTE> CODE INSERTED BETWEEN HERE
//  add your signals and additional architecture here
// AND HERE WILL BE PRESERVED </ALTERA_NOTE>

  //Set us up the Dut
  avalon_jtag DUT
    (
      .clk_0                                                               (clk_0),
      .masterInverseWires_address_to_the_mkAvalonWrapperInstance_0         (masterInverseWires_address_to_the_mkAvalonWrapperInstance_0),
      .masterInverseWires_read_to_the_mkAvalonWrapperInstance_0            (masterInverseWires_read_to_the_mkAvalonWrapperInstance_0),
      .masterInverseWires_readdata_from_the_mkAvalonWrapperInstance_0      (masterInverseWires_readdata_from_the_mkAvalonWrapperInstance_0),
      .masterInverseWires_readdatavalid_from_the_mkAvalonWrapperInstance_0 (masterInverseWires_readdatavalid_from_the_mkAvalonWrapperInstance_0),
      .masterInverseWires_waitrequest_from_the_mkAvalonWrapperInstance_0   (masterInverseWires_waitrequest_from_the_mkAvalonWrapperInstance_0),
      .masterInverseWires_write_to_the_mkAvalonWrapperInstance_0           (masterInverseWires_write_to_the_mkAvalonWrapperInstance_0),
      .masterInverseWires_writedata_to_the_mkAvalonWrapperInstance_0       (masterInverseWires_writedata_to_the_mkAvalonWrapperInstance_0),
      .reset_n                                                             (reset_n)
    );

  initial
    clk_0 = 1'b0;
  always
    #4 clk_0 <= ~clk_0;
  
  initial 
    begin
      reset_n <= 0;
      #80 reset_n <= 1;
    end

endmodule


//synthesis translate_on