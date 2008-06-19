-------------------------------------------------------------------------------
-- Title      : BAR0 Registers Implementation
-- Project    : PCI Express Hardware Channel
-------------------------------------------------------------------------------
-- File       : PCIE_BAR0.vhd
-- Author     : Wang, Liang  <liang.wang@intel.com>
-- Company    : CTL Beijing
-- Created    : 2008-05-29
-- Last update: 2008-06-04
-- Platform   : Xilinx ISE9.2(IP update4), ModelSim SE 6.2e
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: BAR0 Registers: 128B/32 * 256 registers
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


entity PCIE_BAR0 is
  port (
    clk   : in std_logic;
    rst_n : in std_logic;

    wr_a_i  : in  std_logic_vector(7 downto 0);
    wr_en_i : in  std_logic;
    rd_a_i  : in  std_logic_vector(7 downto 0);
    rd_d_o  : out std_logic_vector(31 downto 0);
    wr_d_i  : in  std_logic_vector(31 downto 0);

    pcie_csr_in_h2f_reg0_wr_en : out std_logic;
    pcie_csr_in_h2f_reg0       : out std_logic_vector((32 - 1) downto 0);
    pcie_csr_out_f2h_reg0      : in  std_logic_vector((32 - 1) downto 0);


    pcie_bar0_rst_sig : out std_logic;
    pcie_bar0_rst_ack : in  std_logic;

    intr_host_ack : out std_logic);
end entity PCIE_BAR0;

architecture rtl of PCIE_BAR0 is

  signal soft_rst_reg : std_logic_vector(31 downto 0);


begin

  -- Process to generate data read from PCIE_BAR0
  process (clk, rst_n)
  begin
    if (rst_n = '0') then
      rd_d_o <= (others => '0');
    elsif rising_edge(clk) then
      case rd_a_i is
        when X"01" =>
          rd_d_o <= pcie_csr_out_f2h_reg0;
        when X"03" =>
          if (pcie_bar0_rst_ack = '1') then
            rd_d_o <= (others => '0');
          else
            rd_d_o <= soft_rst_reg;
          end if;
        when others =>
          rd_d_o <= (others => '0');
      end case;
    end if;
  end process;

  -- Process to manipulate data write to PCIE_BAR0         
  process (clk, rst_n)
  begin
    if rst_n = '0' then
      pcie_csr_in_h2f_reg0_wr_en <= '0';
      pcie_csr_in_h2f_reg0       <= (others => '0');

      intr_host_ack <= '0';

      soft_rst_reg      <= (others => '0');
      pcie_bar0_rst_sig <= '0';
      
    elsif rising_edge(clk) then
      case wr_a_i(7 downto 0) is

        -- system CSR
        when X"00" =>
          if wr_en_i = '1' then
            pcie_csr_in_h2f_reg0_wr_en <= '1';
            pcie_csr_in_h2f_reg0       <= wr_d_i;
          else
            pcie_csr_in_h2f_reg0_wr_en <= '0';
            pcie_csr_in_h2f_reg0       <= (others => '0');
          end if;

        -- Interrupt Control Register
        -- SW driver write to this register to establish
        -- the acknowledge to the interrupt.
        when X"02" =>
          if wr_en_i = '1' then
            intr_host_ack <= '1';
          else
            intr_host_ack <= '0';
          end if;

        -- Soft Reset Register
        when X"03" =>
          if (wr_en_i = '1') then
            soft_rst_reg      <= wr_d_i;
            pcie_bar0_rst_sig <= '1';
          else
            pcie_bar0_rst_sig <= '0';
          end if;
          
        when others =>
          pcie_csr_in_h2f_reg0_wr_en <= '0';
          pcie_csr_in_h2f_reg0       <= (others => '0');
          intr_host_ack              <= '0';
          pcie_bar0_rst_sig          <= '0';
      end case;
    end if;
  end process;
  
end rtl;
