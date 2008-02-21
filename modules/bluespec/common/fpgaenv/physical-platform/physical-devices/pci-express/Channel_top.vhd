---- Filename: Channel_top.vhd
---- Wang, Liang(liang.wang@intel.com), Wang, Tao Z (tao.z.wang@intel.com)
---- Description:  HW Channels top level wrapper.
----
---- 1. What you need to connect to is only this file
---- 2. The HW Channels interface signals can be easily found in the entity
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity Channel_top is
--generic (
--	FAST_SIMULATION		: INTEGER := 0;
--	PCIE_LANE_WIDTH		: INTEGER := 4);
port  (

	-- system signals

	sys_clk_p         : in std_logic;
	sys_clk_n         : in std_logic;
	sys_reset_n       : in std_logic;
	
	pci_exp_rxn       : in std_logic_vector((4 - 1) downto 0);
	pci_exp_rxp       : in std_logic_vector((4 - 1) downto 0);
	pci_exp_txn       : out std_logic_vector((4 - 1) downto 0);
	pci_exp_txp       : out std_logic_vector((4 - 1) downto 0);
	
	-- exported clock
	hwchn_clk 		: out std_logic;
	hwchn_rst			: out std_logic;
	
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
end Channel_top;

architecture rtl of   Channel_top is

component channel is
port (
	clk   : in std_logic;
	rst_n : in std_logic;
		
	
	trn_td     : out std_logic_vector(63 downto 0);
	trn_trem_n : out std_logic_vector(7 downto 0);
	trn_tsof_n     : out std_logic;
	trn_teof_n     : out std_logic;
	trn_tsrc_dsc_n : out std_logic;
	trn_tsrc_rdy_n : out std_logic;
	trn_tdst_dsc_n : in  std_logic;
	trn_tdst_rdy_n : in  std_logic;
	
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
	
	
	--------------- interface signals ------------------------
	
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
end component;


component pcieblkplus
port (
	pci_exp_rxn : in std_logic_vector((4 - 1) downto 0);
	pci_exp_rxp : in std_logic_vector((4 - 1) downto 0);
	pci_exp_txn : out std_logic_vector((4 - 1) downto 0);
	pci_exp_txp : out std_logic_vector((4 - 1) downto 0);
	
	sys_clk : in STD_LOGIC;
	sys_reset_n : in STD_LOGIC;
	
	trn_clk : out STD_LOGIC; 
	trn_reset_n : out STD_LOGIC; 
	trn_lnk_up_n : out STD_LOGIC; 
	
	trn_td : in STD_LOGIC_VECTOR((64 - 1) downto 0);
	trn_trem_n: in STD_LOGIC_VECTOR (7 downto 0);
	trn_tsof_n : in STD_LOGIC;
	trn_teof_n : in STD_LOGIC;
	trn_tsrc_dsc_n : in STD_LOGIC;
	trn_tsrc_rdy_n : in STD_LOGIC;
	trn_tdst_dsc_n : out STD_LOGIC;
	trn_tdst_rdy_n : out STD_LOGIC;
	trn_terrfwd_n : in STD_LOGIC ;
	trn_tbuf_av : out STD_LOGIC_VECTOR (( 3 -1 ) downto 0 );
	
	trn_rd : out STD_LOGIC_VECTOR((64 - 1) downto 0);
	trn_rrem_n: out STD_LOGIC_VECTOR (7 downto 0);
	trn_rsof_n : out STD_LOGIC;
	trn_reof_n : out STD_LOGIC; 
	trn_rsrc_dsc_n : out STD_LOGIC; 
	trn_rsrc_rdy_n : out STD_LOGIC; 
	trn_rbar_hit_n : out STD_LOGIC_VECTOR ( 6 downto 0 );
	trn_rdst_rdy_n : in STD_LOGIC; 
	trn_rerrfwd_n : out STD_LOGIC; 
	trn_rnp_ok_n : in STD_LOGIC; 
	trn_rfc_npd_av : out STD_LOGIC_VECTOR ( 11 downto 0 ); 
	trn_rfc_nph_av : out STD_LOGIC_VECTOR ( 7 downto 0 ); 
	trn_rfc_pd_av : out STD_LOGIC_VECTOR ( 11 downto 0 ); 
	trn_rfc_ph_av : out STD_LOGIC_VECTOR ( 7 downto 0 );
	trn_rcpl_streaming_n      : in STD_LOGIC;
	
	cfg_do : out STD_LOGIC_VECTOR ( 31 downto 0 );
	cfg_rd_wr_done_n : out STD_LOGIC; 
	cfg_di : in STD_LOGIC_VECTOR ( 31 downto 0 ); 
	cfg_byte_en_n : in STD_LOGIC_VECTOR ( 3 downto 0 ); 
	cfg_dwaddr : in STD_LOGIC_VECTOR ( 9 downto 0 );
	cfg_wr_en_n : in STD_LOGIC;
	cfg_rd_en_n : in STD_LOGIC; 
	
	cfg_err_cor_n : in STD_LOGIC; 
	cfg_err_cpl_abort_n : in STD_LOGIC; 
	cfg_err_cpl_timeout_n : in STD_LOGIC; 
	cfg_err_cpl_unexpect_n : in STD_LOGIC; 
	cfg_err_ecrc_n : in STD_LOGIC; 
	cfg_err_posted_n : in STD_LOGIC; 
	cfg_err_tlp_cpl_header : in STD_LOGIC_VECTOR ( 47 downto 0 ); 
	cfg_err_ur_n : in STD_LOGIC;
	cfg_interrupt_n : in STD_LOGIC;
	cfg_interrupt_rdy_n : out STD_LOGIC;
	cfg_interrupt_assert_n: IN std_logic;
	cfg_interrupt_di: IN std_logic_VECTOR(7 downto 0);
	cfg_interrupt_do: OUT std_logic_VECTOR(7 downto 0);
	cfg_interrupt_mmenable: OUT std_logic_VECTOR(2 downto 0);
	cfg_interrupt_msienable: OUT std_logic;	 
	cfg_pm_wake_n : in STD_LOGIC;
	cfg_pcie_link_state_n : out STD_LOGIC_VECTOR ( 2 downto 0 ); 
	cfg_to_turnoff_n : out STD_LOGIC;
	cfg_trn_pending_n : in STD_LOGIC;
	cfg_bus_number : out STD_LOGIC_VECTOR ( 7 downto 0 );
	cfg_device_number : out STD_LOGIC_VECTOR ( 4 downto 0 );
	cfg_function_number : out STD_LOGIC_VECTOR ( 2 downto 0 );
	cfg_status : out STD_LOGIC_VECTOR ( 15 downto 0 );
	cfg_command : out STD_LOGIC_VECTOR ( 15 downto 0 );
	cfg_dstatus : out STD_LOGIC_VECTOR ( 15 downto 0 );
	cfg_dcommand : out STD_LOGIC_VECTOR ( 15 downto 0 );
	cfg_lstatus : out STD_LOGIC_VECTOR ( 15 downto 0 );
	cfg_lcommand : out STD_LOGIC_VECTOR ( 15 downto 0 );
	cfg_dsn: in STD_LOGIC_VECTOR (63 downto 0 );
	
	fast_train_simulation_only : in STD_LOGIC;
	two_plm_auto_config : in STD_LOGIC_VECTOR ( 1 downto 0 ));
end component;


signal     sys_clk_c : std_logic;
signal     sys_reset_n_c : std_logic;
signal     trn_clk_c : std_logic;
signal     trn_reset_n_c : std_logic;
signal     trn_lnk_up_n_c : std_logic;
signal     cfg_trn_pending_n_c : std_logic;
signal     trn_tsof_n_c : std_logic;
signal     trn_teof_n_c : std_logic;
signal     trn_tsrc_rdy_n_c : std_logic;
signal     trn_tdst_rdy_n_c : std_logic;
signal     trn_tsrc_dsc_n_c : std_logic;
signal     trn_terrfwd_n_c : std_logic;
signal     trn_tdst_dsc_n_c : std_logic;
signal     trn_td_c : std_logic_vector((64 - 1) downto 0);
signal     trn_trem_n_c : std_logic_vector(7 downto 0);
signal     trn_tbuf_av_c : std_logic_vector(( 3 -1 )  downto 0);
signal     trn_rsof_n_c : std_logic;
signal     trn_reof_n_c : std_logic;
signal     trn_rsrc_rdy_n_c : std_logic;
signal     trn_rsrc_dsc_n_c : std_logic;
signal     trn_rdst_rdy_n_c : std_logic;
signal     trn_rerrfwd_n_c : std_logic;
signal     trn_rnp_ok_n_c : std_logic;
signal     trn_rd_c : std_logic_vector((64 - 1) downto 0);
signal     trn_rrem_n_c : std_logic_vector(7 downto 0);
signal     trn_rbar_hit_n_c : std_logic_vector(6 downto 0);
signal     trn_rfc_nph_av_c : std_logic_vector(7 downto 0);
signal     trn_rfc_npd_av_c : std_logic_vector(11 downto 0);
signal     trn_rfc_ph_av_c : std_logic_vector(7 downto 0);
signal     trn_rfc_pd_av_c : std_logic_vector(11 downto 0);
signal     trn_rcpl_streaming_n_c      : std_logic;

signal     cfg_do_c : std_logic_vector(31 downto 0);
signal     cfg_di_c : std_logic_vector(31 downto 0);
signal     cfg_dwaddr_c : std_logic_vector(9 downto 0) ;
signal     cfg_byte_en_n_c : std_logic_vector(3 downto 0);
signal     cfg_err_tlp_cpl_header_c : std_logic_vector(47 downto 0);
signal     cfg_wr_en_n_c : std_logic;
signal     cfg_rd_en_n_c : std_logic;
signal     cfg_rd_wr_done_n_c : std_logic;
signal     cfg_err_cor_n_c : std_logic;
signal     cfg_err_ur_n_c : std_logic;
signal     cfg_err_ecrc_n_c : std_logic;
signal     cfg_err_cpl_timeout_n_c : std_logic;
signal     cfg_err_cpl_abort_n_c : std_logic;
signal     cfg_err_cpl_unexpect_n_c : std_logic;
signal     cfg_err_posted_n_c : std_logic;
signal     cfg_interrupt_n_c : std_logic;
signal     cfg_interrupt_rdy_n_c : std_logic;
signal     cfg_interrupt_assert_n_c : std_logic;
signal     cfg_turnoff_ok_n_c : std_logic;
signal     cfg_to_turnoff_n_c : std_logic;
signal     cfg_pm_wake_n_c : std_logic;
signal     cfg_pcie_link_state_n_c : std_logic_vector(2 downto 0);
signal     cfg_bus_number_c : std_logic_vector(7 downto 0);
signal     cfg_device_number_c : std_logic_vector(4 downto 0);
signal     cfg_function_number_c : std_logic_vector(2 downto 0);
signal     cfg_status_c : std_logic_vector(15 downto 0);
signal     cfg_command_c : std_logic_vector(15 downto 0);
signal     cfg_dstatus_c : std_logic_vector(15 downto 0);
signal     cfg_dcommand_c : std_logic_vector(15 downto 0);
signal     cfg_lstatus_c : std_logic_vector(15 downto 0);
signal     cfg_lcommand_c : std_logic_vector(15 downto 0);
signal     unsigned_fast_simulation: unsigned(0 downto 0);
signal     vector_fast_simulation: std_logic_vector(0 downto 0);

signal cfg_completer_id       : std_logic_vector(15 downto 0);
signal cfg_bus_mstr_enable    : std_logic;
signal cfg_ext_tag_en	      : std_logic;
signal cfg_max_payload_size   : std_logic_vector(2 downto 0);
signal cfg_max_rd_req_size    : std_logic_vector(2 downto 0);
signal channel_rst_n : std_logic;

-- for system csr test
signal csr_reg0_data_c : std_logic_vector(31 downto 0);


-- regular CSR signals

signal	csr_rd_ready_c	: std_logic;
signal	csr_rd_done_c	: std_logic;
signal	csr_rd_data_c 	: std_logic_vector(31 downto 0);
signal	csr_wr_ready_c	: std_logic;
signal	csr_rd_en_c    : std_logic;
signal	csr_rd_ack_c	: std_logic;
signal	csr_rd_index_c	: std_logic_vector(7 downto 0);
signal	csr_wr_en_c		: std_logic;
signal	csr_wr_data_c	: std_logic_vector(31 downto 0);
signal	csr_wr_index_c	: std_logic_vector(7 downto 0);
	
	-- system CSR signals 
	
signal	csr_h2f_reg0_c			: std_logic_vector(31 downto 0);
signal	csr_f2h_reg0_c			: std_logic_vector(31 downto 0);
signal	csr_f2h_reg0_wr_en_c	: std_logic;
	
	-- interrupt signals
	
signal int_ready_c	: std_logic;
signal int_en_c		: std_logic;


attribute BOX_TYPE : string;
attribute BOX_TYPE of pcieblkplus : component is "BLACK_BOX";


begin


-- convert generic FAST_SIMULATION and pass to express core
unsigned_fast_simulation <= to_unsigned(0,1); --FAST_SIMULATION = 0
vector_fast_simulation <= std_logic_vector(unsigned_fast_simulation);

-------------------------------------------------------
-- Virtex5-FX Global Clock Buffer
-------------------------------------------------------
refclk_ibuf : IBUFDS port map (

  O => sys_clk_c,
  I => sys_clk_p,
  IB => sys_clk_n

);



sys_reset_n_ibuf : IBUF port map (

  O => sys_reset_n_c,
  I => sys_reset_n

);

----------------------------------------------------------
-- pcie_channel port map
----------------------------------------------------------
channel_rst_n				<= trn_reset_n_c and not trn_lnk_up_n_c;
cfg_completer_id			<= (cfg_bus_number_c &
										cfg_device_number_c &
										cfg_function_number_c);
cfg_bus_mstr_enable		<= cfg_command_c(2);
cfg_ext_tag_en				<= cfg_dcommand_c(8);
cfg_max_payload_size		<= cfg_dcommand_c(7 downto 5);
cfg_max_rd_req_size		<= cfg_dcommand_c(14 downto 12);


pcie_channel : channel 
port map( clk   => trn_clk_c,      
	rst_n => channel_rst_n,  
	
	
	trn_td         => trn_td_c,          
	trn_trem_n     => trn_trem_n_c,      
	trn_tsof_n     => trn_tsof_n_c,      
	trn_teof_n     => trn_teof_n_c,      
	trn_tsrc_rdy_n => trn_tsrc_rdy_n_c,  
	trn_tsrc_dsc_n => trn_tsrc_dsc_n_c,  
	trn_tdst_rdy_n => trn_tdst_rdy_n_c,  
	trn_tdst_dsc_n => trn_tdst_dsc_n_c,  
	
	trn_rd         => trn_rd_c,          
	trn_rrem_n     => trn_rrem_n_c,      
	trn_rsof_n     => trn_rsof_n_c,      
	trn_reof_n     => trn_reof_n_c,      
	trn_rsrc_rdy_n => trn_rsrc_rdy_n_c,  
	trn_rsrc_dsc_n => trn_rsrc_dsc_n_c,  
	trn_rbar_hit_n => trn_rbar_hit_n_c,  
	trn_rdst_rdy_n => trn_rdst_rdy_n_c,  
	
	
	cfg_interrupt_n     => cfg_interrupt_n_c,      
	cfg_interrupt_rdy_n => cfg_interrupt_rdy_n_c,  
	cfg_interrupt_assert_n => cfg_interrupt_assert_n_c,
	cfg_completer_id => cfg_completer_id,  
	cfg_ext_tag_en       => cfg_ext_tag_en,        
	cfg_max_payload_size => cfg_max_payload_size,  
	cfg_max_rd_req_size  => cfg_max_rd_req_size,   
	cfg_bus_mstr_enable => cfg_bus_mstr_enable,
	
   ---------------- regular CSR signals --------------------

	csr_out_rd_ready                      => csr_rd_ready_c,
	csr_out_rd_done                       => csr_rd_done_c,
	csr_in_rd_en                          => csr_rd_en_c,
	csr_in_rd_ack                         => csr_rd_ack_c,
	csr_out_rd_data                       => csr_rd_data_c,
	csr_in_rd_index                       => csr_rd_index_c,
	csr_out_wr_ready                      => csr_wr_ready_c,
	csr_in_wr_en                          => csr_wr_en_c,
	csr_in_wr_data                        => csr_wr_data_c,
	csr_in_wr_index                       => csr_wr_index_c,       

   ----------------- system CSR signals --------------------

   csr_in_f2h_reg0_wr_en                 => csr_f2h_reg0_wr_en_c,
   csr_out_h2f_reg0                      => csr_h2f_reg0_c,
   csr_in_f2h_reg0                       => csr_f2h_reg0_c,

   ------------------ Interrupt signals --------------------

   int_out_ready                         => int_ready_c,
   int_in_en                             => int_en_c
);


----------------------------------------------------------
-- pcie_endpoint_plus IP port map
----------------------------------------------------------
ep : pcieblkplus port map  (
	pci_exp_txp => pci_exp_txp,            
	pci_exp_txn => pci_exp_txn,             
	pci_exp_rxp => pci_exp_rxp,             
	pci_exp_rxn => pci_exp_rxn,             
	
	sys_clk => sys_clk_c,                                
	sys_reset_n => sys_reset_n_c,                          
		
	trn_clk => trn_clk_c,                  
	trn_reset_n => trn_reset_n_c,          
	trn_lnk_up_n => trn_lnk_up_n_c,         
		
	trn_td => trn_td_c,                     
	trn_trem_n => trn_trem_n_c,
	trn_tsof_n => trn_tsof_n_c,             
	trn_teof_n => trn_teof_n_c,             
	trn_tsrc_rdy_n => trn_tsrc_rdy_n_c,     
	trn_tsrc_dsc_n => trn_tsrc_dsc_n_c,     
	trn_tdst_rdy_n => trn_tdst_rdy_n_c,    
	trn_tdst_dsc_n => trn_tdst_dsc_n_c,     
	trn_terrfwd_n => '1',       
	trn_tbuf_av => trn_tbuf_av_c,          
	
	trn_rd => trn_rd_c,                     
	trn_rrem_n => trn_rrem_n_c,
	trn_rsof_n => trn_rsof_n_c,             
	trn_reof_n => trn_reof_n_c,             
	trn_rsrc_rdy_n => trn_rsrc_rdy_n_c,     
	trn_rsrc_dsc_n => trn_rsrc_dsc_n_c,     
	trn_rdst_rdy_n => trn_rdst_rdy_n_c,     
	trn_rerrfwd_n => trn_rerrfwd_n_c,       
	trn_rnp_ok_n => '0',         
	trn_rbar_hit_n => trn_rbar_hit_n_c,     
	trn_rfc_nph_av => trn_rfc_nph_av_c,     
	trn_rfc_npd_av => trn_rfc_npd_av_c,     
	trn_rfc_ph_av => trn_rfc_ph_av_c,       
	trn_rfc_pd_av => trn_rfc_pd_av_c,       
	trn_rcpl_streaming_n => '1',	
	
	cfg_do => cfg_do_c,                                   
	cfg_rd_wr_done_n => cfg_rd_wr_done_n_c,               
	cfg_di => (others => '0'),                                   
	cfg_byte_en_n => X"F",                      
	cfg_dwaddr => (others => '0'),                            
	cfg_wr_en_n => '1',                          
	cfg_rd_en_n => '1',                         
	cfg_err_cor_n => '1',                      
	cfg_err_ur_n => '1',                        
	cfg_err_ecrc_n => '1',                   
	cfg_err_cpl_timeout_n => '1',      
	cfg_err_cpl_abort_n => '1',         
	cfg_err_cpl_unexpect_n => '1',    
	cfg_err_posted_n => '0',                
	cfg_err_tlp_cpl_header => (others => '0'),    
	cfg_interrupt_n => cfg_interrupt_n_c,                  
	cfg_interrupt_rdy_n => cfg_interrupt_rdy_n_c,          
	cfg_to_turnoff_n => cfg_to_turnoff_n_c,                
	cfg_pm_wake_n => '1',                      
	cfg_pcie_link_state_n => cfg_pcie_link_state_n_c,     
	cfg_trn_pending_n => '1',              
	cfg_bus_number => cfg_bus_number_c,                    
	cfg_device_number => cfg_device_number_c,              
	cfg_function_number => cfg_function_number_c,          
	cfg_status => cfg_status_c,                            
	cfg_command => cfg_command_c,                          
	cfg_dstatus => cfg_dstatus_c,                          
	cfg_dcommand => cfg_dcommand_c,                        
	cfg_lstatus => cfg_lstatus_c,                          
	cfg_lcommand => cfg_lcommand_c,                        
	cfg_dsn => (others => '0'),
	
	cfg_interrupt_assert_n => cfg_interrupt_assert_n_c,
	cfg_interrupt_di => X"00",
	cfg_interrupt_do => open,
	cfg_interrupt_mmenable => open,
	cfg_interrupt_msienable => open,
	
	fast_train_simulation_only => vector_fast_simulation(0),
	two_plm_auto_config => "00");


---------------------------------------------------------------------
----           connect interface signals

---------------- exported clock -------------------------
	hwchn_clk <= trn_clk_c;
	hwchn_rst <= channel_rst_n;
	
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

end; 
