-------------------------------------------------------------------------------
-- Title      : channel wrapper
-- Project    : PCI Express Hardware Channel
-------------------------------------------------------------------------------
-- File       : channel.vhd
-- Author     : Wang, Liang  <liang.wang@intel.com>
-- Company    : CTL Beijing
-- Created    : 2008-05-29
-- Last update: 2008-06-13
-- Platform   : Xilinx ISE9.2(IP update4), ModelSim SE 6.2e
-- Targets    : XC5VLX110T-FF1136-1
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: a wrapper for subtle modules of PCIe channel. 
-------------------------------------------------------------------------------
-- Copyright (c) 2008 CTL Beijing
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2007-12-25  0.9      lwang12 Created
-- 2008-05-29  1.0      lwang12 Prepare code for release
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity channel is
  port (
    clk   : in std_logic;
    rst_n : in std_logic;

    -- LocalLink Tx
    trn_td         : out std_logic_vector(63 downto 0);
    trn_trem_n     : out std_logic_vector(7 downto 0);
    trn_tsof_n     : out std_logic;
    trn_teof_n     : out std_logic;
    trn_tsrc_dsc_n : out std_logic;
    trn_tsrc_rdy_n : out std_logic;
    trn_tdst_dsc_n : in  std_logic;
    trn_tdst_rdy_n : in  std_logic;

    -- LocalLink Rx
    trn_rd         : in  std_logic_vector(63 downto 0);
    trn_rrem_n     : in  std_logic_vector(7 downto 0);
    trn_rsof_n     : in  std_logic;
    trn_reof_n     : in  std_logic;
    trn_rsrc_rdy_n : in  std_logic;
    trn_rbar_hit_n : in  std_logic_vector(6 downto 0);
    trn_rdst_rdy_n : out std_logic;

    cfg_interrupt_n        : out std_logic;
    cfg_interrupt_rdy_n    : in  std_logic;
    cfg_interrupt_assert_n : out std_logic;
    cfg_completer_id       : in  std_logic_vector(15 downto 0);
    cfg_ext_tag_en         : in  std_logic;
    cfg_max_rd_req_size    : in  std_logic_vector(2 downto 0);
    cfg_max_payload_size   : in  std_logic_vector(2 downto 0);
    cfg_bus_mstr_enable    : in  std_logic;

    -- DMA signals
    ------ h2f ports
    dma_out_h2f_ready          : out std_logic;
    dma_out_h2f_fifo_ready     : out std_logic;
    dma_in_h2f_en              : in  std_logic;
    dma_in_h2f_fifo_ack        : in  std_logic;
    dma_in_h2f_paddr           : in  std_logic_vector(63 downto 0);
    dma_in_h2f_len             : in  std_logic_vector(31 downto 0);
    dma_out_h2f_fifo_data      : out std_logic_vector(63 downto 0);
    ------ f2h ports
    dma_out_f2h_ready          : out std_logic;
    dma_out_f2h_fifo_ready     : out std_logic;
    dma_in_f2h_en              : in  std_logic;
    dma_in_f2h_fifo_data_valid : in  std_logic;
    dma_in_f2h_paddr           : in  std_logic_vector(63 downto 0);
    dma_in_f2h_len             : in  std_logic_vector(31 downto 0);
    dma_in_f2h_fifo_data       : in  std_logic_vector(63 downto 0);

    -- regular CSR signals
    csr_out_rd_ready : out std_logic;
    csr_out_rd_done  : out std_logic;
    csr_out_rd_data  : out std_logic_vector(31 downto 0);
    csr_out_wr_ready : out std_logic;
    csr_in_rd_en     : in  std_logic;
    csr_in_rd_ack    : in  std_logic;
    csr_in_rd_index  : in  std_logic_vector(7 downto 0);
    csr_in_wr_en     : in  std_logic;
    csr_in_wr_data   : in  std_logic_vector(31 downto 0);
    csr_in_wr_index  : in  std_logic_vector(7 downto 0);

    -- system CSR signals 
    csr_out_h2f_reg0      : out std_logic_vector(31 downto 0);
    csr_in_f2h_reg0       : in  std_logic_vector(31 downto 0);
    csr_in_f2h_reg0_wr_en : in  std_logic;

    -- soft RST signals
    rst_init_req_rdy     : out std_logic;
    rst_init_req_en      : in  std_logic;
    rst_init_resp_rdy    : out std_logic;
    rst_init_resp_en     : in  std_logic;

    hw_chnl_rst          : out std_logic;
    
    rst_softrst_req_rdy  : out std_logic;
    rst_softrst_req_en   : in  std_logic;
    rst_softrst_resp_rdy : out std_logic;
    rst_softrst_resp_en  : in  std_logic;

    -- interrupt signals
    int_out_ready : out std_logic;
    int_in_en     : in  std_logic
    );
end channel;

architecture rtl of channel is

  component RST_CONTROLLER
    port (
      pcie_bar0_rst_sig    : in  std_logic;  -- reset signal raised by software
      pcie_bar0_rst_ack    : out std_logic;  -- tell software reset is done

      rst_init_req_rdy     : out std_logic;  -- we are ready to receive init request
      rst_init_req_en      : in  std_logic;  -- init signal from upper app
      rst_init_resp_rdy    : out std_logic;  -- signal upper app that init is done
      rst_init_resp_en     : in  std_logic;  -- upper app acknowledges receipt of response
    
      hw_chnl_rst_sig      : out std_logic;  -- signal other modules to init

      rst_softrst_req_rdy  : out std_logic;  -- notify upper app about sw reset
      rst_softrst_req_en   : in  std_logic;  -- upper app acknowledges receipt of signal
      rst_softrst_resp_rdy : out std_logic;  -- we are ready to accept response
      rst_softrst_resp_en  : in  std_logic;  -- upper app tells us that reset is done

      clk   : in std_logic;
      rst_n : in std_logic);
  end component;

  component DMA_CONTROLLER
    port(
      ------ ports to high-level, h2f ports
      dma_out_h2f_ready          : out std_logic;
      dma_out_h2f_fifo_ready     : out std_logic;
      dma_in_h2f_en              : in  std_logic;
      dma_in_h2f_fifo_ack        : in  std_logic;
      dma_in_h2f_paddr           : in  std_logic_vector(63 downto 0);
      dma_in_h2f_len             : in  std_logic_vector(31 downto 0);
      dma_out_h2f_fifo_data      : out std_logic_vector(63 downto 0);
      ------ ports to high-level, f2h ports
      dma_out_f2h_ready          : out std_logic;
      dma_out_f2h_fifo_ready     : out std_logic;
      dma_in_f2h_en              : in  std_logic;
      dma_in_f2h_fifo_data_valid : in  std_logic;
      dma_in_f2h_paddr           : in  std_logic_vector(63 downto 0);
      dma_in_f2h_len             : in  std_logic_vector(31 downto 0);
      dma_in_f2h_fifo_data       : in  std_logic_vector(63 downto 0);

      ------ ports with TX_ENGINE
      mwr_start_o   : out std_logic;
      mwr_addr_o    : out std_logic_vector(31 downto 0);
      mwr_addr_hi_o : out std_logic_vector(31 downto 0);
      mwr_len_o     : out std_logic_vector(31 downto 0);
      mwr_count_o   : out std_logic_vector(31 downto 0);

      mrd_start_o   : out std_logic;
      mrd_addr_o    : out std_logic_vector(31 downto 0);
      mrd_addr_hi_o : out std_logic_vector(31 downto 0);
      mrd_len_o     : out std_logic_vector(31 downto 0);
      mrd_count_o   : out std_logic_vector(31 downto 0);


      f2h_fifo_empty : out std_logic;
      f2h_fifo_valid : out std_logic;
      f2h_fifo_ren   : in  std_logic;
      dma_f2h_data   : out std_logic_vector(63 downto 0);
      dma_f2h_done   : in  std_logic;

      ------- ports with RX_ENGINE
      dma_h2f_data_len : out std_logic_vector(31 downto 0);
      dma_h2f_done     : in  std_logic;
      wr_data_full     : out std_logic;
      wr_data_fen      : in  std_logic;
      dma_h2f_data     : in  std_logic_vector(63 downto 0);


      cfg_max_rd_req_size  : in std_logic_vector(2 downto 0);
      cfg_max_payload_size : in std_logic_vector(2 downto 0);

      hw_chnl_rst : in std_logic;
      clk         : in std_logic;
      rst_n       : in std_logic
      );
  end component DMA_CONTROLLER;

  component INTR_CONTROLLER
    port (
      clk         : in std_logic;
      rst_n       : in std_logic;
      hw_chnl_rst : in std_logic;

      int_out_ready : out std_logic;
      int_in_en     : in  std_logic;

      intr_host_ack : in std_logic;

      cfg_interrupt_rdy_n    : in  std_logic;
      cfg_interrupt_assert_n : out std_logic;
      cfg_interrupt_n        : out std_logic);
  end component INTR_CONTROLLER;

  component CSR_CONTROLLER
    port (
      clk         : in std_logic;
      rst_n       : in std_logic;
      hw_chnl_rst : in std_logic;

      -- csr ports for PCIe TX/RX Engine
      pcie_csr_out_rd_ready : out std_logic;
      pcie_csr_out_rd_done  : out std_logic;
      pcie_csr_in_rd_en     : in  std_logic;
      pcie_csr_in_rd_ack    : in  std_logic;
      pcie_csr_out_rd_data  : out std_logic_vector((32 - 1) downto 0);
      pcie_csr_in_rd_index  : in  std_logic_vector((8 - 1) downto 0);
      pcie_csr_out_wr_ready : out std_logic;
      pcie_csr_in_wr_en     : in  std_logic;
      pcie_csr_in_wr_data   : in  std_logic_vector((32 - 1) downto 0);
      pcie_csr_in_wr_index  : in  std_logic_vector((8 - 1) downto 0);

      pcie_csr_in_h2f_reg0_wr_en : in  std_logic;
      pcie_csr_in_h2f_reg0       : in  std_logic_vector((32 - 1) downto 0);
      pcie_csr_out_f2h_reg0      : out std_logic_vector((32 - 1) downto 0);

      -- csr ports for hardware channel application use 
      csr_out_rd_ready : out std_logic;
      csr_out_rd_done  : out std_logic;
      csr_in_rd_en     : in  std_logic;
      csr_in_rd_ack    : in  std_logic;
      csr_out_rd_data  : out std_logic_vector((32 - 1) downto 0);
      csr_in_rd_index  : in  std_logic_vector((8 - 1) downto 0);
      csr_out_wr_ready : out std_logic;
      csr_in_wr_en     : in  std_logic;
      csr_in_wr_data   : in  std_logic_vector((32 - 1) downto 0);
      csr_in_wr_index  : in  std_logic_vector((8 - 1) downto 0);


      --------------system CSR SIGNAL-------------------
      csr_in_f2h_reg0_wr_en : in  std_logic;
      csr_out_h2f_reg0      : out std_logic_vector((32 - 1) downto 0);
      csr_in_f2h_reg0       : in  std_logic_vector((32 - 1) downto 0));
  end component CSR_CONTROLLER;

  component PCIE_BAR0
    port (
      clk   : in std_logic;
      rst_n : in std_logic;


      ------------------------------------------------------------
      -- Read Port
      ------------------------------------------------------------
      rd_a_i  : in  std_logic_vector(7 downto 0);
      rd_d_o  : out std_logic_vector(31 downto 0);
      ------------------------------------------------------------
      -- Write Port
      ------------------------------------------------------------
      wr_d_i  : in  std_logic_vector(31 downto 0);
      wr_en_i : in  std_logic;
      wr_a_i  : in  std_logic_vector(7 downto 0);



      pcie_csr_in_h2f_reg0_wr_en : out std_logic;
      pcie_csr_in_h2f_reg0       : out std_logic_vector((32 - 1) downto 0);
      pcie_csr_out_f2h_reg0      : in  std_logic_vector((32 - 1) downto 0);


      pcie_bar0_rst_sig : out std_logic;
      pcie_bar0_rst_ack : in  std_logic;

      intr_host_ack : out std_logic);
  end component PCIE_BAR0;

  component PCIE_RX_ENGINE
    port(
      clk         : in std_logic;
      rst_n       : in std_logic;
      hw_chnl_rst : in std_logic;

      -- From PCIe core 8
      trn_rd         : in  std_logic_vector(63 downto 0);
      trn_rrem_n     : in  std_logic_vector(7 downto 0);
      trn_rsof_n     : in  std_logic;
      trn_reof_n     : in  std_logic;
      trn_rsrc_rdy_n : in  std_logic;
      trn_rbar_hit_n : in  std_logic_vector(6 downto 0);
      trn_rdst_rdy_n : out std_logic;


      -- Hand shake with TX 2 Control 10 out info
      req_compl_o  : out std_logic;
      compl_done_i : in  std_logic;

      req_tc_o   : out std_logic_vector(2 downto 0);
      req_td_o   : out std_logic;
      req_ep_o   : out std_logic;
      req_attr_o : out std_logic_vector(1 downto 0);
      req_len_o  : out std_logic_vector(9 downto 0);
      req_rid_o  : out std_logic_vector(15 downto 0);
      req_tag_o  : out std_logic_vector(7 downto 0);
      req_be_o   : out std_logic_vector(3 downto 0);
      req_addr_o : out std_logic_vector(31 downto 0);
      req_bar_o  : out std_logic;

      -- CSR ports
      csr_wr_ready          : in  std_logic;
      csr_wr_en             : out std_logic;
      csr_wr_data           : out std_logic_vector((32 - 1) downto 0);
      csr_wr_index          : out std_logic_vector((8 - 1) downto 0);
      reserved_csr_wr_index : out std_logic_vector((8 -1) downto 0);
      reserved_csr_wr_data  : out std_logic_vector((32 - 1) downto 0);
      reserved_csr_wr_en    : out std_logic;
      -- CSR ports      


      -- fifo control
      wr_data_full : in  std_logic;
      wr_data_fen  : out std_logic;
      dma_h2f_data : out std_logic_vector(63 downto 0);

      trn_mem_read_req_done : in std_logic;

      -- DMA read Status
      dma_h2f_data_len : in  std_logic_vector(31 downto 0);
      dma_h2f_done     : out std_logic);
  end component PCIE_RX_ENGINE;

  component PCIE_TX_ENGINE
    port (
      clk         : in std_logic;
      rst_n       : in std_logic;
      hw_chnl_rst : in std_logic;

      -- to pcie core 8 tx
      trn_td         : out std_logic_vector(63 downto 0);
      trn_trem_n     : out std_logic_vector(7 downto 0);
      trn_tsof_n     : out std_logic;
      trn_teof_n     : out std_logic;
      trn_tsrc_rdy_n : out std_logic;
      trn_tsrc_dsc_n : out std_logic;
      trn_tdst_rdy_n : in  std_logic;
      trn_tdst_dsc_n : in  std_logic;

      -- Handshake with RX 2 control 10 in
      req_compl_i  : in  std_logic;
      compl_done_o : out std_logic;

      req_tc_i   : in std_logic_vector(2 downto 0);
      req_td_i   : in std_logic;
      req_ep_i   : in std_logic;
      req_attr_i : in std_logic_vector(1 downto 0);
      req_len_i  : in std_logic_vector(9 downto 0);
      req_rid_i  : in std_logic_vector(15 downto 0);
      req_tag_i  : in std_logic_vector(7 downto 0);
      req_be_i   : in std_logic_vector(3 downto 0);
      req_addr_i : in std_logic_vector(31 downto 0);

      -- RAM read control 3+1 select
      dma_f2h_data : in std_logic_vector(63 downto 0);

      trn_mem_read_req_done : out std_logic;


      --fifo control
      f2h_fifo_empty : in  std_logic;
      f2h_fifo_valid : in  std_logic;
      f2h_fifo_ren   : out std_logic;

      -- CSR ports
      csr_rd_ready : in  std_logic;
      csr_rd_done  : in  std_logic;
      csr_rd_en    : out std_logic;
      csr_rd_ack   : out std_logic;
      csr_rd_data  : in  std_logic_vector((32 - 1) downto 0);
      csr_rd_index : out std_logic_vector((8 - 1) downto 0);

      reserved_csr_rd_index : out std_logic_vector((8 -1) downto 0);
      reserved_csr_rd_data  : in  std_logic_vector((32 - 1) downto 0);
      -- CSR ports              



      -----------------------------------------------------------
      -- DMA write Control 6 
      -----------------------------------------------------------
      mwr_start_i   : in  std_logic;
      mwr_len_i     : in  std_logic_vector(31 downto 0);
      mwr_lbe_i     : in  std_logic_vector(3 downto 0);
      mwr_fbe_i     : in  std_logic_vector(3 downto 0);
      mwr_addr_i    : in  std_logic_vector(31 downto 0);
      mwr_addr_hi_i : in  std_logic_vector(31 downto 0);
      mwr_count_i   : in  std_logic_vector(31 downto 0);
      mwr_done_o    : out std_logic;

      -----------------------------------------------------------
      -- DMA Read Control 6 
      -----------------------------------------------------------

      mrd_start_i   : in std_logic;
      mrd_len_i     : in std_logic_vector(31 downto 0);
      mrd_lbe_i     : in std_logic_vector(3 downto 0);
      mrd_fbe_i     : in std_logic_vector(3 downto 0);
      mrd_addr_i    : in std_logic_vector(31 downto 0);
      mrd_addr_hi_i : in std_logic_vector(31 downto 0);
      mrd_count_i   : in std_logic_vector(31 downto 0);


      completer_id_i        : in std_logic_vector(15 downto 0);
      cfg_ext_tag_en_i      : in std_logic;
      cfg_bus_mstr_enable_i : in std_logic);
  end component PCIE_TX_ENGINE;


  signal req_compl  : std_logic;
  signal compl_done : std_logic;

  signal req_tc   : std_logic_vector(2 downto 0);
  signal req_td   : std_logic;
  signal req_ep   : std_logic;
  signal req_attr : std_logic_vector(1 downto 0);
  signal req_len  : std_logic_vector(9 downto 0);
  signal req_rid  : std_logic_vector(15 downto 0);
  signal req_tag  : std_logic_vector(7 downto 0);
  signal req_addr : std_logic_vector(31 downto 0);
  signal req_bar  : std_logic;
  signal req_be   : std_logic_vector (3 downto 0);

  signal trn_mem_read_req_done_c : std_logic;

  signal mwr_start   : std_logic;
  signal mwr_done    : std_logic;
  signal mwr_len     : std_logic_vector(31 downto 0);
  signal mwr_addr    : std_logic_vector(31 downto 0);
  signal mwr_addr_hi : std_logic_vector(31 downto 0);
  signal mwr_count   : std_logic_vector(31 downto 0);


  signal mrd_start   : std_logic;
  signal mrd_len     : std_logic_vector(31 downto 0);
  signal mrd_addr    : std_logic_vector(31 downto 0);
  signal mrd_addr_hi : std_logic_vector(31 downto 0);
  signal mrd_count   : std_logic_vector(31 downto 0);

  signal dma_h2f_data_len_c : std_logic_vector(31 downto 0);
  signal dma_h2f_done_c     : std_logic;


  signal reserved_csr_wr_index_c : std_logic_vector(7 downto 0);
  signal reserved_csr_wr_data_c  : std_logic_vector(31 downto 0);
  signal reserved_csr_wr_en_c    : std_logic;
  signal reserved_csr_rd_index_c : std_logic_vector(7 downto 0);
  signal reserved_csr_rd_data_c  : std_logic_vector(31 downto 0);

  -- wires for fifo
  signal wr_data_fen  : std_logic;
  signal wr_data_full : std_logic;


  signal f2h_fifo_empty : std_logic;
  signal f2h_fifo_valid : std_logic;
  signal f2h_fifo_ren   : std_logic;
  signal h2f_fifo_ren   : std_logic;

  signal dma_h2f_data : std_logic_vector(63 downto 0);
  signal dma_f2h_data : std_logic_vector(63 downto 0);

  -- wires for channel's ports
  signal trn_td_c         : std_logic_vector (63 downto 0);
  signal trn_trem_n_c     : std_logic_vector(7 downto 0);
  signal trn_tsof_n_c     : std_logic;
  signal trn_teof_n_c     : std_logic;
  signal trn_tsrc_dsc_n_c : std_logic;
  signal trn_tsrc_rdy_n_c : std_logic;
  signal trn_tdst_dsc_n_c : std_logic;
  signal trn_tdst_rdy_n_c : std_logic;

  -- LocalLink Rx
  signal trn_rd_c         : std_logic_vector(63 downto 0);
  signal trn_rrem_n_c     : std_logic_vector(7 downto 0);
  signal trn_rsof_n_c     : std_logic;
  signal trn_reof_n_c     : std_logic;
  signal trn_rsrc_rdy_n_c : std_logic;
  signal trn_rbar_hit_n_c : std_logic_vector(6 downto 0);
  signal trn_rdst_rdy_n_c : std_logic;

  -- Interrupt
  signal intr_host_ack_c : std_logic;
  signal int_out_ready_c : std_logic;
  signal int_in_en_c     : std_logic;

  signal pcie_csr_rd_ready_c       : std_logic;
  signal pcie_csr_rd_done_c        : std_logic;
  signal pcie_csr_rd_en_c          : std_logic;
  signal pcie_csr_rd_ack_c         : std_logic;
  signal pcie_csr_rd_data_c        : std_logic_vector(31 downto 0);
  signal pcie_csr_rd_index_c       : std_logic_vector(7 downto 0);
  signal pcie_csr_wr_ready_c       : std_logic;
  signal pcie_csr_wr_en_c          : std_logic;
  signal pcie_csr_wr_data_c        : std_logic_vector(31 downto 0);
  signal pcie_csr_wr_index_c       : std_logic_vector(7 downto 0);
  signal pcie_csr_h2f_reg0_wr_en_c : std_logic;
  signal pcie_csr_h2f_reg0_c       : std_logic_vector((32 - 1) downto 0);
  signal pcie_csr_f2h_reg0_c       : std_logic_vector((32 - 1) downto 0);

  signal csr_out_rd_ready_c      : std_logic;
  signal csr_out_rd_done_c       : std_logic;
  signal csr_in_rd_en_c          : std_logic;
  signal csr_in_rd_ack_c         : std_logic;
  signal csr_out_rd_data_c       : std_logic_vector(31 downto 0);
  signal csr_in_rd_index_c       : std_logic_vector(7 downto 0);
  signal csr_out_wr_ready_c      : std_logic;
  signal csr_in_wr_en_c          : std_logic;
  signal csr_in_wr_data_c        : std_logic_vector(31 downto 0);
  signal csr_in_wr_index_c       : std_logic_vector(7 downto 0);
  signal csr_in_f2h_reg0_wr_en_c : std_logic;
  signal csr_out_h2f_reg0_c      : std_logic_vector((32 - 1) downto 0);
  signal csr_in_f2h_reg0_c       : std_logic_vector((32 - 1) downto 0);

  signal dma_out_h2f_ready_c          : std_logic;
  signal dma_out_h2f_fifo_ready_c     : std_logic;
  signal dma_in_h2f_en_c              : std_logic;
  signal dma_in_h2f_fifo_ack_c        : std_logic;
  signal dma_in_h2f_paddr_c           : std_logic_vector(63 downto 0);
  signal dma_in_h2f_len_c             : std_logic_vector(31 downto 0);
  signal dma_out_h2f_fifo_data_c      : std_logic_vector(63 downto 0);
  ------ f2h ports
  signal dma_out_f2h_ready_c          : std_logic;
  signal dma_out_f2h_fifo_ready_c     : std_logic;
  signal dma_in_f2h_en_c              : std_logic;
  signal dma_in_f2h_fifo_data_valid_c : std_logic;
  signal dma_in_f2h_paddr_c           : std_logic_vector(63 downto 0);
  signal dma_in_f2h_len_c             : std_logic_vector(31 downto 0);
  signal dma_in_f2h_fifo_data_c       : std_logic_vector(63 downto 0);

  signal pcie_bar0_rst_sig_c : std_logic;
  signal pcie_bar0_rst_ack_c : std_logic;
  signal hw_chnl_rst_c       : std_logic;

begin

  PCIE_BAR0_INST : PCIE_BAR0
    port map (
      clk   => clk,
      rst_n => rst_n,


      -- Read Port
      rd_a_i => reserved_csr_rd_index_c(7 downto 0),
      rd_d_o => reserved_csr_rd_data_c,

      -- Write Port
      wr_a_i => reserved_csr_wr_index_c(7 downto 0),

      wr_d_i  => reserved_csr_wr_data_c,
      wr_en_i => reserved_csr_wr_en_c,

      pcie_csr_in_h2f_reg0_wr_en => pcie_csr_h2f_reg0_wr_en_c,
      pcie_csr_in_h2f_reg0       => pcie_csr_h2f_reg0_c,
      pcie_csr_out_f2h_reg0      => pcie_csr_f2h_reg0_c,

      pcie_bar0_rst_sig => pcie_bar0_rst_sig_c,
      pcie_bar0_rst_ack => pcie_bar0_rst_ack_c,

      intr_host_ack => intr_host_ack_c) ;
  -- end port map of "BMD_EP_MEM_ACCESS_INST"

  trn_rd_c         <= trn_rd;
  trn_rrem_n_c     <= trn_rrem_n;
  trn_rsof_n_c     <= trn_rsof_n;
  trn_reof_n_c     <= trn_reof_n;
  trn_rsrc_rdy_n_c <= trn_rsrc_rdy_n;
  trn_rbar_hit_n_c <= trn_rbar_hit_n;
  trn_rdst_rdy_n   <= trn_rdst_rdy_n_c;
  PCIE_RX_ENGINE_INST : PCIE_RX_ENGINE
    port map (
      clk         => clk,
      rst_n       => rst_n,
      hw_chnl_rst => hw_chnl_rst_c,

      -- LocalLink Rx
      trn_rd         => trn_rd_c,
      trn_rrem_n     => trn_rrem_n_c,
      trn_rsof_n     => trn_rsof_n_c,
      trn_reof_n     => trn_reof_n_c,
      trn_rsrc_rdy_n => trn_rsrc_rdy_n_c,
      trn_rbar_hit_n => trn_rbar_hit_n_c,
      trn_rdst_rdy_n => trn_rdst_rdy_n_c,

      -- Handshake with Tx engine 
      req_compl_o  => req_compl,
      compl_done_i => compl_done,

      req_tc_o   => req_tc,
      req_td_o   => req_td,
      req_ep_o   => req_ep,
      req_attr_o => req_attr,
      req_len_o  => req_len,
      req_rid_o  => req_rid,
      req_tag_o  => req_tag,
      req_be_o   => req_be,
      req_bar_o  => req_bar,
      req_addr_o => req_addr,

      trn_mem_read_req_done => trn_mem_read_req_done_c,

      -- CSR ports
      csr_wr_ready => pcie_csr_wr_ready_c,
      csr_wr_en    => pcie_csr_wr_en_c,
      csr_wr_data  => pcie_csr_wr_data_c,
      csr_wr_index => pcie_csr_wr_index_c,

      reserved_csr_wr_index => reserved_csr_wr_index_c,
      reserved_csr_wr_data  => reserved_csr_wr_data_c,
      reserved_csr_wr_en    => reserved_csr_wr_en_c,
      -- CSR ports      


      wr_data_fen  => wr_data_fen,
      wr_data_full => wr_data_full,
      dma_h2f_data => dma_h2f_data,


      dma_h2f_data_len => dma_h2f_data_len_c,
      dma_h2f_done     => dma_h2f_done_c);              
  -- end port map of "PCIE_RX_ENGINE_INST"

  trn_td           <= trn_td_c;
  trn_trem_n       <= trn_trem_n_c;
  trn_tsof_n       <= trn_tsof_n_c;
  trn_teof_n       <= trn_teof_n_c;
  trn_tsrc_dsc_n   <= trn_tsrc_dsc_n_c;
  trn_tsrc_rdy_n   <= trn_tsrc_rdy_n_c;
  trn_tdst_dsc_n_c <= trn_tdst_dsc_n;
  trn_tdst_rdy_n_c <= trn_tdst_rdy_n;
  PCIE_TX_ENGINE_INST : PCIE_TX_ENGINE
    port map(
      clk         => clk,
      rst_n       => rst_n,
      hw_chnl_rst => hw_chnl_rst_c,

      -- LocalLink Tx
      trn_td         => trn_td_c,
      trn_trem_n     => trn_trem_n_c,
      trn_tsof_n     => trn_tsof_n_c,
      trn_teof_n     => trn_teof_n_c,
      trn_tsrc_dsc_n => trn_tsrc_dsc_n_c,
      trn_tsrc_rdy_n => trn_tsrc_rdy_n_c,
      trn_tdst_dsc_n => trn_tdst_dsc_n_c,
      trn_tdst_rdy_n => trn_tdst_rdy_n_c,


      -- Handshake with Rx engine 
      req_compl_i  => req_compl,
      compl_done_o => compl_done,

      req_tc_i   => req_tc,
      req_td_i   => req_td,
      req_ep_i   => req_ep,
      req_attr_i => req_attr,
      req_len_i  => req_len,
      req_rid_i  => req_rid,
      req_tag_i  => req_tag,
      req_be_i   => req_be,
      req_addr_i => req_addr,

      dma_f2h_data => dma_f2h_data,

      trn_mem_read_req_done => trn_mem_read_req_done_c,

      f2h_fifo_empty => f2h_fifo_empty,
      f2h_fifo_valid => f2h_fifo_valid,
      f2h_fifo_ren   => f2h_fifo_ren,



      -- CSR ports
      csr_rd_ready => pcie_csr_rd_ready_c,
      csr_rd_done  => pcie_csr_rd_done_c,
      csr_rd_en    => pcie_csr_rd_en_c,
      csr_rd_ack   => pcie_csr_rd_ack_c,
      csr_rd_data  => pcie_csr_rd_data_c,
      csr_rd_index => pcie_csr_rd_index_c,

      reserved_csr_rd_index => reserved_csr_rd_index_c,
      reserved_csr_rd_data  => reserved_csr_rd_data_c,

      -- CSR ports      
      mrd_start_i => mrd_start,

      mrd_addr_i    => mrd_addr,
      mrd_addr_hi_i => mrd_addr_hi,
      mrd_len_i     => mrd_len,
      mrd_count_i   => mrd_count,
      mrd_lbe_i     => x"F",
      mrd_fbe_i     => x"F",

      mwr_start_i   => mwr_start,
      mwr_done_o    => mwr_done,
      mwr_addr_i    => mwr_addr,
      mwr_addr_hi_i => mwr_addr_hi,
      mwr_len_i     => mwr_len,
      mwr_count_i   => mwr_count,

      mwr_lbe_i => x"F",
      mwr_fbe_i => x"F",


      completer_id_i        => cfg_completer_id,
      cfg_ext_tag_en_i      => cfg_ext_tag_en,
      cfg_bus_mstr_enable_i => '1');  
  -- end port map of "BMD_64_TX_ENGINE_INST"

  csr_out_rd_ready        <= csr_out_rd_ready_c;
  csr_out_rd_done         <= csr_out_rd_done_c;
  csr_in_rd_en_c          <= csr_in_rd_en;
  csr_in_rd_ack_c         <= csr_in_rd_ack;
  csr_out_rd_data         <= csr_out_rd_data_c;
  csr_in_rd_index_c       <= csr_in_rd_index;
  csr_out_wr_ready        <= csr_out_wr_ready_c;
  csr_in_wr_en_c          <= csr_in_wr_en;
  csr_in_wr_data_c        <= csr_in_wr_data;
  csr_in_wr_index_c       <= csr_in_wr_index;
  csr_in_f2h_reg0_wr_en_c <= csr_in_f2h_reg0_wr_en;
  csr_out_h2f_reg0        <= csr_out_h2f_reg0_c;
  csr_in_f2h_reg0_c       <= csr_in_f2h_reg0;
  CSR_CONTROLLER_INST : CSR_CONTROLLER
    port map(
      clk         => clk,
      rst_n       => rst_n,
      hw_chnl_rst => hw_chnl_rst_c,

      pcie_csr_out_rd_ready => pcie_csr_rd_ready_c,
      pcie_csr_out_rd_done  => pcie_csr_rd_done_c,
      pcie_csr_in_rd_en     => pcie_csr_rd_en_c,
      pcie_csr_in_rd_ack    => pcie_csr_rd_ack_c,
      pcie_csr_out_rd_data  => pcie_csr_rd_data_c,
      pcie_csr_in_rd_index  => pcie_csr_rd_index_c,
      pcie_csr_out_wr_ready => pcie_csr_wr_ready_c,
      pcie_csr_in_wr_en     => pcie_csr_wr_en_c,
      pcie_csr_in_wr_data   => pcie_csr_wr_data_c,
      pcie_csr_in_wr_index  => pcie_csr_wr_index_c,

      pcie_csr_in_h2f_reg0_wr_en => pcie_csr_h2f_reg0_wr_en_c,
      pcie_csr_in_h2f_reg0       => pcie_csr_h2f_reg0_c,
      pcie_csr_out_f2h_reg0      => pcie_csr_f2h_reg0_c,

      csr_out_rd_ready      => csr_out_rd_ready_c,
      csr_out_rd_done       => csr_out_rd_done_c,
      csr_in_rd_en          => csr_in_rd_en_c,
      csr_in_rd_ack         => csr_in_rd_ack_c,
      csr_out_rd_data       => csr_out_rd_data_c,
      csr_in_rd_index       => csr_in_rd_index_c,
      csr_out_wr_ready      => csr_out_wr_ready_c,
      csr_in_wr_en          => csr_in_wr_en_c,
      csr_in_wr_data        => csr_in_wr_data_c,
      csr_in_wr_index       => csr_in_wr_index_c,
      --------------system CSR SIGNAL-------------------
      csr_in_f2h_reg0_wr_en => csr_in_f2h_reg0_wr_en_c,
      csr_out_h2f_reg0      => csr_out_h2f_reg0_c,
      csr_in_f2h_reg0       => csr_in_f2h_reg0_c);

  int_out_ready <= int_out_ready_c;
  int_in_en_c   <= int_in_en;
  INTR_CONTROLLER_INST : INTR_CONTROLLER
    port map(
      clk         => clk,
      rst_n       => rst_n,
      hw_chnl_rst => hw_chnl_rst_c,

      int_out_ready => int_out_ready_c,
      int_in_en     => int_in_en_c,

      intr_host_ack => intr_host_ack_c,

      cfg_interrupt_rdy_n    => cfg_interrupt_rdy_n,
      cfg_interrupt_assert_n => cfg_interrupt_assert_n,
      cfg_interrupt_n        => cfg_interrupt_n);       


  dma_out_h2f_ready      <= dma_out_h2f_ready_c;
  dma_out_h2f_fifo_ready <= dma_out_h2f_fifo_ready_c;
  dma_in_h2f_en_c        <= dma_in_h2f_en;
  dma_in_h2f_fifo_ack_c  <= dma_in_h2f_fifo_ack;
  dma_in_h2f_paddr_c     <= dma_in_h2f_paddr;
  dma_in_h2f_len_c       <= dma_in_h2f_len;
  dma_out_h2f_fifo_data  <= dma_out_h2f_fifo_data_c;

  dma_out_f2h_ready            <= dma_out_f2h_ready_c;
  dma_out_f2h_fifo_ready       <= dma_out_f2h_fifo_ready_c;
  dma_in_f2h_en_c              <= dma_in_f2h_en;
  dma_in_f2h_fifo_data_valid_c <= dma_in_f2h_fifo_data_valid;
  dma_in_f2h_paddr_c           <= dma_in_f2h_paddr;
  dma_in_f2h_len_c             <= dma_in_f2h_len;
  dma_in_f2h_fifo_data_c       <= dma_in_f2h_fifo_data;
  DMA_CONTROLLER_INST : DMA_CONTROLLER
    port map(
      ------ h2f ports
      dma_out_h2f_ready          => dma_out_h2f_ready_c,
      dma_out_h2f_fifo_ready     => dma_out_h2f_fifo_ready_c,
      dma_in_h2f_en              => dma_in_h2f_en_c,
      dma_in_h2f_fifo_ack        => dma_in_h2f_fifo_ack_c,
      dma_in_h2f_paddr           => dma_in_h2f_paddr_c,
      dma_in_h2f_len             => dma_in_h2f_len_c,
      dma_out_h2f_fifo_data      => dma_out_h2f_fifo_data_c,
      ------ f2h ports
      dma_out_f2h_ready          => dma_out_f2h_ready_c,
      dma_out_f2h_fifo_ready     => dma_out_f2h_fifo_ready_c,
      dma_in_f2h_en              => dma_in_f2h_en_c,
      dma_in_f2h_fifo_data_valid => dma_in_f2h_fifo_data_valid_c,
      dma_in_f2h_paddr           => dma_in_f2h_paddr_c,
      dma_in_f2h_len             => dma_in_f2h_len_c,
      dma_in_f2h_fifo_data       => dma_in_f2h_fifo_data_c,

      ------ ports with TX_ENGINE
      mwr_start_o   => mwr_start,
      mwr_addr_o    => mwr_addr,
      mwr_addr_hi_o => mwr_addr_hi,
      mwr_len_o     => mwr_len,
      mwr_count_o   => mwr_count,


      mrd_start_o   => mrd_start,
      mrd_addr_o    => mrd_addr,
      mrd_addr_hi_o => mrd_addr_hi,
      mrd_len_o     => mrd_len,
      mrd_count_o   => mrd_count,

      f2h_fifo_empty => f2h_fifo_empty,
      f2h_fifo_ren   => f2h_fifo_ren,
      f2h_fifo_valid => f2h_fifo_valid,
      dma_f2h_data   => dma_f2h_data,
      dma_f2h_done   => mwr_done,

      ------- ports with RX_ENGINE
      dma_h2f_data_len => dma_h2f_data_len_c,
      dma_h2f_done     => dma_h2f_done_c,
      wr_data_full     => wr_data_full,
      wr_data_fen      => wr_data_fen,
      dma_h2f_data     => dma_h2f_data,

      cfg_max_rd_req_size  => cfg_max_rd_req_size,
      cfg_max_payload_size => cfg_max_payload_size,

      hw_chnl_rst => hw_chnl_rst_c,
      clk         => clk,
      rst_n       => rst_n);
  --------------------end port map-------------------------

  hw_chnl_rst <= hw_chnl_rst_c;
  
  RST_CONTROLLER_INST : RST_CONTROLLER
    port map(
      pcie_bar0_rst_sig => pcie_bar0_rst_sig_c,
      pcie_bar0_rst_ack => pcie_bar0_rst_ack_c,

      rst_init_req_rdy  => rst_init_req_rdy,
      rst_init_req_en   => rst_init_req_en,
      rst_init_resp_rdy => rst_init_resp_rdy,
      rst_init_resp_en  => rst_init_resp_en,

      hw_chnl_rst_sig => hw_chnl_rst_c,

      rst_softrst_req_rdy  => rst_softrst_req_rdy,
      rst_softrst_req_en   => rst_softrst_req_en,
      rst_softrst_resp_rdy => rst_softrst_resp_rdy,
      rst_softrst_resp_en  => rst_softrst_resp_en,

      clk   => clk,
      rst_n => rst_n);
--------------------end port map-------------------------       
end rtl;

