-------------------------------------------------------------------------------
-- Title        : PCIe RX Wrapper
-- Project      : 
-------------------------------------------------------------------------------
-- File         : pcie_rx_wrapper.vhd
-- Author       : Wang, Liang  <liang.wang@intel.com>
-- Company      : CTL Beijing, Intel
-- Created      : 2008-10-20
-- Last update  : 2008-10-20
-- Platform     : Virtex 5 vlx110t-ff1136-1
-- Targets      : XC5VLX110T-FF1136-1
-- Simulators   : ModelSim SE 6.2e
-- Synthesizers : XST embedded in ISE
-- Standard     : VHDL'87
-------------------------------------------------------------------------------
-- Description: wrap the pcie basie interface of RX
-------------------------------------------------------------------------------
-- Copyright (c) 2008 CTL Beijing, Intel
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2008-10-20  1.0      lwang12 Created
-------------------------------------------------------------------------------



library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity pcie_rx_wrapper is
  port(
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

end pcie_rx_wrapper;

architecture rtl of pcie_rx_wrapper is

  type pcie_rx_state_type is (
    PCIE_RX_RST,
    PCIE_RX_MRD32_QW1,
    PCIE_RX_MWR32_QW1,
    PCIE_RX_CPLD_QW1,
    PCIE_RX_CPLD_QWN,
    PCIE_RX_CPLD_QWNW);
  signal pcie_rx_state : pcie_rx_state_type;

  constant PCIE_MRD32_FMT_TYPE : std_logic_vector(6 downto 0) := "0000000";
  constant PCIE_MWR32_FMT_TYPE : std_logic_vector(6 downto 0) := "1000000";
  constant PCIE_CPLD_FMT_TYPE  : std_logic_vector(6 downto 0) := "1001010";

-- Local Registers

  signal tlp_eof      : std_logic;  -- indicate whether it's the end of a tlp, only used when the last QW receieved with the fifo unavailable due to it's full
  signal wr_data_tmp  : std_logic_vector (63 downto 0);  -- temporarily store the receieved data, only used when fifo is unavailabe due to it's full.
  signal wr_data_pre1 : std_logic_vector (31 downto 0);
  signal wr_data_pre2 : std_logic_vector (31 downto 0);
  signal wr_data_sel  : std_logic;
  

begin  -- rtl

  -- purpose: The main state machine of pcie_rx_wrapper
  -- type   : sequential
  -- inputs : clk, rst_n
  -- outputs: 
  main_sm : process (clk, rst_n)
  begin  -- process main_sm
    if (rst_n = '0') then               -- asynchronous reset (active low)
      -- reset signals
      trn_rdst_rdy_n <= '0';

      mrd32_req_tc   <= (others => '0');
      mrd32_req_td   <= '0';
      mrd32_req_ep   <= '0';
      mrd32_req_attr <= (others => '0');
      mrd32_req_len  <= (others => '0');
      mrd32_req_rid  <= (others => '0');
      mrd32_req_tag  <= (others => '0');
      mrd32_req_be   <= (others => '0');
      mrd32_req_bar  <= '1';

      wr_data_pre1 <= (others => '0');
      wr_data_pre2 <= (others => '0');
      wr_data_tmp  <= (others => '0');
      wr_data_sel  <= '0';

      tlp_eof <= '0';

      cpld_recv_finish <= '0';
      cpld_recv_len    <= (others => '0');

      h2f_fifo_wen  <= '0';
      h2f_fifo_data <= (others => '0');

      csr_rd_start   <= '0';
      mrd32_req_addr <= (others => '0');

      csr_wr_start <= '0';
      mwr32_addr   <= (others => '0');
      mwr32_data   <= (others => '0');

      pcie_rx_state <= PCIE_RX_RST;
    elsif (rising_edge(clk)) then       -- rising clock edge
      case pcie_rx_state is
        when PCIE_RX_RST =>
          
          csr_rd_start     <= '0';
          csr_wr_start     <= '0';
          cpld_recv_finish <= '0';
          h2f_fifo_wen     <= '0';

          if (trn_rsof_n = '0' and trn_rsrc_rdy_n = '0') then
            case trn_rd(62 downto 56) is
              when PCIE_MRD32_FMT_TYPE =>  -- Read CSR
                if (trn_rd(41 downto 32) = x"001") then

                  mrd32_req_tc   <= trn_rd(54 downto 52);
                  mrd32_req_td   <= trn_rd(47);
                  mrd32_req_ep   <= trn_rd(46);
                  mrd32_req_attr <= trn_rd(45 downto 44);
                  mrd32_req_len  <= trn_rd(41 downto 32);
                  mrd32_req_rid  <= trn_rd(31 downto 16);
                  mrd32_req_tag  <= trn_rd(15 downto 08);
                  mrd32_req_be   <= trn_rd(03 downto 00);

                  pcie_rx_state <= PCIE_RX_MRD32_QW1;
                else
                  -- unsupported TLP
                  pcie_rx_state <= PCIE_RX_RST;
                end if;

              when PCIE_MWR32_FMT_TYPE =>  -- Write CSR
                if (trn_rd(41 downto 32) = x"001") then
                  pcie_rx_state <= PCIE_RX_MWR32_QW1;
                else
                  -- unsupported TLP
                  pcie_rx_state <= PCIE_RX_RST;
                end if;

              when PCIE_CPLD_FMT_TYPE =>
                cpld_recv_len <= trn_rd(41 downto 32);

                pcie_rx_state <= PCIE_RX_CPLD_QW1;
                
              when others =>
                -- other type of TLP is not supported.
                pcie_rx_state <= PCIE_RX_RST;
            end case;
          end if;

        when PCIE_RX_MRD32_QW1 =>
          if (trn_reof_n = '0' and trn_rsrc_rdy_n = '0') then
            mrd32_req_addr <= trn_rd(63 downto 32);
            mrd32_req_bar  <= trn_rbar_hit_n(0);

            csr_rd_start <= '1';

            pcie_rx_state <= PCIE_RX_RST;
          else
            pcie_rx_state <= PCIE_RX_MRD32_QW1;
          end if;
          
        when PCIE_RX_MWR32_QW1 =>
          if (trn_reof_n = '0' and trn_rsrc_rdy_n = '0') then
            mwr32_addr <= trn_rd(63 downto 32);
            mwr32_data <= trn_rd(31 downto 0);

            csr_wr_start <= '1';

            pcie_rx_state <= PCIE_RX_RST;
          else
            pcie_rx_state <= PCIE_RX_MWR32_QW1;
          end if;

        when PCIE_RX_CPLD_QW1 =>
          if (trn_rsrc_rdy_n = '0') then  -- CPLD with only 1DW is not supported
            wr_data_pre1 <= trn_rd(31 downto 0);
            wr_data_sel  <= '0';

            h2f_fifo_wen <= '0';

            trn_rdst_rdy_n <= '0';

            pcie_rx_state <= PCIE_RX_CPLD_QWN;

          else
            pcie_rx_state <= PCIE_RX_CPLD_QW1;
          end if;

        when PCIE_RX_CPLD_QWN =>
          if (h2f_fifo_full = '0') then
            if (trn_rsrc_rdy_n = '0') then
              if (trn_reof_n = '0') then
                --only the first DW is valid
                if (wr_data_sel = '0') then
                  h2f_fifo_data(31 downto 0)  <= wr_data_pre1;
                  h2f_fifo_data(63 downto 32) <= trn_rd(63 downto 32);
                else
                  h2f_fifo_data(31 downto 0)  <= wr_data_pre2;
                  h2f_fifo_data(63 downto 32) <= trn_rd(63 downto 32);
                end if;
                h2f_fifo_wen   <= '1';
                trn_rdst_rdy_n <= '0';

                cpld_recv_finish <= '1';

                pcie_rx_state <= PCIE_RX_RST;
              else
                if (wr_data_sel = '0') then
                  h2f_fifo_data(31 downto 0)  <= wr_data_pre1;
                  h2f_fifo_data(63 downto 32) <= trn_rd(63 downto 32);
                  wr_data_pre2                <= trn_rd(31 downto 0);
                  wr_data_sel                 <= '1';
                else
                  h2f_fifo_data(31 downto 0)  <= wr_data_pre2;
                  h2f_fifo_data(63 downto 32) <= trn_rd(63 downto 32);
                  wr_data_pre1                <= trn_rd(31 downto 0);
                  wr_data_sel                 <= '0';
                end if;
                h2f_fifo_wen   <= '1';
                trn_rdst_rdy_n <= '0';

                pcie_rx_state <= PCIE_RX_CPLD_QWN;
              end if;
            else
              h2f_fifo_wen   <= '0';
              trn_rdst_rdy_n <= '0';

              pcie_rx_state <= PCIE_RX_CPLD_QWN;
            end if;
          else
            if (trn_rsrc_rdy_n = '0') then
              if (trn_reof_n = '0') then
                tlp_eof <= '1';
              else
                tlp_eof <= '0';
              end if;
              wr_data_tmp    <= trn_rd;
              trn_rdst_rdy_n <= '1';
              h2f_fifo_wen   <= '0';

              pcie_rx_state <= PCIE_RX_CPLD_QWNW;
            else
              trn_rdst_rdy_n <= '0';
              h2f_fifo_wen   <= '0';

              pcie_rx_state <= PCIE_RX_CPLD_QWN;
            end if;
          end if;

        when PCIE_RX_CPLD_QWNW =>
          if (h2f_fifo_full = '0') then
            if (tlp_eof = '1') then
              if (wr_data_sel = '0') then
                h2f_fifo_data(31 downto 0)  <= wr_data_pre1;
                h2f_fifo_data(63 downto 32) <= wr_data_tmp(63 downto 32);
              else
                h2f_fifo_data(31 downto 0)  <= wr_data_pre2;
                h2f_fifo_data(63 downto 32) <= wr_data_tmp(63 downto 32);
              end if;
              trn_rdst_rdy_n <= '0';
              h2f_fifo_wen   <= '1';

              cpld_recv_finish <= '1';

              pcie_rx_state <= PCIE_RX_RST;
            else
              if (wr_data_sel = '0') then
                h2f_fifo_data(31 downto 0)  <= wr_data_pre1;
                h2f_fifo_data(63 downto 32) <= wr_data_tmp(63 downto 32);
                wr_data_pre2                <= wr_data_tmp(31 downto 0);
                wr_data_sel                 <= '1';
              else
                h2f_fifo_data(31 downto 0)  <= wr_data_pre2;
                h2f_fifo_data(63 downto 32) <= wr_data_tmp(63 downto 32);
                wr_data_pre1                <= wr_data_tmp(31 downto 0);
                wr_data_sel                 <= '0';
              end if;
              h2f_fifo_wen   <= '1';
              trn_rdst_rdy_n <= '0';

              pcie_rx_state <= PCIE_RX_CPLD_QWN;
            end if;
          else
            trn_rdst_rdy_n <= '1';

            h2f_fifo_wen <= '0';

            pcie_rx_state <= PCIE_RX_CPLD_QWNW;
          end if;
      end case;
    end if;
  end process main_sm;

end rtl;

