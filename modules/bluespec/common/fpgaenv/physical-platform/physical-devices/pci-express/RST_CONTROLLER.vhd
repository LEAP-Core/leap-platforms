-------------------------------------------------------------------------------
-- Title      : Controller for the reset in user level
-- Project    : PCI Express Hardware Channel
-------------------------------------------------------------------------------
-- File       : RST_CONTROLLER.vhd
-- Author     : Wang, Liang  <liang.wang@intel.com>
-- Company    : CTL Beijing
-- Created    : 2008-05-29
-- Last update: 2008-06-12
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


entity RST_CONTROLLER is
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
end RST_CONTROLLER;

architecture rtl of RST_CONTROLLER is

  type SOFTRST_STATE_TYPE is (
    SOFTRST_STATE_IDLE,
    SOFTRST_STATE_READY,
    SOFTRST_STATE_BUSY
  );
  
  type INIT_STATE_TYPE is (
    INIT_STATE_IDLE,
    INIT_STATE_READY,
    INIT_STATE_WAIT_FOR_CHANNEL_RST,
    INIT_STATE_WAIT_FOR_RESP_ACK
  );

  signal softrst_req_state  : SOFTRST_STATE_TYPE;
  signal softrst_resp_state : SOFTRST_STATE_TYPE;
  signal init_state         : INIT_STATE_TYPE;

begin  -- rtl

  -- Handle the following scenarios:
  --
  -- (1) Software (PCIE_BAR0) sends us a reset request, which we must propagate
  --     to the upper layer.
  -- (2) Upper layer sends us a reset response, which we must propagate to
  --     software (PCIE_BAR0).
  -- (3) Upper layer sends us an init request, which we must use to init/reset
  --     sibling hwchnl modules.
  -- (4) After sibling modules are done resetting (we allow a fixed 1 cycle), we
  --     must notify upper layer.
  --
  -- Note that there is a strict ordering dependence between (3) -> (4), but no
  -- other orders are assumed or imposed, not even (1) -> (2). We use 3
  -- processes to implement the logic: one process each for items (1) and (2),
  -- and a single third process for items (3) and (4).
  
  -- process that handles soft reset request logic
  process(clk, rst_n)
  begin

    if (rst_n = '0') then

      -- hard reset
      rst_softrst_req_rdy <= '0';
      softrst_req_state   <= SOFTRST_STATE_IDLE;
      
    elsif rising_edge(clk) then

      case softrst_req_state is

        when SOFTRST_STATE_IDLE =>

          -- initialize
          rst_softrst_req_rdy <= '0';
          softrst_req_state   <= SOFTRST_STATE_READY;
        
        when SOFTRST_STATE_READY =>

          -- if PCIe enables reset signal, then propagate it to upper layer
          if (pcie_bar0_rst_sig = '1') then
            rst_softrst_req_rdy <= '1';
            softrst_req_state   <= SOFTRST_STATE_BUSY;
          end if;

        when SOFTRST_STATE_BUSY =>

          -- accept acknowledgement that upper layer has received request
          if (rst_softrst_req_en = '1') then
            rst_softrst_req_rdy <= '0';
            softrst_req_state   <= SOFTRST_STATE_READY;
          end if;
          
      end case;
      
    end if;

  end process;

  -- process that handles soft reset response logic
  process(clk, rst_n)
  begin

    if (rst_n = '0') then

      -- hard reset
      pcie_bar0_rst_ack    <= '0';
      rst_softrst_resp_rdy <= '0';
      softrst_resp_state   <= SOFTRST_STATE_IDLE;
      
    elsif rising_edge(clk) then

      case softrst_resp_state is

        when SOFTRST_STATE_IDLE =>

          -- initialize
          pcie_bar0_rst_ack    <= '0';
          rst_softrst_resp_rdy <= '1';
          softrst_resp_state   <= SOFTRST_STATE_READY;
       
        when SOFTRST_STATE_READY =>

          -- if upper layer sends reset response, propagate it to PCIE_BAR0
          -- FIXME: modify logic to only propagate the signal if this follows
          -- a soft reset. For now, looking at the PCIE_BAR0 logic leads me
          -- to believe that things should work as they are, but it's not clean
          if (rst_softrst_resp_en = '1') then
            pcie_bar0_rst_ack    <= '1';
            rst_softrst_resp_rdy <= '0';
            softrst_resp_state   <= SOFTRST_STATE_BUSY;
          end if;

        when SOFTRST_STATE_BUSY =>

          -- hold ack to PCIE_BAR0 for 1 cycle
          pcie_bar0_rst_ack    <= '0';
          rst_softrst_resp_rdy <= '1';
          softrst_resp_state   <= SOFTRST_STATE_READY;
          
      end case;
      
    end if;

  end process;

  -- process that handles init logic
  process(clk, rst_n)
  begin

    if (rst_n = '0') then

      -- hard reset
      rst_init_req_rdy  <= '0';         -- debug
      rst_init_resp_rdy <= '0';
      hw_chnl_rst_sig   <= '0';
      init_state        <= INIT_STATE_IDLE;
      
    elsif rising_edge(clk) then

      case init_state is

        when INIT_STATE_IDLE =>
          
          rst_init_req_rdy  <= '1';
          rst_init_resp_rdy <= '0';
          init_state        <= INIT_STATE_READY;

        when INIT_STATE_READY =>

          -- receive init request
          if (rst_init_req_en = '1') then
            rst_init_req_rdy <= '0';
            hw_chnl_rst_sig  <= '1';
            init_state       <= INIT_STATE_WAIT_FOR_CHANNEL_RST;
          end if;
          
        when INIT_STATE_WAIT_FOR_CHANNEL_RST =>

          -- lower channel init signal and set ready signal for init_resp
          hw_chnl_rst_sig   <= '0';
          rst_init_resp_rdy <= '1';
          init_state        <= INIT_STATE_WAIT_FOR_RESP_ACK;

        when INIT_STATE_WAIT_FOR_RESP_ACK =>

          if (rst_init_resp_en = '1') then
            rst_init_resp_rdy <= '0';
            rst_init_req_rdy  <= '1';
            init_state        <= INIT_STATE_READY;
          end if;
          
      end case;

    end if;

  end process;

end rtl;
