----------------------------------------------------------------------------------
---- Filename: BMD_64_TX_ENGINE.vhd
---- Wang, Liang(liang.wang@intel.com)
---- Description: Local-Link Transmit Unit.
----
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity PCIE_TX_ENGINE is
port ( 
	clk   : in std_logic;
	rst_n : in std_logic;
	
	-- 8 pcie core
	trn_td         : out std_logic_vector(63 downto 0);
	trn_trem_n     : out std_logic_vector(7 downto 0);
	trn_tsof_n     : out std_logic;
	trn_teof_n     : out std_logic;
	trn_tsrc_rdy_n : out std_logic;
	trn_tsrc_dsc_n : out std_logic;
	trn_tdst_rdy_n : in  std_logic;
	trn_tdst_dsc_n : in  std_logic;
	
	-- 2control + 10 in
	req_compl_i  : in  std_logic;
	compl_done_o : out std_logic;
	rd_addr_fen : out std_logic;
	req_tc_i   : in std_logic_vector(2 downto 0);
	req_td_i   : in std_logic;
	req_ep_i   : in std_logic;
	req_attr_i : in std_logic_vector(1 downto 0);
	req_len_i  : in std_logic_vector(9 downto 0);
	req_rid_i  : in std_logic_vector(15 downto 0);
	req_tag_i  : in std_logic_vector(7 downto 0);
	req_be_i   : in std_logic_vector(3 downto 0);
	req_addr_i : in std_logic_vector(31 downto 0);
	req_bar_i  : in std_logic;

	-- CSR ports
	csr_rd_ready		: in std_logic; 
	csr_rd_done			: in std_logic;
	csr_rd_en				  : out std_logic;
	csr_rd_ack				 : out std_logic;
	csr_rd_data			: in std_logic_vector((32 - 1) downto 0);
	csr_rd_index			: out std_logic_vector((8 - 1) downto 0);	
	
	reserved_csr_rd_index : out std_logic_vector((8 -1) downto 0);
	reserved_csr_rd_data  : in std_logic_vector((32 - 1) downto 0);
	
	-- CSR ports
	
	
	-- read control 5
	
	rd_addr_o : out std_logic_vector(31 downto 0);
	rd_be_o   : out std_logic_vector(3 downto 0);
	rd_be_hi_o : out std_logic_vector(3 downto 0);
	rd_data_i : in  std_logic_vector(31 downto 0);
	rd_data_hi_i : in std_logic_vector(31 downto 0);
	rd_select_o : out std_logic;
	
	init_rst_i : in std_logic;
	
	mwr_start_i : in  std_logic;
	mwr_len_i   : in  std_logic_vector(31 downto 0);
	mwr_lbe_i   : in  std_logic_vector(3 downto 0);
	mwr_fbe_i   : in  std_logic_vector(3 downto 0);
	mwr_addr_i  : in  std_logic_vector(31 downto 0);
	mwr_addr_hi_i : in std_logic_vector(31 downto 0);
	mwr_base_i  : in  std_logic_vector(31 downto 0);
	mwr_count_i : in  std_logic_vector(31 downto 0);
	mwr_done_o  : out std_logic;
	mrd_suspend_i : in std_logic;
	mrd_cur_count_o : out std_logic_vector(15 downto 0);
	mrd_cur_data_size_o : out std_logic_vector (31 downto 0);
	
	
	mrd_start_i : in std_logic;
	mrd_len_i   : in std_logic_vector(31 downto 0);
	mrd_lbe_i   : in std_logic_vector(3 downto 0);
	mrd_fbe_i   : in std_logic_vector(3 downto 0);
	mrd_addr_i  : in std_logic_vector(31 downto 0);
	mrd_addr_hi_i : in std_logic_vector(31 downto 0);
	mrd_count_i : in std_logic_vector(31 downto 0);
	mrd_base_i  : in std_logic_vector(31 downto 0);
	mrd_done_i  : in std_logic; --no use signal
	
--	cfg_interrupt_n_o     : out std_logic;
--	cfg_interrupt_rdy_n_i : in  std_logic;
--	cfg_interrupt_assert_n: out std_logic;
	
	--for debug use only
	f2h_data_tmp_o : out std_logic_vector(63 downto 0);
	dst_rdy_n_o    : out std_logic;
	rd_en_o : out std_logic;
	--			  rd_data_hi_1_o   : out std_logic_vector(31 downto 0);
	--			  rd_data_hi_2_o   : out std_logic_vector(31 downto 0);
	--			  rd_data_tmp_o    : out std_logic_vector(31 downto 0);
	--			  rd_data_tmp_hi_o : out std_logic_vector(31 downto 0);
	--			  rd_data_sel_o    : out std_logic;
	cur_wr_count_o	 : out std_logic_vector(15 downto 0);
	cur_mwr_dw_count_o : out std_logic_vector(9 downto 0);
	--			  rd_data_fen_o    : out std_logic;
	--			  data_valid_flag_o 	 : out std_logic;
	--for debug use only
	
	completer_id_i        : in std_logic_vector(15 downto 0);
	cfg_ext_tag_en_i      : in std_logic;
	cfg_bus_mstr_enable_i : in std_logic;
	
	
	f2h_fifo_empty    : in std_logic;
	rd_data_valid			: in std_logic;
	f2h_fifo_ren			: out std_logic);
    
end PCIE_TX_ENGINE;

architecture rtl of PCIE_TX_ENGINE is



--component INTERRUPT_CTRL
--port (
--	clk   : in std_logic;
--	rst_n : in std_logic;
--	
--	init_rst_i : in std_logic;
--	
--	mrd_done_i : in std_logic;
--	mwr_done_i : in std_logic;
--	
--	cfg_interrupt_rdy_n_i : in  std_logic;
--	cfg_interrupt_n_o     : out std_logic;
--	cfg_interrupt_assert_n: out std_logic);
--end component;

constant BMD_64_CPLD_FMT_TYPE : std_logic_vector(6 downto 0) := "1001010";
constant BMD_64_MWR_FMT_TYPE  : std_logic_vector(6 downto 0) := "1000000";
constant BMD_64_MRD_FMT_TYPE  : std_logic_vector(6 downto 0) := "0000000";
constant BMD_64_MRD64_FMT_TYPE : std_logic_vector(6 downto 0) := "0100000";
constant BMD_64_MWR64_FMT_TYPE : std_logic_vector(6 downto 0) := "1100000";

type bmd_64_tx_state_type is (
	BMD_64_TX_RST_STATE,
	BMD_64_TX_CPLD_CSR_WT,
	BMD_64_TX_CPLD_CSR_WT_FOR_DATA,
	BMD_64_TX_CPLD_CSR_RESERVED,
	BMD_64_TX_CPLD_QW1,
	BMD_64_TX_CPLD_WIT, 
	BMD_64_TX_MWR_QW1,
--	BMD_64_TX_MWR_QWNH, 
	BMD_64_TX_MWR_QWNL,
	BMD_64_TX_MWR_LAST_WIT,
	BMD_64_TX_MWR_LAST,
	BMD_64_TX_MRD_QW1);
signal bmd_64_tx_state : bmd_64_tx_state_type;

-- DMA read
signal mwr_done_internal : std_logic;
signal mrd_done : std_logic;
signal cur_rd_count : std_logic_vector(15 downto 0);
signal cur_data_size : std_logic_vector (31 downto 0);
signal mrd_len_byte : std_logic_vector(11 downto 0);
signal tmrd_addr : std_logic_vector(63 downto 0);
signal rmrd_count_sub : std_logic_vector(15 downto 0);

signal serv_mrd : std_logic;

-- DMA write

signal compl_done_internal : std_logic;
signal req_compl_q : std_logic;
signal cur_wr_count : std_logic_vector(15 downto 0);
signal cur_wr_count_eq_zero : std_logic;
signal cur_mwr_dw_count : std_logic_vector(9 downto 0);
signal mwr_len_byte : std_logic_vector(11 downto 0);
signal tmwr_addr : std_logic_vector(63 downto 0);
signal rmwr_count : std_logic_vector(15 downto 0);
signal cpld_addr : std_logic_vector(28 downto 0);
signal cpld_addr_plus : std_logic_vector(10 downto 0);
signal serv_mwr : std_logic;
signal rd_data_tmp : std_logic_vector(31 downto 0);
signal rd_data_tmp_hi: std_logic_vector(31 downto 0);
signal rd_data_tmp1 : std_logic_vector(31 downto 0);
signal rd_data_hi_1 : std_logic_vector(31 downto 0);
signal rd_data_hi_2 : std_logic_vector(31 downto 0);
signal rd_data_sel : std_logic;

signal rd_en : std_logic;

signal f2h_data_tmp : std_logic_vector(63 downto 0);

signal dst_rdy_n: std_logic;

-- Read Completion
signal byte_count : std_logic_vector(11 downto 0);
signal lower_addr : std_logic_vector(6 downto 0);

signal cfg_bm_en : std_logic;
signal mwr_addr  : std_logic_vector(31 downto 0);
signal mwr_addr_hi : std_logic_vector(31 downto 0);
signal mrd_addr  : std_logic_vector(31 downto 0);
signal mrd_addr_hi: std_logic_vector(31 downto 0);
signal addr_internal : std_logic_vector(31 downto 0);
signal addr_max : std_logic_vector(31 downto 0);

signal csr_sel : std_logic; --'1',select Common CSRs; '0' select Reserved CSRs

signal data_valid_flag : std_logic; -- flag = '1' => qw has been send, flag = '0' => qw has not been send

--debug use only-----
signal addr_fifo_full :std_logic; -- no use
signal rd_addr_fifo : std_logic_vector(31 downto 0); -- no use
--signal trn_tsrc_rdy_n_c : std_logic;


    
begin  -- rtl

	addr_fifo_full <= '0';
	
	mwr_done_o <= mwr_done_internal;
	compl_done_o <= compl_done_internal;
	
	cfg_bm_en <= cfg_bus_mstr_enable_i;
	--    cfg_bm_en <= '1';
	mwr_addr <= mwr_addr_i;
	mwr_addr_hi <= mwr_addr_hi_i;
	mrd_addr <= mrd_addr_i;
	mrd_addr_hi <= mrd_addr_hi_i;
	mrd_cur_count_o <= cur_rd_count;
	mrd_cur_data_size_o <= cur_data_size;
	 
	 f2h_fifo_ren <= (not trn_tdst_rdy_n) and (rd_en);
	
	--for debug use only
	f2h_data_tmp_o <= f2h_data_tmp;
	dst_rdy_n_o <= dst_rdy_n;
	cur_wr_count_o	  <= cur_wr_count;
	cur_mwr_dw_count_o <= cur_mwr_dw_count;
	rd_en_o <= rd_en;
	--for debug use only
	
	csr_rd_index <= req_addr_i(9 downto 2);
	reserved_csr_rd_index <= req_addr_i(9 downto 2);
	csr_sel <= req_addr_i(12);
	
--	rd_data_en <= '1' when trn_tdst_rdy_n = '0' and trn_tdst_dsc_n = '1' and rd_data_fen = '1' else
--					  '0';
	
	 addr_max <= (mwr_count_i(24 downto 0) & "0000000"); -- assume all TLP has 128B payload, so addr_max = tlp_count * 128, the data ranges from 0 to (addr_max - 1)
	 process(clk, rst_n)
	 begin
		if rst_n = '0' then
			addr_internal <= (others => '0');
			rd_addr_fen <= '0';
		elsif rising_edge(clk) then
			if init_rst_i = '1' then
				addr_internal <= (others => '0');
				rd_addr_fen <= '0';
			elsif mwr_start_i = '1' then
				if (( addr_internal < addr_max) and (addr_fifo_full = '0')) then
					addr_internal <= addr_internal + 8;
					rd_addr_fen <= '1';
				else
					rd_addr_fen <= '0';
				end if;
			else
				addr_internal <= (others => '0');
				rd_addr_fen <= '0';
			end if;
		end if;
	 end process;
	 
	 process(clk, rst_n)
	 begin
		if rst_n = '0' then
			rd_addr_fifo <= (others => '0');
		elsif rising_edge(clk) then
			rd_addr_fifo <= addr_internal;
		end if;
	 end process;	 


    ---------------------------------------------------------------------------
    -- Present address and byte enable to memory module
    ---------------------------------------------------------------------------


    ---------------------------------------------------------------------------
    -- Calculate byte count based on byte enable
    ---------------------------------------------------------------------------
    process (req_be_i)
    begin
        case req_be_i(3 downto 0) is
            when "1001" | "1011" | "1101" | "1111"  => byte_count <= x"004";
            when "0101" | "0111" => byte_count <= x"003";
            when "1010" | "1110" => byte_count <= x"003";
            when "0011" => byte_count <= x"002";
            when "0110" => byte_count <= x"002";
            when "1100" => byte_count <= x"002";
            when "0001" => byte_count <= x"001";
            when "0010" => byte_count <= x"001";
            when "0100" => byte_count <= x"001";
            when "1000" => byte_count <= x"001";
            when "0000" => byte_count <= x"001";
            when others => byte_count <= (others => 'X');
        end case;
    end process;

    ---------------------------------------------------------------------------
    -- Calculate lower address based on  byte enable
    ---------------------------------------------------------------------------

    process (req_be_i, req_addr_i)
    begin
        case req_be_i(3 downto 0) is
            when "0000" => lower_addr <= req_addr_i(6 downto 2) & "00";
            when "0001" | "0011" | "0101" | "0111" | "1001" | "1011" |
                 "1101" | "1111" => lower_addr <= req_addr_i(6 downto 2) & "00";
            when "0010" | "0110" | "1010" | "1110" => lower_addr <= req_addr_i(6 downto 2) & "01";
            when "0100" | "1100" => lower_addr <= req_addr_i(6 downto 2) & "10";
            when "1000" => lower_addr <= req_addr_i(6 downto 2) & "11";
            when others => lower_addr <= (others => 'X');
        end case;
    end process;
    
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            req_compl_q <= '0';
        elsif rising_edge(clk) then
            req_compl_q <= req_compl_i;
        end if;
    end process;
    
 
    ---------------------------------------------------------------------------
    -- Interrupt Controller
    ---------------------------------------------------------------------------

--INTERRUPT_CTRL_inst: INTERRUPT_CTRL
--port map(
--	clk                   => clk,
--	rst_n                 => rst_n,
--	init_rst_i            => init_rst_i,
--	mrd_done_i            => mrd_done_i,
--	mwr_done_i            => mwr_done_internal,
--	cfg_interrupt_rdy_n_i => cfg_interrupt_rdy_n_i,
--	cfg_interrupt_n_o     => cfg_interrupt_n_o,
--	cfg_interrupt_assert_n => cfg_interrupt_assert_n);
-- end port map of "BMD_INTR_CTRL_inst"

---------------------------------------------------------------------------
-- Tx State Machine 
---------------------------------------------------------------------------
mwr_len_byte <= mwr_len_i(9 downto 0) & "00";
mrd_len_byte <= mrd_len_i(9 downto 0) & "00";
rmwr_count          <= mwr_count_i(15 downto 0);
    
	 
process (clk, rst_n)
begin
	if rst_n = '0' then
		rmrd_count_sub <= (others => '0');
	elsif rising_edge (clk) then
		rmrd_count_sub  <= mrd_count_i(15 downto 0) - 1;
	end if;
end process;
	 
	 
				
process (bmd_64_tx_state, req_be_i, req_bar_i, mwr_base_i, req_addr_i, cur_wr_count_eq_zero, cpld_addr,req_compl_q, mwr_start_i, mwr_done_internal)
begin
	if cur_wr_count_eq_zero = '1' and bmd_64_tx_state = BMD_64_TX_RST_STATE and mwr_start_i = '1' and mwr_done_internal = '0' then
		rd_addr_o <= mwr_base_i(31 downto 0);
			rd_be_o <= x"F";
			rd_be_hi_o <= x"F";
			rd_select_o <= '1';
	elsif (bmd_64_tx_state = BMD_64_TX_RST_STATE and req_compl_q = '1') or bmd_64_tx_state = BMD_64_TX_CPLD_QW1 then
			rd_addr_o <= req_addr_i;
			rd_be_o <= req_be_i;
			rd_be_hi_o <= x"0";
			rd_select_o <= req_bar_i;
	else 
			rd_addr_o <= cpld_addr & "000";
			rd_be_o <= x"F";
			rd_be_hi_o <= x"F";
			rd_select_o <= '1';
	end if;
end process;


process (clk, rst_n)
begin
	if rst_n = '0' then
		trn_tsof_n              <= '1';
		trn_teof_n              <= '1';
		trn_tsrc_rdy_n          <= '1';
		trn_tsrc_dsc_n          <= '1';
		trn_td                  <= (others => '0');
		trn_trem_n              <= (others => '0');
		cur_mwr_dw_count        <= (others => '0');
		compl_done_internal     <= '0';
		mwr_done_internal       <= '0';
		mrd_done                <= '0';
		cur_wr_count            <= (others => '0');
		cur_wr_count_eq_zero    <= '1';
		cur_rd_count            <= (others => '0');
		cur_data_size	         	<= (others => '0');
		tmrd_addr               <= (others => '0');
		tmwr_addr               <= (others => '0');
		serv_mwr                <= '1';
		serv_mrd                <= '1';
		bmd_64_tx_state         <= BMD_64_TX_RST_STATE;
		dst_rdy_n               <= '0';
		cpld_addr               <= (others => '0');
		cpld_addr_plus          <= (others => '0');
		rd_data_tmp             <= (others => '0');
		rd_data_sel             <= '0';
		rd_data_hi_1            <= (others => '0');
		rd_data_hi_2            <= (others => '0');
		f2h_data_tmp						<= (others => '0');
		rd_en <= '0';
		csr_rd_en <= '0';
		csr_rd_ack <= '0';			
--		rd_data_fen <= '0';
		data_valid_flag <= '0';
	elsif rising_edge(clk) then
		if init_rst_i = '1' then
			trn_tsof_n              <= '1';
			trn_teof_n              <= '1';
			trn_tsrc_rdy_n          <= '1';
			trn_tsrc_dsc_n          <= '1';
			trn_td                  <= (others => '0');
			trn_trem_n              <= (others => '0');
			cur_mwr_dw_count        <= (others => '0');
			compl_done_internal     <= '0';
			mwr_done_internal       <= '0';
			mrd_done                <= '0';
			cur_wr_count            <= (others => '0');
			cur_wr_count_eq_zero    <= '1';
			cur_rd_count            <= (others => '0');
			cur_data_size		      <= (others => '0');
			serv_mwr                <= '1';
			serv_mrd                <= '1';
			tmrd_addr               <= (others => '0');
			tmwr_addr               <= (others => '0');	
			bmd_64_tx_state         <= BMD_64_TX_RST_STATE;	    
			cpld_addr               <= (others => '0');
			cpld_addr_plus          <= (others => '0');
			rd_data_tmp             <= (others => '0');
			dst_rdy_n               <= '0';
			rd_data_tmp             <= (others => '0');			
			rd_data_sel             <= '0';
			rd_data_hi_1            <= (others => '0');
			rd_data_hi_2            <= (others => '0');	
			f2h_data_tmp						<= (others => '0');
			rd_en <= '0';
--			rd_data_fen <= '0';
			data_valid_flag <= '0';
			csr_rd_en <= '0';
			csr_rd_ack <= '0';				

		else
			case bmd_64_tx_state is
				when BMD_64_TX_RST_STATE =>
					compl_done_internal       <= '0';
--					rd_data_fen <= '0';
					
					rd_en <= '0';
					if (req_compl_q = '1' and compl_done_internal = '0' and
                        trn_tdst_dsc_n = '1') then
						trn_tsof_n       <= '0';
						trn_teof_n       <= '1';
						trn_tsrc_rdy_n   <= '0';
						trn_td(63) <= '0';
						trn_td(62 downto 56) <= BMD_64_CPLD_FMT_TYPE;  --7
						trn_td(55) <= '0';  --1
						trn_td(54 downto 52) <= req_tc_i;  --3
						trn_td(51 downto 48) <= "0000";  --4
						trn_td(47) <= req_td_i;  --1
						trn_td(46) <= req_ep_i;  --1
						trn_td(45 downto 44) <= req_attr_i;  --2
						trn_td(43 downto 42) <= "00";  --2
						trn_td(41 downto 32) <= req_len_i;  --10
						trn_td(31 downto 16) <= completer_id_i;  --16
						trn_td(15 downto 13) <= "000";  --3
						trn_td(12) <= '0';  --1
						trn_td(11 downto 0) <= byte_count;  --12
						trn_trem_n        <= (others => '0');
						
						if ( csr_sel = '1') then -- common csr
							if ( csr_rd_ready = '1') then
								csr_rd_en <= '1';
								csr_rd_ack <= '0';
								bmd_64_tx_state   <= BMD_64_TX_CPLD_CSR_WT_FOR_DATA;
							else
								csr_rd_en <= '0';
								csr_rd_ack <= '0';
								bmd_64_tx_state <= BMD_64_TX_CPLD_CSR_WT;
							end if;
						else -- reserved csr
							bmd_64_tx_state <= BMD_64_TX_CPLD_CSR_RESERVED;
						end if;

					elsif (mwr_start_i = '1' and mwr_done_internal = '0' and
								serv_mwr = '1' and trn_tdst_dsc_n = '1' and 
								cfg_bm_en = '1') then								
								
						if (trn_tdst_rdy_n = '0' ) then	
							trn_tsof_n       <= '0';
							trn_teof_n       <= '1';
							trn_tsrc_rdy_n   <= '0';
							-- trn_td
							---------------------------------------------------
							trn_td(63 downto 16) <= ( '0' &  --1
													 BMD_64_MWR64_FMT_TYPE &  --7
													 '0' &  --1
													 req_tc_i &  --3
													 "0000" &  --4
													 '0' &  --1
													 '0' &  --1
													 "00" &  --2
													 "00" &  --2
													 mwr_len_i(9 downto 0) &  -- 10
													 completer_id_i);  -- 16
	
							if cfg_ext_tag_en_i = '1' then
								trn_td(15 downto 8) <= cur_wr_count(7 downto 0);
							else
								trn_td(15 downto 13) <= "000";
								trn_td(12 downto 8) <= cur_wr_count(4 downto 0);
							end if;
							
							if mwr_len_i(9 downto 0) = "0000000001" then
								trn_td(7 downto 4) <= "0000";
							else
								trn_td(7 downto 4) <= mwr_lbe_i;
							end if;
							
							trn_td(3 downto 0) <= mwr_fbe_i;
							---------------------------------------------------
	
							trn_trem_n        <= (others => '0');
							cur_mwr_dw_count  <= mwr_len_i(9 downto 0);			    		    
							
							if cur_wr_count_eq_zero = '1' then
								tmwr_addr       <= mwr_addr_hi & mwr_addr;
							else 
								tmwr_addr       <= tmwr_addr + mwr_len_byte;					 
							end if;
							
							
							if (mrd_start_i = '1' and mrd_done = '0') then
								serv_mwr        <= '0';
								serv_mrd        <= '1';
							else
								serv_mwr        <= '1';
								serv_mrd        <= '0';
							end if;
							dst_rdy_n <= '0';
							rd_en <= '0'; -- 4DW Header, data is not needed in the next state.
--							rd_data_fen <= '0'; 
							
							bmd_64_tx_state   <= BMD_64_TX_MWR_QW1;

						else
							trn_tsof_n       <= '1';
							trn_tsrc_rdy_n   <= '0';
--							rd_data_fen 		  <= '0';
							rd_en <= '0';
							bmd_64_tx_state <= BMD_64_TX_RST_STATE;
						end if;
							
					elsif (mrd_start_i = '1' and mrd_done = '0' and
									serv_mrd = '1' and trn_tdst_dsc_n = '1' and
									cfg_bm_en = '1' and mrd_suspend_i = '0') then
             
						trn_tsof_n       <= '0';
						trn_teof_n       <= '1';
						trn_tsrc_rdy_n   <= '0';
						-- trn_td
						---------------------------------------------------
						trn_td(63 downto 16) <= ( '0' &  --1
												 BMD_64_MRD64_FMT_TYPE &  --7
												 '0' &  --1
												 req_tc_i &  --3
												 "0000" &  --4
												 '0' &  --1
												 '0' &  --1
												 "00" &  --2
												 "00" &
												 mrd_len_i(9 downto 0) &  --10
												 completer_id_i);  --16

						if cfg_ext_tag_en_i = '1' then
							trn_td(15 downto 8) <= cur_rd_count(7 downto 0);
						else
							trn_td(15 downto 8) <= ("000" & cur_rd_count(4 downto 0));
						end if;

						if mrd_len_i(9 downto 0) = "0000000001" then
							trn_td(7 downto 4) <= "0000";
						else
							trn_td(7 downto 4) <= mrd_lbe_i;
						end if;
						
						trn_td(3 downto 0) <= mrd_fbe_i;
							
						---------------------------------------------------
						trn_trem_n        <= (others => '0');
						if cur_rd_count = 0 then
							tmrd_addr       <= mrd_addr_hi & mrd_addr;
						else 
							tmrd_addr       <= tmrd_addr + mrd_len_byte;
						end if;
						
						-- Round robin
						if (mwr_start_i = '1' and mwr_done_internal = '0') then
							serv_mwr        <= '1';
							serv_mrd        <= '0';
						else 
							serv_mwr        <= '0';
							serv_mrd        <= '1';
						end if;

						bmd_64_tx_state   <= BMD_64_TX_MRD_QW1;
					else    
						trn_tsof_n        <= '1';
						trn_teof_n        <= '1';
						trn_tsrc_rdy_n    <= '1';
						trn_tsrc_dsc_n    <= '1';
						trn_td            <= (others => '0');
						trn_trem_n        <= (others => '0');
						bmd_64_tx_state   <= BMD_64_TX_RST_STATE;
					end if;
				
				when BMD_64_TX_CPLD_CSR_RESERVED =>
					-- wait a cycle to get the data
					if ( trn_tdst_rdy_n = '0') then
						trn_tsrc_rdy_n <= '1';
						bmd_64_tx_state <= BMD_64_TX_CPLD_QW1;
					else
						trn_tsrc_rdy_n <= '0';
						bmd_64_tx_state <= BMD_64_TX_CPLD_CSR_RESERVED;
					end if;

				when BMD_64_TX_CPLD_CSR_WT =>
					if ( csr_rd_ready = '1' and trn_tdst_rdy_n = '0') then
						csr_rd_en <= '1';
						csr_rd_ack <= '0';
						trn_tsrc_rdy_n <= '1';
						bmd_64_tx_state <= BMD_64_TX_CPLD_CSR_WT_FOR_DATA;
					elsif (trn_tdst_rdy_n = '0') then
						csr_rd_en <= '0';
						csr_rd_ack <= '0';
						trn_tsrc_rdy_n <= '1';
						bmd_64_tx_state <= BMD_64_TX_CPLD_CSR_WT;
					else
						csr_rd_en <= '0';
						csr_rd_ack <= '0';
						trn_tsrc_rdy_n <= '0';
						bmd_64_tx_state <= 	BMD_64_TX_CPLD_CSR_WT;
					end if;
					
				when BMD_64_TX_CPLD_CSR_WT_FOR_DATA =>
					csr_rd_en <= '0';
					trn_tsrc_rdy_n <= '1';
					csr_rd_ack <= '0';
					if (csr_rd_done = '1') then
						bmd_64_tx_state <= BMD_64_TX_CPLD_QW1;
					else
						bmd_64_tx_state <= BMD_64_TX_CPLD_CSR_WT_FOR_DATA;
					end if;
        
				when BMD_64_TX_CPLD_QW1 =>
--					csr_rd_ack <= '0';
--					csr_rd_en <= '0';
					if (trn_tdst_rdy_n = '0' and trn_tdst_dsc_n = '1') then
						trn_tsof_n       <= '1';
						trn_teof_n       <= '0';
						trn_tsrc_rdy_n   <= '0';
						trn_td(63 downto 32) <= ( req_rid_i & 
											req_tag_i &
											'0' &
											lower_addr);
						if ( csr_sel = '1') then
							trn_td(31 downto 0) <= csr_rd_data;
						else
							trn_td(31 downto 0) <= reserved_csr_rd_data;
						end if;
						
						trn_trem_n       <= (others => '0');
						compl_done_internal     <= '1';
						bmd_64_tx_state  <= BMD_64_TX_CPLD_WIT;
					elsif (trn_tdst_dsc_n = '0') then
						trn_tsrc_dsc_n   <= '0';
						bmd_64_tx_state  <= BMD_64_TX_CPLD_WIT;
					else  -- source not ready 
						bmd_64_tx_state  <= BMD_64_TX_CPLD_QW1;
					end if;

				when BMD_64_TX_CPLD_WIT =>
					if (trn_tdst_rdy_n = '0' or trn_tdst_dsc_n = '0') then
						trn_tsof_n       <= '1';
						trn_teof_n       <= '1';
						trn_tsrc_rdy_n   <= '1';
						trn_tsrc_dsc_n   <= '1';
						if ( csr_sel = '1') then
							csr_rd_ack <= '1';
						end if;
						bmd_64_tx_state  <= BMD_64_TX_RST_STATE;
					else
						if ( csr_sel = '1') then
							csr_rd_ack <= '0';
						end if;
						bmd_64_tx_state  <= BMD_64_TX_CPLD_WIT;
					end if;
--				when BMD_64_TX_CPLD_QW1 =>
--					if (trn_tdst_rdy_n = '0' and trn_tdst_dsc_n = '1') then
--						trn_tsof_n       <= '1';
--						trn_teof_n       <= '0';
--						trn_tsrc_rdy_n   <= '0';
--						trn_td           <= ( req_rid_i & 
--											req_tag_i &
--											'0' &
--											lower_addr &
--											rd_data_i);
--
--						trn_trem_n       <= (others => '0');
--						compl_done_internal     <= '1';
--						bmd_64_tx_state  <= BMD_64_TX_CPLD_WIT;
--					elsif (trn_tdst_dsc_n = '0') then
--						trn_tsrc_dsc_n   <= '0';
--						bmd_64_tx_state  <= BMD_64_TX_CPLD_WIT;
--					else  -- source not ready 
--						bmd_64_tx_state  <= BMD_64_TX_CPLD_QW1;
--					end if;
--
--				when BMD_64_TX_CPLD_WIT =>
--					if (trn_tdst_rdy_n = '0' or trn_tdst_dsc_n = '0') then
--						trn_tsof_n       <= '1';
--						trn_teof_n       <= '1';
--						trn_tsrc_rdy_n   <= '1';
--						trn_tsrc_dsc_n   <= '1';
--						bmd_64_tx_state  <= BMD_64_TX_RST_STATE;
--					else
--						bmd_64_tx_state  <= BMD_64_TX_CPLD_WIT;
--					end if;

				when BMD_64_TX_MWR_QW1 =>
					if ( (trn_tdst_rdy_n = '0' and trn_tdst_dsc_n = '1')) then -- Previous TLP has been send             
						trn_tsof_n       <= '1';
						
						-- assert src_rdy
						trn_tsrc_rdy_n   <= '0';
						-- place data on data_bus
						trn_td <= (tmwr_addr(63 downto 2) & "00");
						
						dst_rdy_n <= '0';
							
						if (cur_wr_count = (rmwr_count - 1)) then 
							cur_wr_count <= (others => '0');
							cur_wr_count_eq_zero <= '1';
							if cur_mwr_dw_count = "0000000001" then 
								mwr_done_internal   <= '1'; 
							end if;										 
						else 
							cur_wr_count <= cur_wr_count + 1;
							cur_wr_count_eq_zero <= '0';
						end if;
						
						rd_en <= '1';
						
						bmd_64_tx_state <= BMD_64_TX_MWR_QWNL;

					elsif trn_tdst_dsc_n = '0' then         
						rd_en <= '0';
						trn_tsrc_dsc_n     <= '0';
						bmd_64_tx_state    <= BMD_64_TX_RST_STATE;
					-- TX interface is temporarily unavailable
					else
						trn_tsrc_rdy_n <= '0';
						rd_en <= '0';
						bmd_64_tx_state <= BMD_64_TX_MWR_QW1;
					end if;
					
--					when BMD_64_TX_MWR_LAST =>
--						if ( trn_tdst_rdy_n = '0') then
--							if (cur_wr_count = X"00000000") then
--								bmd_64_tx_state <= BMD_64_TX_MWR_LAST_WIT;
--							else
--								bmd_64_tx_state <= BDM_64_TX_RST_STATE;
--							end if;
							
		
					when BMD_64_TX_MWR_QWNL =>
						if ( trn_tdst_rdy_n = '0') then-- pcie linke is ok
							if ( rd_data_valid = '1' or dst_rdy_n = '1' ) then -- (data ok) & (pcie ok)
								trn_tsrc_rdy_n <= '0';
								data_valid_flag <= '0';
								if (dst_rdy_n = '0') then
									trn_td(63 downto 32) <= rd_data_i;
									trn_td(31 downto 0) <= rd_data_hi_i;
								else
									trn_td(63 downto 32) <= f2h_data_tmp(31 downto 0);
									trn_td(31 downto 0) <= f2h_data_tmp(63 downto 32);
								end if;
								
								trn_trem_n <= X"FF";
								trn_teof_n <= '1';
								rd_en <= '1';
								
								
								if ( cur_mwr_dw_count = "100" ) then
									bmd_64_tx_state <= BMD_64_TX_MWR_LAST;
								else
									bmd_64_tx_state <= BMD_64_TX_MWR_QWNL;
								end if;
									
								
								if (cur_mwr_dw_count = "10") then -- the last QW of TLP
									rd_en <= '0';
									trn_trem_n <= X"00";
									trn_teof_n <= '0';
									if ( cur_wr_count = X"00000000") then -- the last TLP of tansaction
										bmd_64_tx_state <= BMD_64_TX_MWR_LAST_WIT;
									else
										bmd_64_tx_state <= BMD_64_TX_RST_STATE;
									end if;
								else
--									if ( cur_mwr_dw_count > "100") then
										rd_en <= '1';
--									else
--										rd_en <= '0';
--									end if;
									trn_trem_n <= X"FF";
									trn_teof_n <= '1';
									bmd_64_tx_state <= BMD_64_TX_MWR_QWNL;
								end if;
								dst_rdy_n <= '0';
								cur_mwr_dw_count <= cur_mwr_dw_count - 2;
							else --(data unavailable) & (pcie ok)
								trn_tsrc_rdy_n <= '1';
								if ( f2h_fifo_empty = '1') then
									rd_en <= '1';
								else
									rd_en <= '0';
								end if;
								data_valid_flag <= '1';
								bmd_64_tx_state <= BMD_64_TX_MWR_QWNL;
							end if;
						else -- pcie link is unavailable
							if data_valid_flag = '0' then
								trn_tsrc_rdy_n <= '0';
							else
								trn_tsrc_rdy_n <= '1';
							end if;
							
							rd_en <= '1';
							if ( rd_data_valid = '1') then -- (data ok) & (pcie unavailable)
								if (dst_rdy_n = '1') then
									f2h_data_tmp <= f2h_data_tmp;
								else
									f2h_data_tmp <= rd_data_hi_i & rd_data_i;
									dst_rdy_n <= '1';
								end if;
								-- if (data unavailable) & (pcie unavailable), do nothing
							end if;
							bmd_64_tx_state <= BMD_64_TX_MWR_QWNL;
						end if;
						
						
				  when BMD_64_TX_MWR_LAST_WIT =>
					if ( trn_tdst_rdy_n = '0' and trn_tdst_dsc_n = '1') then
						trn_tsrc_rdy_n <= '1';
						mwr_done_internal <= '1';
						trn_teof_n <= '1';
						bmd_64_tx_state <= BMD_64_TX_RST_STATE;
					else
						bmd_64_tx_state <= BMD_64_TX_MWR_LAST_WIT;
					end if;
						
               when BMD_64_TX_MRD_QW1 =>
                  if trn_tdst_rdy_n = '0' and trn_tdst_dsc_n = '1' then
                     trn_tsof_n       <= '1';
                     trn_teof_n       <= '0';
                     trn_tsrc_rdy_n   <= '0';
                     trn_td           <= (tmrd_addr(63 downto 2) & "00" );
                     trn_trem_n       <= x"00";
                              
                     if cur_rd_count = (rmrd_count_sub) then
                        cur_rd_count   <= (others => '0');
                        cur_data_size <= (others => '0');
                        mrd_done       <= '1';
                     else 
                        cur_rd_count <= cur_rd_count + 1;
                        cur_data_size <= cur_data_size + mrd_len_i;
                     end if;
                     bmd_64_tx_state  <= BMD_64_TX_RST_STATE;

                  elsif trn_tdst_dsc_n = '0' then
                     bmd_64_tx_state  <= BMD_64_TX_RST_STATE;
                     trn_tsrc_dsc_n   <= '0';

                  else
                     bmd_64_tx_state  <= BMD_64_TX_MRD_QW1;
                  end if;
               when others => null;
            end case;
         end if;
      end if;
   end process;
end rtl;
