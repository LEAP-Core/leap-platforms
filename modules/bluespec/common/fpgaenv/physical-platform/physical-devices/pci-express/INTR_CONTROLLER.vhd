-------------------------------------------------------------------------------
-- Title      : Interrupt Controller
-- Project    : PCI Express Hardware Channel
-------------------------------------------------------------------------------
-- File       : INTR_CONTROLLER.vhd
-- Author     : Wang, Liang  <liang.wang@intel.com>
-- Company    : CTL Beijing
-- Created    : 2008-05-29
-- Last update: 2008-06-04
-- Platform   : Xilinx ISE9.2(IP update4), ModelSim SE 6.2e
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Interrupt
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


entity INTR_CONTROLLER is
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
end INTR_CONTROLLER;

architecture rtl of INTR_CONTROLLER is

  type INTR_CTRL_STATE_TYPE is (
    INTR_CTRL_IDLE,
    INTR_CTRL_ASSERT,
    INTR_CTRL_WAIT,
    INTR_CTRL_DEASSERT
    );
  signal intr_ctrl_state : INTR_CTRL_STATE_TYPE;

begin

  process (clk, rst_n, hw_chnl_rst)
  begin
    if (rst_n = '0' or hw_chnl_rst = '1') then
      --reset all signals
      int_out_ready          <= '1';
      cfg_interrupt_assert_n <= '1';
      cfg_interrupt_n        <= '1';
      intr_ctrl_state        <= INTR_CTRL_IDLE;
    elsif(rising_edge(clk)) then
      case intr_ctrl_state is
        when INTR_CTRL_IDLE =>
          if (int_in_en = '1') then
            cfg_interrupt_assert_n <= '0';
            cfg_interrupt_n        <= '0';
            int_out_ready          <= '0';
            intr_ctrl_state        <= INTR_CTRL_ASSERT;
          else
            cfg_interrupt_assert_n <= '1';
            cfg_interrupt_n        <= '1';
            int_out_ready          <= '1';
            intr_ctrl_state        <= INTR_CTRL_IDLE;
          end if;
          
        when INTR_CTRL_ASSERT =>
          if (cfg_interrupt_rdy_n = '0') then
            cfg_interrupt_n        <= '1';
            cfg_interrupt_assert_n <= '0';
            intr_ctrl_state        <= INTR_CTRL_WAIT;
          else
            cfg_interrupt_n        <= '0';
            cfg_interrupt_assert_n <= '0';
            intr_ctrl_state        <= INTR_CTRL_ASSERT;
          end if;
          
        when INTR_CTRL_WAIT =>
          if (intr_host_ack = '1') then
            cfg_interrupt_n        <= '0';
            cfg_interrupt_assert_n <= '1';
            intr_ctrl_state        <= INTR_CTRL_DEASSERT;
          else
            cfg_interrupt_n        <= '1';
            cfg_interrupt_assert_n <= '0';
            intr_ctrl_state        <= INTR_CTRL_WAIT;
          end if;
          
        when INTR_CTRL_DEASSERT =>
          if (cfg_interrupt_rdy_n = '0') then
            cfg_interrupt_n <= '1';
            cfg_interrupt_n <= '1';
            int_out_ready   <= '1';
            intr_ctrl_state <= INTR_CTRL_IDLE;
          else
            cfg_interrupt_n        <= '0';
            cfg_interrupt_assert_n <= '1';
            intr_ctrl_state        <= INTR_CTRL_DEASSERT;
          end if;

      end case;
    end if;
  end process;

end rtl;

