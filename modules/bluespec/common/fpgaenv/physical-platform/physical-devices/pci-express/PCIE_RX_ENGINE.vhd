----------------------------------------------------------------------------------
---- Filename: BMD_64_RX_ENGINE.vhd
---- Wang, Liang(liang.wang@intel.com)
---- Description: Local-Link Receive Unit.
----
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity PCIE_RX_ENGINE is
port(
	clk   : in std_logic;
	rst_n : in std_logic;
	
	init_rst_i : in std_logic;
	
	-- pcie core 8
	trn_rd         : in  std_logic_vector(63 downto 0);
	trn_rrem_n     : in  std_logic_vector(7 downto 0);
	trn_rsof_n     : in  std_logic;
	trn_reof_n     : in  std_logic;
	trn_rsrc_rdy_n : in  std_logic;
	trn_rsrc_dsc_n : in  std_logic;
	trn_rbar_hit_n : in std_logic_vector(6 downto 0);
	trn_rdst_rdy_n : out std_logic;
	
	-- hand shake 10+2
	req_compl_o  : out std_logic;
	compl_done_i : in  std_logic;         
	
	req_tc_o   : out std_logic_vector(2 downto 0);
	req_td_o   : out std_logic;
	req_ep_o   : out std_logic;
	req_attr_o : out std_logic_vector(1 downto 0);
	req_len_o  : out std_logic_vector(9 downto 0);
	req_rid_o  : out std_logic_vector(15 downto 0);
	req_tag_o  : out std_logic_vector(7 downto 0);
	req_be_o   : out std_logic_vector(3 downto 0);
	req_addr_o : out std_logic_vector(31 downto 0); --MEM_RD hand shake with TX
	req_bar_o  : out std_logic;
	
	-- write RAM control 6
	wr_be_o   : out std_logic_vector(3 downto 0);
	wr_data_o : out std_logic_vector(31 downto 0);
	--- added port to support 64bit
	wr_be_hi_o   : out std_logic_vector(3 downto 0);
	wr_data_hi_o : out std_logic_vector( 31 downto 0);
	--- end adding
	wr_en_o   : out std_logic;
	wr_busy_i : in  std_logic;
	wr_select_o : out std_logic;
	wr_addr_o : out std_logic_vector(31 downto 0);
	
	mrd_addr_i : in std_logic_vector (31 downto 0);
	mrd_base_i : in std_logic_vector (31 downto 0);
	
	dma_h2f_data : out std_logic_vector(63 downto 0);
	
	-- CSR ports
	csr_wr_ready		: in std_logic;
	csr_wr_en				  : out std_logic;
	csr_wr_data			 : out std_logic_vector((32 - 1) downto 0);
	csr_wr_index			: out std_logic_vector((8 - 1) downto 0);
	
	reserved_csr_wr_index : out std_logic_vector((8 -1) downto 0);
	reserved_csr_wr_data  : out std_logic_vector((32 - 1) downto 0);
	reserved_csr_wr_en    : out std_logic;		
	-- CSR ports
	
	
	-- BEGIN: for debug use only -----
	wr_data_pre1_o : out std_logic_vector(31 downto 0);
	wr_data_pre2_o : out std_logic_vector(31 downto 0);
	wr_data_sel_o : out std_logic;
	cpld_real_size_o : out std_logic_vector(9 downto 0);
	
	-- END: for debug use only -------
	
	
	cpl_ur_found_o : out std_logic_vector(7 downto 0);
	cpl_ur_tag_o   : out std_logic_vector(7 downto 0);
	cpld_found_o     : out std_logic_vector(31 downto 0);
	cpld_data_size_o : out std_logic_vector(31 downto 0);
	cpld_malformed_o : out std_logic;
	
	wr_data_full : in std_logic;
	wr_data_fen: out std_logic);
			
end PCIE_RX_ENGINE;

architecture rtl of PCIE_RX_ENGINE is

    type bmd_64_rx_state_type is (
      BMD_64_RX_RST,
    	BMD_64_RX_MEM_RD32_QW1,
      BMD_64_RX_MEM_RD32_WT,
      BMD_64_RX_MEM_WR32_QW1,
      BMD_64_RX_MEM_WR32_WT, 
			BMD_64_RX_MEM_WR32_WT_CSR,
		BMD_64_RX_CPL_QW1,
      BMD_64_RX_CPLD_QW1, 
		BMD_64_RX_CPLD_QWN, 
		BMD_64_RX_CPLD_QWNW);
    signal bmd_64_rx_state : bmd_64_rx_state_type;
    
    constant BMD_MEM_RD32_FMT_TYPE : std_logic_vector(6 downto 0) := "0000000";
    constant BMD_MEM_WR32_FMT_TYPE : std_logic_vector(6 downto 0) := "1000000";
    constant BMD_CPL_FMT_TYPE      : std_logic_vector(6 downto 0) := "0001010";
    constant BMD_CPLD_FMT_TYPE     : std_logic_vector(6 downto 0) := "1001010";
    
    -- Local Registers
    signal cpld_found_internal : std_logic_vector(31 downto 0); -- How many CPLD
    signal cpld_data_size_internal : std_logic_vector(31 downto 0); --How many dw received, count using packet head
    signal cpl_ur_found_internal : std_logic_vector(7 downto 0);
--    signal trn_rdst_rdy_n_internal : std_logic;

    signal cpld_real_size : std_logic_vector(9 downto 0);
    signal cpld_tlp_size  : std_logic_vector(9 downto 0);
    signal last_be : std_logic_vector(3 downto 0);
      --    signal wr_addr_cal : std_logic_vector (31 downto 0);
	 signal wr_addr : std_logic_vector (31 downto 0);
    
	 signal wr_eof : std_logic;
	 
	 signal tlp_eof : std_logic;-- indicate whether it's the end of a tlp, only used when the last QW receieved with the fifo unavailable due to it's full
   signal	wr_data_tmp :  std_logic_vector (63 downto 0); -- temporarily store the receieved data, only used when fifo is unavailabe due to it's full.
--	 signal data_tmp_valid : std_logic; -- indicate whether wr_data_tmp is valid, for it's possible the fifo is full along with the pcie is unavailable, so there is no need to store the data so that wr_data_tmp is invalid.
	 
    signal wr_data_pre1    : std_logic_vector ( 31 downto 0);
    signal wr_data_pre2    : std_logic_vector ( 31 downto 0);
    signal wr_data_sel  : std_logic;
	 
	-- BEGIN: for debug use only -----
	signal addr_fifo_full :std_logic;	
	signal wr_addr_fen: std_logic;
	-- END: for debug use only -------
				


begin  -- rtl
    cpld_found_o <= cpld_found_internal;
    cpld_data_size_o <= cpld_data_size_internal;
    cpl_ur_found_o <= cpl_ur_found_internal;
--    trn_rdst_rdy_n <= trn_rdst_rdy_n_internal;
--    wr_addr_cal <= trn_rd(63 downto 32) - mrd_addr_i + mrd_base_i;
    wr_addr_o <= wr_addr ;
    
	 addr_fifo_full <= '0';
	 
	 -- debug use only
	 wr_data_pre1_o <= wr_data_pre1;
	 wr_data_pre2_o <= wr_data_pre2;
	 wr_data_sel_o <= wr_data_sel;
	 cpld_real_size_o <= cpld_real_size;
	 -- debug use only
	 
	 
	process (clk, rst_n )
	begin
		if rst_n = '0' then
			bmd_64_rx_state  <= BMD_64_RX_RST;
			req_compl_o      <= '0';
			req_tc_o         <= (others => '0');
			req_td_o         <= '0';
			req_ep_o         <= '0';
			req_attr_o       <= (others => '0');
			req_len_o        <= (others => '0');
			req_rid_o        <= (others => '0');
			req_tag_o        <= (others => '0');
			req_be_o         <= (others => '0');
			req_addr_o	     <= (others => '0');
			req_bar_o	     <= '1';            
			
			wr_addr        <= (others => '0');
			wr_be_o          <= (others => '0');
			wr_be_hi_o        <= (others => '0');
			wr_data_o        <= (others => '0');
			wr_data_hi_o      <= (others => '0');
			wr_data_pre1         <= (others => '0');
			wr_data_pre2         <= (others => '0');
			wr_en_o          <= '0';
			wr_select_o	     <= '1';
			wr_data_sel       <= '0';
			wr_addr_fen			<= '0';			wr_data_fen			<= '0';
			cpl_ur_found_internal   <= (others => '0');
			cpl_ur_tag_o     <= (others => '0');
			cpld_found_internal     <= (others => '0');
			cpld_data_size_internal <= (others => '0');
			cpld_malformed_o <= '0';
			
			cpld_real_size   <= (others => '0');
			cpld_tlp_size    <= (others => '0');
			last_be	<= "1111";
			wr_data_tmp <= (others => '0');
			wr_eof <='0';
			
			trn_rdst_rdy_n <= '0';
			dma_h2f_data <= (others => '0');
			
			csr_wr_en <= '0';
			csr_wr_index <= (others => '0');
			csr_wr_data <= (others => '0');
			
			reserved_csr_wr_index <= (others => '0');
			reserved_csr_wr_data <= (others => '0');
			reserved_csr_wr_en <= '0';			
			

		elsif rising_edge(clk) then
 
			if init_rst_i = '1' then
				bmd_64_rx_state  <= BMD_64_RX_RST;
				wr_data_fen <= '0';				wr_addr_fen <= '0';
				cpl_ur_found_internal   <= (others => '0');
				cpl_ur_tag_o     <= (others => '0');
				cpld_found_internal     <= (others => '0');
				cpld_data_size_internal <= (others => '0');
				cpld_malformed_o <= '0';
				cpld_real_size   <= (others => '0');
				cpld_tlp_size    <= (others => '0');
				wr_data_tmp <= (others => '0');
				wr_en_o <= '0';
				wr_data_o <= (others => '0');
				wr_data_hi_o      <= (others => '0');
				wr_data_pre1 <= (others => '0');
				wr_data_pre2 <= (others => '0');
				wr_addr <= (others =>'0');
				wr_eof <='0';
				wr_data_sel <= '0';
				dma_h2f_data <= (others => '0');
				csr_wr_en <= '0';
				csr_wr_index <= (others => '0');
				csr_wr_data <= (others => '0');				

				reserved_csr_wr_index <= (others => '0');
				reserved_csr_wr_data <= (others => '0');
				reserved_csr_wr_en <= '0';			
				
			end if;
            
			case bmd_64_rx_state is

				when BMD_64_RX_RST =>
					wr_en_o <= '0';
					reserved_csr_wr_en <= '0';
					wr_data_fen <= '0';
					wr_addr_fen <= '0';

					if trn_rsof_n = '0' and trn_rsrc_rdy_n = '0' then                    
						case trn_rd(62 downto 56) is
							when BMD_MEM_RD32_FMT_TYPE =>
								if trn_rd(41 downto 32) = x"001" then
									bmd_64_rx_state <= BMD_64_RX_MEM_RD32_QW1;
									req_tc_o   <= trn_rd(54 downto 52);
									req_td_o   <= trn_rd(47);
									req_ep_o   <= trn_rd(46);
									req_attr_o <= trn_rd(45 downto 44);
									req_len_o  <= trn_rd(41 downto 32);
									req_rid_o  <= trn_rd(31 downto 16);
									req_tag_o  <= trn_rd(15 downto 08);
									req_be_o   <= trn_rd(03 downto 00);
								else
									bmd_64_rx_state <= BMD_64_RX_RST;
								end if;  
								
							when BMD_MEM_WR32_FMT_TYPE =>
								if trn_rd(41 downto 32) = x"001" then
									bmd_64_rx_state <= BMD_64_RX_MEM_WR32_QW1;
									wr_be_o      <= trn_rd(3 downto 0);
									wr_select_o  <= '0';
								else
									bmd_64_rx_state <= BMD_64_RX_RST;
								end if;
                        
							when BMD_CPL_FMT_TYPE =>
								if trn_rd(15 downto 13) /= "000" then -- ??
									cpl_ur_found_internal <= cpl_ur_found_internal + 1;
									bmd_64_rx_state   <= BMD_64_RX_CPL_QW1;
								else
									bmd_64_rx_state   <= BMD_64_RX_RST;
								end if;
                        
							when BMD_CPLD_FMT_TYPE =>
								cpld_data_size_internal <= cpld_data_size_internal + trn_rd(41 downto 32);
								cpld_tlp_size    <= trn_rd(41 downto 32);
								cpld_found_internal     <= cpld_found_internal  + 1;
								cpld_real_size   <= (others => '0');
								
								wr_be_o <= "1111";
								wr_select_o <= '1';
								bmd_64_rx_state  <= BMD_64_RX_CPLD_QW1;

							when others =>
								bmd_64_rx_state   <= BMD_64_RX_RST;
						end case;
                     
					else
						bmd_64_rx_state   <= BMD_64_RX_RST;
					end if;
                  
				when BMD_64_RX_MEM_RD32_QW1 =>
					if trn_reof_n = '0' and trn_rsrc_rdy_n = '0'  then                     
						req_addr_o            <= trn_rd(63 downto 32);
						req_bar_o		<= trn_rbar_hit_n(0);			 
						req_compl_o       <= '1';
						trn_rdst_rdy_n <= '1';
						
						bmd_64_rx_state   <= BMD_64_RX_MEM_RD32_WT;
					else
						bmd_64_rx_state   <= BMD_64_RX_MEM_RD32_QW1;
					end if;
                  
				when BMD_64_RX_MEM_RD32_WT =>
					if compl_done_i = '1' then
						 bmd_64_rx_state   <= BMD_64_RX_RST;
						 req_compl_o       <= '0';
						 trn_rdst_rdy_n <= '0';
					else 
						 req_compl_o       <= '1';
						 trn_rdst_rdy_n <= '1';
						 bmd_64_rx_state   <= BMD_64_RX_MEM_RD32_WT;
					end if;
                  
--				when BMD_64_RX_MEM_WR32_QW1 =>
--					if trn_reof_n = '0' and trn_rsrc_rdy_n = '0' then
--						 wr_addr           <= trn_rd(63 downto 32);
--						 wr_data_o        <= trn_rd(31 downto 0);
--						 wr_en_o          <= '1';
--
--						 trn_rdst_rdy_n <= '1';
--						 bmd_64_rx_state  <= BMD_64_RX_MEM_WR32_WT;
--					else
--						 bmd_64_rx_state  <= BMD_64_RX_MEM_WR32_QW1;
--					end if;
				
				when BMD_64_RX_MEM_WR32_QW1 =>
					if trn_reof_n = '0' and trn_rsrc_rdy_n = '0' then
						------------------------------------------
						-- CSR Selecting Mechanism
						--
						-- let addr(31 downto 0) <= trn_rd(63 downto 31)
						-- Since all CSR is 32bit width, the last 2bits of addr should always
						-- be 0(addr(1 downto 0) = "00"). Since now there are totally 256 Common
						-- CSRs, so the COMM_CSR_INDEX_WIDTH=8. addr(9 downto 2)
						-- specify the common csr index, addr(10) should be '1' if 
						-- the addr specify a common csr, else it should be '0' to specify reserved csr.
						if ( trn_rd(44) = '1' ) then-- the addr is common CSRs
							csr_wr_index <= trn_rd(41 downto 34);
							csr_wr_data <= trn_rd(31 downto 0);
							trn_rdst_rdy_n <= '1';
							if (csr_wr_ready = '1') then
								csr_wr_en <= '1';
								bmd_64_rx_state <= BMD_64_RX_MEM_WR32_WT;
							else
								csr_wr_en <= '0';
								bmd_64_rx_state <= BMD_64_RX_MEM_WR32_WT_CSR;
							end if;
						else -- the addr is reserved CSRs
							reserved_csr_wr_index <= trn_rd(41 downto 34);
							reserved_csr_wr_data <= trn_rd(31 downto 0);
							reserved_csr_wr_en <= '1';
							trn_rdst_rdy_n <= '0';
							bmd_64_rx_state <= BMD_64_RX_RST;
						end if;
					else
						bmd_64_rx_state <= BMD_64_RX_MEM_WR32_QW1;
					end if;
				
--				when BMD_64_RX_MEM_WR32_WT_RESERVED =>
--					reserved_csr_wr_en <= '0';
--					trn_rdst_rdy_n <= '0';
--					bmd_64_rx_state <= BMD_64_RX_RST;
				
				when BMD_64_RX_MEM_WR32_WT_CSR =>
					if ( csr_wr_ready = '1') then
						csr_wr_en <= '1';
						bmd_64_rx_state <= BMD_64_RX_MEM_WR32_WT;
					else
						csr_wr_en <= '0';
						bmd_64_rx_state <= BMD_64_RX_MEM_WR32_WT_CSR;
					end if;
        
				when BMD_64_RX_MEM_WR32_WT =>
					csr_wr_en <= '0';
					if ( csr_wr_ready = '1') then
						trn_rdst_rdy_n <= '0';
						bmd_64_rx_state <= BMD_64_RX_RST;
					else
						trn_rdst_rdy_n <= '1';
						bmd_64_rx_state <= BMD_64_RX_MEM_WR32_WT;
					end if;	
				
--					wr_en_o <= '0';
--					if wr_busy_i = '0' then
--						 bmd_64_rx_state  <= BMD_64_RX_RST;
--						 trn_rdst_rdy_n <= '0';
--					else
--						 bmd_64_rx_state  <= BMD_64_RX_MEM_WR32_WT;
--						 trn_rdst_rdy_n <= '1';
--					end if;
                     
				when BMD_64_RX_CPL_QW1 =>
					if trn_reof_n = '0' and trn_rsrc_rdy_n = '0'  then
						 cpl_ur_tag_o     <= trn_rd(47 downto 40);
						 bmd_64_rx_state  <= BMD_64_RX_RST;
					else
						 bmd_64_rx_state  <= BMD_64_RX_CPL_QW1;
					end if;
                     
				when BMD_64_RX_CPLD_QW1 =>
					--- CPLD with only 1DW, temporarily unsupported
					if trn_reof_n = '0' and trn_rsrc_rdy_n = '0' then
						
						cpld_malformed_o <= '1';
						bmd_64_rx_state <= BMD_64_RX_RST;
					
					elsif trn_rsrc_rdy_n = '0' then 						
						wr_data_pre1 <= trn_rd(31 downto 0);
						wr_data_sel <= '0';
						
						wr_select_o      <= trn_rbar_hit_n(0);
						
						cpld_real_size   <= cpld_real_size  + 1;
						bmd_64_rx_state  <= BMD_64_RX_CPLD_QWN;
						wr_en_o          <= '0';
						wr_data_fen <= '0';
						wr_addr_fen <= '0';						
						trn_rdst_rdy_n <= '0';					
					else
						bmd_64_rx_state   <= BMD_64_RX_CPLD_QW1;
					end if;
									
							when BMD_64_RX_CPLD_QWN =>
								if ( wr_data_full = '0' ) then -- fifo is ok, retrieve data from pcie
									if ( trn_rsrc_rdy_n = '0' ) then -- pcie link is ok
										if ( trn_reof_n = '0' ) then-- the last QW of the tlp
											if (trn_rrem_n = X"0F") then -- only the first DW is valid
												if (wr_data_sel = '0') then 
													dma_h2f_data(31 downto 0)  <= wr_data_pre1;
													dma_h2f_data(63 downto 32) <= trn_rd(63 downto 32);
												else
													dma_h2f_data(31 downto 0) <= wr_data_pre2;
													dma_h2f_data(63 downto 32) <= trn_rd(63 downto 32);
												end if;
												wr_data_fen <= '1';
												trn_rdst_rdy_n <= '0';
												bmd_64_rx_state  <= BMD_64_RX_RST;
											else --data is QW aligned, this case is just unexpected 
												cpld_malformed_o <= '1';
												bmd_64_rx_state <= BMD_64_RX_RST;
											end if;
										else -- not the last
											cpld_real_size <= cpld_real_size + 2;
											if wr_data_sel = '0'  then
												dma_h2f_data(31 downto 0) <= wr_data_pre1;
												dma_h2f_data(63 downto 32) <= trn_rd(63 downto 32);
												wr_data_pre2 <= trn_rd(31 downto 0);
												wr_data_sel <= '1';
											else
												dma_h2f_data(31 downto 0) <= wr_data_pre2;
												dma_h2f_data(63 downto 32) <= trn_rd(63 downto 32);
												wr_data_pre1 <= trn_rd(31 downto 0);
												wr_data_sel <= '0';
											end if; 			
											wr_data_fen <= '1';
											trn_rdst_rdy_n <= '0';
											bmd_64_rx_state <= BMD_64_RX_CPLD_QWN;
										end if;
									else -- pcie link is unavailable
										wr_data_fen <= '0';
										trn_rdst_rdy_n <= '0';
										bmd_64_rx_state <= BMD_64_RX_CPLD_QWN;
									end if;
								
								else-- fifo is full, stall retrieving data from pcie
									if ( trn_rsrc_rdy_n = '0' ) then -- already retrieve one data
										if ( trn_reof_n = '0' ) then -- end of tlp
											tlp_eof <= '1';
										else
											tlp_eof <= '0';																						
										end if;
										wr_data_tmp <= trn_rd;
										trn_rdst_rdy_n <= '1';
										wr_data_fen <= '0';
										bmd_64_rx_state <= BMD_64_RX_CPLD_QWNW;
									else
										trn_rdst_rdy_n <= '0';
										wr_data_fen <= '0';
										bmd_64_rx_state <= BMD_64_RX_CPLD_QWN;
									end if;
								end if;
								
							when BMD_64_RX_CPLD_QWNW =>
								if ( wr_data_full = '0') then-- fifo is available
									if ( tlp_eof = '1') then-- the last QW of tlp
										if (wr_data_sel = '0') then 
											dma_h2f_data(31 downto 0) <= wr_data_pre1;
											dma_h2f_data(63 downto 32) <= wr_data_tmp(63 downto 32);
										else
											dma_h2f_data(31 downto 0) <= wr_data_pre2;
											dma_h2f_data(63 downto 32) <= wr_data_tmp(63 downto 32);
										end if;
										trn_rdst_rdy_n <= '0';
										wr_data_fen <= '1';
										bmd_64_rx_state <= BMD_64_RX_RST;
									else -- not the last
										cpld_real_size <= cpld_real_size + 2;
										if wr_data_sel = '0'  then
											dma_h2f_data(31 downto 0) <= wr_data_pre1;
											dma_h2f_data(63 downto 32) <= wr_data_tmp(63 downto 32);
											wr_data_pre2 <= wr_data_tmp(31 downto 0);
											wr_data_sel <= '1';
										else
											dma_h2f_data(31 downto 0) <= wr_data_pre2;
											dma_h2f_data(63 downto 32) <= wr_data_tmp(63 downto 32);
											wr_data_pre1 <= wr_data_tmp(31 downto 0);
											wr_data_sel <= '0';
										end if; 			
										wr_data_fen <= '1';
										trn_rdst_rdy_n <= '0';
										bmd_64_rx_state <= BMD_64_RX_CPLD_QWN;									
									end if;
								else -- fifo is still unavailable
									trn_rdst_rdy_n <= '1';
									wr_data_fen <= '0';
									bmd_64_rx_state <= BMD_64_RX_CPLD_QWNW;
								end if;
              
            end case;
        end if;
    end process;
end rtl;

