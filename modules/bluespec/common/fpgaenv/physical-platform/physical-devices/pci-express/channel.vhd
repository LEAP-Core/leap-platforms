----------------------------------------------------------------------------------
---- Filename: channel.vhd
---- Wang, Liang(liang.wang@intel.com), Wang, Tao Z (tao.z.wang@intel.com)
---- Description: a wrapper for subtle modules of PCIe channel. 
----
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity channel is
	port (
	clk   : in std_logic;
	rst_n : in std_logic;
	
	
	-- LocalLink Tx
	
	trn_td     : out std_logic_vector(63 downto 0);
	trn_trem_n : out std_logic_vector(7 downto 0);
	trn_tsof_n     : out std_logic;
	trn_teof_n     : out std_logic;
	trn_tsrc_dsc_n : out std_logic;
	trn_tsrc_rdy_n : out std_logic;
	trn_tdst_dsc_n : in  std_logic;
	trn_tdst_rdy_n : in  std_logic;
	
	-- LocalLink Rx
	
	trn_rd         : in  std_logic_vector(63 downto 0);
	trn_rrem_n     : in  std_logic_vector(7 downto 0);
	trn_rsof_n     : in  std_logic;
	trn_reof_n     : in  std_logic;
	trn_rsrc_rdy_n : in  std_logic;
	trn_rsrc_dsc_n : in  std_logic;
	trn_rbar_hit_n : in std_logic_vector(6 downto 0);
	trn_rdst_rdy_n : out std_logic;
	
	cfg_interrupt_n      : out std_logic;
	cfg_interrupt_rdy_n  : in  std_logic;
	cfg_interrupt_assert_n: out std_logic;
	cfg_completer_id     : in  std_logic_vector(15 downto 0);
	cfg_ext_tag_en       : in  std_logic;
	cfg_max_rd_req_size  : in  std_logic_vector(2 downto 0);
	cfg_max_payload_size : in  std_logic_vector(2 downto 0);
	cfg_bus_mstr_enable  : in  std_logic;
	
	-- regular CSR signals

	csr_out_rd_ready		: out std_logic;
	csr_out_rd_done		: out std_logic;
	csr_out_rd_data 		: out std_logic_vector(31 downto 0);
	csr_out_wr_ready		: out std_logic;
	csr_in_rd_en         : in std_logic;
	csr_in_rd_ack			: in std_logic;
	csr_in_rd_index		: in std_logic_vector(7 downto 0);
	csr_in_wr_en			: in std_logic;
	csr_in_wr_data			: in std_logic_vector(31 downto 0);
	csr_in_wr_index		: in std_logic_vector(7 downto 0);
	
	-- system CSR signals 
	
	csr_out_h2f_reg0			: out std_logic_vector(31 downto 0);
	csr_in_f2h_reg0			: in std_logic_vector(31 downto 0);
	csr_in_f2h_reg0_wr_en	: in std_logic;	
	
	-- interrupt signals

	int_out_ready				: out std_logic;
	int_in_en					: in std_logic
);
end channel;

architecture structural of channel is

-------------------------------------------------------------
-- chipscope support
-- component ila
--	 port
--	 (
--		 control     : in    std_logic_vector(35 downto 0);
--		 clk         : in    std_logic;
--		 data        : in    std_logic_vector(499 downto 0);
--		 trig0       : in    std_logic_vector(9 downto 0)
--	 );
-- end component;
-- component icon
--	 port
--	 (
--		 control0    :   out std_logic_vector(35 downto 0)
--	 );
-- end component;
-- end chipscope support
------------------------------------------------------------

--component SPL_CSR_TESTER is
--port(
--   clk                  : in std_logic;
--	rst_n                : in std_logic;
--	-- from CSR_CONTROLLER
--	csr_out_rd_ready		: in std_logic; 
--	csr_out_rd_done			: in std_logic;
--	csr_in_rd_en				  : out std_logic;
--	csr_in_rd_ack				 : out std_logic;
--	csr_out_rd_data			: in std_logic_vector((32 - 1) downto 0);
--	csr_in_rd_index			: out std_logic_vector((8 - 1) downto 0);
--	csr_out_wr_ready		: in std_logic;
--	csr_in_wr_en				  : out std_logic;
--	csr_in_wr_data			 : out std_logic_vector((32 - 1) downto 0);
--	csr_in_wr_index			: out std_logic_vector((8 - 1) downto 0);
--	--------------system CSR SIGNAL-------------------
--	csr_in_f2h_reg0_wr_en : out std_logic;
--	csr_out_h2f_reg0			: in std_logic_vector((32 - 1) downto 0);
--	csr_in_f2h_reg0				: out std_logic_vector((32 - 1) downto 0)	;
--	-- for test
--	csr_test_start_i : in std_logic_vector(31 downto 0);
--	csr_test_data_in_i  : in std_logic_vector(31 downto 0);
--	csr_test_index_i : in std_logic_vector(31 downto 0);
--	csr_test_data_out_o : out std_logic_vector(31 downto 0)
--);
--end component SPL_CSR_TESTER;

--component SPL_DMA_TESTER is
--	port (
--	clk          : in std_logic;
--	rst_n        : in std_logic;
--	init_rst		 : in std_logic;
--
--  --  Read Port
--
----	rd_addr_i    : in std_logic_vector(31 downto 0); -- no use
----	rd_be_i      : in std_logic_vector(3 downto 0);  -- no use
----	rd_be_hi_i   : in std_logic_vector(3 downto 0);  -- no use
--	rd_data_o    : out std_logic_vector(31 downto 0);
--	rd_data_hi_o : out std_logic_vector(31 downto 0);
--	
--	f2h_len		: in std_logic_vector(31 downto 0);
--	f2h_fifo_wen : out std_logic;
--	f2h_fifo_full: in std_logic;
--	f2h_start		: in std_logic;
--	f2h_done     : std_logic;
--
--  --  Write Port
--		
----	wr_addr_i    : in std_logic_vector(31 downto 0);  -- no use
----	wr_be_i      : in std_logic_vector(3 downto 0);   -- no use
----	wr_be_hi_i   : in std_logic_vector(3 downto 0);   -- no use
--	wr_data_i    : in std_logic_vector(31 downto 0);
--	wr_data_hi_i : in std_logic_vector(31 downto 0);
--	wr_en_i      : in std_logic;
--	
--	h2f_len    : in std_logic_vector(31 downto 0);
--	h2f_fifo_ren : out std_logic;
--	h2f_fifo_empty : in std_logic;
--	h2f_fifo_valid : in std_logic;
--	h2f_start : in std_logic;
--	h2f_done  : in std_logic;
--	
--	-- debug use only
--	h2f_addr_o : out std_logic_vector ( 10 downto 0);
--	h2f_qword_left_o : out std_logic_vector ( 31 downto 0);
--	h2f_ram_wen_o : out std_logic;
--	-- debug use only	
--	
--	wr_busy_o    : out std_logic);
--end component SPL_DMA_TESTER;

component INTR_CONTROLLER
port (
	clk   : in std_logic;
	rst_n : in std_logic;
	
	int_out_ready : out std_logic;
	int_in_en			: in std_logic;
	
	intr_host_ack : in std_logic;
	
	cfg_interrupt_rdy_n : in  std_logic;
	cfg_interrupt_assert_n: out std_logic;
	cfg_interrupt_n     : out std_logic);
end component INTR_CONTROLLER;

component CSR_CONTROLLER 
	port ( 
	clk   : in std_logic;
	rst_n : in std_logic;
	
	-- csr ports for PCIe TX/RX Engine
	pcie_csr_out_rd_ready		: out std_logic; 
	pcie_csr_out_rd_done			: out std_logic;
	pcie_csr_in_rd_en				  : in std_logic;
	pcie_csr_in_rd_ack				 : in std_logic;
	pcie_csr_out_rd_data			: out std_logic_vector((32 - 1) downto 0);
	pcie_csr_in_rd_index			: in std_logic_vector((8 - 1) downto 0);
	pcie_csr_out_wr_ready		: out std_logic;
	pcie_csr_in_wr_en				  : in std_logic;
	pcie_csr_in_wr_data			 : in std_logic_vector((32 - 1) downto 0);
	pcie_csr_in_wr_index			: in std_logic_vector((8 - 1) downto 0);
	
	pcie_csr_in_h2f_reg0_wr_en: in std_logic;
	pcie_csr_in_h2f_reg0      : in std_logic_vector((32 - 1) downto 0);
	pcie_csr_out_f2h_reg0			: out std_logic_vector((32 - 1) downto 0);
	
	-- csr ports for hardware channel application use	
	csr_out_rd_ready		: out std_logic; 
	csr_out_rd_done			: out std_logic;
	csr_in_rd_en				  : in std_logic;
	csr_in_rd_ack				 : in std_logic;
	csr_out_rd_data			: out std_logic_vector((32 - 1) downto 0);
	csr_in_rd_index			: in std_logic_vector((8 - 1) downto 0);
	csr_out_wr_ready		: out std_logic;
	csr_in_wr_en				  : in std_logic;
	csr_in_wr_data			 : in std_logic_vector((32 - 1) downto 0);
	csr_in_wr_index			: in std_logic_vector((8 - 1) downto 0);


	--------------system CSR SIGNAL-------------------
	csr_in_f2h_reg0_wr_en : in std_logic;
	csr_out_h2f_reg0			: out std_logic_vector((32 - 1) downto 0);
	csr_in_f2h_reg0				: in std_logic_vector((32 - 1) downto 0));
end component CSR_CONTROLLER;

component PCIE_BAR0 
	port (
	clk   : in std_logic;
	rst_n : in std_logic;
	
	------------------------------------------------------------
	-- Misc. control ports
	------------------------------------------------------------
	cfg_max_rd_req_size  : in std_logic_vector(2 downto 0);
	cfg_max_payload_size : in std_logic_vector(2 downto 0);
	
	------------------------------------------------------------
	-- Read Port
	------------------------------------------------------------
	rd_a_i    : in  std_logic_vector(7 downto 0);
--	rd_be_i   : in  std_logic_vector(3 downto 0);
	rd_d_o : out std_logic_vector(31 downto 0);
	------------------------------------------------------------
	-- Write Port
	------------------------------------------------------------
--	wr_be_i   : in  std_logic_vector(3 downto 0);
	wr_d_i : in  std_logic_vector(31 downto 0);
	wr_en_i   : in  std_logic;
--	wr_busy_o : out std_logic;
	wr_a_i    : in  std_logic_vector(7 downto 0);
	
	-----------------------------------------------------------
	-- DMA Misc Control
	-----------------------------------------------------------
	init_rst_o : out std_logic;
	
	-----------------------------------------------------------
	-- DMA read Control 6 out
	-----------------------------------------------------------
	mrd_start_o : out std_logic;
	mrd_done_o  : out std_logic;
	mrd_addr_o  : out std_logic_vector(31 downto 0);
	mrd_addr_hi_o 			: out std_logic_vector(31 downto 0);
	mrd_len_o   : out std_logic_vector(31 downto 0);
	mrd_count_o : out std_logic_vector(31 downto 0);
	mrd_base_o  : out std_logic_vector(31 downto 0);
	mrd_suspend_o : out std_logic;
	mrd_cur_count_i : in std_logic_vector(15 downto 0);
	mrd_cur_data_size_i : in std_logic_vector (31 downto 0);
	
	-----------------------------------------------------------
	-- DMA Write Control 5 out 1 in
	-----------------------------------------------------------
	mwr_start_o : out std_logic;
	mwr_done_i  : in  std_logic;
	mwr_addr_o  : out std_logic_vector(31 downto 0);
	mwr_addr_hi_o 			: out std_logic_vector(31 downto 0);
	mwr_len_o   : out std_logic_vector(31 downto 0);
	mwr_count_o : out std_logic_vector(31 downto 0);
	mwr_base_o  : out std_logic_vector(31 downto 0);
	
	pcie_csr_in_h2f_reg0_wr_en: out std_logic;
	pcie_csr_in_h2f_reg0      : out std_logic_vector((32 - 1) downto 0);	
	pcie_csr_out_f2h_reg0     : in std_logic_vector((32 - 1) downto 0);	
	
	intr_host_ack : out std_logic;
	intr_host_en : out std_logic;
	
	-----------------------------------------------------------
	-- DMA Read Status 5
	-----------------------------------------------------------	
	cpl_ur_found_i : in std_logic_vector(7 downto 0);
	cpl_ur_tag_i   : in std_logic_vector(7 downto 0);
	cpld_found_i     : in std_logic_vector(31 downto 0);
	cpld_data_size_i : in std_logic_vector(31 downto 0);
	cpld_malformed_i : in std_logic;
	csr_test_start_o : out std_logic_vector(31 downto 0);
	csr_test_data_in_o  : out std_logic_vector(31 downto 0);
	csr_test_index_o    : out std_logic_vector(31 downto 0);
	csr_test_data_out_i : in std_logic_vector(31 downto 0));
end component PCIE_BAR0;

component PCIE_RX_ENGINE 
	port(
	clk   : in std_logic;
	rst_n : in std_logic;
	
	-- From PCIe core 8
	
	trn_rd         : in  std_logic_vector(63 downto 0);
	trn_rrem_n     : in  std_logic_vector(7 downto 0);
	trn_rsof_n     : in  std_logic;
	trn_reof_n     : in  std_logic;
	trn_rsrc_rdy_n : in  std_logic;
	trn_rsrc_dsc_n : in  std_logic;
	trn_rbar_hit_n	: in std_logic_vector(6 downto 0);
	trn_rdst_rdy_n : out std_logic;
	
	
	init_rst_i : in std_logic;
	
	
	-- Hand shake with TX 2 Control 10 out info
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
	req_addr_o : out std_logic_vector(31 downto 0);
	req_bar_o  : out std_logic;
	
	-- BEGIN: for debug use only -----
	wr_data_pre1_o : out std_logic_vector(31 downto 0);
	wr_data_pre2_o : out std_logic_vector(31 downto 0);
	wr_data_sel_o : out std_logic;
	cpld_real_size_o : out std_logic_vector(9 downto 0);
	-- END: for debug use only -------	

	-- CSR ports
	csr_wr_ready		: in std_logic;
	csr_wr_en				  : out std_logic;
	csr_wr_data			 : out std_logic_vector((32 - 1) downto 0);
	csr_wr_index			: out std_logic_vector((8 - 1) downto 0);
	reserved_csr_wr_index : out std_logic_vector((8 -1) downto 0);
	reserved_csr_wr_data  : out std_logic_vector((32 - 1) downto 0);
	reserved_csr_wr_en    : out std_logic;		
	-- CSR ports	
	
	-- Write RAM control 1 select + 4 out 1 in
	wr_addr_o : out std_logic_vector(31 downto 0);
	wr_be_o   : out std_logic_vector(3 downto 0);
	wr_data_o : out std_logic_vector(31 downto 0);
	--- added port to support 64bit
	wr_data_hi_o : out std_logic_vector( 31 downto 0);
	wr_be_hi_o   : out std_logic_vector(3 downto 0);
	--- end adding
	wr_en_o   : out std_logic;
	wr_busy_i : in  std_logic;
	wr_select_o : out std_logic;
	
	-- fifo control
	wr_data_full : in std_logic;
	wr_data_fen: out std_logic;
	dma_h2f_data : out std_logic_vector(63 downto 0);
	
	-- DMA read control determine the write address
	mrd_addr_i : in std_logic_vector (31 downto 0);
	mrd_base_i : in std_logic_vector (31 downto 0);
	
	-- DMA read Status
	cpl_ur_found_o : out std_logic_vector(7 downto 0);
	cpl_ur_tag_o   : out std_logic_vector(7 downto 0);
	cpld_found_o     : out std_logic_vector(31 downto 0);
	cpld_data_size_o : out std_logic_vector(31 downto 0);
	cpld_malformed_o : out std_logic);
end component PCIE_RX_ENGINE;
    
component PCIE_TX_ENGINE 
	port ( 
	clk   : in std_logic;
	rst_n : in std_logic;
	
	-- to pcie core 8 tx
	trn_td         : out std_logic_vector(63 downto 0);
	trn_trem_n     : out std_logic_vector(7 downto 0);
	trn_tsof_n     : out std_logic;
	trn_teof_n     : out std_logic;
	trn_tsrc_rdy_n : out std_logic;
	trn_tsrc_dsc_n : out std_logic;
	trn_tdst_rdy_n : in  std_logic;
	trn_tdst_dsc_n : in  std_logic;
	
	-- Handshake with RX 2 control 10 in
	req_compl_i  : in  std_logic;
	compl_done_o : out std_logic;
	
	req_tc_i   : in std_logic_vector(2 downto 0);
	req_td_i   : in std_logic;
	req_ep_i   : in std_logic;
	req_attr_i : in std_logic_vector(1 downto 0);
	req_len_i  : in std_logic_vector(9 downto 0);
	req_rid_i  : in std_logic_vector(15 downto 0);
	req_tag_i  : in std_logic_vector(7 downto 0);
	req_be_i   : in std_logic_vector(3 downto 0);
	req_addr_i : in std_logic_vector(31 downto 0);
	req_bar_i : in std_logic;
	
	-- RAM read control 3+1 select
	rd_addr_o : out std_logic_vector(31 downto 0);
	rd_be_o   : out std_logic_vector(3 downto 0);
	rd_data_i : in  std_logic_vector(31 downto 0);
	--- added port to support 64bit
	rd_data_hi_i : in std_logic_vector( 31 downto 0);
	rd_be_hi_o   : out std_logic_vector(3 downto 0);
	--- end adding
	rd_select_o : out std_logic;    
	
	init_rst_i : in std_logic;
	
	--fifo control
	f2h_fifo_empty    : in std_logic;
	rd_data_valid			: in std_logic;
	f2h_fifo_ren			: out std_logic;

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
	
	-- for debug use only
	f2h_data_tmp_o : out std_logic_vector(63 downto 0);
	dst_rdy_n_o : out std_logic;
	cur_wr_count_o	 : out std_logic_vector(15 downto 0);
	cur_mwr_dw_count_o : out std_logic_vector(9 downto 0);	
	rd_en_o : out std_logic;
	-- for debug use only
	
	-----------------------------------------------------------
	-- DMA write Control 6 
	-----------------------------------------------------------
	mwr_start_i : in  std_logic;
	mwr_len_i   : in  std_logic_vector(31 downto 0);
	mwr_lbe_i   : in  std_logic_vector(3 downto 0); --undefined
	mwr_fbe_i   : in  std_logic_vector(3 downto 0); --undefined
	mwr_addr_i  : in  std_logic_vector(31 downto 0);
	mwr_addr_hi_i: in std_logic_vector(31 downto 0);
	mwr_base_i  : in  std_logic_vector(31 downto 0);
	mwr_count_i : in  std_logic_vector(31 downto 0);
	mwr_done_o  : out std_logic;
	
	-----------------------------------------------------------
	-- DMA Read Control 6 
	-----------------------------------------------------------
	
	mrd_start_i : in std_logic;
	mrd_len_i   : in std_logic_vector(31 downto 0);
	mrd_lbe_i   : in std_logic_vector(3 downto 0); -- undefined
	mrd_fbe_i   : in std_logic_vector(3 downto 0); -- undefined
	mrd_addr_i  : in std_logic_vector(31 downto 0);
	mrd_addr_hi_i: in std_logic_vector(31 downto 0);
	mrd_base_i  : in std_logic_vector(31 downto 0);
	mrd_count_i : in std_logic_vector(31 downto 0);
	mrd_done_i  : in std_logic;
	mrd_suspend_i : in std_logic;
	mrd_cur_count_o : out std_logic_vector(15 downto 0);
	mrd_cur_data_size_o : out std_logic_vector (31 downto 0);
--	cfg_interrupt_n_o     : out std_logic;
--	cfg_interrupt_rdy_n_i : in  std_logic;
--	cfg_interrupt_assert_n: out std_logic;
	completer_id_i        : in std_logic_vector(15 downto 0);
	cfg_ext_tag_en_i      : in std_logic;
	cfg_bus_mstr_enable_i : in std_logic);
end component PCIE_TX_ENGINE;

component h2f_data_fifo
	port (
	din: IN std_logic_VECTOR(63 downto 0);
	rd_clk: IN std_logic;
	rd_en: IN std_logic;
	rst: IN std_logic;
	wr_clk: IN std_logic;
	wr_en: IN std_logic;
	dout: OUT std_logic_VECTOR(63 downto 0);
	empty: OUT std_logic;
	valid: OUT std_logic;
	almost_full: OUT std_logic;
	full: OUT std_logic);
end component h2f_data_fifo;

component f2h_data_fifo
	port (
	din: IN std_logic_VECTOR(63 downto 0);
	rd_clk: IN std_logic;
	rd_en: IN std_logic;
	rst: IN std_logic;
	wr_clk: IN std_logic;
	wr_en: IN std_logic;
	dout: OUT std_logic_VECTOR(63 downto 0);
	valid: OUT std_logic;
	empty: OUT std_logic;
	almost_full: OUT std_logic;
	full: OUT std_logic);
end component;
    
-- Local wires
signal rd_data_bmd : std_logic_vector(31 downto 0);
signal rd_data_pio : std_logic_vector(31 downto 0);
signal rd_data : std_logic_vector(31 downto 0);
signal rd_data_hi : std_logic_vector(31 downto 0);
signal rd_addr : std_logic_vector(31 downto 0);
signal rd_be	: std_logic_vector(3 downto 0);
signal rd_be_hi : std_logic_vector(3 downto 0);
signal rd_select : std_logic;


signal wr_busy_bmd : std_logic;
signal wr_busy_pio : std_logic;
signal wr_busy     : std_logic;
signal wr_data	    : std_logic_vector(31 downto 0);
signal wr_data_hi   : std_logic_vector(31 downto 0);
signal wr_addr     : std_logic_vector(31 downto 0);
signal wr_be	    : std_logic_vector(3 downto 0);
signal wr_be_hi  : std_logic_vector(3 downto 0);
signal wr_en	    : std_logic;
signal wr_en_bmd   : std_logic;
signal wr_en_pio   : std_logic;
signal wr_select   : std_logic;

signal req_compl  : std_logic;
signal compl_done : std_logic;

signal req_tc   : std_logic_vector(2 downto 0);
signal req_td   : std_logic;
signal req_ep   : std_logic;
signal req_attr : std_logic_vector(1 downto 0);
signal req_len  : std_logic_vector(9 downto 0);
signal req_rid  : std_logic_vector(15 downto 0);
signal req_tag  : std_logic_vector(7 downto 0);
signal req_addr : std_logic_vector(31 downto 0);
signal req_bar	 : std_logic;
signal req_be	 : std_logic_vector (3 downto 0);

signal init_rst : std_logic;

signal mwr_start : std_logic;
signal mwr_done  : std_logic;
signal mwr_len   : std_logic_vector(31 downto 0);
signal mwr_addr  : std_logic_vector(31 downto 0);
signal mwr_addr_hi: std_logic_vector(31 downto 0);
signal mwr_count : std_logic_vector(31 downto 0);
signal mwr_base  : std_logic_vector(31 downto 0);

signal mrd_start : std_logic;
signal mrd_done  : std_logic;
signal mrd_len   : std_logic_vector(31 downto 0);
signal mrd_addr  : std_logic_vector(31 downto 0);
signal mrd_addr_hi: std_logic_vector(31 downto 0);
signal mrd_count : std_logic_vector(31 downto 0);
signal mrd_base  : std_logic_vector(31 downto 0);
signal mrd_suspend: std_logic;
signal mrd_cur_count: std_logic_vector(15 downto 0);
signal mrd_cur_data_size : std_logic_vector (31 downto 0);
signal cpl_ur_found : std_logic_vector(7 downto 0);
signal cpl_ur_tag   : std_logic_vector(7 downto 0);
signal cpld_found     : std_logic_vector(31 downto 0);
signal cpld_size      : std_logic_vector(31 downto 0);
signal cpld_malformed : std_logic;

signal clk_d2	: std_logic;
signal clk_cnt : std_logic_vector(3 downto 0);
signal clk_fifo : std_logic;

signal reserved_csr_wr_index_c : std_logic_vector(7 downto 0);
signal reserved_csr_wr_data_c  : std_logic_vector(31 downto 0);
signal reserved_csr_wr_en_c    : std_logic;
signal reserved_csr_rd_index_c : std_logic_vector(7 downto 0);
signal reserved_csr_rd_data_c   : std_logic_vector(31 downto 0);
signal req_csr_selector_c      : std_logic;

-- wires for fifo
signal wr_data_fen  : std_logic;
signal wr_data_full : std_logic;
signal empty_data_out        : std_logic;
signal rd_data_valid			: std_logic;
signal rd_data_en 				: std_logic;
signal f2h_fifo_dout : std_logic_vector(63 downto 0);
signal f2h_fifo_din : std_logic_vector(63 downto 0);
signal f2h_fifo_wen :  std_logic;
signal f2h_fifo_ren : std_logic;
signal f2h_fifo_full:  std_logic;
signal f2h_fifo_empty: std_logic;
signal f2h_start		:  std_logic;

signal h2f_fifo_din : std_logic_vector(63 downto 0);
signal h2f_fifo_dout : std_logic_vector(63 downto 0);
signal h2f_fifo_ren : std_logic;
signal h2f_fifo_empty : std_logic;
signal h2f_fifo_valid : std_logic;
signal h2f_start :std_logic;
signal fifo_rst_p : std_logic;

signal dma_h2f_data : std_logic_vector(63 downto 0);

-- wires for channel's ports
signal trn_td_c 				: std_logic_vector (63 downto 0);
signal trn_trem_n_c 		: std_logic_vector(7 downto 0);
signal trn_tsof_n_c 		: std_logic;
signal trn_teof_n_c 		: std_logic;
signal trn_tsrc_dsc_n_c : std_logic;
signal trn_tsrc_rdy_n_c : std_logic;
signal trn_tdst_dsc_n_c : std_logic;
signal trn_tdst_rdy_n_c : std_logic;

-- LocalLink Rx

signal trn_rd_c         : std_logic_vector(63 downto 0);
signal trn_rrem_n_c     : std_logic_vector(7 downto 0);
signal trn_rsof_n_c     : std_logic;
signal trn_reof_n_c     : std_logic;
signal trn_rsrc_rdy_n_c : std_logic;
signal trn_rsrc_dsc_n_c : std_logic;
signal trn_rbar_hit_n_c : std_logic_vector(6 downto 0);
signal trn_rdst_rdy_n_c : std_logic;


signal cfg_completer_id_c     	: std_logic_vector(15 downto 0);
signal cfg_ext_tag_en_c       	: std_logic;
signal cfg_max_rd_req_size_c  	: std_logic_vector(2 downto 0);
signal cfg_max_payload_size_c 	: std_logic_vector(2 downto 0);
signal cfg_bus_mstr_enable_c  	: std_logic;

-- Interrupt
signal intr_host_ack_c : std_logic;
signal cfg_interrupt_n_c      	: std_logic;
signal cfg_interrupt_rdy_n_c  	: std_logic;
signal cfg_interrupt_assert_n_c	: std_logic;
signal int_ready_c : std_logic;
signal int_en_c : std_logic;

-- for debug use only
signal f2h_data_tmp : std_logic_vector(63 downto 0);
signal dst_rdy_n : std_logic;
signal cur_wr_count : std_logic_vector(15 downto 0);
signal cur_mwr_dw_count : std_logic_vector(9 downto 0);
signal wr_data_pre1: std_logic_vector(31 downto 0);
signal wr_data_pre2: std_logic_vector(31 downto 0);
signal wr_data_sel : std_logic;
signal cpld_real_size : std_logic_vector(9 downto 0);
signal h2f_addr	: std_logic_vector(10 downto 0);
signal h2f_qword_left: std_logic_vector(31 downto 0);
signal h2f_ram_wen : std_logic;
signal rd_en : std_logic;
-- for debug use only

----------------------------------------------------------
-- chipscope support
signal control    : std_logic_vector(35 downto 0);
signal data       : std_logic_vector(499 downto 0);
signal trig0      : std_logic_vector(9 downto 0);
-- end chipscope support
-----------------------------------------------------------
-----------------csr_test----------------------------------
--signal	csr_out_rd_ready_r :std_logic;
--signal	csr_out_rd_done_r  :std_logic;
--signal	csr_in_rd_en_r     :std_logic;
--signal	csr_in_rd_ack_r    :std_logic;
--signal	csr_out_rd_data_r  :std_logic_vector(31 downto 0);
--signal	csr_in_rd_index_r  :std_logic_vector(7  downto 0);
--signal	csr_out_wr_ready_r :std_logic;
--signal	csr_in_wr_en_r     :std_logic;
--signal	csr_in_wr_data_r   :std_logic_vector(31 downto 0);
--signal	csr_in_wr_index_r  :std_logic_vector(7  downto 0);
--	       
--signal   csr_in_f2h_reg0_wr_en_r:std_logic;
--signal   csr_out_h2f_reg0_r :std_logic_vector(31 downto 0);
--signal   csr_in_f2h_reg0_r	 :std_logic_vector(31 downto 0);
signal   csr_test_start_i_r :std_logic_vector(31 downto 0);
signal	csr_test_data_in_i_r :std_logic_vector(31 downto 0);                
signal	csr_test_index_i_r   :std_logic_vector(31 downto 0);
signal	csr_test_data_out_o_r:std_logic_vector(31 downto 0);
-----------------------------------------------------------


signal	pcie_csr_rd_ready_c :std_logic;
signal	pcie_csr_rd_done_c  :std_logic;
signal	pcie_csr_rd_en_c     :std_logic;
signal	pcie_csr_rd_ack_c    :std_logic;
signal	pcie_csr_rd_data_c  :std_logic_vector(31 downto 0);
signal	pcie_csr_rd_index_c  :std_logic_vector(7  downto 0);
signal	pcie_csr_wr_ready_c :std_logic;
signal	pcie_csr_wr_en_c     :std_logic;
signal	pcie_csr_wr_data_c   :std_logic_vector(31 downto 0);
signal	pcie_csr_wr_index_c  :std_logic_vector(7  downto 0);
signal	pcie_csr_h2f_reg0_wr_en_c: std_logic;
signal	pcie_csr_h2f_reg0_c      : std_logic_vector((32 - 1) downto 0);
signal	pcie_csr_f2h_reg0_c			 : std_logic_vector((32 - 1) downto 0);

signal	csr_rd_ready_c :std_logic;
signal	csr_rd_done_c  :std_logic;
signal	csr_rd_en_c     :std_logic;
signal	csr_rd_ack_c    :std_logic;
signal	csr_rd_data_c  :std_logic_vector(31 downto 0);
signal	csr_rd_index_c  :std_logic_vector(7  downto 0);
signal	csr_wr_ready_c :std_logic;
signal	csr_wr_en_c     :std_logic;
signal	csr_wr_data_c   :std_logic_vector(31 downto 0);
signal	csr_wr_index_c  :std_logic_vector(7  downto 0);
signal   csr_f2h_reg0_wr_en_c:std_logic;
signal   csr_h2f_reg0_c :std_logic_vector(31 downto 0);
signal   csr_f2h_reg0_c	 :std_logic_vector(31 downto 0);


begin  -- structural


-- chipscope support
--   i_ila : ila
--     port map
--     (
--       control   => control,
--       clk       => clk,
--       data      => data,
--       trig0     => trig0
--     );
--   i_icon : icon
--     port map
--     (
--       control0    => control
--     );		
--		
--	trig0(0) <= mwr_start;
--	trig0(1) <= mrd_start;
--	trig0(2) <= wr_select;
--	trig0(3) <= pcie_csr_rd_en_c;
--	trig0(4) <= req_compl;
--	trig0(5) <= pcie_csr_wr_en_c;
--	trig0(6) <= csr_rd_en_c;
--	trig0(7) <= csr_wr_en_c;
--	 
--	data(63 downto 0) <= trn_td_c;
--	data(127 downto 64) <= trn_rd_c;
--	data(159 downto 128) <= pcie_csr_rd_data_c;
--	data(191 downto 160) <= pcie_csr_wr_data_c;
--	data(223 downto 192) <= csr_rd_data_c;
--	data(255 downto 224) <= csr_wr_data_c;
--	data(287 downto 256) <= csr_h2f_reg0_c;
--	data(319 downto 288) <= reserved_csr_rd_data_c;
--	data(351 downto 320) <= reserved_csr_wr_data_c;
--	data(383 downto 352) <= csr_f2h_reg0_c;
--	
--	data(406 downto 400) <= rd_addr(8 downto 2);
--	data(414 downto 407) <= pcie_csr_rd_index_c;
--	data(422 downto 415) <= pcie_csr_wr_index_c;
--	data(430 downto 423) <= csr_rd_index_c;
--	data(438 downto 431) <= csr_wr_index_c;
--	data(446 downto 439) <= reserved_csr_rd_index_c;
--	data(454 downto 447) <= reserved_csr_wr_index_c;
--	
--	data(499) <= pcie_csr_rd_ready_c;
--	data(498) <= pcie_csr_rd_done_c;						
--	data(496) <= pcie_csr_rd_ack_c;		
--	data(495) <= pcie_csr_wr_ready_c;			
--	data(494) <= trn_tsrc_rdy_n_c;
--	data(493) <= trn_tdst_rdy_n_c;
--	data(492) <= trn_tsof_n_c;
--	data(491) <= trn_teof_n_c;
--	data(490) <= csr_rd_ready_c;
--	data(489) <= csr_rd_done_c;						
--	data(488) <= csr_rd_ack_c;		
--	data(487) <= csr_wr_ready_c;
-- end chipscope support



trn_td     <= trn_td_c;
trn_trem_n <= trn_trem_n_c;
trn_tsof_n     <= trn_tsof_n_c;
trn_teof_n     <= trn_teof_n_c;
trn_tsrc_dsc_n <= trn_tsrc_dsc_n_c;
trn_tsrc_rdy_n <= trn_tsrc_rdy_n_c;
trn_tdst_dsc_n_c <= trn_tdst_dsc_n;
trn_tdst_rdy_n_c <= trn_tdst_rdy_n;

-- LocalLink Rx

trn_rd_c <= trn_rd;         
trn_rrem_n_c <= trn_rrem_n     ;
trn_rsof_n_c <= trn_rsof_n  ;   
trn_reof_n_c <= trn_reof_n ;    
trn_rsrc_rdy_n_c <= trn_rsrc_rdy_n ;
trn_rsrc_dsc_n_c <= trn_rsrc_dsc_n ;
trn_rbar_hit_n_c <= trn_rbar_hit_n ;
trn_rdst_rdy_n  <= trn_rdst_rdy_n_c;

cfg_interrupt_n     <= cfg_interrupt_n_c;
cfg_interrupt_rdy_n_c <= cfg_interrupt_rdy_n  ;
cfg_interrupt_assert_n <= cfg_interrupt_assert_n_c;
cfg_completer_id_c <= cfg_completer_id     ;
cfg_ext_tag_en_c <= cfg_ext_tag_en       ;
cfg_max_rd_req_size_c <= cfg_max_rd_req_size  ;
cfg_max_payload_size_c <= cfg_max_payload_size ;
cfg_bus_mstr_enable_c <= cfg_bus_mstr_enable  ;

	-- clock generator
	process (clk, rst_n)
	begin
		if (rst_n = '0') then
			clk_cnt <= "0000";
		elsif (rising_edge(clk)) then
			clk_cnt <= clk_cnt + 1;
		end if;
	end process;
	clk_d2 <= clk_cnt(0);
--	clk_fifo <= clk_d2;
	clk_fifo <= clk;
	fifo_rst_p <= not rst_n;

	h2f_data : h2f_data_fifo
	port map (
		rst => fifo_rst_p,
		
		rd_clk => clk_fifo,
		rd_en => h2f_fifo_ren,
		dout => h2f_fifo_dout,
		empty => h2f_fifo_empty,
		valid => h2f_fifo_valid,
		
		wr_clk => clk,
		din => h2f_fifo_din,
		wr_en => wr_data_fen,
		full => open,
		almost_full =>wr_data_full );
	-- end port map of "h2f_data"
	
	f2h_data : f2h_data_fifo
	port map (
		rst => fifo_rst_p,
		
		dout => f2h_fifo_dout,
		empty => f2h_fifo_empty,
		valid => rd_data_valid,
		rd_clk => clk,
		rd_en => f2h_fifo_ren,
		
		din => f2h_fifo_din,
		wr_clk => clk_fifo,
		wr_en => f2h_fifo_wen,
		full => open,
		almost_full => f2h_fifo_full);
	-- end port map of "f2h_data"
	
	h2f_fifo_din <= dma_h2f_data; 
	rd_data_pio <= f2h_fifo_dout(31 downto 0);
	rd_data_hi <= f2h_fifo_dout(63 downto 32);
	
--SPL_DMA_SIM : SPL_DMA_TESTER
--port map (
--	clk => clk_fifo,                         
--	rst_n => rst_n,  
--	init_rst => init_rst,
--		
----	rd_addr_i => rd_addr,                 
----	rd_be_i => rd_be,                     
----	rd_be_hi_i => rd_be_hi,
--	rd_data_o => f2h_fifo_din(31 downto 0),--             
--	rd_data_hi_o => f2h_fifo_din(63 downto 32),--
--	
--	f2h_len => X"00000200", --512 QWORDs
--	f2h_fifo_wen =>f2h_fifo_wen, -- 
--	f2h_fifo_full =>f2h_fifo_full,-- 
--	f2h_start		=>mwr_start, --	
--	f2h_done      =>mwr_done,
--		
----	wr_addr_i => wr_addr,                 
----	wr_be_i => wr_be,                     
----	wr_be_hi_i => wr_be_hi,
--	wr_data_i => h2f_fifo_dout(31 downto 0),--               
--	wr_data_hi_i => h2f_fifo_dout(63 downto 32), --
--	wr_en_i => wr_en_pio, 
--	
--	h2f_len    =>X"00000200", --512 QWORDs 
--	h2f_fifo_ren =>h2f_fifo_ren, -- std_logic;
--	h2f_fifo_empty =>h2f_fifo_empty, -- std_logic;
--	h2f_fifo_valid =>h2f_fifo_valid,
--	h2f_start =>mrd_start, -- std_logic
--	h2f_done =>mrd_done,
--	
--	-- debug use only
--	h2f_addr_o => h2f_addr,
--	h2f_qword_left_o => h2f_qword_left,
--	h2f_ram_wen_o => h2f_ram_wen,
--	-- debug use only
--	
--	wr_busy_o => wr_busy_pio);
---- end port map of "EP_MEM"

PCIE_BAR0_INST : PCIE_BAR0
port map ( 
	clk   => clk,       
	rst_n => rst_n,      
	
	cfg_max_rd_req_size  => cfg_max_rd_req_size,
	cfg_max_payload_size => cfg_max_payload_size,
	
	-- Read Port
	rd_a_i => reserved_csr_rd_index_c(7 downto 0),
--	rd_be_i   => rd_be,
	rd_d_o => reserved_csr_rd_data_c,
	
	-- Write Port
	wr_a_i => reserved_csr_wr_index_c(7 downto 0),--wr_addr(7 downto 2),


--	wr_be_i   => wr_be,
	wr_d_i => reserved_csr_wr_data_c,--wr_data,
	wr_en_i   => reserved_csr_wr_en_c,--wr_en_bmd,  
--	wr_busy_o => wr_busy_bmd, 
	
	pcie_csr_in_h2f_reg0_wr_en => pcie_csr_h2f_reg0_wr_en_c,
	pcie_csr_in_h2f_reg0       => pcie_csr_h2f_reg0_c,
	pcie_csr_out_f2h_reg0			 => pcie_csr_f2h_reg0_c,
	
	init_rst_o => init_rst,  
	
	intr_host_ack => intr_host_ack_c,
--	intr_host_en => int_en_c,
	
	mrd_start_o => mrd_start, 
	mrd_done_o  => mrd_done,  
	mrd_addr_o  => mrd_addr,  
	mrd_addr_hi_o  => mrd_addr_hi, 
	mrd_len_o   => mrd_len,    
	mrd_count_o => mrd_count, 
	mrd_base_o  => mrd_base,   
	mrd_suspend_o => mrd_suspend,
	mrd_cur_count_i => mrd_cur_count,
	mrd_cur_data_size_i => mrd_cur_data_size,
	
	mwr_start_o => mwr_start,  
	mwr_done_i  => mwr_done,   
	mwr_addr_o  => mwr_addr,   
	mwr_addr_hi_o  => mwr_addr_hi, 
	mwr_len_o   => mwr_len,    
	mwr_count_o => mwr_count,  
	mwr_base_o  => mwr_base,   
	
	cpl_ur_found_i => cpl_ur_found,  
	cpl_ur_tag_i   => cpl_ur_tag,    
	
	cpld_found_i     => cpld_found,       
	cpld_data_size_i => cpld_size,        
	cpld_malformed_i => cpld_malformed,
	csr_test_start_o => csr_test_start_i_r,
	csr_test_data_in_o => csr_test_data_in_i_r,                  
	csr_test_index_o   => csr_test_index_i_r,
	csr_test_data_out_i=> csr_test_data_out_o_r) ;
   
   
-- end port map of "BMD_EP_MEM_ACCESS_INST"

rd_data <= rd_data_bmd when (rd_select = '0') else rd_data_pio;
wr_en_bmd <= wr_en when (wr_select = '0') else '0';
wr_en_pio <= wr_en when (wr_select = '1') else '0';
wr_busy <= wr_busy_bmd or wr_busy_pio;
	 

PCIE_RX_ENGINE_INST : PCIE_RX_ENGINE
port map (
	clk   => clk,     
	rst_n => rst_n,   
	
	init_rst_i => init_rst,  
	
	-- LocalLink Rx
	trn_rd         => trn_rd_c,         
	trn_rrem_n     => trn_rrem_n_c,      
	trn_rsof_n     => trn_rsof_n_c,     
	trn_reof_n     => trn_reof_n_c,      
	trn_rsrc_rdy_n => trn_rsrc_rdy_n_c,  
	trn_rsrc_dsc_n => trn_rsrc_dsc_n_c, 
	trn_rbar_hit_n => trn_rbar_hit_n_c, 
	trn_rdst_rdy_n => trn_rdst_rdy_n_c,  
	
	-- Handshake with Tx engine 
	
	req_compl_o  => req_compl,  
	compl_done_i => compl_done, 
	
	req_tc_o   => req_tc,   
	req_td_o   => req_td,    -- O
	req_ep_o   => req_ep,    -- O
	req_attr_o => req_attr,  -- O [1:0]
	req_len_o  => req_len,   -- O [9:0]
	req_rid_o  => req_rid,   -- O [15:0]
	req_tag_o  => req_tag,   -- O [7:0]
	req_be_o   => req_be,    -- O [7:0]
	req_bar_o => req_bar,   -- O
	req_addr_o => req_addr, -- O [31:0]
	
	-- CSR ports
	csr_wr_ready		=> pcie_csr_wr_ready_c,
	csr_wr_en				=>  pcie_csr_wr_en_c,
	csr_wr_data			=> pcie_csr_wr_data_c,
	csr_wr_index		=>	pcie_csr_wr_index_c,

	reserved_csr_wr_index => reserved_csr_wr_index_c,
	reserved_csr_wr_data  => reserved_csr_wr_data_c,
	reserved_csr_wr_en    => reserved_csr_wr_en_c,
	-- CSR ports	
	
	-- BEGIN: for debug use only -----
	wr_data_pre1_o => wr_data_pre1,
	wr_data_pre2_o => wr_data_pre2,
	wr_data_sel_o  => wr_data_sel,
	cpld_real_size_o => cpld_real_size,
	-- END: for debug use only -------	
	
	-- RAM Write Port
	
	wr_addr_o => wr_addr,
	wr_be_o   => wr_be,    -- O [3:0]
	wr_be_hi_o => wr_be_hi,
	wr_data_o => wr_data,  -- O [31:0]
	wr_data_hi_o => wr_data_hi,
	wr_en_o   => wr_en,    -- O
	wr_busy_i => wr_busy,  -- I
	wr_select_o => wr_select, -- O
	
	wr_data_fen => wr_data_fen,
	wr_data_full => wr_data_full,
	dma_h2f_data => dma_h2f_data,
	
	mrd_addr_i  => mrd_addr,   -- I [31:0]
	mrd_base_i  => mrd_base,   -- I [31:0] 
	
	cpl_ur_found_o => cpl_ur_found,  -- O [7:0]
	cpl_ur_tag_o   => cpl_ur_tag,    -- O [7:0]
	
	cpld_found_o     => cpld_found,  -- O [31:0]
	cpld_data_size_o => cpld_size,  -- O [31:0]
	cpld_malformed_o => cpld_malformed);  -- O                  
-- end port map of "BMD_64_RX_ENGINE_INST"

PCIE_TX_ENGINE_INST : PCIE_TX_ENGINE
port map(
	clk   => clk,      -- I
	rst_n => rst_n,    -- I
	
	-- LocalLink Tx
	trn_td         => trn_td_c,          -- O [63/31:0]
	trn_trem_n     => trn_trem_n_c,      -- O [7:0]
	trn_tsof_n     => trn_tsof_n_c,      -- O
	trn_teof_n     => trn_teof_n_c,      -- O
	trn_tsrc_dsc_n => trn_tsrc_dsc_n_c,  -- O
	trn_tsrc_rdy_n => trn_tsrc_rdy_n_c,  -- O
	trn_tdst_dsc_n => trn_tdst_dsc_n_c,  -- I
	trn_tdst_rdy_n => trn_tdst_rdy_n_c,  -- I
	
	
	-- Handshake with Rx engine 
	req_compl_i  => req_compl,   -- I
	compl_done_o => compl_done,  -- 0
	
	req_tc_i   => req_tc,    -- I [2:0]
	req_td_i   => req_td,    -- I
	req_ep_i   => req_ep,    -- I
	req_attr_i => req_attr,  -- I [1:0]
	req_len_i  => req_len,   -- I [9:0]
	req_rid_i  => req_rid,   -- I [15:0]
	req_tag_i  => req_tag,   -- I [7:0]
	req_be_i   => req_be,    -- I [7:0]
	req_addr_i => req_addr,  -- I [10:0]
	req_bar_i => req_bar, --I
	
	-- Read Port
	
	rd_addr_o => rd_addr,  -- I [10:0]
	rd_be_o   => rd_be,           -- I [3:0]
	rd_be_hi_o => rd_be_hi,
	rd_data_i => rd_data,         -- O [31:0]
	rd_data_hi_i => rd_data_hi,
	rd_select_o => rd_select,
	
	-- Initiator Controls
	
	init_rst_i => init_rst,  -- I
	
	f2h_fifo_empty => f2h_fifo_empty,
	rd_data_valid	=> rd_data_valid,
	f2h_fifo_ren 		=> f2h_fifo_ren,
	
	-- for debug use only
	f2h_data_tmp_o => f2h_data_tmp,
	dst_rdy_n_o => dst_rdy_n,
	cur_wr_count_o	  => cur_wr_count,
	cur_mwr_dw_count_o => cur_mwr_dw_count,
	rd_en_o => rd_en,
	-- for debug use only

	-- CSR ports
	csr_rd_ready		=> pcie_csr_rd_ready_c,--'1',
	csr_rd_done			=> pcie_csr_rd_done_c,--'1',
	csr_rd_en				=> pcie_csr_rd_en_c,
	csr_rd_ack			=> pcie_csr_rd_ack_c,
	csr_rd_data			=> pcie_csr_rd_data_c,--(others => '0'),
	csr_rd_index		=> pcie_csr_rd_index_c,
	
	reserved_csr_rd_index =>reserved_csr_rd_index_c,
	reserved_csr_rd_data  =>reserved_csr_rd_data_c,
		
	-- CSR ports	
	
	mrd_start_i => mrd_start,  -- I
	mrd_done_i  => mrd_done,   -- I
	mrd_addr_i  => mrd_addr,   -- I [31:0]
	mrd_addr_hi_i => mrd_addr_hi,
	mrd_len_i   => mrd_len,    -- I [31:0]
	mrd_count_i => mrd_count,  -- I [31:0]
	mrd_lbe_i   => x"F",
	mrd_fbe_i   => x"F",
	mrd_base_i  => mrd_base,   -- I [31:0] 
	mrd_suspend_i => mrd_suspend,
	mrd_cur_count_o => mrd_cur_count,
	mrd_cur_data_size_o => mrd_cur_data_size,
	
	mwr_start_i => mwr_start,  -- I
	mwr_done_o  => mwr_done,   -- O
	mwr_addr_i  => mwr_addr,   -- I [31:0]
	mwr_addr_hi_i => mwr_addr_hi,
	mwr_len_i   => mwr_len,    -- I [31:0]
	mwr_count_i => mwr_count,  -- I [31:0]
	mwr_base_i  => mwr_base,   -- I [31:0] 
	mwr_lbe_i   => x"F",
	mwr_fbe_i   => x"F",                     
	
--	cfg_interrupt_n_o => cfg_interrupt_n_c,  -- O
--	cfg_interrupt_rdy_n_i => cfg_interrupt_rdy_n_c,  -- I
--	cfg_interrupt_assert_n => cfg_interrupt_assert_n_c,
	
	completer_id_i        => cfg_completer_id_c,     -- I [15:0]
	cfg_ext_tag_en_i      => cfg_ext_tag_en_c,       -- I
	cfg_bus_mstr_enable_i => cfg_bus_mstr_enable_c);  -- I
-- end port map of "BMD_64_TX_ENGINE_INST"

--SPL_CSR_SIM: SPL_CSR_TESTER 
--port MAP(
--	clk   => clk,
--	rst_n => rst_n,
--	csr_out_rd_ready		=> csr_rd_ready_c,
--	csr_out_rd_done		=> csr_rd_done_c,
--	csr_in_rd_en			=> csr_rd_en_c,
--	csr_in_rd_ack			=> csr_rd_ack_c,
--	csr_out_rd_data		=> csr_rd_data_c,
--	csr_in_rd_index		=> csr_rd_index_c,
--	csr_out_wr_ready		=> csr_wr_ready_c,
--	csr_in_wr_en			=> csr_wr_en_c,
--	csr_in_wr_data			=> csr_wr_data_c,
--	csr_in_wr_index		=> csr_wr_index_c,
--	--------------system CSR SIGNAL-------------------
--	csr_in_f2h_reg0_wr_en=> csr_f2h_reg0_wr_en_c,
--	csr_out_h2f_reg0		=> csr_h2f_reg0_c,
--	csr_in_f2h_reg0		=> csr_f2h_reg0_c,
--	-- for test
--	csr_test_start_i     => csr_test_start_i_r,
--	csr_test_data_in_i   => csr_test_data_in_i_r,
--	csr_test_index_i     => csr_test_index_i_r,
--	csr_test_data_out_o  => csr_test_data_out_o_r);


CSR_CONTROLLER_INST:CSR_CONTROLLER 
port MAP( 
	clk   => clk,
	rst_n => rst_n,
	pcie_csr_out_rd_ready		=> pcie_csr_rd_ready_c,
	pcie_csr_out_rd_done			=> pcie_csr_rd_done_c,
	pcie_csr_in_rd_en				=> pcie_csr_rd_en_c,
	pcie_csr_in_rd_ack			=> pcie_csr_rd_ack_c,
	pcie_csr_out_rd_data			=> pcie_csr_rd_data_c,
	pcie_csr_in_rd_index			=> pcie_csr_rd_index_c,
	pcie_csr_out_wr_ready		=> pcie_csr_wr_ready_c,
	pcie_csr_in_wr_en				=> pcie_csr_wr_en_c,
	pcie_csr_in_wr_data			=> pcie_csr_wr_data_c,
	pcie_csr_in_wr_index			=> pcie_csr_wr_index_c,
	
	pcie_csr_in_h2f_reg0_wr_en => pcie_csr_h2f_reg0_wr_en_c,
	pcie_csr_in_h2f_reg0       => pcie_csr_h2f_reg0_c,
	pcie_csr_out_f2h_reg0			=> pcie_csr_f2h_reg0_c,
	
	csr_out_rd_ready		=> csr_rd_ready_c,
	csr_out_rd_done			=> csr_rd_done_c,
	csr_in_rd_en				=> csr_rd_en_c,
	csr_in_rd_ack				=> csr_rd_ack_c,
	csr_out_rd_data			=> csr_rd_data_c,
	csr_in_rd_index			=> csr_rd_index_c,
	csr_out_wr_ready		=> csr_wr_ready_c,
	csr_in_wr_en				=> csr_wr_en_c,
	csr_in_wr_data			=> csr_wr_data_c,
	csr_in_wr_index			=> csr_wr_index_c,	
	--------------system CSR SIGNAL-------------------
	csr_in_f2h_reg0_wr_en => csr_f2h_reg0_wr_en_c,--csr_in_f2h_reg0_wr_en_r,
	csr_out_h2f_reg0		=> csr_h2f_reg0_c,
	csr_in_f2h_reg0			=> csr_f2h_reg0_c);--csr_in_f2h_reg0_r);
	
INTR_CONTROLLER_INST:INTR_CONTROLLER
port map(
	clk   => clk,
	rst_n => rst_n,
	
	int_out_ready => int_ready_c,
	int_in_en			=> int_en_c,
	
	intr_host_ack => intr_host_ack_c,
	
	cfg_interrupt_rdy_n => cfg_interrupt_rdy_n_c,
	cfg_interrupt_assert_n => cfg_interrupt_assert_n_c,
	cfg_interrupt_n     => cfg_interrupt_n_c);	
	
	
---------------------------------------------------------------------
----           connect interface signals

---------------- regular CSR signals --------------------

	csr_out_rd_ready <= csr_rd_ready_c;
   csr_out_rd_done  <= csr_rd_done_c;
	csr_out_rd_data  <= csr_rd_data_c;
	csr_out_wr_ready <= csr_wr_ready_c;

	csr_rd_en_c		<= csr_in_rd_en;
	csr_rd_ack_c	<=	csr_in_rd_ack;
	csr_rd_index_c	<=	csr_in_rd_index;
	csr_wr_en_c		<= csr_in_wr_en;
	csr_wr_data_c	<=	csr_in_wr_data;
	csr_wr_index_c	<= csr_in_wr_index;
    
----------------- system CSR signals --------------------

	csr_out_h2f_reg0		<= csr_h2f_reg0_c;
	csr_f2h_reg0_c			<= csr_in_f2h_reg0;
	csr_f2h_reg0_wr_en_c	<= csr_in_f2h_reg0_wr_en;

------------------ Interrupt signals --------------------
 
	int_out_ready	<= int_ready_c;
	int_en_c 		<= int_in_en;

----------------------------------------------------------------------

end structural;

