-- DISCLAIMER OF LIABILITY
--
-- This text/file contains proprietary, confidential
-- information of Xilinx, Inc., is distributed under license
-- from Xilinx, Inc., and may be used, copied and/or
-- disclosed only pursuant to the terms of a valid license
-- agreement with Xilinx, Inc. Xilinx hereby grants you
-- a license to use this text/file solely for design, simulation,
-- implementation and creation of design files limited
-- to Xilinx devices or technologies. Use with non-Xilinx
-- devices or technologies is expressly prohibited and
-- immediately terminates your license unless covered by
-- a separate agreement.
--
-- Xilinx is providing this design, code, or information
-- "as is" solely for use in developing programs and
-- solutions for Xilinx devices. By providing this design,
-- code, or information as one possible implementation of
-- this feature, application or standard, Xilinx is making no
-- representation that this implementation is free from any
-- claims of infringement. You are responsible for
-- obtaining any rights you may require for your implementation.
-- Xilinx expressly disclaims any warranty whatsoever with
-- respect to the adequacy of the implementation, including
-- but not limited to any warranties or representations that this
-- implementation is free from claims of infringement, implied
-- warranties of merchantability or fitness for a particular
-- purpose.
--
-- Xilinx products are not intended for use in life support
-- appliances, devices, or systems. Use in such applications are
-- expressly prohibited.
--
--
-- Copyright (c) 2001, 2002, 2003, 2004, 2005, 2007 Xilinx, Inc. All rights reserved.
--
-- This copyright and support notice must be retained as part
-- of this text at all times.
--
-- Filename: pci_exp_64b_app.vhd
--
-- Description:  PCI Express Endpoint Core 32 bit interface sample application
--               design.
--
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;


entity pci_exp_64b_app is

port  (

  -- Common

  trn_clk                   : in std_logic;
  trn_reset_n               : in std_logic;
  trn_lnk_up_n              : in std_logic;

  -- Tx 10

  trn_td                    : out std_logic_vector(63 downto 0);
  trn_trem_n                : out std_logic_vector(7 downto 0);
  trn_tsof_n                : out std_logic;
  trn_teof_n                : out std_logic;
  trn_tsrc_rdy_n            : out std_logic;
  trn_tdst_rdy_n            : in std_logic;
  trn_tsrc_dsc_n            : out std_logic;
  trn_terrfwd_n             : out std_logic;
  trn_tdst_dsc_n            : in std_logic;
  trn_tbuf_av               : in std_logic_vector(2 downto 0);

  -- Rx 15

  trn_rd                    : in std_logic_vector(63 downto 0);
  trn_rrem_n                : in std_logic_vector(7 downto 0);
  trn_rsof_n                : in std_logic;
  trn_reof_n                : in std_logic;
  trn_rsrc_rdy_n            : in std_logic;
  trn_rsrc_dsc_n            : in std_logic;
  trn_rdst_rdy_n            : out std_logic;
  trn_rerrfwd_n             : in std_logic;
  trn_rnp_ok_n              : out std_logic;
  trn_rbar_hit_n            : in std_logic_vector(6 downto 0);
  trn_rfc_nph_av            : in std_logic_vector(7 downto 0);
  trn_rfc_npd_av            : in std_logic_vector(11 downto 0);
  trn_rfc_ph_av             : in std_logic_vector(7 downto 0);
  trn_rfc_pd_av             : in std_logic_vector(11 downto 0);
  trn_rcpl_streaming_n      : out std_logic;

  
  led_switch     : out std_logic;
  
  
  -- Host (CFG) Interface 
  
  

  cfg_do                    : in std_logic_vector(31 downto 0);
  cfg_di                    : out std_logic_vector(31 downto 0);
  cfg_byte_en_n             : out std_logic_vector(3 downto 0);
  cfg_dwaddr                : out std_logic_vector(9 downto 0);
  cfg_rd_wr_done_n          : in std_logic;
  cfg_wr_en_n               : out std_logic;
  cfg_rd_en_n               : out std_logic;
  cfg_err_cor_n             : out std_logic;
  cfg_err_ur_n              : out std_logic;
  cfg_err_ecrc_n            : out std_logic;
  cfg_err_cpl_timeout_n     : out std_logic;
  cfg_err_cpl_abort_n       : out std_logic;
  cfg_err_cpl_unexpect_n    : out std_logic;
  cfg_err_posted_n          : out std_logic;
  cfg_interrupt_n           : out std_logic;
  cfg_interrupt_rdy_n       : in std_logic;
  cfg_turnoff_ok_n 			 : out std_logic;
  cfg_to_turnoff_n          : in std_logic;
  cfg_pm_wake_n             : out std_logic;
  cfg_pcie_link_state_n     : in std_logic_vector(2 downto 0);
  cfg_trn_pending_n         : out std_logic;
  cfg_err_tlp_cpl_header    : out std_logic_vector(47 downto 0);
  cfg_bus_number            : in std_logic_vector(7 downto 0);
  cfg_device_number         : in std_logic_vector(4 downto 0);
  cfg_function_number       : in std_logic_vector(2 downto 0);
  cfg_status                : in std_logic_vector(15 downto 0);
  cfg_command               : in std_logic_vector(15 downto 0);
  cfg_dstatus               : in std_logic_vector(15 downto 0);
  cfg_dcommand              : in std_logic_vector(15 downto 0);
  cfg_lstatus               : in std_logic_vector(15 downto 0);
  cfg_lcommand              : in std_logic_vector(15 downto 0)
    
);
end pci_exp_64b_app;

architecture rtl of pci_exp_64b_app is

component BMD is

port (

  trn_clk                : in std_logic;
  trn_reset_n            : in std_logic;
  trn_lnk_up_n           : in std_logic;

  --Transmission 8 signals
  trn_td                 : out std_logic_vector((64 - 1) downto 0);
  trn_trem_n             : out std_logic_vector(7 downto 0);
  trn_tsof_n             : out std_logic;
  trn_teof_n             : out std_logic;
  trn_tsrc_rdy_n         : out std_logic;
  trn_tsrc_dsc_n         : out std_logic;
  trn_tdst_rdy_n         : in std_logic;
  trn_tdst_dsc_n         : in std_logic;
  
  
  led_switch     : out std_logic;

  --Recieve 8 signals
  trn_rd                 : in std_logic_vector((64 - 1) downto 0);
  trn_rrem_n             : in std_logic_vector(7 downto 0);
  trn_rsof_n             : in std_logic;
  trn_reof_n             : in std_logic;
  trn_rsrc_rdy_n         : in std_logic;
  trn_rsrc_dsc_n         : in std_logic;
  trn_rdst_rdy_n         : out std_logic;
  trn_rbar_hit_n	 : in std_logic_vector (6 downto 0);

  --Config 7 signals
  cfg_interrupt_n	 : out std_logic;
  cfg_interrupt_rdy_n    : in std_logic;
  cfg_completer_id       : in std_logic_vector(15 downto 0);
  cfg_ext_tag_en	 : in std_logic;
  cfg_bus_mstr_enable    : in std_logic;
  cfg_max_payload_size   : in std_logic_vector(2 downto 0);
  cfg_max_rd_req_size    : in std_logic_vector(2 downto 0)
);

end component;

-- Local wires 

signal cfg_completer_id       : std_logic_vector(15 downto 0);
signal cfg_bus_mstr_enable    : std_logic;
signal cfg_ext_tag_en	      : std_logic;
signal cfg_max_payload_size   : std_logic_vector(2 downto 0);
signal cfg_max_rd_req_size    : std_logic_vector(2 downto 0);

begin 

  -- Core input tie-offs

  trn_rnp_ok_n              <= '0';
  trn_rcpl_streaming_n      <= '1'; 
  trn_terrfwd_n             <= '1';

  cfg_err_cor_n             <= '1';
  cfg_err_ur_n              <= '1';
  cfg_err_ecrc_n            <= '1';
  cfg_err_cpl_timeout_n     <= '1';
  cfg_err_cpl_abort_n       <= '1';
  cfg_err_cpl_unexpect_n    <= '1';
  cfg_err_posted_n          <= '0';
  cfg_pm_wake_n             <= '1';
  cfg_trn_pending_n         <= '1';
  cfg_dwaddr                <= (others => '0');
  cfg_err_tlp_cpl_header    <= (others => '0');
  cfg_di                    <= (others => '0');
  cfg_byte_en_n             <= X"F"; -- 4-bit bus
  cfg_wr_en_n               <= '1';
  cfg_rd_en_n               <= '1';
  cfg_completer_id          <= (cfg_bus_number &
                                cfg_device_number &
                                cfg_function_number);
  cfg_bus_mstr_enable       <= cfg_command(2);
  cfg_ext_tag_en	    <= cfg_dcommand(8);
  cfg_max_payload_size	    <= cfg_dcommand(7 downto 5);
  cfg_max_rd_req_size	    <= cfg_dcommand(14 downto 12);
  cfg_turnoff_ok_n 			<= '0';


-- Programmable I/O Module

BMD_interface : BMD 

port map (

  trn_clk  =>  trn_clk,                       -- I
  trn_reset_n  =>  trn_reset_n,               -- I
  trn_lnk_up_n  =>  trn_lnk_up_n,             -- I

  trn_td  => trn_td,                          -- O (63:0)
  trn_tsof_n  => trn_tsof_n,
  trn_trem_n  => trn_trem_n,
  trn_teof_n  => trn_teof_n,                  -- O
  trn_tsrc_rdy_n  => trn_tsrc_rdy_n,          -- O
  trn_tsrc_dsc_n  => trn_tsrc_dsc_n,          -- O
  trn_tdst_rdy_n  => trn_tdst_rdy_n,          -- I
  trn_tdst_dsc_n  => trn_tdst_dsc_n,          -- I

  trn_rd  => trn_rd ,                         -- I (63:0)
  trn_rrem_n  => trn_rrem_n,
  trn_rsof_n  => trn_rsof_n,                  -- I
  trn_reof_n  => trn_reof_n,                  -- I
  trn_rsrc_rdy_n  => trn_rsrc_rdy_n,          -- I
  trn_rsrc_dsc_n  => trn_rsrc_dsc_n,          -- I
  trn_rbar_hit_n => trn_rbar_hit_n,           -- I (6:0)
  trn_rdst_rdy_n  => trn_rdst_rdy_n,          -- O
  
  led_switch  => led_switch,

  cfg_interrupt_n => cfg_interrupt_n,	      -- O
  cfg_interrupt_rdy_n => cfg_interrupt_rdy_n,  -- I
  cfg_completer_id  => cfg_completer_id,      -- I (15:0)
  cfg_ext_tag_en => cfg_ext_tag_en,	      -- I
  cfg_bus_mstr_enable => cfg_bus_mstr_enable, -- I
  cfg_max_payload_size => cfg_max_payload_size, -- I (2:0)
  cfg_max_rd_req_size => cfg_max_rd_req_size  -- I (2:0)

);

end; -- pci_exp_64b_app
