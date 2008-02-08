----------------------------------------------------------------------------------
---- Filename: BMD_EP_MEM.vhd
---- Wang, Liang(liang.wang@intel.com)
---- Description: BAR0 Registers: 128B/32 registers
----
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity PCIE_BAR0 is
port ( 
	clk   : in std_logic;
	rst_n : in std_logic;			  
	
	cfg_max_rd_req_size  	: in  std_logic_vector(2 downto 0);
	cfg_max_payload_size 	: in  std_logic_vector(2 downto 0);
	wr_a_i                  : in  std_logic_vector(7 downto 0);
	wr_en_i              	: in  std_logic;
	rd_a_i                  : in  std_logic_vector(7 downto 0);
	rd_d_o               	: out std_logic_vector(31 downto 0);
	wr_d_i               	: in  std_logic_vector(31 downto 0);
	
	-- CSR bits
	
	init_rst_o 				: out std_logic;
	
	mrd_start_o 			: out std_logic;
	mrd_done_o  			: out std_logic;
	mrd_addr_o  			: out std_logic_vector(31 downto 0);
	mrd_addr_hi_o 			: out std_logic_vector(31 downto 0);
	mrd_len_o   			: out std_logic_vector(31 downto 0);
	mrd_count_o 			: out std_logic_vector(31 downto 0);
	mrd_base_o  			: out std_logic_vector(31 downto 0);
	mrd_suspend_o 			: out std_logic;
	mrd_cur_count_i 		: in std_logic_vector(15 downto 0);
	mrd_cur_data_size_i 	: in std_logic_vector (31 downto 0);
	
	
	mwr_start_o 			: out std_logic;
	mwr_done_i  			: in  std_logic;
	mwr_addr_o  			: out std_logic_vector(31 downto 0);
	mwr_addr_hi_o 			: out std_logic_vector(31 downto 0);
	mwr_len_o   			: out std_logic_vector(31 downto 0);
	mwr_count_o 			: out std_logic_vector(31 downto 0);
	mwr_base_o  			: out std_logic_vector(31 downto 0);
	
	pcie_csr_in_h2f_reg0_wr_en: out std_logic;
	pcie_csr_in_h2f_reg0      : out std_logic_vector((32 - 1) downto 0);	
	pcie_csr_out_f2h_reg0     : in std_logic_vector((32 - 1) downto 0);
	
	csr_test_start_o : out std_logic_vector(31 downto 0);
	csr_test_data_in_o  : out std_logic_vector(31 downto 0);
	csr_test_index_o : out std_logic_vector(31 downto 0);
	csr_test_data_out_i : in std_logic_vector(31 downto 0);

	intr_host_ack : out std_logic;
	intr_host_en : out std_logic;
	
	cpl_ur_found_i 			: in std_logic_vector(7 downto 0);
	cpl_ur_tag_i   			: in std_logic_vector(7 downto 0);
	
	cpld_found_i     		: in std_logic_vector(31 downto 0);
	cpld_data_size_i 		: in std_logic_vector(31 downto 0);
	cpld_malformed_i 		: in std_logic);
end entity PCIE_BAR0;

architecture rtl of PCIE_BAR0 is
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
signal mrd_addr_hi_internal : std_logic_vector(31 downto 0);
signal mrd_len_internal   : std_logic_vector(31 downto 0);
signal mrd_count_internal : std_logic_vector(31 downto 0);
signal mrd_count_tmp : std_logic_vector(31 downto 0);
signal mrd_base_internal  : std_logic_vector(31 downto 0);

signal mrd_suspend : std_logic;

signal mwr_start_internal : std_logic;
signal mwr_addr_internal  : std_logic_vector(31 downto 0);
signal mwr_addr_hi_internal: std_logic_vector(31 downto 0);
signal mwr_len_internal   : std_logic_vector(31 downto 0);
signal mwr_count_internal : std_logic_vector(31 downto 0);
signal mwr_base_internal  : std_logic_vector(31 downto 0);

signal addr_reg : std_logic_vector(7 downto 0);

signal cpld_found_plus : std_logic_vector (31 downto 0);
signal cpld_data_size_plus : std_logic_vector (31 downto 0);

signal csr_test_start_internal : std_logic_vector(31 downto 0);
signal csr_test_data_in_internal  : std_logic_vector(31 downto 0);
signal csr_test_index_internal : std_logic_vector(31 downto 0);
signal csr_test_data_out_internal : std_logic_vector(31 downto 0);
signal start_impulse_internal : std_logic;
signal impulse_internal : std_logic;
signal impulse_state : std_logic;

--    signal wr_intr_proc       : std_logic;
--    signal rd_intr_proc       : std_logic;

begin  -- rtl

    mrd_done_o  <= mrd_done_internal;
    mrd_start_o <= mrd_start_internal;
    mrd_addr_o  <= mrd_addr_internal;
	mrd_addr_hi_o <= mrd_addr_hi_internal;
    mrd_len_o   <= mrd_len_internal;
    mrd_count_o <= mrd_count_internal;
	 mrd_base_o  <= mrd_base_internal;

    mwr_start_o <= mwr_start_internal;
    mwr_addr_o  <= mwr_addr_internal;
	mwr_addr_hi_o <= mwr_addr_hi_internal;
    mwr_len_o   <= mwr_len_internal;
    mwr_count_o <= mwr_count_internal;
    mwr_base_o  <= mwr_base_internal;
    
    init_rst_o <= init_rst_internal;
	 mrd_suspend_o <= mrd_suspend;
	 
	csr_test_start_o <= csr_test_start_internal; 
	csr_test_data_in_o  <= csr_test_data_in_internal;
	csr_test_index_o <= csr_test_index_internal;
	csr_test_data_out_internal <= csr_test_data_out_i;
	
   csr_test_start_internal <= "0000000000000000000000000000000" & start_impulse_internal;

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
	 
process (addr_reg, pcie_csr_out_f2h_reg0--mrd_perf, mwr_perf, expect_cpld_data_size, 
--				cpld_data_size, cpld_done ,init_rst_internal, 
--		 mrd_done_internal,mrd_start_internal, mrd_addr_internal,
--		 mrd_len_internal   ,mrd_count_internal ,
--		 mrd_base_internal , mwr_start_internal , mwr_addr_internal,
--		 mwr_len_internal  , mwr_count_internal , mwr_base_internal, 
--		 mwr_done_i, cfg_max_payload_size, cfg_max_rd_req_size, 
--		 cpld_malformed_i, cpl_ur_tag_i, cpl_ur_found_i, 
--		 cpld_found_i, cpld_data_size_i
		 )
	 
begin
case addr_reg is
	when X"01" =>
		rd_d_o <= pcie_csr_out_f2h_reg0;
                -- 00-03H : Reg # 0 
                -- Byte0[0]: Initiator Reset (RW) 0= no reset 1=reset.
--                when "000000" =>
--                    rd_d_o <= (0 => init_rst_internal, others => '0');

                -- 04-07H :  Reg # 1
                -- Byte0(0): Memory Write Start (RW) 0=no start, 1=start
                -- Byte1(0): Memory Write Done  (RO) 0=not done, 1=done
                -- Byte2(0): Memory Read Start (RW) 0=no start, 1=start
                -- Byte3(0): Memory Read Done  (RO) 0=not done, 1=done
--                when "000001" =>
--                    rd_d_o <= "0000000" & mrd_done_internal & "0000000" &
--                              mrd_start_internal & "0000000" & mwr_done_i &
--                              "0000000" & mwr_start_internal;
                -- 08-0BH : Reg # 2
                -- Memory Write DMA Address (RW)
--                when "000010" =>
--                    rd_d_o <= mwr_addr_internal;
                -- 0C-0FH : Reg # 3
                -- Memory Write length in DWORDs (RW)
--                when "000011" =>
--                    rd_d_o <= "0000000000000" & cfg_max_payload_size &
--                              mwr_len_internal(15 downto 0);
                    
                -- 10-13H : Reg # 4
                -- Memory Write Packet Count (RW)
--                when "000100" =>
--                    rd_d_o <= mwr_count_internal;
                -- 14-17H : Reg # 5
                -- Memory Write Packet DWORD Data (RW)
--                when "000101" =>
--                    rd_d_o <= mwr_base_internal;
                -- 18-1BH : Reg # 6
                -- Reserved for future use
--                when "000110" =>
--					     rd_d_o <= mrd_base_internal;
                -- 1C-1FH : Reg # 7
                -- Read DMA Address (RW)
--                when "000111" =>
--                    rd_d_o <= mrd_addr_internal;
                -- 20-23H : Reg # 8
                -- Read length in DWORDs (RW)
--                when "001000" =>
--                    rd_d_o <= "0000000000000" & cfg_max_rd_req_size &
--                              mrd_len_internal(15 downto 0);
                -- 24-27H : Reg # 9
                -- Read Packet Count (RW)
--                when "001001" =>
--                    rd_d_o <= mrd_count_internal;
                -- 28-2BH : Reg # 10 
                -- Memory Write Performance (RO)
--                when "001010" =>
--                    rd_d_o <= mwr_perf;
                -- 2C-2FH  : Reg # 11
                -- Memory Read  Performance (RO)
--                when "001011" =>
--                    rd_d_o <= mrd_perf;
                -- 30-33H  : Reg # 12
                -- Memory Read Completion Status (RO)
--                when "001100" =>
--                    rd_d_o(31 downto 17) <= "000000000000000";
--                    rd_d_o(16 downto 0) <= cpld_malformed_i &
--                              cpl_ur_tag_i & cpl_ur_found_i;
                -- 34-37H  : Reg # 13
                -- Memory Read Completion with Data Detected (RO)
--                when "001101" =>
--                    rd_d_o <= cpld_found_i;
                -- 38-3BH  : Reg # 14
                -- Memory Read Completion with Data Size (RO)
--                when "001110" =>
--                    rd_d_o <= cpld_data_size_i;
		-- 3C-7FH : Reserved Interrupt Processed
--	    	when "0001111" =>
--		    rd_d_o <= (0 => wr_intr_proc, 8=> rd_intr_proc, others => '0');
--	            if wr_en_i = '1' then
--                        wr_intr_proc  <= wr_d_i(0);
--			rd_intr_proc  <= wr_d_i(8);
--                    end if;
--				when "010000" =>
--					rd_d_o <= mwr_addr_hi_internal;
				
--				when "010001" =>
--					rd_d_o <= mrd_addr_hi_internal;
				-- lwang
--				when "010101" =>
--					rd_d_o <= csr_test_data_out_internal;
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
		mrd_addr_hi_internal  <= (others => '0');
		mrd_len_internal   <= (others => '0');
		mrd_count_internal <= (others => '0');
		mrd_base_internal <= (others => '0');
		
		mwr_start_internal <= '0';
		mwr_addr_internal  <= (others => '0');
		mwr_addr_hi_internal  <= (others => '0');
		mwr_len_internal   <= (others => '0');
		mwr_count_internal <= (others => '0');
		mwr_base_internal  <= (others => '0');
		
		csr_test_data_in_internal  <= (others => '0');
		csr_test_index_internal <= (others => '0');
		start_impulse_internal <= '0';
		
		pcie_csr_in_h2f_reg0_wr_en <= '0';
		pcie_csr_in_h2f_reg0 <= (others => '0');
		
		intr_host_ack <= '0';
		intr_host_en <= '0';
	
	elsif rising_edge(clk) then
		case wr_a_i(7 downto 0) is
		
		-- system CSR
		when X"00" =>
			if wr_en_i = '1' then
				pcie_csr_in_h2f_reg0_wr_en <= '1';
				pcie_csr_in_h2f_reg0 <= wr_d_i;
			else
				pcie_csr_in_h2f_reg0_wr_en <= '0';
				pcie_csr_in_h2f_reg0 <= (others => '0');
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
		
		-- csr_test start	signal(index=X"FA" or D"250")
		when X"FA" =>
			if wr_en_i = '1' then
				start_impulse_internal <= '1';
			else
				start_impulse_internal <= '0';
			end if;
		
		-- csr_test write data(index=X"FB" or D"251")
		when X"FB" =>
			if wr_en_i = '1' then
				csr_test_data_in_internal <= wr_d_i;
			end if;
		
		-- csr_test write index(index=X"FC" or D"252")
		when X"FC" =>
			if wr_en_i = '1' then
				csr_test_index_internal <= wr_d_i;
			end if;
		
		-- start a interrupt, just a test
		when X"FD" =>
			if wr_en_i = '1' then
				intr_host_en <= '1';
			else
				intr_host_en <= '0';
			end if;
		
		when others => 
			start_impulse_internal <= '0';
			pcie_csr_in_h2f_reg0_wr_en <= '0';
			pcie_csr_in_h2f_reg0 <= (others => '0');		
			intr_host_ack <= '0';
			intr_host_en <= '0';
		end case;
	end if;
end process;
    
    -- generate a impulse to start the test
    process (clk, rst_n)
    begin
        if rst_n = '0' then
           impulse_internal <= '0';
           impulse_state <= '0';
           
        elsif rising_edge(clk) then
           case impulse_state is
           when '0' =>
               impulse_internal <= '0';
               if ( start_impulse_internal = '1') then
                  impulse_state <= '1';
               else
                  impulse_state <= '0';
               end if;
           when '1' =>
               impulse_internal <= '1';
               impulse_state <= '0';
           when others =>
              null;         
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
