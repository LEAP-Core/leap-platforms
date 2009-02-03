----------------------------------------------------------------------------------
---- Filename: BMD_INTR_CTRL.vhd
---- Wang, Liang(liang.wang@intel.com)
---- Description: Endpoint Intrrupt Controller
----
----------------------------------------------------------------------------------

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



--  type INTR_CTRL_STATE_TYPE is (
  constant INTR_CTRL_IDLE         : std_logic_vector(1 downto 0) := "00";
  constant INTR_CTRL_ASSERT       : std_logic_vector(1 downto 0) := "01";
  constant INTR_CTRL_WAIT         : std_logic_vector(1 downto 0) := "10";
  constant INTR_CTRL_DEASSERT     : std_logic_vector(1 downto 0) := "11";
--    );
  signal intr_ctrl_state          : std_logic_vector(1 downto 0);
  signal int_out_ready_c          : std_logic;
  signal int_in_en_c              : std_logic;
  signal intr_host_ack_c          : std_logic;
  signal cfg_interrupt_assert_n_c : std_logic;
  signal cfg_interrupt_n_c        : std_logic;
  signal cfg_interrupt_rdy_n_c    : std_logic;

  
begin  -- rtl
  
  int_out_ready <= int_out_ready_c;
  int_in_en_c   <= int_in_en;

  intr_host_ack_c <= intr_host_ack;

  cfg_interrupt_rdy_n_c  <= cfg_interrupt_rdy_n;
  cfg_interrupt_assert_n <= cfg_interrupt_assert_n_c;
  cfg_interrupt_n        <= cfg_interrupt_n_c;

  process (clk, rst_n)
  begin
    if (rst_n = '0' or hw_chnl_rst = '1') then
      --reset all signals
      int_out_ready_c          <= '1';
      cfg_interrupt_assert_n_c <= '1';
      cfg_interrupt_n_c        <= '1';
      intr_ctrl_state          <= INTR_CTRL_IDLE;
    elsif(rising_edge(clk)) then
      case intr_ctrl_state is
        when INTR_CTRL_IDLE =>
          if (int_in_en_c = '1') then
            cfg_interrupt_assert_n_c <= '0';
            cfg_interrupt_n_c        <= '0';
            int_out_ready_c          <= '0';
            intr_ctrl_state          <= INTR_CTRL_ASSERT;
          else
            cfg_interrupt_assert_n_c <= '1';
            cfg_interrupt_n_c        <= '1';
            int_out_ready_c          <= '1';
            intr_ctrl_state          <= INTR_CTRL_IDLE;
          end if;
          
        when INTR_CTRL_ASSERT =>
          if (cfg_interrupt_n_c = '0') then
            cfg_interrupt_n_c        <= '1';
            cfg_interrupt_assert_n_c <= '0';
            intr_ctrl_state          <= INTR_CTRL_WAIT;
          else
            cfg_interrupt_n_c        <= '0';
            cfg_interrupt_assert_n_c <= '0';
            intr_ctrl_state          <= INTR_CTRL_ASSERT;
          end if;
          
        when INTR_CTRL_WAIT =>
          if (intr_host_ack_c = '1') then
            cfg_interrupt_n_c        <= '0';
            cfg_interrupt_assert_n_c <= '1';
            intr_ctrl_state          <= INTR_CTRL_DEASSERT;
          else
            cfg_interrupt_n_c        <= '1';
            cfg_interrupt_assert_n_c <= '0';
            intr_ctrl_state          <= INTR_CTRL_WAIT;
          end if;
          
        when INTR_CTRL_DEASSERT =>
          if (cfg_interrupt_n_c = '0') then
            cfg_interrupt_n_c <= '1';
            cfg_interrupt_n_c <= '1';
            int_out_ready_c   <= '1';
            intr_ctrl_state   <= INTR_CTRL_IDLE;
          else
            cfg_interrupt_n_c        <= '0';
            cfg_interrupt_assert_n_c <= '1';
            intr_ctrl_state          <= INTR_CTRL_DEASSERT;
          end if;
          
        when others =>
          null;
      end case;
    end if;
  end process;

end rtl;

