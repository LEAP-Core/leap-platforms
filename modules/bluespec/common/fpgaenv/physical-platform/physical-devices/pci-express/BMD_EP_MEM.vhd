----------------------------------------------------------------------------------

----
----------------------------------------------------------------------------------
---- Filename: BMD_EP_MEM.vhd
---- Li, Zheng Intel
---- Description: Endpoint Memory: 128B/32 registers
----
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library work;
use work.bmd_pak.all;

entity BMD_EP_MEM is
    port ( clk   : in std_logic;
           rst_n : in std_logic;			  
           
			  cfg_max_rd_req_size  : in  std_logic_vector(2 downto 0);
           cfg_max_payload_size : in  std_logic_vector(2 downto 0);
           wr_a_i                  : in  std_logic_vector(6 downto 0);
           wr_en_i              : in  std_logic;
			  rd_a_i                  : in  std_logic_vector(6 downto 0);
           rd_d_o               : out std_logic_vector(31 downto 0);
           wr_d_i               : in  std_logic_vector(31 downto 0);

           -- CSR bits

           init_rst_o : out std_logic;

           mrd_start_o : out std_logic;
           mrd_done_o  : out std_logic;
           mrd_addr_o  : out std_logic_vector(31 downto 0);
           mrd_len_o   : out std_logic_vector(31 downto 0);
           mrd_count_o : out std_logic_vector(31 downto 0);
			  mrd_base_o  : out std_logic_vector(31 downto 0);
			  mrd_suspend_o : out std_logic;
			  mrd_cur_count_i : in std_logic_vector(15 downto 0);
			  mrd_cur_data_size_i : in std_logic_vector (31 downto 0);


           mwr_start_o : out std_logic;
           mwr_done_i  : in  std_logic;
           mwr_addr_o  : out std_logic_vector(31 downto 0);
           mwr_len_o   : out std_logic_vector(31 downto 0);
           mwr_count_o : out std_logic_vector(31 downto 0);
           mwr_base_o  : out std_logic_vector(31 downto 0);

--    	   wr_intr_proc_o : out std_logic;
--           rd_intr_proc_o : out std_logic;

           cpl_ur_found_i : in std_logic_vector(7 downto 0);
           cpl_ur_tag_i   : in std_logic_vector(7 downto 0);
			  
--			  special_reg_o  : out std_logic_vector(31 downto 0);
			  led_switch     : out std_logic;

           cpld_found_i     : in std_logic_vector(31 downto 0);
           cpld_data_size_i : in std_logic_vector(31 downto 0);
           cpld_malformed_i : in std_logic
			  
			  );
end entity BMD_EP_MEM;

architecture rtl of BMD_EP_MEM is
    -- Local Regs

    signal mrd_perf : std_logic_vector(31 downto 0);
    signal mwr_perf : std_logic_vector(31 downto 0);

    signal expect_cpld_data_size : std_logic_vector(31 downto 0);  -- 2 GB max
    signal expect_cal_complete   : std_logic;
    signal cpld_data_size        : std_logic_vector(31 downto 0);  -- 2 GB max
    signal cpld_done             : std_logic;

    signal init_rst_internal     : std_logic;

    signal mrd_done_internal  : std_logic;
    signal mrd_start_internal : std_logic;
    signal mrd_addr_internal  : std_logic_vector(31 downto 0);
    signal mrd_len_internal   : std_logic_vector(31 downto 0);
    signal mrd_count_internal : std_logic_vector(31 downto 0);
    signal mrd_count_tmp : std_logic_vector(31 downto 0);
	 signal mrd_base_internal  : std_logic_vector(31 downto 0);
	 
	 signal mrd_suspend : std_logic;

    signal mwr_start_internal : std_logic;
    signal mwr_addr_internal  : std_logic_vector(31 downto 0);
    signal mwr_len_internal   : std_logic_vector(31 downto 0);
    signal mwr_count_internal : std_logic_vector(31 downto 0);
    signal mwr_base_internal  : std_logic_vector(31 downto 0);
	 
	 signal special_reg			: std_logic_vector(31 downto 0);
	 
	 signal addr_reg : std_logic_vector(6 downto 0);
	 
	 signal cpld_found_plus : std_logic_vector (31 downto 0);
	 signal cpld_data_size_plus : std_logic_vector (31 downto 0);

--    signal wr_intr_proc       : std_logic;
--    signal rd_intr_proc       : std_logic;

begin  -- rtl

    -- special_reg_o <= special_reg;

    mrd_done_o  <= mrd_done_internal;
    mrd_start_o <= mrd_start_internal;
    mrd_addr_o  <= mrd_addr_internal;
    mrd_len_o   <= mrd_len_internal;
    mrd_count_o <= mrd_count_internal;
	 mrd_base_o  <= mrd_base_internal;

    mwr_start_o <= mwr_start_internal;
    mwr_addr_o  <= mwr_addr_internal;
    mwr_len_o   <= mwr_len_internal;
    mwr_count_o <= mwr_count_internal;
    mwr_base_o  <= mwr_base_internal;
    
    init_rst_o <= init_rst_internal;
	 mrd_suspend_o <= mrd_suspend;
	 
	 led_switch <= special_reg(0);

--    wr_intr_proc_o <= wr_intr_proc;
--    rd_intr_proc_o <= rd_intr_proc;
	process (clk, rst_n)
	begin
		if (rst_n = '0') then
			cpld_found_plus <= x"00000008";
			cpld_data_size_plus <= x"00000080";
		elsif rising_edge(clk) then 
			cpld_found_plus <= cpld_found_i + x"00000008";
			cpld_data_size_plus <=  cpld_data_size_i + x"00000080";
		end if;
	end process;

    process (clk, rst_n)
	 begin
		if (rst_n = '0') then
			mrd_suspend <= '0';
		elsif rising_edge(clk) then
			if (init_rst_internal = '1') then
				mrd_suspend <= '0';
			else
			   if (mrd_cur_count_i >= cpld_found_plus) 
				   or (mrd_cur_data_size_i >= cpld_data_size_plus) then
					mrd_suspend <= '1';
				else
					mrd_suspend <= '0';
				end if;				
			end if;
		end if;
	end process;
					
					
				
	process (clk, rst_n)
	begin
		if (rst_n = '0') then
			addr_reg <= (others =>'0');
		elsif rising_edge(clk) then
			addr_reg <= rd_a_i;
		end if;
	end process;
	 
	 process (addr_reg, mrd_perf, mwr_perf, expect_cpld_data_size, 
	          cpld_data_size, cpld_done ,init_rst_internal, 
				 mrd_done_internal,mrd_start_internal, mrd_addr_internal,
				 mrd_len_internal   ,mrd_count_internal ,
				 mrd_base_internal , mwr_start_internal , mwr_addr_internal,
				 mwr_len_internal  , mwr_count_internal , mwr_base_internal, 
				 mwr_done_i, cfg_max_payload_size, cfg_max_rd_req_size, 
				 cpld_malformed_i, cpl_ur_tag_i, cpl_ur_found_i, 
				 cpld_found_i, cpld_data_size_i)
	 
	 begin
	 case addr_reg(6 downto 0) is
                -- 00-03H : Reg # 0 
                -- Byte0[0]: Initiator Reset (RW) 0= no reset 1=reset.
                when "0000000" =>
                    rd_d_o <= (0 => init_rst_internal, others => '0');
--			wr_intr_proc <= '0';
--			rd_intr_proc <= '0';
                -- 04-07H :  Reg # 1
                -- Byte0(0): Memory Write Start (RW) 0=no start, 1=start
                -- Byte1(0): Memory Write Done  (RO) 0=not done, 1=done
                -- Byte2(0): Memory Read Start (RW) 0=no start, 1=start
                -- Byte3(0): Memory Read Done  (RO) 0=not done, 1=done
                when "0000001" =>
                    rd_d_o <= "0000000" & mrd_done_internal & "0000000" &
                              mrd_start_internal & "0000000" & mwr_done_i &
                              "0000000" & mwr_start_internal;
                -- 08-0BH : Reg # 2
                -- Memory Write DMA Address (RW)
                when "0000010" =>
                    rd_d_o <= mwr_addr_internal;
                -- 0C-0FH : Reg # 3
                -- Memory Write length in DWORDs (RW)
                when "0000011" =>
                    rd_d_o <= "0000000000000" & cfg_max_payload_size &
                              mwr_len_internal(15 downto 0);
                    
                -- 10-13H : Reg # 4
                -- Memory Write Packet Count (RW)
                when "0000100" =>
                    rd_d_o <= mwr_count_internal;
                -- 14-17H : Reg # 5
                -- Memory Write Packet DWORD Data (RW)
                when "0000101" =>
                    rd_d_o <= mwr_base_internal;
                -- 18-1BH : Reg # 6
                -- Reserved for future use
                when "0000110" =>
					     rd_d_o <= mrd_base_internal;
                -- 1C-1FH : Reg # 7
                -- Read DMA Address (RW)
                when "0000111" =>
                    rd_d_o <= mrd_addr_internal;
                -- 20-23H : Reg # 8
                -- Read length in DWORDs (RW)
                when "0001000" =>
                    rd_d_o <= "0000000000000" & cfg_max_rd_req_size &
                              mrd_len_internal(15 downto 0);
                -- 24-27H : Reg # 9
                -- Read Packet Count (RW)
                when "0001001" =>
                    rd_d_o <= mrd_count_internal;
                -- 28-2BH : Reg # 10 
                -- Memory Write Performance (RO)
                when "0001010" =>
                    rd_d_o <= mwr_perf;
                -- 2C-2FH  : Reg # 11
                -- Memory Read  Performance (RO)
                when "0001011" =>
                    rd_d_o <= mrd_perf;
                -- 30-33H  : Reg # 12
                -- Memory Read Completion Status (RO)
                when "0001100" =>
                    rd_d_o(31 downto 17) <= "000000000000000";
                    rd_d_o(16 downto 0) <= cpld_malformed_i &
                              cpl_ur_tag_i & cpl_ur_found_i;
                -- 34-37H  : Reg # 13
                -- Memory Read Completion with Data Detected (RO)
                when "0001101" =>
                    rd_d_o <= cpld_found_i;
                -- 38-3BH  : Reg # 14
                -- Memory Read Completion with Data Size (RO)
                when "0001110" =>
                    rd_d_o <= cpld_data_size_i;
						  
					 when "0010000" =>
						  rd_d_o <= special_reg;
		-- 3C-7FH : Reserved Interrupt Processed
--	    	when "0001111" =>
--		    rd_d_o <= (0 => wr_intr_proc, 8=> rd_intr_proc, others => '0');
--	            if wr_en_i = '1' then
--                        wr_intr_proc  <= wr_d_i(0);
--			rd_intr_proc  <= wr_d_i(8);
--                    end if;

	        when others => 
                    rd_d_o <= (others => '0');
            end case;
	 end process;
	 
	 
	 process (clk, rst_n)
    begin
        if rst_n = '0' then
            -- RW: Added

            init_rst_internal <= '0';

            mrd_start_internal <= '0';
            mrd_addr_internal  <= (others => '0');
            mrd_len_internal   <= (others => '0');
            mrd_count_internal <= (others => '0');
				mrd_base_internal <= (others => '0');

            mwr_start_internal <= '0';
            mwr_addr_internal  <= (others => '0');
            mwr_len_internal   <= (others => '0');
            mwr_count_internal <= (others => '0');
            mwr_base_internal  <= (others => '0');

-- 	    wr_intr_proc <='0';
-- 	    rd_intr_proc <='0';
        elsif rising_edge(clk) then
            case wr_a_i(6 downto 0) is
                -- 00-03H : Reg # 0 
                -- Byte0[0]: Initiator Reset (RW) 0= no reset 1=reset.
                when "0000000" =>
                    
                    if wr_en_i = '1' then
                        init_rst_internal  <= wr_d_i(0);
                    end if;
                    if wr_en_i = '1' and wr_d_i(0) = '1' then
                        mwr_start_internal <= '0';
                        mrd_start_internal <= '0';
--			wr_intr_proc <= '0';
--			rd_intr_proc <= '0';
                    end if;
                -- 04-07H :  Reg # 1
                -- Byte0(0): Memory Write Start (RW) 0=no start, 1=start
                -- Byte1(0): Memory Write Done  (RO) 0=not done, 1=done
                -- Byte2(0): Memory Read Start (RW) 0=no start, 1=start
                -- Byte3(0): Memory Read Done  (RO) 0=not done, 1=done
                when "0000001" =>
                    
                    if wr_en_i = '1' then
                        mwr_start_internal  <= wr_d_i(0);
                        mrd_start_internal  <= wr_d_i(16);
                    end if;
                -- 08-0BH : Reg # 2
                -- Memory Write DMA Address (RW)
                when "0000010" =>
                    
                    if wr_en_i = '1' then
                        mwr_addr_internal  <= wr_d_i;
                    end if;
                -- 0C-0FH : Reg # 3
                -- Memory Write length in DWORDs (RW)
                when "0000011" =>
                    
                    if wr_en_i = '1' then
                        mwr_len_internal(15 downto 0)  <= wr_d_i(15 downto 0);
                    end if;
                -- 10-13H : Reg # 4
                -- Memory Write Packet Count (RW)
                when "0000100" =>
                    
                    if wr_en_i = '1' then
                        mwr_count_internal  <= wr_d_i;
                    end if;
                -- 14-17H : Reg # 5
                -- Memory Write Packet DWORD Data (RW)
                when "0000101" =>
                    
                    if wr_en_i = '1' then
                        mwr_base_internal  <= wr_d_i;
                    end if;
                -- 18-1BH : Reg # 6
                -- Reserved for future use
                when "0000110" =>
					     
                    if wr_en_i = '1' then
                        mrd_base_internal  <= wr_d_i;
                    end if;
                -- 1C-1FH : Reg # 7
                -- Read DMA Address (RW)
                when "0000111" =>
                    
                    if wr_en_i = '1' then
                        mrd_addr_internal  <= wr_d_i;
                    end if;
                -- 20-23H : Reg # 8
                -- Read length in DWORDs (RW)
                when "0001000" =>
                    
                    if wr_en_i = '1' then
                        mrd_len_internal(15 downto 0)  <= wr_d_i(15 downto 0);
                    end if;
                -- 24-27H : Reg # 9
                -- Read Packet Count (RW)
                when "0001001" =>
                    
                    if wr_en_i = '1' then
                        mrd_count_internal  <= wr_d_i;
                    end if;
                -- 28-2BH : Reg # 10 
                -- Memory Write Performance (RO)
					 
					 when "0010000" =>
						  if wr_en_i = '1' then
								special_reg <= wr_d_i;
						  end if;
						  
                
	        when others => 
            end case;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Memory Write Performance Instrumentation
    ---------------------------------------------------------------------------

    process (clk, rst_n)
    begin
        if rst_n = '0' then
            mwr_perf <= (others => '0');
        elsif rising_edge(clk) then
            if init_rst_internal = '1' then
                mwr_perf <= (others => '0');
            elsif mwr_start_internal = '1' and mwr_done_i = '0' then
                mwr_perf <= mwr_perf + 1;
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Memory Read Performance Instrumentation
    ---------------------------------------------------------------------------

    process (clk, rst_n)
    begin
        if rst_n = '0' then
            mrd_perf <= (others => '0');
        elsif rising_edge(clk) then
          if init_rst_internal = '1' then
              mrd_perf <= (others => '0');
          elsif mrd_start_internal = '1' and mrd_done_internal = '0' then
              mrd_perf <= mrd_perf + 1;
          end if;
        end if;
    end process;

	process (clk, rst_n)
	begin
		if rst_n = '0' then
			expect_cpld_data_size <= (others =>'0');
			mrd_count_tmp <= (others => '0');
         expect_cal_complete <= '0';
		elsif rising_edge(clk) then
			if init_rst_internal = '1' then
				expect_cpld_data_size <= (others =>'0');
				mrd_count_tmp <= (others => '0');
            expect_cal_complete <= '0';
			elsif mrd_start_internal = '1' and mrd_count_tmp /= mrd_count_internal then
				expect_cpld_data_size <= expect_cpld_data_size + mrd_len_internal;
				mrd_count_tmp <= mrd_count_tmp + 1;
            expect_cal_complete <= '0';
          elsif mrd_start_internal = '1' and mrd_count_tmp = mrd_count_internal then
            expect_cal_complete <= '1';
			end if;
		end if;
	end process;
				
--			expect_cpld_data_size <= ext(mrd_len_internal(15 downto 0) * mrd_count_internal(15 downto 0),
--                                             expect_cpld_data_size'length);

	
	cpld_data_size        <= cpld_data_size_i;
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            cpld_done <= '0';				
        elsif rising_edge(clk) then					
            if init_rst_internal = '1' then
                cpld_done <= '0';
            else
             if (expect_cpld_data_size = cpld_data_size) and (expect_cal_complete = '1') then
                    cpld_done <= '1';
                else
                    cpld_done <= '0';
                end if;
            end if;
        end if;
    end process;
	 
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            mrd_done_internal <= '0';
        elsif rising_edge(clk) then
            if init_rst_internal = '1' then
                mrd_done_internal <= '0';
            elsif mrd_start_internal = '1' and mrd_done_internal = '0' and cpld_done = '1' then
                mrd_done_internal <= '1';
            end if;
        end if;
    end process;
end rtl;
