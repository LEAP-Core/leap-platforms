-------------------------------------------------------------------------------
-- Title        : PCIe TX Wrapper
-- Project      : 
-------------------------------------------------------------------------------
-- File         : pcie_tx_wrapper.vhd
-- Author       : Wang, Liang  <liang.wang@intel.com>
-- Company      : CTL Beijing, Intel
-- Created      : 2008-10-17
-- Last update  : 2008-10-17
-- Platform     : Virtex 5 vlx110t-ff1136-1
-- Targets      : XC5VLX110T-FF1136-1
-- Simulators   : ModelSim SE 6.2e
-- Synthesizers : XST embedded in ISE
-- Standard     : VHDL'87
-------------------------------------------------------------------------------
-- Description: wrap the pcie basic interface of TX
-------------------------------------------------------------------------------
-- Copyright (c) 2008 CTL Beijing, Intel
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2008-10-17  1.0      lwang12 Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity pcie_tx_wrapper is
  
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

end pcie_tx_wrapper;

architecture rtl of pcie_tx_wrapper is

  -- Constants for PCIe Transaction Layer Packets(TLP) type definition
  constant PCIE_CPLD_FMT_TYPE  : std_logic_vector(6 downto 0) := "1001010";
  constant PCIE_MRD64_FMT_TYPE : std_logic_vector(6 downto 0) := "0100000";
  constant PCIE_MWR64_FMT_TYPE : std_logic_vector(6 downto 0) := "1100000";
  
  type pcie_tx_state_type is (
    PCIE_TX_CPLD_QW1,
    PCIE_TX_CPLD_QW_LAST,
    PCIE_TX_MRD64_REQ_QW1,
    PCIE_TX_MRD64_REQ_QW_LAST,
    PCIE_TX_MWR64_QW1,
    PCIE_TX_MWR64_QWN,
    PCIE_TX_MWR64_QW_LAST,
    PCIE_TX_RST);
  signal pcie_tx_state : pcie_tx_state_type;


  constant DO_TX_CPLD      : std_logic_vector(2 downto 0) := "001";
  constant DO_TX_MRD64_REQ : std_logic_vector(2 downto 0) := "010";
  constant DO_TX_MWR64     : std_logic_vector(2 downto 0) := "100";
  constant DO_NOTHING      : std_logic_vector(2 downto 0) := "000";

  signal tx_sel_flag : std_logic_vector(2 downto 0);
  signal tx_busy     : std_logic;       -- whether processing a transaction

  -- signals for CPLD
  signal cpld_byte_count : std_logic_vector(11 downto 0);
  signal cpld_lower_addr : std_logic_vector(6 downto 0);


  -- singals for Memory Write
  signal f2h_data_tmp_valid : std_logic;
  signal f2h_data_tmp       : std_logic_vector(63 downto 0);
  signal mwr64_len_rem      : std_logic_vector(9 downto 0);  -- counted in DWs

  --signals for buffering input ports
  signal mrd32_req_len_c  : std_logic_vector(9 downto 0);
  signal mrd32_req_addr_c : std_logic_vector(31 downto 0);
  signal mrd32_req_data_c : std_logic_vector(31 downto 0);
  signal mrd64_req_tag_c  : std_logic_vector(7 downto 0);
  signal mrd64_req_len_c  : std_logic_vector(9 downto 0);
  signal mrd64_req_addr_c : std_logic_vector(63 downto 0);
  signal mwr64_len_c      : std_logic_vector(9 downto 0);
  signal mwr64_tag_c      : std_logic_vector(7 downto 0);
  signal mwr64_addr_c     : std_logic_vector(63 downto 0);

  signal priority_counter : std_logic_vector(3 downto 0);
begin  -- rtl

  -- purpose: Calculate byte count based on byte enable
  -- type   : combinational
  -- inputs : mrd32_req_be
  -- outputs: cpld_byte_count
  calc_be : process (mrd32_req_be)
  begin  -- process calc_be
    case mrd32_req_be(3 downto 0) is
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
  end process calc_be;

  -- purpose: Calculate lower address based on byte enable
  -- type   : combinational
  -- inputs : mrd32_req_be, mrd32_req_addr
  -- outputs: cpld_lower_addr
  calc_laddr : process (mrd32_req_be, mrd32_req_addr)
  begin  -- process calc_laddr
    case mrd32_req_be(3 downto 0) is
      when "0000" | "0001" | "0011" | "0101" | "0111" |
        "1001" | "1011" | "1101" | "1111" =>
        cpld_lower_addr <= mrd32_req_addr(6 downto 2) & "00";
      when "0010" | "0110" | "1010" | "1110" =>
        cpld_lower_addr <= mrd32_req_addr(6 downto 2) & "01";
      when "0100" | "1100" =>
        cpld_lower_addr <= mrd32_req_addr(6 downto 2) & "10";
      when "1000" =>
        cpld_lower_addr <= mrd32_req_addr(6 downto 2) & "11";
      when others =>
        cpld_lower_addr <= (others => '0');
    end case;
  end process calc_laddr;


  arbitrator : process (clk, rst_n)
  begin  -- process arbitrator
    if (rst_n = '0') then               -- asynchronous reset (active low)
      priority_counter <= (others => '0');

      mrd32_req_len_c  <= (others => '0');
      mrd32_req_data_c <= (others => '0');

      mrd64_req_len_c  <= (others => '0');
      mrd64_req_tag_c  <= (others => '0');
      mrd64_req_addr_c <= (others => '0');

      mwr64_len_c  <= (others => '0');
      mwr64_tag_c  <= (others => '0');
      mwr64_addr_c <= (others => '0');

      tx_sel_flag <= DO_NOTHING;
    elsif (rising_edge(clk)) then       -- rising clock edge
      case pcie_tx_state is
        when PCIE_TX_CPLD_QW_LAST|PCIE_TX_MWR64_QW_LAST|PCIE_TX_MRD64_REQ_QW_LAST =>
          if (cpld_start = '1') then
            mrd32_req_len_c  <= mrd32_req_len;
            mrd32_req_data_c <= mrd32_req_data;

            tx_sel_flag <= DO_TX_CPLD;
          elsif (mrd64_req_start = '1') then
            if (mwr64_start = '1') then
              if (priority_counter(3) = '1') then
                mwr64_len_c  <= mwr64_len;
                mwr64_tag_c  <= mwr64_tag;
                mwr64_addr_c <= mwr64_addr;

                tx_sel_flag <= DO_TX_MWR64;
              else
                mrd64_req_len_c  <= mrd64_req_len;
                mrd64_req_tag_c  <= mrd64_req_tag;
                mrd64_req_addr_c <= mrd64_req_addr;

                tx_sel_flag <= DO_TX_MRD64_REQ;
              end if;
              priority_counter <= priority_counter + 1;
            else
              mrd64_req_len_c  <= mrd64_req_len;
              mrd64_req_tag_c  <= mrd64_req_tag;
              mrd64_req_addr_c <= mrd64_req_addr;

              tx_sel_flag <= DO_TX_MRD64_REQ;

              priority_counter <= (others => '0');
            end if;
          elsif (mwr64_start = '1') then
            mwr64_len_c  <= mwr64_len;
            mwr64_tag_c  <= mwr64_tag;
            mwr64_addr_c <= mwr64_addr;

            tx_sel_flag <= DO_TX_MWR64;

            priority_counter <= (others => '0');
          else
            tx_sel_flag <= DO_NOTHING;
          end if;

        when PCIE_TX_RST =>
          if (tx_sel_flag = DO_NOTHING) then
            if (cpld_start = '1') then
              mrd32_req_len_c  <= mrd32_req_len;
              mrd32_req_data_c <= mrd32_req_data;

              tx_sel_flag <= DO_TX_CPLD;
            elsif (mrd64_req_start = '1') then
              if (mwr64_start = '1') then
                if (priority_counter(3) = '1') then
                  mwr64_len_c  <= mwr64_len;
                  mwr64_tag_c  <= mwr64_tag;
                  mwr64_addr_c <= mwr64_addr;

                  tx_sel_flag <= DO_TX_MWR64;
                else
                  mrd64_req_len_c  <= mrd64_req_len;
                  mrd64_req_tag_c  <= mrd64_req_tag;
                  mrd64_req_addr_c <= mrd64_req_addr;

                  tx_sel_flag <= DO_TX_MRD64_REQ;
                end if;
                priority_counter <= priority_counter + 1;
              else
                mrd64_req_len_c  <= mrd64_req_len;
                mrd64_req_tag_c  <= mrd64_req_tag;
                mrd64_req_addr_c <= mrd64_req_addr;

                tx_sel_flag <= DO_TX_MRD64_REQ;

                priority_counter <= (others => '0');
              end if;
            elsif (mwr64_start = '1') then
              mwr64_len_c  <= mwr64_len;
              mwr64_tag_c  <= mwr64_tag;
              mwr64_addr_c <= mwr64_addr;

              tx_sel_flag <= DO_TX_MWR64;

              priority_counter <= (others => '0');
            else
              tx_sel_flag <= DO_NOTHING;
            end if;
          end if;
        when others => null;
      end case;
    end if;
  end process arbitrator;

  cpld_ack : process (clk, rst_n)
  begin  -- process reg_cpld_signal
    if (rst_n = '0') then               -- asynchronous reset (active low)
      cpld_start_ack <= '0';

    elsif (rising_edge(clk)) then       -- rising clock edge
      if (pcie_tx_state = PCIE_TX_RST and tx_sel_flag = DO_TX_CPLD) then
        cpld_start_ack <= '1';
      else
        cpld_start_ack <= '0';
      end if;
    end if;
  end process cpld_ack;

  mrd64_req_ack : process (clk, rst_n)
  begin  -- process mrd64_req_ack
    if (rst_n = '0') then               -- asynchronous reset (active low)
      mrd64_req_start_ack <= '0';
      
    elsif (rising_edge(clk)) then       -- rising clock edge
      if (pcie_tx_state = PCIE_TX_RST and tx_sel_flag = DO_TX_MRD64_REQ) then
        mrd64_req_start_ack <= '1';
      else
        mrd64_req_start_ack <= '0';
      end if;
    end if;
  end process mrd64_req_ack;

  mwr64_ack : process (clk, rst_n)
  begin  -- process mwr64_ack
    if (rst_n = '0') then               -- asynchronous reset (active low)
      mwr64_start_ack <= '0';
    elsif (rising_edge(clk)) then       -- rising clock edge
      if (pcie_tx_state = PCIE_TX_RST and tx_sel_flag = DO_TX_MWR64) then
        mwr64_start_ack <= '1';
      else
        mwr64_start_ack <= '0';
      end if;
    end if;
  end process mwr64_ack;




  -- purpose: The main state machine of pcie_tx_wrapper
  -- type   : sequential
  -- inputs : clk, rst_n
  -- outputs: 
  main_sm : process (clk, rst_n)
  begin  -- process main_sm
    if (rst_n = '0') then               -- asynchronous reset (active low)
      -- reset state machine
      pcie_tx_state <= PCIE_TX_RST;

      -- reset signals for PCIe core
      trn_tsof_n     <= '1';
      trn_teof_n     <= '1';
      trn_tsrc_rdy_n <= '1';
      trn_td         <= (others => '0');
      trn_trem_n     <= (others => '0');

      -- output signals for CPLD
      cpld_finish <= '1';

      -- signals for Memory Write
      mwr64_finish  <= '1';
      mwr64_len_rem <= (others => '0');
      f2h_fifo_ren  <= '0';

      f2h_data_tmp       <= (others => '0');
      f2h_data_tmp_valid <= '0';

      -- signals for Memory Read Request
      mrd64_req_finish <= '1';

      -- signals with arbitrator
      tx_busy <= '0';
      
    elsif (rising_edge(clk)) then       -- rising clock edge
      case pcie_tx_state is
        when PCIE_TX_RST =>
--          if (trn_tdst_rdy_n = '0') then
          case tx_sel_flag is
            when DO_TX_CPLD =>
              trn_tsof_n     <= '0';
              trn_teof_n     <= '1';
              trn_tsrc_rdy_n <= '0';
              trn_trem_n     <= (others => '0');

              trn_td <= ('0' &          -- [63]: Reserved                  
                         PCIE_CPLD_FMT_TYPE &  -- [62:56]: Fmt & Type
                         '0' &          -- [55]: Reserved
                         mrd32_req_tc &     -- [54:52]: Traffic class 
                         "0000" &       -- [51: 48]: Reserved
                         mrd32_req_td &     -- [47]: TD
                         mrd32_req_ep &     -- [46]: EP
                         mrd32_req_attr &   -- [45:44]: Attr
                         "00" &         -- [43:42]: Reserved
                         mrd32_req_len_c &  -- [41:32]: Length(counted in DWords)
                         cfg_completer_id &    -- [31:16]: Completer ID
                         "000" &        -- [15:13]: Completion Status
                         '0' &          -- [12]: Reserved
                         cpld_byte_count);  -- [11:0]: Byte Count

              cpld_finish <= '0';

              tx_busy <= '1';

              pcie_tx_state <= PCIE_TX_CPLD_QW1;

            when DO_TX_MRD64_REQ =>
              trn_tsof_n     <= '0';
              trn_teof_n     <= '1';
              trn_tsrc_rdy_n <= '0';
              trn_trem_n     <= (others => '0');

              trn_td <= ('0' &          -- [63]: Reserved
                         PCIE_MRD64_FMT_TYPE &  -- [62:56] Fmt & Type
                         '0' &          -- [55]: Reserved
                         "000" &  -- [54:52]:Traffic class(Spec v1.1, Section 2.6.6.6)
                         "0000" &       -- [51:48]: Reserved
                         '0' &          -- [47]: TD
                         '0' &          -- [46]: EP
                         "10" &         -- [45:44]: Attr
                         "00" &         -- [43:42]: reseved
                         mrd64_req_len_c &  -- [41:32]: Length(counted in DWords)
                         cfg_completer_id &     -- [31:16]: requester ID
                         mrd64_req_tag_c &  -- [15:8]: request tag
                         "1111" &       -- [7:4]: request last byte enable
                         "1111");       -- [3:0]: request fisrt byte enable

              mrd64_req_finish <= '0';

              tx_busy <= '1';

              pcie_tx_state <= PCIE_TX_MRD64_REQ_QW1;

            when DO_TX_MWR64 =>
              trn_tsof_n     <= '0';
              trn_teof_n     <= '1';
              trn_tsrc_rdy_n <= '0';
              trn_trem_n     <= (others => '0');

              trn_td <= ('0' &          -- [63]: reserved
                         PCIE_MWR64_FMT_TYPE &  -- [62:56]: format&type
                         '0' &          -- [55]: reserved
                         "000" &        -- [54:52]: traffic class
                         "0000" &       -- [51:48]: reserved
                         '0' &          -- [47]: td
                         '0' &          -- [46]: ep
                         "00" &         -- [45:44]: attr
                         "00" &         -- [43:42]: reserved
                         mwr64_len_c &  -- [41:32]: length(counted in dwords)
                         cfg_completer_id &     -- [31:16]: requester id
                         x"00" &  -- [15:8]: requester tag(Spec v1.1, Section 2.2.6.2)
                         "1111" &       -- [7:4]: last dword's byte enable
                         "1111");       -- [3:0]: first dword's byte enable

              mwr64_len_rem <= mwr64_len;

              mwr64_finish <= '0';

              tx_busy <= '1';

              pcie_tx_state <= PCIE_TX_MWR64_QW1;

            when others =>

              trn_tsof_n     <= '1';
              trn_teof_n     <= '1';
              trn_tsrc_rdy_n <= '1';
              trn_trem_n     <= (others => '0');

              trn_td <= (others => '0');

              tx_busy <= '0';

              pcie_tx_state <= PCIE_TX_RST;

          end case;
--          else
          -- wait for the last tlp to be sent
          -- keep all signals as they are
--            trn_tsof_n     <= '1';
--            trn_tsrc_rdy_n <= '0';

--            tx_busy <= '1';

--            pcie_tx_state <= PCIE_TX_RST;
--          end if;

        when PCIE_TX_CPLD_QW1 =>
          if (trn_tdst_rdy_n = '0') then
            trn_tsof_n     <= '1';
            trn_teof_n     <= '0';
            trn_tsrc_rdy_n <= '0';

            trn_td(63 downto 32) <= (mrd32_req_rid &
                                     mrd32_req_tag &
                                     '0' &
                                     cpld_lower_addr);
            trn_td(31 downto 0) <= mrd32_req_data_c;

            trn_trem_n <= (others => '0');

            pcie_tx_state <= PCIE_TX_CPLD_QW_LAST;
          else
            pcie_tx_state <= PCIE_TX_CPLD_QW1;
          end if;

        when PCIE_TX_CPLD_QW_LAST =>
          if (trn_tdst_rdy_n = '0') then
            trn_tsrc_rdy_n <= '1';
            trn_tsof_n     <= '1';
            trn_teof_n     <= '1';

            cpld_finish <= '1';
            tx_busy     <= '0';

            pcie_tx_state <= PCIE_TX_RST;
          else
            pcie_tx_state <= PCIE_TX_CPLD_QW_LAST;
          end if;

        when PCIE_TX_MWR64_QW1 =>
          if (trn_tdst_rdy_n = '0') then
            trn_tsof_n     <= '1';
            trn_tsrc_rdy_n <= '0';

            f2h_fifo_ren <= '1';

            trn_td <= mwr64_addr_c(63 downto 2) & "00";

            pcie_tx_state <= PCIE_TX_MWR64_QWN;
          else
            pcie_tx_state <= PCIE_TX_MWR64_QW1;
          end if;

        when PCIE_TX_MWR64_QWN =>
          if (trn_tdst_rdy_n = '0') then
            if (f2h_fifo_valid = '1') then
              if (f2h_data_tmp_valid = '1') then
                trn_td(63 downto 32) <= f2h_data_tmp(31 downto 0);
                trn_td(31 downto 0)  <= f2h_data_tmp(63 downto 32);
                f2h_data_tmp_valid   <= '0';
              else
                trn_td(63 downto 32) <= f2h_fifo_data(31 downto 0);
                trn_td(31 downto 0)  <= f2h_fifo_data(63 downto 32);
              end if;  -- f2h_data_tmp_valid

              trn_tsrc_rdy_n <= '0';

              mwr64_len_rem <= mwr64_len_rem - 2;  -- take effect at the next cycle.

              if (mwr64_len_rem = "0000000010") then
                -- the last QW of current TLP
--                trn_trem_n <= X"00";
                trn_teof_n <= '0';
                trn_trem_n <= (others => '0');

                f2h_fifo_ren <= '0';

                pcie_tx_state <= PCIE_TX_MWR64_QW_LAST;
              else
--                trn_trem_n <= X"00";
                trn_teof_n <= '1';
                trn_trem_n <= (others => '1');

                f2h_fifo_ren <= '1';

                pcie_tx_state <= PCIE_TX_MWR64_QWN;
              end if;
              
            else                        --f2h_fifo_valid='0'
              trn_tsrc_rdy_n <= '1';
              trn_teof_n     <= '1';
              trn_trem_n     <= (others => '1');

              f2h_fifo_ren <= '1';

              pcie_tx_state <= PCIE_TX_MWR64_QWN;
            end if;
          else                          --trn_tdst_rdy_n = '1'
            if (f2h_fifo_valid = '1') then
              if (f2h_data_tmp_valid = '0') then
                f2h_data_tmp       <= f2h_fifo_data;
                f2h_data_tmp_valid <= '1';
              end if;
            end if;

            trn_tsrc_rdy_n <= '0';
            f2h_fifo_ren   <= '0';

            pcie_tx_state <= PCIE_TX_MWR64_QWN;
          end if;


        when PCIE_TX_MWR64_QW_LAST =>
          if (trn_tdst_rdy_n = '0') then
            trn_tsrc_rdy_n <= '1';
            trn_teof_n     <= '1';
            trn_tsof_n     <= '1';
            trn_trem_n     <= (others => '1');

            trn_td <= (others => '0');

            mwr64_finish <= '1';

            tx_busy <= '0';

            pcie_tx_state <= PCIE_TX_RST;
          else
            pcie_tx_state <= PCIE_TX_MWR64_QW_LAST;
          end if;

        when PCIE_TX_MRD64_REQ_QW1 =>
          if (trn_tdst_rdy_n = '0') then
            trn_tsof_n     <= '1';
            trn_teof_n     <= '0';
            trn_tsrc_rdy_n <= '0';
            trn_td         <= mrd64_req_addr_c(63 downto 2) & "00";
            trn_trem_n     <= x"00";

            pcie_tx_state <= PCIE_TX_MRD64_REQ_QW_LAST;
          else
            pcie_tx_state <= PCIE_TX_MRD64_REQ_QW1;
          end if;

        when PCIE_TX_MRD64_REQ_QW_LAST =>
          if (trn_tdst_rdy_n = '0') then
            trn_tsrc_rdy_n <= '1';
            trn_teof_n     <= '1';
            trn_tsof_n     <= '1';
            trn_trem_n     <= (others => '1');

            trn_td <= (others => '0');

            mrd64_req_finish <= '1';

            tx_busy <= '0';

            pcie_tx_state <= PCIE_TX_RST;
          else
            pcie_tx_state <= PCIE_TX_MRD64_REQ_QW_LAST;
          end if;
        when others => null;
      end case;
    end if;
  end process main_sm;

end rtl;
