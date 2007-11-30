
----------------------------------------------------------------------------------

----
----------------------------------------------------------------------------------
---- Filename: BMD_INTR_CTRL.vhd
---- Li, Zheng Intel
---- Description: Endpoint Intrrupt Controller
----
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library work;
use work.bmd_pak.all;

entity BMD_INTR_CTRL is
    port (clk   : in std_logic;
          rst_n : in std_logic;

          init_rst_i : in std_logic;
--          rd_intr_proc_i : in std_logic;
--          wr_intr_proc_i : in std_logic;

          mrd_done_i : in std_logic;
          mwr_done_i : in std_logic;

          cfg_interrupt_rdy_n_i : in  std_logic;
          cfg_interrupt_n_o     : out std_logic);
end BMD_INTR_CTRL;

architecture rtl of BMD_INTR_CTRL is
    -- Local Registers

    signal rd_intr_n : std_logic;
    signal wr_intr_n : std_logic;

    signal mrd_done : std_logic;
    signal mwr_done : std_logic;

--    type intr_state_type is (BMD_INTR_RST, BMD_INTR_RD, BMD_INTR_WR);
    type rd_intr_state_type is (BMD_INTR_RD_RST, BMD_INTR_RD_ACT, BMD_INTR_RD_RCV,
                                BMD_INTR_RD_DUN);
    type wr_intr_state_type is (BMD_INTR_WR_RST, BMD_INTR_WR_ACT, BMD_INTR_WR_RCV,
                                BMD_INTR_WR_DUN);
--    signal intr_state, next_intr_state: intr_state_type;
    signal rd_intr_state, next_rd_intr_state : rd_intr_state_type;
    signal wr_intr_state, next_wr_intr_state : wr_intr_state_type;

begin  -- rtl

    cfg_interrupt_n_o <= rd_intr_n and wr_intr_n;

    -------------------------------------------------------------------
    -- Resolve mrd_done_i and mwr_done_i
    -------------------------------------------------------------------
	 
	 mwr_done <= mwr_done_i;
	 mrd_done <= mrd_done_i when (mwr_done_i = '0' or wr_intr_state = BMD_INTR_WR_DUN) else '0';

--    process (mrd_done_i, mwr_done_i, rd_intr_state, intr_state,
--             rd_intr_state, wr_intr_state)
--    begin
--        case intr_state is
--            when BMD_INTR_RST =>
--                if mrd_done_i = '1' and (rd_intr_state = BMD_INTR_RD_RST) then
--                    mrd_done <= '1';
--                    mwr_done <= '0';
--                    next_intr_state <= BMD_INTR_RD;
--                elsif mwr_done_i = '1' and (wr_intr_state = BMD_INTR_WR_RST) then
--                    mrd_done <= '0';
--                    mwr_done <= '1';
--                    next_intr_state <= BMD_INTR_WR;
--                else
--                    mrd_done <= '0';
--                    mwr_done <= '0';
--                    next_intr_state <= BMD_INTR_RST;
--                end if;
--            when BMD_INTR_RD =>
--                if mrd_done_i = '1' and (rd_intr_state = BMD_INTR_RD_DUN) then
--                    mwr_done <= '0';
--                    mrd_done <= '1';
--                    next_intr_state <= BMD_INTR_RST;
--                else
--                    mwr_done <= '0';
--                    mrd_done <= '1';
--						  next_intr_state <= BMD_INTR_RD;
--                end if;
--            when BMD_INTR_WR =>
--                if mwr_done_i = '1' and (wr_intr_state = BMD_INTR_WR_DUN) then
--                    mrd_done <= '0';
--                    mwr_done <= '1';
--						  next_intr_state <= BMD_INTR_RST;
--                else 
--                    mrd_done <= '0';
--                    mwr_done <= '1';
--						  next_intr_state <= BMD_INTR_WR;
--                end if;
--                when others => null;
--        end case;
--    end process;

    ---------------------------------------------------------------------------
    -- Read Interrupt Control
    ---------------------------------------------------------------------------

    process (rd_intr_state, mrd_done, cfg_interrupt_rdy_n_i)
    begin
        -- default
        case rd_intr_state is
            when BMD_INTR_RD_RST =>
                if mrd_done = '1' and cfg_interrupt_rdy_n_i = '0' then
                    next_rd_intr_state <= BMD_INTR_RD_ACT;
                    rd_intr_n <= '0';
                else
                    next_rd_intr_state <= BMD_INTR_RD_RST;
                    rd_intr_n <= '1';
                end if;
            when BMD_INTR_RD_ACT =>
                if cfg_interrupt_rdy_n_i = '1' then
                    next_rd_intr_state <= BMD_INTR_RD_RCV;
                    rd_intr_n <= '0';
                else
                    next_rd_intr_state <= BMD_INTR_RD_ACT;
                    rd_intr_n <= '0';
                end if;
				when BMD_INTR_RD_RCV =>
					 if cfg_interrupt_rdy_n_i = '0' then
					     next_rd_intr_state <= BMD_INTR_RD_DUN;
						  rd_intr_n <= '1';
					  else
					     next_rd_intr_state <= BMD_INTR_RD_RCV;
						  rd_intr_n <= '0';
					  end if;						  
            when BMD_INTR_RD_DUN => 
                next_rd_intr_state <= BMD_INTR_RD_DUN;
                rd_intr_n <= '1';
            when others => null;
        end case;
    end process;

    ---------------------------------------------------------------------------
    -- Write Interrupt Control
    ---------------------------------------------------------------------------

    process (wr_intr_state, wr_intr_state, mwr_done, cfg_interrupt_rdy_n_i)
    begin
        case wr_intr_state is
            when BMD_INTR_WR_RST =>
                if mwr_done = '1' and cfg_interrupt_rdy_n_i = '0' then
                    next_wr_intr_state <= BMD_INTR_WR_ACT;
                    wr_intr_n <= '0';
                else
                    next_wr_intr_state <= BMD_INTR_WR_RST;
                    wr_intr_n <= '1';
                end if;
            when BMD_INTR_WR_ACT =>
                if cfg_interrupt_rdy_n_i = '1'  then
                    next_wr_intr_state <= BMD_INTR_WR_RCV;
                    wr_intr_n <= '0';
                else
                    next_wr_intr_state <= BMD_INTR_WR_ACT;
                    wr_intr_n <= '0';
                end if;
			   when BMD_INTR_WR_RCV =>
				    if cfg_interrupt_rdy_n_i = '0' then
					     next_wr_intr_state <= BMD_INTR_WR_DUN;
						  wr_intr_n <= '1';
					 else
					     next_wr_intr_state <= BMD_INTR_WR_RCV;
						  wr_intr_n <= '0';
						end if;						  
            when BMD_INTR_WR_DUN =>
                next_wr_intr_state <= BMD_INTR_WR_DUN;
                wr_intr_n <= '1';
        end case;
    end process;

    process (clk, rst_n)
    begin
        if rst_n = '0' then
            rd_intr_state <= BMD_INTR_RD_RST;
            wr_intr_state <= BMD_INTR_WR_RST;
--            intr_state    <= BMD_INTR_RST;
        elsif rising_edge(clk) then
            if init_rst_i = '1' then
                rd_intr_state <= BMD_INTR_RD_RST;
                wr_intr_state <= BMD_INTR_WR_RST;
--                intr_state    <= BMD_INTR_RST;
            else 
                rd_intr_state <= next_rd_intr_state;
                wr_intr_state <= next_wr_intr_state;
--                intr_state <= next_intr_state;
            end if;
        end if;
    end process;

end rtl;

