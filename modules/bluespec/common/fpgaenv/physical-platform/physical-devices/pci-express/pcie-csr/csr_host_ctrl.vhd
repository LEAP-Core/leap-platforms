-------------------------------------------------------------------------------
-- Title        : csr_host_ctrl.vhd
-- Project      : 
-------------------------------------------------------------------------------
-- File         : csr_host_ctrl.vhd
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
-- Description: Controll the access from/to host side
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

entity csr_host_ctrl is
  
  port (
    clk   : in std_logic;
    rst_n : in std_logic;

    hw_chnl_rst : in std_logic;

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

    --ports with BRAM
    bram_addr : out std_logic_vector(7 downto 0);
    bram_din  : out std_logic_vector(31 downto 0);
    bram_dout : in  std_logic_vector(31 downto 0);
    bram_wen  : out std_logic);

end csr_host_ctrl;

architecture rtl of csr_host_ctrl is

  type csr_ctrl_state_type is (
    CSR_RST,
    CSR_READ_BRAM,
    CSR_READ_BAR0,
    CSR_READ_CPLD,
    CSR_READ_CPLD_FINISH,
    CSR_WRITE);
  signal csr_st : csr_ctrl_state_type;

  signal csr_rd_delay : std_logic;
  
begin  -- rtl

  -- purpose: main control state machine
  -- type   : sequential
  -- inputs : clk, rst_n
  -- outputs: 
  csr_host_sm : process (clk, rst_n)
  begin  -- process csr_host_sm
    if (rst_n = '0') then               -- asynchronous reset (active low)
      cpld_start     <= '0';
      mrd32_req_data <= (others => '0');

      bar0_wr_addr <= (others => '0');
      bar0_wr_en   <= '0';
      bar0_wr_data <= (others => '0');

      bar0_rd_addr <= (others => '0');

      bram_addr <= (others => '0');
      bram_din  <= (others => '0');
      bram_wen  <= '0';

      csr_rd_delay <= '0';

      csr_st <= CSR_RST;
    elsif (rising_edge(clk)) then       -- rising clock edge
      if (hw_chnl_rst = '1') then
        --reset signals
        cpld_start     <= '0';
        mrd32_req_data <= (others => '0');

        bar0_wr_addr <= (others => '0');
        bar0_wr_en   <= '0';
        bar0_wr_data <= (others => '0');

        bar0_rd_addr <= (others => '0');

        bram_addr <= (others => '0');
        bram_din  <= (others => '0');
        bram_wen  <= '0';

        csr_rd_delay <= '0';

        csr_st <= CSR_RST;
      else
        case csr_st is
          when CSR_RST =>
            if (csr_wr_start = '1') then
              if (mwr32_addr(12) = '1') then
                -- regular CSR
                bram_addr  <= mwr32_addr(9 downto 2);
                bram_din   <= mwr32_data;
                bram_wen   <= '1';
                bar0_wr_en <= '0';
              else
                bar0_wr_addr <= mwr32_addr(9 downto 2);
                bar0_wr_data <= mwr32_data;
                bar0_wr_en   <= '1';
                bram_wen     <= '0';
              end if;
              csr_st <= CSR_WRITE;
            elsif (csr_rd_start = '1') then
              if (mrd32_req_addr(12) = '1') then
                -- regular CSR
                bram_addr <= mrd32_req_addr(9 downto 2);
                csr_st    <= CSR_READ_BRAM;
              else
                bar0_rd_addr <= mrd32_req_addr(9 downto 2);
                csr_st       <= CSR_READ_BAR0;
              end if;
            else

              csr_st <= CSR_RST;
            end if;

          when CSR_WRITE =>
            bram_wen   <= '0';
            bar0_wr_en <= '0';

            csr_st <= CSR_RST;

          when CSR_READ_BRAM =>
            if (csr_rd_delay = '0') then
              csr_rd_delay <= '1';
              csr_st       <= CSR_READ_BRAM;
            else
              mrd32_req_data <= bram_dout;
              cpld_start     <= '1';
              csr_rd_delay   <= '0';

              csr_st <= CSR_READ_CPLD;
            end if;
            
          when CSR_READ_BAR0 =>
            if (csr_rd_delay = '0') then
              csr_rd_delay <= '1';
              csr_st       <= CSR_READ_BAR0;
            else
              mrd32_req_data <= bar0_rd_data;
              cpld_start     <= '1';
              csr_rd_delay   <= '0';

              csr_st <= CSR_READ_CPLD;
            end if;

          when CSR_READ_CPLD =>
            if (cpld_start_ack = '1') then
              cpld_start <= '0';

              csr_st <= CSR_READ_CPLD_FINISH;
            else
              csr_st <= CSR_READ_CPLD;
            end if;

          when CSR_READ_CPLD_FINISH =>
            if (cpld_finish = '1') then
              csr_st <= CSR_RST;
            else
              csr_st <= CSR_READ_CPLD_FINISH;
            end if;
            
        end case;
      end if;
    end if;
  end process csr_host_sm;

end rtl;
