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
	clk   : in std_logic;
	rst_n : in std_logic;
	
	int_out_ready : out std_logic;
	int_in_en			: in std_logic;
	
	intr_host_ack : in std_logic;
	
	cfg_interrupt_rdy_n : in  std_logic;
	cfg_interrupt_assert_n: out std_logic;
	cfg_interrupt_n     : out std_logic);
end INTR_CONTROLLER;

architecture rtl of INTR_CONTROLLER is

type INTR_CTRL_STATE_TYPE is (
INTR_CTRL_IDLE,
INTR_CTRL_ASSERT,
INTR_CTRL_WAIT,
INTR_CTRL_DEASSERT
);
signal intr_ctrl_state : INTR_CTRL_STATE_TYPE;

    signal rd_intr_n : std_logic;
    signal wr_intr_n : std_logic;
	 
	 signal rd_interrupt_assert_n : std_logic;
	 signal wr_interrupt_assert_n : std_logic;

    signal mrd_done : std_logic;
    signal mwr_done : std_logic;

	 type rd_intr_state_type is ( BMD_INTR_RD_RST,
											BMD_INTR_RD_ASSERT, -- sending INT Assert Message
											BMD_INTR_RD_WAIT, -- wait for INT to be handled
											BMD_INTR_RD_DEASSERT -- sending INT Deassert Message
											);
	 type wr_intr_state_type is ( BMD_INTR_WR_RST,
											BMD_INTR_WR_ASSERT, -- sending INT Assert Message
											BMD_INTR_WR_WAIT, -- wait for INT to be handled
											BMD_INTR_WR_DEASSERT -- sending INT Deassert Message
											);											
    signal rd_intr_state, next_rd_intr_state : rd_intr_state_type;
    signal wr_intr_state, next_wr_intr_state : wr_intr_state_type;
	 
	 signal cfg_interrupt_n_c : std_logic;
	 signal cfg_interrupt_assert_n_c : std_logic;

begin  -- rtl
--	 cfg_interrupt_assert_n <= cfg_interrupt_assert_n_c;
--	 cfg_interrupt_n_o <= cfg_interrupt_n_c;
--    cfg_interrupt_n_c <= rd_intr_n and wr_intr_n;
--	 
--	 cfg_interrupt_assert_n_c <= rd_interrupt_assert_n when mrd_done = '1' else
--										wr_interrupt_assert_n;
--
--	 
--	 mwr_done <= mwr_done_i;
--	 mrd_done <= mrd_done_i; --when (mwr_done_i = '0' or wr_intr_state = BMD_INTR_WR_DUN) else '0';

process (clk, rst_n)
begin
	if (rst_n = '0') then
		--reset all signals
		int_out_ready <= '1';
		cfg_interrupt_assert_n <= '1';
		cfg_interrupt_n <= '1';
		intr_ctrl_state <= INTR_CTRL_IDLE;
	elsif(rising_edge(clk)) then
		case intr_ctrl_state is
		when INTR_CTRL_IDLE =>
			if (int_in_en = '1') then
				cfg_interrupt_assert_n <= '0';
				cfg_interrupt_n <= '0';
				int_out_ready <= '0';
				intr_ctrl_state <= INTR_CTRL_ASSERT;
			else
				cfg_interrupt_assert_n <= '1';
				cfg_interrupt_n <= '1';
				int_out_ready <= '1';
				intr_ctrl_state <= INTR_CTRL_IDLE;			
			end if;
				
		when INTR_CTRL_ASSERT =>
			if ( cfg_interrupt_rdy_n = '0') then
				cfg_interrupt_n <= '1';
				cfg_interrupt_assert_n <= '0';
				intr_ctrl_state <= INTR_CTRL_WAIT;
			else
				cfg_interrupt_n <= '0';
				cfg_interrupt_assert_n <= '0';
				intr_ctrl_state <= INTR_CTRL_ASSERT;	
			end if;
			
		when INTR_CTRL_WAIT =>
			if ( intr_host_ack = '1') then
				cfg_interrupt_n <= '0';
				cfg_interrupt_assert_n <= '1';
				intr_ctrl_state <= INTR_CTRL_DEASSERT;
			else
				cfg_interrupt_n <= '1';
				cfg_interrupt_assert_n <= '0';
				intr_ctrl_state <= INTR_CTRL_WAIT;
			end if;
			
		when INTR_CTRL_DEASSERT =>
			if ( cfg_interrupt_rdy_n = '0') then
				cfg_interrupt_n <= '1';
				cfg_interrupt_n <= '1';
				int_out_ready <= '1';
				intr_ctrl_state <= INTR_CTRL_IDLE;
			else
				cfg_interrupt_n <= '0';
				cfg_interrupt_assert_n <= '1';
				intr_ctrl_state <= INTR_CTRL_DEASSERT;
			end if;
			
		when others =>
			null;
		end case;
	end if;
end process;

--	process (rd_intr_state, mrd_done, cfg_interrupt_rdy_n_i)
--	begin
--		case rd_intr_state is
--			when BMD_INTR_RD_RST =>
--				if ( mrd_done = '1' ) then
--					rd_intr_n <= '0';
--					rd_interrupt_assert_n <= '0';
--					next_rd_intr_state <= BMD_INTR_RD_ASSERT;
--				else
--					rd_intr_n <= '1';
--					rd_interrupt_assert_n <= '1';
--					next_rd_intr_state <= BMD_INTR_RD_RST;
--				end if;
--				
--			when BMD_INTR_RD_ASSERT =>
--				if ( cfg_interrupt_rdy_n_i = '0') then
--					rd_intr_n <= '1';
--					-- cfg_interrrupt_assert_n remains the same
--					next_rd_intr_state <= BMD_INTR_RD_WAIT;
--				else
--					rd_intr_n <= '0';
--					rd_interrupt_assert_n <= '0';
--					next_rd_intr_state <= BMD_INTR_RD_ASSERT;
--				end if;
--				
--			when BMD_INTR_RD_WAIT =>
--				if ( init_rst_i = '1' ) then -- interrupt has been serviced, then send INT deassert MESSAGE
--					rd_intr_n <= '0';
--					rd_interrupt_assert_n <= '1';
--					next_rd_intr_state <= BMD_INTR_RD_DEASSERT;
--				else
--					rd_intr_n <= '1';
--					-- cfg_interrupt_assert_n remains the same
--					next_rd_intr_state <= BMD_INTR_RD_WAIT;
--				end if;
--					
--			when BMD_INTR_RD_DEASSERT => 
--				if ( cfg_interrupt_rdy_n_i = '0') then
--					rd_intr_n <= '1';
--					-- cfg_interrupt_assert_n remains the same
--					next_rd_intr_state <= BMD_INTR_RD_RST;
--				else
--					rd_intr_n <= '0';
--					rd_interrupt_assert_n <= '1';
--					next_rd_intr_state <= BMD_INTR_RD_DEASSERT;
--				end if;
--			when others => null;
--		end case;
--	end process;
--
----    process (rd_intr_state, mrd_done, cfg_interrupt_rdy_n_i)
----    begin
----        -- default
----        case rd_intr_state is
----            when BMD_INTR_RD_RST =>
----                if mrd_done = '1' and cfg_interrupt_rdy_n_i = '0' then
----                    next_rd_intr_state <= BMD_INTR_RD_ACT;
----                    rd_intr_n <= '0';
----						  rd_interrupt_assert_n <= '0';
----                else
----                    next_rd_intr_state <= BMD_INTR_RD_RST;
----                    rd_intr_n <= '1';
----						  rd_interrupt_assert_n <= '1';
----                end if;
----            when BMD_INTR_RD_ACT =>
----                if cfg_interrupt_rdy_n_i = '1' then
----                    next_rd_intr_state <= BMD_INTR_RD_RCV;
----                    rd_intr_n <= '0';
----                else
----                    next_rd_intr_state <= BMD_INTR_RD_ACT;
----                    rd_intr_n <= '0';
----                end if;
----				when BMD_INTR_RD_RCV =>
----					 if cfg_interrupt_rdy_n_i = '0' then
----					     next_rd_intr_state <= BMD_INTR_RD_DUN;
----						  rd_intr_n <= '1';
----					  else
----					     next_rd_intr_state <= BMD_INTR_RD_RCV;
----						  rd_intr_n <= '0';
----					  end if;						  
----            when BMD_INTR_RD_DUN => 
----                next_rd_intr_state <= BMD_INTR_RD_DUN;
----                rd_intr_n <= '1';
----            when others => null;
----        end case;
----    end process;
--
--    ---------------------------------------------------------------------------
--    -- Write Interrupt Control
--    ---------------------------------------------------------------------------
--
--	process (wr_intr_state, mwr_done, cfg_interrupt_rdy_n_i)
--	begin
--		case wr_intr_state is
--			when BMD_INTR_WR_RST =>
--				if ( mwr_done = '1' ) then
--					wr_intr_n <= '0';
--					wr_interrupt_assert_n <= '0';
--					next_wr_intr_state <= BMD_INTR_WR_ASSERT;
--				else
--					wr_intr_n <= '1';
--					wr_interrupt_assert_n <= '1';
--					next_wr_intr_state <= BMD_INTR_WR_RST;
--				end if;
--				
--			when BMD_INTR_WR_ASSERT =>
--				if ( cfg_interrupt_rdy_n_i = '0') then
--					wr_intr_n <= '1';
--					-- cfg_interrrupt_assert_n remains the same
--					next_wr_intr_state <= BMD_INTR_WR_WAIT;
--				else
--					wr_intr_n <= '0';
--					wr_interrupt_assert_n <= '0';
--					next_wr_intr_state <= BMD_INTR_WR_ASSERT;
--				end if;
--				
--			when BMD_INTR_WR_WAIT =>
--				if ( init_rst_i = '1' ) then -- interrupt has been serviced, then send INT deassert MESSAGE
--					wr_intr_n <= '0';
--					wr_interrupt_assert_n <= '1';
--					next_wr_intr_state <= BMD_INTR_WR_DEASSERT;
--				else
--					wr_intr_n <= '1';
--					-- cfg_interrupt_assert_n remains the same
--					next_wr_intr_state <= BMD_INTR_WR_WAIT;
--				end if;
--					
--			when BMD_INTR_WR_DEASSERT => 
--				if ( cfg_interrupt_rdy_n_i = '0') then
--					wr_intr_n <= '1';
--					-- cfg_interrupt_assert_n remains the same
--					next_wr_intr_state <= BMD_INTR_WR_RST;
--				else
--					wr_intr_n <= '0';
--					wr_interrupt_assert_n <= '1';
--					next_wr_intr_state <= BMD_INTR_WR_DEASSERT;
--				end if;
--			when others => null;
--		end case;
--	end process;
--
----    process (wr_intr_state, mwr_done, cfg_interrupt_rdy_n_i)
----    begin
----        case wr_intr_state is
----            when BMD_INTR_WR_RST =>
----                if mwr_done = '1' and cfg_interrupt_rdy_n_i = '0' then
----                    next_wr_intr_state <= BMD_INTR_WR_ACT;
----                    wr_intr_n <= '0';
----                else
----                    next_wr_intr_state <= BMD_INTR_WR_RST;
----                    wr_intr_n <= '1';
----                end if;
----            when BMD_INTR_WR_ACT =>
----                if cfg_interrupt_rdy_n_i = '1'  then
----                    next_wr_intr_state <= BMD_INTR_WR_RCV;
----                    wr_intr_n <= '0';
----                else
----                    next_wr_intr_state <= BMD_INTR_WR_ACT;
----                    wr_intr_n <= '0';
----                end if;
----			   when BMD_INTR_WR_RCV =>
----				    if cfg_interrupt_rdy_n_i = '0' then
----					     next_wr_intr_state <= BMD_INTR_WR_DUN;
----						  wr_intr_n <= '1';
----					 else
----					     next_wr_intr_state <= BMD_INTR_WR_RCV;
----						  wr_intr_n <= '0';
----						end if;						  
----            when BMD_INTR_WR_DUN =>
----                next_wr_intr_state <= BMD_INTR_WR_DUN;
----                wr_intr_n <= '1';
----        end case;
----    end process;
--
--    process (clk, rst_n)
--    begin
--        if rst_n = '0' then
--            rd_intr_state <= BMD_INTR_RD_RST;
--            wr_intr_state <= BMD_INTR_WR_RST;
----            intr_state    <= BMD_INTR_RST;
--        elsif rising_edge(clk) then
----            if init_rst_i = '1' then
----                rd_intr_state <= BMD_INTR_RD_RST;
----                wr_intr_state <= BMD_INTR_WR_RST;
------                intr_state    <= BMD_INTR_RST;
----            else 
--                rd_intr_state <= next_rd_intr_state;
--                wr_intr_state <= next_wr_intr_state;
----                intr_state <= next_intr_state;
----            end if;
--        end if;
--    end process;

end rtl;

