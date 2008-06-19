-------------------------------------------------------------------------------
-- Title      : PCIE Link TX Engine
-- Project    : PCI Express Hardware Channel
-------------------------------------------------------------------------------
-- File       : PCIE_TX_ENGINE.vhd
-- Author     : Wang, Liang  <liang.wang@intel.com>
-- Company    : CTL Beijing
-- Created    : 2008-05-29
-- Last update: 2008-06-04
-- Platform   : Xilinx ISE9.2(IP update4), ModelSim SE 6.2e
-- Targets    : XC5VLX110T-FF1136-1
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
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
use ieee.numeric_std.all;

entity PCIE_TX_ENGINE is
  port (
    clk         : in std_logic;
    rst_n       : in std_logic;
    hw_chnl_rst : in std_logic;

    -- 8 pcie core
    trn_td         : out std_logic_vector(63 downto 0);
    trn_trem_n     : out std_logic_vector(7 downto 0);
    trn_tsof_n     : out std_logic;
    trn_teof_n     : out std_logic;
    trn_tsrc_rdy_n : out std_logic;
    trn_tsrc_dsc_n : out std_logic;
    trn_tdst_rdy_n : in  std_logic;
    trn_tdst_dsc_n : in  std_logic;

    -- 2control + 10 in
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

    -- CSR ports
    csr_rd_ready : in  std_logic;
    csr_rd_done  : in  std_logic;
    csr_rd_en    : out std_logic;
    csr_rd_ack   : out std_logic;
    csr_rd_data  : in  std_logic_vector((32 - 1) downto 0);
    csr_rd_index : out std_logic_vector((8 - 1) downto 0);

    reserved_csr_rd_index : out std_logic_vector((8 -1) downto 0);
    reserved_csr_rd_data  : in  std_logic_vector((32 - 1) downto 0);


    dma_f2h_data          : in  std_logic_vector(63 downto 0);
    trn_mem_read_req_done : out std_logic;

    mwr_start_i   : in  std_logic;
    mwr_len_i     : in  std_logic_vector(31 downto 0);
    mwr_lbe_i     : in  std_logic_vector(3 downto 0);
    mwr_fbe_i     : in  std_logic_vector(3 downto 0);
    mwr_addr_i    : in  std_logic_vector(31 downto 0);
    mwr_addr_hi_i : in  std_logic_vector(31 downto 0);
    mwr_count_i   : in  std_logic_vector(31 downto 0);
    mwr_done_o    : out std_logic;

    mrd_start_i   : in std_logic;
    mrd_len_i     : in std_logic_vector(31 downto 0);
    mrd_lbe_i     : in std_logic_vector(3 downto 0);
    mrd_fbe_i     : in std_logic_vector(3 downto 0);
    mrd_addr_i    : in std_logic_vector(31 downto 0);
    mrd_addr_hi_i : in std_logic_vector(31 downto 0);
    mrd_count_i   : in std_logic_vector(31 downto 0);


    completer_id_i        : in std_logic_vector(15 downto 0);
    cfg_ext_tag_en_i      : in std_logic;
    cfg_bus_mstr_enable_i : in std_logic;


    f2h_fifo_empty : in  std_logic;
    f2h_fifo_valid : in  std_logic;
    f2h_fifo_ren   : out std_logic);

end PCIE_TX_ENGINE;

architecture rtl of PCIE_TX_ENGINE is

  --------------------------------------------------------------------------
  -- Constants for PCIe Transaction Layer Packets(TLP) type definition
  --------------------------------------------------------------------------
  constant PCIE_CPLD_FMT_TYPE  : std_logic_vector(6 downto 0) := "1001010";
  constant PCIE_MRD64_FMT_TYPE : std_logic_vector(6 downto 0) := "0100000";
  constant PCIE_MWR64_FMT_TYPE : std_logic_vector(6 downto 0) := "1100000";

  type pcie_tx_state_type is (
    PCIE_TX_RST_STATE,
    PCIE_TX_CPLD_CSR_REGULAR,
    PCIE_TX_CPLD_CSR_RESERVED,
    PCIE_TX_CPLD_CSR_REGULAR_WAIT,
    PCIE_TX_CPLD_QW1,
    PCIE_TX_CPLD_WAIT,
    PCIE_TX_MWR_QW1,
    PCIE_TX_MWR_QWN,
    PCIE_TX_MRD_QW1);
  signal pcie_tx_state : pcie_tx_state_type;

  -- signals for memory_read
  signal cur_mrd_req_count : std_logic_vector(31 downto 0);
  signal mrd_len_byte      : std_logic_vector(11 downto 0);
  signal trn_mrd_addr      : std_logic_vector(63 downto 0);
  signal tx_mrd_req        : std_logic;
  signal mrd_base_addr     : std_logic_vector(31 downto 0);
  signal mrd_base_addr_hi  : std_logic_vector(31 downto 0);

  -- added at 08.04.14
  --------------------------------------
  -- '1' - available for generating new read_reqs for memory read transactions
  -- '0' - not available for generating new read_reqs, usually it means currently
  --       certain generating of read_reqs are on processing.
  signal trn_mrd_req_done_c : std_logic;
  signal trn_mrd_req_count  : std_logic_vector(31 downto 0);

  -- signals for memory_write
  signal tx_mwr             : std_logic;
  signal read_data_en       : std_logic;
  signal cur_mwr_count      : std_logic_vector(31 downto 0);
  signal mwr_tlp_dw_count   : std_logic_vector(9 downto 0);
  signal mwr_len_byte       : std_logic_vector(11 downto 0);
  signal trn_mwr_addr       : std_logic_vector(63 downto 0);
  signal f2h_data_tmp       : std_logic_vector(63 downto 0);
  signal f2h_data_tmp_valid : std_logic;
  signal trn_td_transmitted : std_logic;
  signal trn_mwr_done       : std_logic;
  signal mwr_base_addr      : std_logic_vector(31 downto 0);
  signal mwr_base_addr_hi   : std_logic_vector(31 downto 0);
  signal trn_mwr_count      : std_logic_vector(31 downto 0);

  -- signals for completion_with_data
  signal cpld_byte_count : std_logic_vector(11 downto 0);
  signal cpld_lower_addr : std_logic_vector(6 downto 0);
  signal csr_selector    : std_logic;  --'1',select Common CSRs; '0' select Reserved CSRs
  signal trn_cpld_done   : std_logic;


begin

  mwr_done_o   <= trn_mwr_done;
  compl_done_o <= trn_cpld_done;

  f2h_fifo_ren <= (not trn_tdst_rdy_n) and (read_data_en);


  csr_rd_index          <= req_addr_i(9 downto 2);
  reserved_csr_rd_index <= req_addr_i(9 downto 2);
  csr_selector          <= req_addr_i(12);

  trn_mem_read_req_done <= trn_mrd_req_done_c;
  mwr_len_byte          <= mwr_len_i(9 downto 0) & "00";
  mrd_len_byte          <= mrd_len_i(9 downto 0) & "00";



  ---------------------------------------------------------------------------
  -- Calculate byte count based on byte enable
  ---------------------------------------------------------------------------
  process (req_be_i)
  begin
    case req_be_i(3 downto 0) is
      when "1001" | "1011" | "1101" | "1111" =>
        cpld_byte_count <= x"004";
      when "0101" | "0111" | "1010" | "1110" =>
        cpld_byte_count <= x"003";
      when "0011" | "0110" | "1100" =>
        cpld_byte_count <= x"002";
      when "0001" | "0010" | "0100" | "1000" | "0000" =>
        cpld_byte_count <= x"001";
      when others =>
        cpld_byte_count <= (others => '0');
    end case;
  end process;

  ---------------------------------------------------------------------------
  -- Calculate lower address based on  byte enable
  ---------------------------------------------------------------------------
  process (req_be_i, req_addr_i)
  begin
    case req_be_i(3 downto 0) is
      when "0000" | "0001" | "0011" | "0101" | "0111" |
        "1001" | "1011" | "1101" | "1111" =>
        cpld_lower_addr <= req_addr_i(6 downto 2) & "00";
      when "0010" | "0110" | "1010" | "1110" =>
        cpld_lower_addr <= req_addr_i(6 downto 2) & "01";
      when "0100" | "1100" =>
        cpld_lower_addr <= req_addr_i(6 downto 2) & "10";
      when "1000" =>
        cpld_lower_addr <= req_addr_i(6 downto 2) & "11";
      when others =>
        cpld_lower_addr <= (others => '0');
    end case;
  end process;

  ---------------------------------------------------------------------------
  -- Tx State Machine 
  ---------------------------------------------------------------------------
  process (clk, rst_n, hw_chnl_rst)
  begin
    if rst_n = '0' or hw_chnl_rst = '1' then
      pcie_tx_state <= PCIE_TX_RST_STATE;

      trn_tsof_n     <= '1';
      trn_teof_n     <= '1';
      trn_tsrc_rdy_n <= '1';
      trn_tsrc_dsc_n <= '1';
      trn_td         <= (others => '0');
      trn_trem_n     <= (others => '0');

      mwr_tlp_dw_count   <= (others => '0');
      mwr_base_addr      <= (others => '0');
      mwr_base_addr_hi   <= (others => '0');
      trn_mwr_count      <= (others => '0');
      cur_mwr_count      <= (others => '0');
      trn_mwr_addr       <= (others => '0');
      tx_mwr             <= '1';
      read_data_en       <= '0';
      trn_mwr_done       <= '1';
      f2h_data_tmp_valid <= '0';
      f2h_data_tmp       <= (others => '0');
      trn_td_transmitted <= '0';


      mrd_base_addr      <= (others => '0');
      mrd_base_addr_hi   <= (others => '0');
      trn_mrd_req_count  <= (others => '0');
      cur_mrd_req_count  <= (others => '0');
      trn_mrd_addr       <= (others => '0');
      tx_mrd_req         <= '1';
      trn_mrd_req_done_c <= '1';


      csr_rd_en     <= '0';
      csr_rd_ack    <= '0';
      trn_cpld_done <= '1';
    elsif rising_edge(clk) then
      -- catch the start signal to generate read request TLPs
      if (mrd_start_i = '1') then
        trn_mrd_req_done_c <= '0';
        mrd_base_addr      <= mrd_addr_i;
        mrd_base_addr_hi   <= mrd_addr_hi_i;
        trn_mrd_req_count  <= mrd_count_i;
      end if;
      -- catch the start signal to generate write TLPs
      if (mwr_start_i = '1') then
        trn_mwr_done     <= '0';
        trn_mwr_count    <= mwr_count_i;
        mwr_base_addr    <= mwr_addr_i;
        mwr_base_addr_hi <= mwr_addr_hi_i;
      end if;
      -- catch the start signal to CPLD(ComPLetion with Data)
      if (req_compl_i = '1') then
        trn_cpld_done <= '0';
      end if;

      case pcie_tx_state is
        when PCIE_TX_RST_STATE =>
          if (trn_tdst_rdy_n = '0') then
            if (trn_cpld_done = '0') then
              trn_tsof_n     <= '0';
              trn_teof_n     <= '1';
              trn_tsrc_rdy_n <= '0';
              trn_trem_n     <= (others => '0');

              trn_td(63)           <= '0';
              trn_td(62 downto 56) <= PCIE_CPLD_FMT_TYPE;
              trn_td(55)           <= '0';
              trn_td(54 downto 52) <= req_tc_i;
              trn_td(51 downto 48) <= "0000";
              trn_td(47)           <= req_td_i;
              trn_td(46)           <= req_ep_i;
              trn_td(45 downto 44) <= req_attr_i;
              trn_td(43 downto 42) <= "00";
              trn_td(41 downto 32) <= req_len_i;
              trn_td(31 downto 16) <= completer_id_i;
              trn_td(15 downto 13) <= "000";
              trn_td(12)           <= '0';
              trn_td(11 downto 0)  <= cpld_byte_count;

              if (csr_selector = '1') then  -- common csr
                if (csr_rd_ready = '1') then
                  csr_rd_en     <= '1';
                  csr_rd_ack    <= '0';
                  pcie_tx_state <= PCIE_TX_CPLD_CSR_REGULAR;
                else
                  csr_rd_en     <= '0';
                  csr_rd_ack    <= '0';
                  pcie_tx_state <= PCIE_TX_CPLD_CSR_REGULAR_WAIT;
                end if;
              else                          -- reserved csr
                pcie_tx_state <= PCIE_TX_CPLD_CSR_RESERVED;
              end if;
              
            elsif (trn_mwr_done = '0'  -- generating of write TLPs is not completed
                   and tx_mwr = '1'  -- it's time to generate write in Duplex transactions
                   and cfg_bus_mstr_enable_i = '1') then                                                                

              trn_tsof_n     <= '0';
              trn_teof_n     <= '1';
              trn_tsrc_rdy_n <= '0';
              -- trn_td
              ---------------------------------------------------
              trn_td(63 downto 16) <= ('0' &
                                       PCIE_MWR64_FMT_TYPE &
                                       '0' &
                                       req_tc_i &
                                       "0000" &
                                       '0' &
                                       '0' &
                                       "00" &
                                       "00" &
                                       mwr_len_i(9 downto 0) &
                                       completer_id_i);         

              if cfg_ext_tag_en_i = '1' then
                trn_td(15 downto 8) <= cur_mwr_count(7 downto 0);
              else
                trn_td(15 downto 13) <= "000";
                trn_td(12 downto 8)  <= cur_mwr_count(4 downto 0);
              end if;

              if mwr_len_i(9 downto 0) = "0000000001" then
                trn_td(7 downto 4) <= "0000";
              else
                trn_td(7 downto 4) <= mwr_lbe_i;
              end if;

              trn_td(3 downto 0) <= mwr_fbe_i;
              ---------------------------------------------------

              trn_trem_n       <= (others => '0');
              mwr_tlp_dw_count <= mwr_len_i(9 downto 0);

              if cur_mwr_count = x"00000000" then
                trn_mwr_addr <= mwr_base_addr_hi & mwr_base_addr;
              else
                trn_mwr_addr <= trn_mwr_addr + mwr_len_byte;
              end if;

              if (trn_mrd_req_done_c = '0') then
                tx_mwr     <= '0';
                tx_mrd_req <= '1';
              end if;
              f2h_data_tmp_valid <= '0';
              read_data_en       <= '1';
              pcie_tx_state      <= PCIE_TX_MWR_QW1;
              
            elsif (trn_mrd_req_done_c = '0'  -- generating of read_req is not completed
                   and tx_mrd_req = '1'  -- it's time to generate read_req in Duplex transactions
                   and cfg_bus_mstr_enable_i = '1') then

              trn_tsof_n     <= '0';
              trn_teof_n     <= '1';
              trn_tsrc_rdy_n <= '0';
              -- trn_td
              ---------------------------------------------------
              trn_td(63 downto 16) <= ('0' &
                                       PCIE_MRD64_FMT_TYPE &
                                       '0' &
                                       req_tc_i &
                                       "0000" &
                                       '0' &
                                       '0' &
                                       "00" &
                                       "00" &
                                       mrd_len_i(9 downto 0) &
                                       completer_id_i);  

              if cfg_ext_tag_en_i = '1' then
                trn_td(15 downto 8) <= cur_mrd_req_count(7 downto 0);
              else
                trn_td(15 downto 8) <= ("000" & cur_mrd_req_count(4 downto 0));
              end if;

              if mrd_len_i(9 downto 0) = "0000000001" then
                trn_td(7 downto 4) <= "0000";
              else
                trn_td(7 downto 4) <= mrd_lbe_i;
              end if;

              trn_td(3 downto 0) <= mrd_fbe_i;

              ---------------------------------------------------
              trn_trem_n <= (others => '0');
              if cur_mrd_req_count = 0 then
                trn_mrd_addr <= mrd_base_addr_hi & mrd_base_addr;
              else
                trn_mrd_addr <= trn_mrd_addr + mrd_len_byte;
              end if;

              -- Round robin
              if (trn_mwr_done = '0') then
                tx_mwr     <= '1';
                tx_mrd_req <= '0';
              end if;

              pcie_tx_state <= PCIE_TX_MRD_QW1;

            else  -- nothing to do, reset all control signals
              trn_tsof_n     <= '1';
              trn_teof_n     <= '1';
              trn_tsrc_rdy_n <= '1';
              trn_tsrc_dsc_n <= '1';
              trn_td         <= (others => '0');
              trn_trem_n     <= (others => '0');
              pcie_tx_state  <= PCIE_TX_RST_STATE;
            end if;
          else
            trn_tsof_n     <= '1';
            trn_tsrc_rdy_n <= '0';
            read_data_en   <= '0';
            pcie_tx_state  <= PCIE_TX_RST_STATE;
          end if;
          
        when PCIE_TX_CPLD_CSR_RESERVED =>
          -- wait a cycle to get the data
          if (trn_tdst_rdy_n = '0') then
            trn_tsrc_rdy_n <= '1';
            pcie_tx_state  <= PCIE_TX_CPLD_QW1;
          else
            trn_tsrc_rdy_n <= '0';
            pcie_tx_state  <= PCIE_TX_CPLD_CSR_RESERVED;
          end if;
          
        when PCIE_TX_CPLD_CSR_REGULAR =>
          csr_rd_en      <= '0';
          trn_tsrc_rdy_n <= '1';
          csr_rd_ack     <= '0';
          if (csr_rd_done = '1') then
            pcie_tx_state <= PCIE_TX_CPLD_QW1;
          else
            pcie_tx_state <= PCIE_TX_CPLD_CSR_REGULAR;
          end if;
          
        when PCIE_TX_CPLD_CSR_REGULAR_WAIT =>
          if (csr_rd_ready = '1' and trn_tdst_rdy_n = '0') then
            csr_rd_en      <= '1';
            csr_rd_ack     <= '0';
            trn_tsrc_rdy_n <= '1';
            pcie_tx_state  <= PCIE_TX_CPLD_CSR_REGULAR;
          elsif (trn_tdst_rdy_n = '0') then
            csr_rd_en      <= '0';
            csr_rd_ack     <= '0';
            trn_tsrc_rdy_n <= '1';
            pcie_tx_state  <= PCIE_TX_CPLD_CSR_REGULAR_WAIT;
          else
            csr_rd_en      <= '0';
            csr_rd_ack     <= '0';
            trn_tsrc_rdy_n <= '0';
            pcie_tx_state  <= PCIE_TX_CPLD_CSR_REGULAR_WAIT;
          end if;
          
          
          
        when PCIE_TX_CPLD_QW1 =>
          if (trn_tdst_rdy_n = '0' and trn_tdst_dsc_n = '1') then
            trn_tsof_n     <= '1';
            trn_teof_n     <= '0';
            trn_tsrc_rdy_n <= '0';
            trn_td(63 downto 32) <= (req_rid_i &
                                     req_tag_i &
                                     '0' &
                                     cpld_lower_addr);
            if (csr_selector = '1') then
              trn_td(31 downto 0) <= csr_rd_data;
            else
              trn_td(31 downto 0) <= reserved_csr_rd_data;
            end if;

            trn_trem_n    <= (others => '0');
            pcie_tx_state <= PCIE_TX_CPLD_WAIT;
          elsif (trn_tdst_dsc_n = '0') then
            trn_tsrc_dsc_n <= '0';
            pcie_tx_state  <= PCIE_TX_CPLD_WAIT;
          else                          -- source not ready 
            pcie_tx_state <= PCIE_TX_CPLD_QW1;
          end if;
          
        when PCIE_TX_CPLD_WAIT =>
          if (trn_tdst_rdy_n = '0' or trn_tdst_dsc_n = '0') then
            trn_tsof_n     <= '1';
            trn_teof_n     <= '1';
            trn_tsrc_rdy_n <= '1';
            trn_tsrc_dsc_n <= '1';
            if (csr_selector = '1') then
              csr_rd_ack <= '1';
            end if;
            csr_rd_en     <= '0';
            trn_cpld_done <= '1';
            pcie_tx_state <= PCIE_TX_RST_STATE;
          else
            if (csr_selector = '1') then
              csr_rd_ack <= '0';
            end if;
            pcie_tx_state <= PCIE_TX_CPLD_WAIT;
          end if;
          
        when PCIE_TX_MWR_QW1 =>
          if ((trn_tdst_rdy_n = '0' and trn_tdst_dsc_n = '1')) then  -- Previous TLP has been send             
            trn_tsof_n <= '1';

            -- assert src_rdy
            trn_tsrc_rdy_n <= '0';
            -- place data on data_bus
            trn_td         <= (trn_mwr_addr(63 downto 2) & "00");

            f2h_data_tmp_valid <= '0';

            if (cur_mwr_count = (trn_mwr_count - 1)) then
              cur_mwr_count <= (others => '0');
            else
              cur_mwr_count <= cur_mwr_count + 1;
            end if;

            trn_td_transmitted <= '0';

            pcie_tx_state <= PCIE_TX_MWR_QWN;
            
          elsif trn_tdst_dsc_n = '0' then
            read_data_en   <= '0';
            trn_tsrc_dsc_n <= '0';
            pcie_tx_state  <= PCIE_TX_RST_STATE;
          -- TX interface is temporarily unavailable
          else
            trn_tsrc_rdy_n <= '0';
            read_data_en   <= '1';
            if (f2h_fifo_valid = '1') then  -- there is data need to be buffered.
              if (f2h_data_tmp_valid = '1') then
                f2h_data_tmp <= f2h_data_tmp;
              else
                f2h_data_tmp       <= dma_f2h_data;
                f2h_data_tmp_valid <= '1';
              end if;
            end if;
            pcie_tx_state <= PCIE_TX_MWR_QW1;
          end if;
          
          
        when PCIE_TX_MWR_QWN =>
          if (trn_tdst_rdy_n = '0') then          -- try to send next QW
            trn_td_transmitted <= '1';
            if (f2h_fifo_empty = '0') then        -- data FIFO is ready
              if (f2h_data_tmp_valid = '0') then  -- use fifo
                                                  -- form QW with fifo, enable FIFO
                if (f2h_fifo_valid = '1') then
                  trn_td(63 downto 32) <= dma_f2h_data(31 downto 0);
                  trn_td(31 downto 0)  <= dma_f2h_data(63 downto 32);
                  trn_tsrc_rdy_n       <= '0';
                  trn_td_transmitted   <= '0';

                  if (mwr_tlp_dw_count = "10") then  -- the last QW of TLP
                    trn_trem_n <= X"00";
                    trn_teof_n <= '0';
                    if (cur_mwr_count = X"00000000") then  -- the last TLP of transaction
                      mwr_tlp_dw_count   <= (others => '0');
                      cur_mwr_count      <= (others => '0');
                      trn_mwr_addr       <= (others => '0');
                      f2h_data_tmp       <= (others => '0');
                      read_data_en       <= '0';
                      f2h_data_tmp_valid <= '0';
                      tx_mwr             <= '1';
                      trn_mwr_done       <= '1';
                    end if;
                    pcie_tx_state <= PCIE_TX_RST_STATE;
                  else
                    trn_trem_n    <= X"FF";
                    trn_teof_n    <= '1';
                    pcie_tx_state <= PCIE_TX_MWR_QWN;
                  end if;

                  if (mwr_tlp_dw_count > "100") then
                    read_data_en <= '1';
                  else
                    read_data_en <= '0';
                  end if;

                  mwr_tlp_dw_count <= mwr_tlp_dw_count - 2;
                else
                  trn_tsrc_rdy_n <= '1';
                  read_data_en   <= '1';
                  pcie_tx_state  <= PCIE_TX_MWR_QWN;
                end if;
              else                      -- use buffer data
                -- form QW with buffer, enable FIFO
                trn_td(63 downto 32) <= f2h_data_tmp(31 downto 0);
                trn_td(31 downto 0)  <= f2h_data_tmp(63 downto 32);
                trn_tsrc_rdy_n       <= '0';
                trn_td_transmitted   <= '0';
                f2h_data_tmp_valid   <= '0';

                -- handling the last QW(including the last TLP of transaction)
                if (mwr_tlp_dw_count = "10") then        -- the last QW of TLP
                  trn_trem_n <= X"00";
                  trn_teof_n <= '0';
                  if (cur_mwr_count = X"00000000") then  -- the last TLP of transaction
                    mwr_tlp_dw_count   <= (others => '0');
                    cur_mwr_count      <= (others => '0');
                    trn_mwr_addr       <= (others => '0');
                    f2h_data_tmp       <= (others => '0');
                    read_data_en       <= '0';
                    f2h_data_tmp_valid <= '0';
                    tx_mwr             <= '1';
                    trn_mwr_done       <= '1';
                  end if;
                  pcie_tx_state <= PCIE_TX_RST_STATE;
                else
                  trn_trem_n    <= X"FF";
                  trn_teof_n    <= '1';
                  pcie_tx_state <= PCIE_TX_MWR_QWN;
                end if;

                if (mwr_tlp_dw_count > "100") then
                  read_data_en <= '1';
                else
                  read_data_en <= '0';
                end if;

                mwr_tlp_dw_count <= mwr_tlp_dw_count - 2;
              end if;
            else                                  -- FIFO is not ready
              if (f2h_data_tmp_valid = '0') then  -- use fifo
                if (f2h_fifo_valid = '1') then
                  trn_td(63 downto 32) <= dma_f2h_data(31 downto 0);
                  trn_td(31 downto 0)  <= dma_f2h_data(63 downto 32);
                  trn_tsrc_rdy_n       <= '0';
                  trn_td_transmitted   <= '0';

                  if (mwr_tlp_dw_count = "10") then  -- the last QW of TLP
                    trn_trem_n <= X"00";
                    trn_teof_n <= '0';
                    if (cur_mwr_count = X"00000000") then  -- the last TLP of transaction
                      mwr_tlp_dw_count   <= (others => '0');
                      cur_mwr_count      <= (others => '0');
                      trn_mwr_addr       <= (others => '0');
                      f2h_data_tmp       <= (others => '0');
                      read_data_en       <= '0';
                      f2h_data_tmp_valid <= '0';
                      tx_mwr             <= '1';
                      trn_mwr_done       <= '1';
                    end if;
                    pcie_tx_state <= PCIE_TX_RST_STATE;
                  else
                    trn_trem_n    <= X"FF";
                    trn_teof_n    <= '1';
                    pcie_tx_state <= PCIE_TX_MWR_QWN;
                  end if;

                  if (mwr_tlp_dw_count > "100") then
                    read_data_en <= '1';
                  else
                    read_data_en <= '0';
                  end if;

                  mwr_tlp_dw_count <= mwr_tlp_dw_count - 2;
                else
                  trn_tsrc_rdy_n <= '1';
                  read_data_en   <= '0';
                  pcie_tx_state  <= PCIE_TX_MWR_QWN;
                end if;
              else
                trn_td(63 downto 32) <= f2h_data_tmp(31 downto 0);
                trn_td(31 downto 0)  <= f2h_data_tmp(63 downto 32);
                trn_tsrc_rdy_n       <= '0';
                trn_td_transmitted   <= '0';
                f2h_data_tmp_valid   <= '0';

                -- handling the last QW(including the last TLP of transaction)
                if (mwr_tlp_dw_count = "10") then        -- the last QW of TLP
                  trn_trem_n <= X"00";
                  trn_teof_n <= '0';
                  if (cur_mwr_count = X"00000000") then  -- the last TLP of transaction
                    mwr_tlp_dw_count   <= (others => '0');
                    cur_mwr_count      <= (others => '0');
                    trn_mwr_addr       <= (others => '0');
                    f2h_data_tmp       <= (others => '0');
                    read_data_en       <= '0';
                    f2h_data_tmp_valid <= '0';
                    tx_mwr             <= '1';
                    trn_mwr_done       <= '1';
                  end if;
                  pcie_tx_state <= PCIE_TX_RST_STATE;
                else
                  trn_trem_n    <= X"FF";
                  trn_teof_n    <= '1';
                  pcie_tx_state <= PCIE_TX_MWR_QWN;
                end if;

                if (mwr_tlp_dw_count > "100") then
                  read_data_en <= '1';
                else
                  read_data_en <= '0';
                end if;

                mwr_tlp_dw_count <= mwr_tlp_dw_count - 2;
              end if;
            end if;
          else                          -- link is not ready
            -- modification for the case of during the span of fifo empty, trn_tdst_rdy_n deasserted
            if (trn_td_transmitted = '1') then
              trn_tsrc_rdy_n <= '1';
            else
              trn_tsrc_rdy_n <= '0';
            end if;

            if (mwr_tlp_dw_count > "10") then
              read_data_en <= '1';
            else
              read_data_en <= '0';
            end if;

            if (f2h_fifo_valid = '1') then  -- there is data need to be buffered.
              if (f2h_data_tmp_valid = '1') then
                f2h_data_tmp <= f2h_data_tmp;
              else
                f2h_data_tmp       <= dma_f2h_data;
                f2h_data_tmp_valid <= '1';
              end if;
            end if;
            pcie_tx_state <= PCIE_TX_MWR_QWN;
          end if;
          
        when PCIE_TX_MRD_QW1 =>
          if trn_tdst_rdy_n = '0' and trn_tdst_dsc_n = '1' then
            trn_tsof_n     <= '1';
            trn_teof_n     <= '0';
            trn_tsrc_rdy_n <= '0';
            trn_td         <= (trn_mrd_addr(63 downto 2) & "00");
            trn_trem_n     <= x"00";

            if cur_mrd_req_count = (trn_mrd_req_count - 1) then
              cur_mrd_req_count  <= (others => '0');
              trn_mrd_addr       <= (others => '0');
              tx_mrd_req         <= '1';
              trn_mrd_req_done_c <= '1';
            else
              cur_mrd_req_count <= cur_mrd_req_count + 1;
            end if;

            pcie_tx_state <= PCIE_TX_RST_STATE;
          elsif trn_tdst_dsc_n = '0' then
            pcie_tx_state  <= PCIE_TX_RST_STATE;
            trn_tsrc_dsc_n <= '0';
          else
            pcie_tx_state <= PCIE_TX_MRD_QW1;
          end if;
          
      end case;
    end if;
  end process;


end rtl;
