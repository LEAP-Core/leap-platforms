----------------------------------------------------------------------------------
---- Filename: channel_ctrl.vhd
---- Wang, Liang(liang.wang@intel.com), Wang, Tao Z (tao.z.wang@intel.com)
---- Description: a wrapper for subtle modules of PCIe channel. 
----
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity channel_ctrl is
  port (
    clk   : in std_logic;
    rst_n : in std_logic;
    
    -- LocalLink Tx
    trn_td         : out std_logic_vector(63 downto 0);
    trn_trem_n     : out std_logic_vector(7 downto 0);
    trn_tsof_n     : out std_logic;
    trn_teof_n     : out std_logic;
    trn_tsrc_rdy_n : out std_logic;
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

    rst_softrst_req_rdy  : out std_logic;
    rst_softrst_req_en   : in  std_logic;
    rst_softrst_resp_rdy : out std_logic;
    rst_softrst_resp_en  : in  std_logic;

    -- interrupt signals

    int_out_ready : out std_logic;
    int_in_en     : in  std_logic
    );
end channel_ctrl;

architecture rtl of channel_ctrl is

  component rst_controller
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

  component intr_controller
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
  end component;

  component dma_ctrl
    port (
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


      ------ ports with tx_wrapper
      mwr64_start     : out std_logic;
      mwr64_start_ack : in  std_logic;
      mwr64_finish    : in  std_logic;
      mwr64_len       : out std_logic_vector(9 downto 0);
      mwr64_tag       : out std_logic_vector(7 downto 0);
      mwr64_addr      : out std_logic_vector(63 downto 0);

      f2h_fifo_valid : out std_logic;
      f2h_fifo_ren   : in  std_logic;
      f2h_fifo_data  : out std_logic_vector(63 downto 0);

      mrd64_req_start     : out std_logic;
      mrd64_req_start_ack : in  std_logic;
      mrd64_req_finish    : in  std_logic;
      mrd64_req_tag       : out std_logic_vector(7 downto 0);
      mrd64_req_len       : out std_logic_vector(9 downto 0);
      mrd64_req_addr      : out std_logic_vector(63 downto 0);

      ------ ports with rx_wrapper
      h2f_fifo_data : in  std_logic_vector(63 downto 0);
      h2f_fifo_full : out std_logic;
      h2f_fifo_wen  : in  std_logic;

      cpld_recv_finish : in std_logic;
      cpld_recv_len    : in std_logic_vector(9 downto 0);


      cfg_max_rd_req_size  : in std_logic_vector(2 downto 0);
      cfg_max_payload_size : in std_logic_vector(2 downto 0);
      cfg_ext_tag_en       : in std_logic;

      hw_chnl_rst : in std_logic;
      clk         : in std_logic;
      rst_n       : in std_logic);
  end component;

  component csr_ctrl
    port (
      clk   : in std_logic;
      rst_n : in std_logic;

      hw_chnl_rst : in std_logic;

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
      csr_out_h2f_reg0 : out std_logic_vector((32 - 1) downto 0);

      csr_in_f2h_reg0_wr_en : in std_logic;
      csr_in_f2h_reg0       : in std_logic_vector((32 - 1) downto 0);

      -- ports with pcie_rx_wrapper
      mrd32_req_addr : in std_logic_vector(31 downto 0);
      csr_rd_start   : in std_logic;

      mwr32_addr : in std_logic_vector(31 downto 0);
      mwr32_data : in std_logic_vector(31 downto 0);

      csr_wr_start : in std_logic;

      -- ports with pcie_tx_wrapper
      cpld_start     : out std_logic;
      cpld_start_ack : in  std_logic;
      cpld_finish    : in  std_logic;
      mrd32_req_data : out std_logic_vector(31 downto 0);

      -- ports with pcie_bar0
      bar0_wr_addr : out std_logic_vector(7 downto 0);
      bar0_wr_en   : out std_logic;
      bar0_wr_data : out std_logic_vector(31 downto 0);

      bar0_rd_addr : out std_logic_vector(7 downto 0);
      bar0_rd_data : in  std_logic_vector(31 downto 0);

      -- system csr ports with pcie_bar0
      pcie_csr_in_h2f_reg0_wr_en : in  std_logic;
      pcie_csr_in_h2f_reg0       : in  std_logic_vector((32 - 1) downto 0);
      pcie_csr_out_f2h_reg0      : out std_logic_vector((32 - 1) downto 0));
  end component;

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

      intr_host_ack  : out std_logic);
  end component PCIE_BAR0;

  component pcie_rx_wrapper
    port (
      clk   : in std_logic;
      rst_n : in std_logic;

      hw_chnl_rst : in std_logic;

      -- pcie core 8
      trn_rd         : in  std_logic_vector(63 downto 0);
      trn_rrem_n     : in  std_logic_vector(7 downto 0);
      trn_rsof_n     : in  std_logic;
      trn_reof_n     : in  std_logic;
      trn_rsrc_rdy_n : in  std_logic;
      trn_rbar_hit_n : in  std_logic_vector(6 downto 0);
      trn_rdst_rdy_n : out std_logic;


      -- ports for CSR Read
      mrd32_req_tc   : out std_logic_vector(2 downto 0);
      mrd32_req_td   : out std_logic;
      mrd32_req_ep   : out std_logic;
      mrd32_req_attr : out std_logic_vector(1 downto 0);
      mrd32_req_len  : out std_logic_vector(9 downto 0);
      mrd32_req_rid  : out std_logic_vector(15 downto 0);
      mrd32_req_tag  : out std_logic_vector(7 downto 0);
      mrd32_req_be   : out std_logic_vector(3 downto 0);
      mrd32_req_addr : out std_logic_vector(31 downto 0);  --MEM_RD hand shake with TX
      mrd32_req_bar  : out std_logic;

      csr_rd_start : out std_logic;

      --ports for CSR Write
      mwr32_addr : out std_logic_vector(31 downto 0);
      mwr32_data : out std_logic_vector(31 downto 0);

      csr_wr_start : out std_logic;

      -- ports for CPLD
      cpld_recv_finish : out std_logic;
      cpld_recv_len    : out std_logic_vector(9 downto 0);


      -- DMA h2f fifo interface.
      h2f_fifo_data : out std_logic_vector(63 downto 0);
      h2f_fifo_full : in  std_logic;
      h2f_fifo_wen  : out std_logic);
  end component;

  component pcie_tx_wrapper
    port (
      clk         : in std_logic;
      rst_n       : in std_logic;
      hw_chnl_rst : in std_logic;

      -- signals with Endpoint Block Plus for PCI Express(TRN)
      trn_td         : out std_logic_vector(63 downto 0);
      trn_trem_n     : out std_logic_vector(7 downto 0);
      trn_tsof_n     : out std_logic;
      trn_teof_n     : out std_logic;
      trn_tsrc_rdy_n : out std_logic;
      trn_tdst_rdy_n : in  std_logic;


      -- signals with Endpoint Block Plus for PCI Express(CFG)
      cfg_completer_id : in std_logic_vector(15 downto 0);


      -- signals for CPLD
      cpld_start     : in  std_logic;
      cpld_start_ack : out std_logic;
      cpld_finish    : out std_logic;
      mrd32_req_data : in  std_logic_vector(31 downto 0);

      -- they are connected to the corresponding ports in rx
      mrd32_req_tc   : in std_logic_vector(2 downto 0);
      mrd32_req_td   : in std_logic;
      mrd32_req_ep   : in std_logic;
      mrd32_req_attr : in std_logic_vector(1 downto 0);
      mrd32_req_len  : in std_logic_vector(9 downto 0);
      mrd32_req_rid  : in std_logic_vector(15 downto 0);
      mrd32_req_tag  : in std_logic_vector(7 downto 0);
      mrd32_req_be   : in std_logic_vector(3 downto 0);
      mrd32_req_addr : in std_logic_vector(31 downto 0);

      -- signals for Memory_Read_Req
      mrd64_req_start     : in  std_logic;
      mrd64_req_start_ack : out std_logic;
      mrd64_req_finish    : out std_logic;
      mrd64_req_tag       : in  std_logic_vector(7 downto 0);
      mrd64_req_len       : in  std_logic_vector(9 downto 0);
      mrd64_req_lbe       : in  std_logic_vector(3 downto 0);
      mrd64_req_fbe       : in  std_logic_vector(3 downto 0);
      mrd64_req_addr      : in  std_logic_vector(63 downto 0);

      -- signals for Memory_Write
      mwr64_start     : in  std_logic;
      mwr64_start_ack : out std_logic;
      mwr64_finish    : out std_logic;
      mwr64_len       : in  std_logic_vector(9 downto 0);
      mwr64_lbe       : in  std_logic_vector(3 downto 0);
      mwr64_fbe       : in  std_logic_vector(3 downto 0);
      mwr64_tag       : in  std_logic_vector(7 downto 0);
      mwr64_addr      : in  std_logic_vector(63 downto 0);

      f2h_fifo_valid : in  std_logic;
      f2h_fifo_ren   : out std_logic;
      f2h_fifo_data  : in  std_logic_vector(63 downto 0));
  end component;

  -- rx wrapper
  signal mrd32_req_tc   : std_logic_vector(2 downto 0);
  signal mrd32_req_td   : std_logic;
  signal mrd32_req_ep   : std_logic;
  signal mrd32_req_attr : std_logic_vector(1 downto 0);
  signal mrd32_req_len  : std_logic_vector(9 downto 0);
  signal mrd32_req_rid  : std_logic_vector(15 downto 0);
  signal mrd32_req_tag  : std_logic_vector(7 downto 0);
  signal mrd32_req_addr : std_logic_vector(31 downto 0);
  signal mrd32_req_bar  : std_logic;
  signal mrd32_req_be   : std_logic_vector (3 downto 0);

  signal csr_rd_start : std_logic;

  signal mwr32_addr : std_logic_vector(31 downto 0);
  signal mwr32_data : std_logic_vector(31 downto 0);

  signal csr_wr_start : std_logic;

  signal cpld_recv_finish : std_logic;
  signal cpld_recv_len    : std_logic_vector(9 downto 0);

  signal h2f_fifo_wen  : std_logic;
  signal h2f_fifo_full : std_logic;
  signal h2f_fifo_data : std_logic_vector(63 downto 0);

  -- tx wrapper
  signal cpld_start     : std_logic;
  signal cpld_start_ack : std_logic;
  signal cpld_finish    : std_logic;
  signal mrd32_req_data : std_logic_vector(31 downto 0);

  signal mrd64_req_start     : std_logic;
  signal mrd64_req_start_ack : std_logic;
  signal mrd64_req_finish    : std_logic;
  signal mrd64_req_tag       : std_logic_vector(7 downto 0);
  signal mrd64_req_len       : std_logic_vector(9 downto 0);
  signal mrd64_req_addr      : std_logic_vector(63 downto 0);

  signal mwr64_start     : std_logic;
  signal mwr64_start_ack : std_logic;
  signal mwr64_finish    : std_logic;
  signal mwr64_len       : std_logic_vector(9 downto 0);
  signal mwr64_tag       : std_logic_vector(7 downto 0);
  signal mwr64_addr      : std_logic_vector(63 downto 0);

  signal f2h_fifo_valid : std_logic;
  signal f2h_fifo_ren   : std_logic;
  signal f2h_fifo_data  : std_logic_vector(63 downto 0);



  -- csr_ctrl and pcie_bar0
  signal bar0_wr_addr : std_logic_vector(7 downto 0);
  signal bar0_wr_en   : std_logic;
  signal bar0_wr_data : std_logic_vector(31 downto 0);

  signal bar0_rd_addr : std_logic_vector(7 downto 0);
  signal bar0_rd_data : std_logic_vector(31 downto 0);

  signal pcie_csr_h2f_reg0_wr_en_c : std_logic;
  signal pcie_csr_h2f_reg0_c       : std_logic_vector((32 - 1) downto 0);
  signal pcie_csr_f2h_reg0_c       : std_logic_vector((32 - 1) downto 0);


  signal trn_mem_read_req_done_c : std_logic;
  signal trn_mrd_recv_len_c      : std_logic_vector(31 downto 0);

  signal init_rst_c : std_logic;

  signal mwr_start   : std_logic;
  signal mwr_done    : std_logic;
  signal mwr_len     : std_logic_vector(31 downto 0);
  signal mwr_addr    : std_logic_vector(31 downto 0);
  signal mwr_addr_hi : std_logic_vector(31 downto 0);
  signal mwr_count   : std_logic_vector(31 downto 0);


  signal mrd_start   : std_logic;
  signal mrd_done    : std_logic;
  signal mrd_len     : std_logic_vector(31 downto 0);
  signal mrd_addr    : std_logic_vector(31 downto 0);
  signal mrd_addr_hi : std_logic_vector(31 downto 0);
  signal mrd_count   : std_logic_vector(31 downto 0);

  signal mrd_cur_data_size  : std_logic_vector (31 downto 0);
  signal cpl_ur_found       : std_logic_vector(7 downto 0);
  signal cpl_ur_tag         : std_logic_vector(7 downto 0);
  signal cpld_found         : std_logic_vector(31 downto 0);
  signal cpld_size          : std_logic_vector(31 downto 0);
  signal cpld_malformed     : std_logic;
  signal dma_h2f_data_len_c : std_logic_vector(31 downto 0);
  signal dma_h2f_done_c     : std_logic;


  -- wires for fifo
  signal empty_data_out : std_logic;
  signal rd_data_valid  : std_logic;
  signal rd_data_en     : std_logic;
  signal f2h_fifo_dout  : std_logic_vector(63 downto 0);
  signal f2h_fifo_din   : std_logic_vector(63 downto 0);
  signal f2h_fifo_wen   : std_logic;

  signal f2h_fifo_full  : std_logic;
  signal f2h_fifo_empty : std_logic;

  signal h2f_fifo_din   : std_logic_vector(63 downto 0);
  signal h2f_fifo_dout  : std_logic_vector(63 downto 0);
  signal h2f_fifo_ren   : std_logic;
  signal h2f_fifo_empty : std_logic;
  signal h2f_fifo_valid : std_logic;

  -- wires for channel's ports
  signal trn_td_c         : std_logic_vector (63 downto 0);
  signal trn_trem_n_c     : std_logic_vector(7 downto 0);
  signal trn_tsof_n_c     : std_logic;
  signal trn_teof_n_c     : std_logic;
  signal trn_tsrc_rdy_n_c : std_logic;
  signal trn_tdst_rdy_n_c : std_logic;

  -- LocalLink Rx
  signal trn_rd_c         : std_logic_vector(63 downto 0);
  signal trn_rrem_n_c     : std_logic_vector(7 downto 0);
  signal trn_rsof_n_c     : std_logic;
  signal trn_reof_n_c     : std_logic;
  signal trn_rsrc_rdy_n_c : std_logic;
  signal trn_rbar_hit_n_c : std_logic_vector(6 downto 0);
  signal trn_rdst_rdy_n_c : std_logic;


  signal cfg_completer_id_c     : std_logic_vector(15 downto 0);
  signal cfg_ext_tag_en_c       : std_logic;
  signal cfg_max_rd_req_size_c  : std_logic_vector(2 downto 0);
  signal cfg_max_payload_size_c : std_logic_vector(2 downto 0);
  signal cfg_bus_mstr_enable_c  : std_logic;

  -- Interrupt
  signal intr_host_ack_c          : std_logic;
  signal int_out_ready_c          : std_logic;
  signal int_in_en_c              : std_logic;
  signal cfg_interrupt_n_c        : std_logic;
  signal cfg_interrupt_rdy_n_c    : std_logic;
  signal cfg_interrupt_assert_n_c : std_logic;

-----------------csr_test----------------------------------
  signal csr_test_start_i_r    : std_logic_vector(31 downto 0);
  signal csr_test_data_in_i_r  : std_logic_vector(31 downto 0);
  signal csr_test_index_i_r    : std_logic_vector(31 downto 0);
  signal csr_test_data_out_o_r : std_logic_vector(31 downto 0);
-----------------------------------------------------------

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

  signal sig_impulse_c : std_logic;

  signal pcie_bar0_rst_sig_c : std_logic;
  signal pcie_bar0_rst_ack_c : std_logic;

  signal rst_init_req_rdy_c  : std_logic;
  signal rst_init_req_en_c   : std_logic;
  signal rst_init_resp_rdy_c : std_logic;
  signal rst_init_resp_en_c  : std_logic;

  signal hw_chnl_rst_c : std_logic;

  signal rst_softrst_req_rdy_c  : std_logic;
  signal rst_softrst_req_en_c   : std_logic;
  signal rst_softrst_resp_rdy_c : std_logic;
  signal rst_softrst_resp_en_c  : std_logic;
  
begin  -- rtl

  PCIE_BAR0_INST : PCIE_BAR0
    port map (
      clk   => clk,
      rst_n => rst_n,

      -- Read Port
      rd_a_i => bar0_rd_addr,
      rd_d_o => bar0_rd_data,

      -- Write Port
      wr_a_i => bar0_wr_addr,

      wr_d_i  => bar0_wr_data,
      wr_en_i => bar0_wr_en,

      pcie_csr_in_h2f_reg0_wr_en => pcie_csr_h2f_reg0_wr_en_c,
      pcie_csr_in_h2f_reg0       => pcie_csr_h2f_reg0_c,
      pcie_csr_out_f2h_reg0      => pcie_csr_f2h_reg0_c,

      pcie_bar0_rst_sig => pcie_bar0_rst_sig_c,
      pcie_bar0_rst_ack => pcie_bar0_rst_ack_c,

      intr_host_ack => intr_host_ack_c) ;
  -- end port map of "pcie_bar0"
  
  trn_rd_c         <= trn_rd;
  trn_rrem_n_c     <= trn_rrem_n;
  trn_rsof_n_c     <= trn_rsof_n;
  trn_reof_n_c     <= trn_reof_n;
  trn_rsrc_rdy_n_c <= trn_rsrc_rdy_n;
  trn_rbar_hit_n_c <= trn_rbar_hit_n;
  trn_rdst_rdy_n   <= trn_rdst_rdy_n_c;
  pcie_rx_wrapper_inst : pcie_rx_wrapper
    port map (
      clk   => clk,
      rst_n => rst_n,

      hw_chnl_rst => hw_chnl_rst_c,

      trn_rd         => trn_rd_c,
      trn_rrem_n     => trn_rrem_n_c,
      trn_rsof_n     => trn_rsof_n_c,
      trn_reof_n     => trn_reof_n_c,
      trn_rsrc_rdy_n => trn_rsrc_rdy_n_c,
      trn_rbar_hit_n => trn_rbar_hit_n_c,
      trn_rdst_rdy_n => trn_rdst_rdy_n_c,

      mrd32_req_tc   => mrd32_req_tc,
      mrd32_req_td   => mrd32_req_td,
      mrd32_req_ep   => mrd32_req_ep,
      mrd32_req_attr => mrd32_req_attr,
      mrd32_req_len  => mrd32_req_len,
      mrd32_req_rid  => mrd32_req_rid,
      mrd32_req_tag  => mrd32_req_tag,
      mrd32_req_be   => mrd32_req_be,
      mrd32_req_addr => mrd32_req_addr,
      mrd32_req_bar  => mrd32_req_bar,

      csr_rd_start => csr_rd_start,

      mwr32_addr => mwr32_addr,
      mwr32_data => mwr32_data,

      csr_wr_start => csr_wr_start,

      cpld_recv_finish => cpld_recv_finish,
      cpld_recv_len    => cpld_recv_len,

      h2f_fifo_data => h2f_fifo_data,
      h2f_fifo_full => h2f_fifo_full,
      h2f_fifo_wen  => h2f_fifo_wen);




  trn_td           <= trn_td_c;
  trn_trem_n       <= trn_trem_n_c;
  trn_tsof_n       <= trn_tsof_n_c;
  trn_teof_n       <= trn_teof_n_c;
  trn_tsrc_rdy_n   <= trn_tsrc_rdy_n_c;
  trn_tdst_rdy_n_c <= trn_tdst_rdy_n;
  pcie_tx_wrapper_inst : pcie_tx_wrapper
    port map (
      clk   => clk,
      rst_n => rst_n,

      hw_chnl_rst => hw_chnl_rst_c,

      trn_td         => trn_td_c,
      trn_trem_n     => trn_trem_n_c,
      trn_tsof_n     => trn_tsof_n_c,
      trn_teof_n     => trn_teof_n_c,
      trn_tsrc_rdy_n => trn_tsrc_rdy_n_c,
      trn_tdst_rdy_n => trn_tdst_rdy_n_c,

      cfg_completer_id => cfg_completer_id,

      cpld_start     => cpld_start,
      cpld_start_ack => cpld_start_ack,
      cpld_finish    => cpld_finish,
      mrd32_req_data => mrd32_req_data,

      mrd32_req_tc   => mrd32_req_tc,
      mrd32_req_td   => mrd32_req_td,
      mrd32_req_ep   => mrd32_req_ep,
      mrd32_req_attr => mrd32_req_attr,
      mrd32_req_len  => mrd32_req_len,
      mrd32_req_rid  => mrd32_req_rid,
      mrd32_req_tag  => mrd32_req_tag,
      mrd32_req_be   => mrd32_req_be,
      mrd32_req_addr => mrd32_req_addr,

      mrd64_req_start     => mrd64_req_start,
      mrd64_req_start_ack => mrd64_req_start_ack,
      mrd64_req_finish    => mrd64_req_finish,
      mrd64_req_tag       => mrd64_req_tag,
      mrd64_req_len       => mrd64_req_len,
      mrd64_req_lbe       => x"f",
      mrd64_req_fbe       => x"f",
      mrd64_req_addr      => mrd64_req_addr,

      mwr64_start     => mwr64_start,
      mwr64_start_ack => mwr64_start_ack,
      mwr64_finish    => mwr64_finish,
      mwr64_len       => mwr64_len,
      mwr64_lbe       => x"f",
      mwr64_fbe       => x"f",
      mwr64_tag       => mwr64_tag,
      mwr64_addr      => mwr64_addr,

      f2h_fifo_valid => f2h_fifo_valid,
      f2h_fifo_ren   => f2h_fifo_ren,
      f2h_fifo_data  => f2h_fifo_data);



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
  csr_ctrl_inst : csr_ctrl
    port map (
      clk   => clk,
      rst_n => rst_n,

      hw_chnl_rst => hw_chnl_rst_c,

      csr_out_rd_ready => csr_out_rd_ready_c,
      csr_out_rd_done  => csr_out_rd_done_c,
      csr_in_rd_en     => csr_in_rd_en_c,
      csr_in_rd_ack    => csr_in_rd_ack_c,
      csr_out_rd_data  => csr_out_rd_data_c,
      csr_in_rd_index  => csr_in_rd_index_c,
      csr_out_wr_ready => csr_out_wr_ready_c,
      csr_in_wr_en     => csr_in_wr_en_c,
      csr_in_wr_data   => csr_in_wr_data_c,
      csr_in_wr_index  => csr_in_wr_index_c,

      csr_out_h2f_reg0      => csr_out_h2f_reg0_c,
      csr_in_f2h_reg0_wr_en => csr_in_f2h_reg0_wr_en_c,
      csr_in_f2h_reg0       => csr_in_f2h_reg0_c,

      mrd32_req_addr => mrd32_req_addr,
      csr_rd_start   => csr_rd_start,

      mwr32_addr => mwr32_addr,
      mwr32_data => mwr32_data,

      csr_wr_start => csr_wr_start,

      cpld_start     => cpld_start,
      cpld_start_ack => cpld_start_ack,
      cpld_finish    => cpld_finish,
      mrd32_req_data => mrd32_req_data,

      bar0_wr_addr => bar0_wr_addr,
      bar0_wr_en   => bar0_wr_en,
      bar0_wr_data => bar0_wr_data,

      bar0_rd_addr => bar0_rd_addr,
      bar0_rd_data => bar0_rd_data,

      pcie_csr_in_h2f_reg0_wr_en => pcie_csr_h2f_reg0_wr_en_c,
      pcie_csr_in_h2f_reg0       => pcie_csr_h2f_reg0_c,
      pcie_csr_out_f2h_reg0      => pcie_csr_f2h_reg0_c);

  
  int_out_ready <= int_out_ready_c;
  int_in_en_c   <= int_in_en;
  intr_controller_inst : intr_controller
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
  dma_ctrl_inst : dma_ctrl
    port map (
      dma_out_h2f_ready      => dma_out_h2f_ready_c,
      dma_out_h2f_fifo_ready => dma_out_h2f_fifo_ready_c,
      dma_in_h2f_en          => dma_in_h2f_en_c,
      dma_in_h2f_fifo_ack    => dma_in_h2f_fifo_ack_c,
      dma_in_h2f_paddr       => dma_in_h2f_paddr_c,
      dma_in_h2f_len         => dma_in_h2f_len_c,
      dma_out_h2f_fifo_data  => dma_out_h2f_fifo_data_c,

      dma_out_f2h_ready          => dma_out_f2h_ready_c,
      dma_out_f2h_fifo_ready     => dma_out_f2h_fifo_ready_c,
      dma_in_f2h_en              => dma_in_f2h_en_c,
      dma_in_f2h_fifo_data_valid => dma_in_f2h_fifo_data_valid_c,
      dma_in_f2h_paddr           => dma_in_f2h_paddr_c,
      dma_in_f2h_len             => dma_in_f2h_len_c,
      dma_in_f2h_fifo_data       => dma_in_f2h_fifo_data_c,

      mwr64_start     => mwr64_start,
      mwr64_start_ack => mwr64_start_ack,
      mwr64_finish    => mwr64_finish,
      mwr64_len       => mwr64_len,
      mwr64_addr      => mwr64_addr,
      mwr64_tag       => mwr64_tag,

      f2h_fifo_valid => f2h_fifo_valid,
      f2h_fifo_ren   => f2h_fifo_ren,
      f2h_fifo_data  => f2h_fifo_data,

      mrd64_req_start     => mrd64_req_start,
      mrd64_req_start_ack => mrd64_req_start_ack,
      mrd64_req_finish    => mrd64_req_finish,
      mrd64_req_tag       => mrd64_req_tag,
      mrd64_req_len       => mrd64_req_len,
      mrd64_req_addr      => mrd64_req_addr,

      h2f_fifo_data => h2f_fifo_data,
      h2f_fifo_full => h2f_fifo_full,
      h2f_fifo_wen  => h2f_fifo_wen,

      cpld_recv_finish => cpld_recv_finish,
      cpld_recv_len    => cpld_recv_len,

      cfg_max_rd_req_size  => cfg_max_rd_req_size,
      cfg_max_payload_size => cfg_max_payload_size,
      cfg_ext_tag_en       => cfg_ext_tag_en,

      hw_chnl_rst => hw_chnl_rst_c,

      clk   => clk,
      rst_n => rst_n);

  rst_init_req_rdy   <= rst_init_req_rdy_c;
  rst_init_req_en_c  <= rst_init_req_en;
  rst_init_resp_rdy  <= rst_init_resp_rdy_c;
  rst_init_resp_en_c <= rst_init_resp_en;
    
  rst_softrst_req_rdy   <= rst_softrst_req_rdy_c;
  rst_softrst_req_en_c  <= rst_softrst_req_en;
  rst_softrst_resp_rdy  <= rst_softrst_resp_rdy_c;
  rst_softrst_resp_en_c <= rst_softrst_resp_en;
  
  rst_controller_inst : rst_controller
    port map(
      pcie_bar0_rst_sig => pcie_bar0_rst_sig_c,
      pcie_bar0_rst_ack => pcie_bar0_rst_ack_c,

      rst_init_req_rdy  => rst_init_req_rdy_c,
      rst_init_req_en   => rst_init_req_en_c,
      rst_init_resp_rdy => rst_init_resp_rdy_c,
      rst_init_resp_en  => rst_init_resp_en_c,

      hw_chnl_rst_sig => hw_chnl_rst_c,

      rst_softrst_req_rdy  => rst_softrst_req_rdy_c,
      rst_softrst_req_en   => rst_softrst_req_en_c,
      rst_softrst_resp_rdy => rst_softrst_resp_rdy_c,
      rst_softrst_resp_en  => rst_softrst_resp_en_c,

      clk   => clk,
      rst_n => rst_n);
end rtl;
