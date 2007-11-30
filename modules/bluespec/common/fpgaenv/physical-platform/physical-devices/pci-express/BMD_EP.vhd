----------------------------------------------------------------------------------
----

----
----------------------------------------------------------------------------------
---- Filename: BMD_EP.vhd
---- Li, Zheng Intel
---- Description: Bus Master Device I/O Endpoint module. 
----
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library work;
use work.bmd_pak.all;

entity BMD_EP is
    port (
        clk   : in std_logic;
        rst_n : in std_logic;

        -- LocalLink Tx

        trn_td     : out std_logic_vector(msb_64_32 downto 0);
        trn_trem_n : out std_logic_vector(7 downto 0);
        trn_tsof_n     : out std_logic;
        trn_teof_n     : out std_logic;
        trn_tsrc_dsc_n : out std_logic;
        trn_tsrc_rdy_n : out std_logic;
        trn_tdst_dsc_n : in  std_logic;
        trn_tdst_rdy_n : in  std_logic;

        -- LocalLink Rx

        trn_rd         : in  std_logic_vector(msb_64_32 downto 0);
        trn_rrem_n     : in  std_logic_vector(7 downto 0);
        trn_rsof_n     : in  std_logic;
        trn_reof_n     : in  std_logic;
        trn_rsrc_rdy_n : in  std_logic;
        trn_rsrc_dsc_n : in  std_logic;
	trn_rbar_hit_n : in std_logic_vector(6 downto 0);
        trn_rdst_rdy_n : out std_logic;
		  
		  led_switch     : out std_logic;			 

        cfg_interrupt_n      : out std_logic;
        cfg_interrupt_rdy_n  : in  std_logic;
        cfg_completer_id     : in  std_logic_vector(15 downto 0);
        cfg_ext_tag_en       : in  std_logic;
        cfg_max_rd_req_size  : in  std_logic_vector(2 downto 0);
        cfg_max_payload_size : in  std_logic_vector(2 downto 0);
        cfg_bus_mstr_enable  : in  std_logic);

end BMD_EP;

architecture structural of BMD_EP is

    component PIO_EP_MEM_ACCESS is
	port (
		
		  clk          : in std_logic;
		  rst_n        : in std_logic;

		  --  Read Port 2in 1out

		 rd_addr_i    : in std_logic_vector(10 downto 0);
		 rd_be_i      : in std_logic_vector(3 downto 0);
       rd_be_hi_i   : in std_logic_vector(3 downto 0);
		 rd_data_o    : out std_logic_vector(31 downto 0);
       rd_data_hi_o : out std_logic_vector(31 downto 0);

		  --  Write Port 4in 1 out

		wr_addr_i    : in std_logic_vector(10 downto 0);
		wr_be_i      : in std_logic_vector(3 downto 0);
      wr_be_hi_i   : in std_logic_vector(3 downto 0);
		wr_data_i    : in std_logic_vector(31 downto 0);
      wr_data_hi_i : in std_logic_vector(31 downto 0);
		wr_en_i      : in std_logic;
		wr_busy_o    : out std_logic
	);

end component PIO_EP_MEM_ACCESS;

	 component BMD_EP_MEM_ACCESS 
        port (clk   : in std_logic;
              rst_n : in std_logic;

	      ------------------------------------------------------------
	      -- Misc. control ports
              ------------------------------------------------------------
              cfg_max_rd_req_size  : in std_logic_vector(2 downto 0);
              cfg_max_payload_size : in std_logic_vector(2 downto 0);

	      ------------------------------------------------------------
              -- Read Port
              ------------------------------------------------------------
              rd_addr_i    : in  std_logic_vector(6 downto 0);
              rd_be_i   : in  std_logic_vector(3 downto 0);
              rd_data_o : out std_logic_vector(31 downto 0);
              ------------------------------------------------------------
              -- Write Port
              ------------------------------------------------------------
              wr_be_i   : in  std_logic_vector(3 downto 0);
              wr_data_i : in  std_logic_vector(31 downto 0);
              wr_en_i   : in  std_logic;
              wr_busy_o : out std_logic;
	      wr_addr_i    : in  std_logic_vector(6 downto 0);

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
              mwr_len_o   : out std_logic_vector(31 downto 0);
              mwr_count_o : out std_logic_vector(31 downto 0);
              mwr_base_o  : out std_logic_vector(31 downto 0);

					led_switch     : out std_logic;
	      
              -----------------------------------------------------------
	      -- DMA Read Status 5
	      -----------------------------------------------------------	
              cpl_ur_found_i : in std_logic_vector(7 downto 0);
              cpl_ur_tag_i   : in std_logic_vector(7 downto 0);
              cpld_found_i     : in std_logic_vector(31 downto 0);
              cpld_data_size_i : in std_logic_vector(31 downto 0);
              cpld_malformed_i : in std_logic);
    end component BMD_EP_MEM_ACCESS;

    component BMD_64_RX_ENGINE 
    port(clk   : in std_logic;
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
         req_addr_o : out std_logic_vector(10 downto 0);
    	 req_bar_o  : out std_logic;
                  
	 -- Write RAM control 1 select + 4 out 1 in
	 wr_addr_o : out std_logic_vector(10 downto 0);
	 wr_be_o   : out std_logic_vector(3 downto 0);
         wr_data_o : out std_logic_vector(31 downto 0);
         --- added port to support 64bit
         wr_data_hi_o : out std_logic_vector( 31 downto 0);
         wr_be_hi_o   : out std_logic_vector(3 downto 0);
         --- end adding
         wr_en_o   : out std_logic;
         wr_busy_i : in  std_logic;
         wr_select_o : out std_logic;
	 
         -- DMA read control determine the write address
	 mrd_addr_i : in std_logic_vector (31 downto 0);
	 mrd_base_i : in std_logic_vector (31 downto 0);

    	 -- DMA read Status
         cpl_ur_found_o : out std_logic_vector(7 downto 0);
         cpl_ur_tag_o   : out std_logic_vector(7 downto 0);
         cpld_found_o     : out std_logic_vector(31 downto 0);
         cpld_data_size_o : out std_logic_vector(31 downto 0);
         cpld_malformed_o : out std_logic);
    end component;
    
    component BMD_64_TX_ENGINE 
    port ( clk   : in std_logic;
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
           req_addr_i : in std_logic_vector(10 downto 0);
           req_bar_i : in std_logic;

           -- RAM read control 3+1 select
           rd_addr_o : out std_logic_vector(10 downto 0);
           rd_be_o   : out std_logic_vector(3 downto 0);
           rd_data_i : in  std_logic_vector(31 downto 0);
           --- added port to support 64bit
           rd_data_hi_i : in std_logic_vector( 31 downto 0);
           rd_be_hi_o   : out std_logic_vector(3 downto 0);
           --- end adding
           rd_select_o : out std_logic;    
    	
           init_rst_i : in std_logic;

	   -----------------------------------------------------------
	   -- DMA write Control 6 
	   -----------------------------------------------------------
           mwr_start_i : in  std_logic;
           mwr_len_i   : in  std_logic_vector(31 downto 0);
           mwr_lbe_i   : in  std_logic_vector(3 downto 0); --undefined
           mwr_fbe_i   : in  std_logic_vector(3 downto 0); --undefined
           mwr_addr_i  : in  std_logic_vector(31 downto 0);
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
	   mrd_base_i  : in std_logic_vector(31 downto 0);
           mrd_count_i : in std_logic_vector(31 downto 0);
           mrd_done_i  : in std_logic;
			  			  mrd_suspend_i : in std_logic;
			  mrd_cur_count_o : out std_logic_vector(15 downto 0);
mrd_cur_data_size_o : out std_logic_vector (31 downto 0);
           cfg_interrupt_n_o     : out std_logic;
           cfg_interrupt_rdy_n_i : in  std_logic;
           completer_id_i        : in std_logic_vector(15 downto 0);
           cfg_ext_tag_en_i      : in std_logic;
           cfg_bus_mstr_enable_i : in std_logic);
    end component;
    
    -- Local wires
	 signal rd_data_bmd : std_logic_vector(31 downto 0);
	 signal rd_data_pio : std_logic_vector(31 downto 0);
	 signal rd_data : std_logic_vector(31 downto 0);
    signal rd_data_hi : std_logic_vector(31 downto 0);
	 signal rd_addr : std_logic_vector(10 downto 0);
	 signal rd_be	: std_logic_vector(3 downto 0);
    signal rd_be_hi : std_logic_vector(3 downto 0);
	 signal rd_select : std_logic;


         signal wr_busy_bmd : std_logic;
	 signal wr_busy_pio : std_logic;
	 signal wr_busy     : std_logic;
	 signal wr_data	    : std_logic_vector(31 downto 0);
    signal wr_data_hi   : std_logic_vector(31 downto 0);
	 signal wr_addr     : std_logic_vector(10 downto 0);
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
	 signal req_addr : std_logic_vector(10 downto 0);
	 signal req_bar	 : std_logic;
	 signal req_be	 : std_logic_vector (3 downto 0);

	  signal init_rst : std_logic;
--    signal rd_intr_proc : std_logic;
--    signal wr_intr_proc : std_logic;

	  signal mwr_start : std_logic;
	  signal mwr_done  : std_logic;
	  signal mwr_len   : std_logic_vector(31 downto 0);
      	  signal mwr_addr  : std_logic_vector(31 downto 0);
      	  signal mwr_count : std_logic_vector(31 downto 0);
      	  signal mwr_base  : std_logic_vector(31 downto 0);

	  signal mrd_start : std_logic;
      	  signal mrd_done  : std_logic;
      	  signal mrd_len   : std_logic_vector(31 downto 0);
      	  signal mrd_addr  : std_logic_vector(31 downto 0);
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
	 

begin  -- structural

    --
    -- ENDPOINT MEMORY : 
    -- 
	 
  EP_MEM : PIO_EP_MEM_ACCESS
     port map (

     clk => clk,                           -- I
     rst_n => rst_n,                       -- I

     -- Read Port

      rd_addr_i => rd_addr,                 -- I [10:0]
      rd_be_i => rd_be,                     -- I [3:0]
      rd_be_hi_i => rd_be_hi,
      rd_data_o => rd_data_pio,                 -- O [31:0]
      rd_data_hi_o => rd_data_hi,

  -- Write Port

     wr_addr_i => wr_addr,                 -- I [10:0]
     wr_be_i => wr_be,                     -- I [7:0]
     wr_be_hi_i => wr_be_hi,
     wr_data_i => wr_data,                 -- I [31:0]
     wr_data_hi_i => wr_data_hi,
     wr_en_i => wr_en_pio,                     -- I
     wr_busy_o => wr_busy_pio                  -- O

    );

    BMD_EP_MEM_ACCESS_INST : BMD_EP_MEM_ACCESS
        port map ( clk   => clk,        -- I
                   rst_n => rst_n,      -- I

                   cfg_max_rd_req_size  => cfg_max_rd_req_size,   -- I [2:0]
                   cfg_max_payload_size => cfg_max_payload_size,  -- I [2:0]

		 -- Read Port
  		   rd_addr_i => rd_addr(6 downto 0),  -- I [10:0]
                   rd_be_i   => rd_be,    -- I [3:0]
                   rd_data_o => rd_data_bmd,  -- O [31:0]

                   -- Write Port
		   wr_addr_i => wr_addr(6 downto 0), --I [10:0]
                   wr_be_i   => wr_be,    -- I [7:0]
                   wr_data_i => wr_data,  -- I [31:0]
                   wr_en_i   => wr_en_bmd,    -- I
                   wr_busy_o => wr_busy_bmd,  -- O
						 
						 
                   init_rst_o => init_rst,  -- O

                   mrd_start_o => mrd_start,  -- O
                   mrd_done_o  => mrd_done,   -- O
                   mrd_addr_o  => mrd_addr,   -- O [31:0]
                   mrd_len_o   => mrd_len,    -- O [31:0]
                   mrd_count_o => mrd_count,  -- O [31:0]
		   mrd_base_o  => mrd_base,   -- O [31:0]
			mrd_suspend_o => mrd_suspend,
			mrd_cur_count_i => mrd_cur_count,
			mrd_cur_data_size_i => mrd_cur_data_size,

                   mwr_start_o => mwr_start,  -- O
                   mwr_done_i  => mwr_done,   -- I
                   mwr_addr_o  => mwr_addr,   -- O [31:0]
                   mwr_len_o   => mwr_len,    -- O [31:0]
                   mwr_count_o => mwr_count,  -- O [31:0]
                   mwr_base_o  => mwr_base,   -- O [31:0]
						 
						 led_switch  => led_switch,

                   cpl_ur_found_i => cpl_ur_found,  -- I [7:0]
                   cpl_ur_tag_i   => cpl_ur_tag,    -- I [7:0]

                   cpld_found_i     => cpld_found,       -- I [31:0]
                   cpld_data_size_i => cpld_size,        -- I [31:0]
                   cpld_malformed_i => cpld_malformed);  -- I 

		   rd_data <= rd_data_bmd when (rd_select = '0') else rd_data_pio;
	  	   wr_en_bmd <= wr_en when (wr_select = '0') else '0';
	  	   wr_en_pio <= wr_en when (wr_select = '1') else '0';
	  	   wr_busy <= wr_busy_bmd or wr_busy_pio;
	 
    gen_64bit_rx_tx : if bmd_64 = TRUE generate
    begin 
        --
        -- Local-Link Receive Controller
        -- 
        BMD_64_RX_ENGINE_INST : BMD_64_RX_ENGINE
            port map (clk   => clk,     -- I
                      rst_n => rst_n,   -- I

                      init_rst_i => init_rst,  -- I

                      -- LocalLink Rx
                      trn_rd         => trn_rd,          -- I [63/31:0]
                      trn_rrem_n     => trn_rrem_n,      -- I [7:0]
                      trn_rsof_n     => trn_rsof_n,      -- I
                      trn_reof_n     => trn_reof_n,      -- I
                      trn_rsrc_rdy_n => trn_rsrc_rdy_n,  -- I
                      trn_rsrc_dsc_n => trn_rsrc_dsc_n,  -- I
 		      trn_rbar_hit_n => trn_rbar_hit_n,  -- I [6:0]
                      trn_rdst_rdy_n => trn_rdst_rdy_n,  -- O

                      -- Handshake with Tx engine 

                      req_compl_o  => req_compl,   -- O
                      compl_done_i => compl_done,  -- I
							 
                      req_tc_o   => req_tc,    -- O [2:0]
                      req_td_o   => req_td,    -- O
                      req_ep_o   => req_ep,    -- O
                      req_attr_o => req_attr,  -- O [1:0]
                      req_len_o  => req_len,   -- O [9:0]
                      req_rid_o  => req_rid,   -- O [15:0]
                      req_tag_o  => req_tag,   -- O [7:0]
                      req_be_o   => req_be,    -- O [7:0]
		      req_bar_o => req_bar,   -- O
		      req_addr_o => req_addr, -- O [31:0]


		       -- RAM Write Port

                      wr_addr_o => wr_addr,
                      wr_be_o   => wr_be,    -- O [3:0]
                      wr_be_hi_o => wr_be_hi,
                      wr_data_o => wr_data,  -- O [31:0]
                      wr_data_hi_o => wr_data_hi,
                      wr_en_o   => wr_en,    -- O
                      wr_busy_i => wr_busy,  -- I
		      wr_select_o => wr_select, -- O

		      mrd_addr_i  => mrd_addr,   -- I [31:0]
                      mrd_base_i  => mrd_base,   -- I [31:0] 

                      cpl_ur_found_o => cpl_ur_found,  -- O [7:0]
                      cpl_ur_tag_o   => cpl_ur_tag,    -- O [7:0]

                      cpld_found_o     => cpld_found,  -- O [31:0]
                      cpld_data_size_o => cpld_size,  -- O [31:0]
                      cpld_malformed_o => cpld_malformed);  -- O                  

        --
        -- Local-Link Transmit Controller
        -- 
        BMD_64_TX_ENGINE_INST : BMD_64_TX_ENGINE
            port map(clk   => clk,      -- I
                     rst_n => rst_n,    -- I

                     -- LocalLink Tx
                     trn_td         => trn_td,          -- O [63/31:0]
                     trn_trem_n     => trn_trem_n,      -- O [7:0]
                     trn_tsof_n     => trn_tsof_n,      -- O
                     trn_teof_n     => trn_teof_n,      -- O
                     trn_tsrc_dsc_n => trn_tsrc_dsc_n,  -- O
                     trn_tsrc_rdy_n => trn_tsrc_rdy_n,  -- O
                     trn_tdst_dsc_n => trn_tdst_dsc_n,  -- I
                     trn_tdst_rdy_n => trn_tdst_rdy_n,  -- I


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

                     mrd_start_i => mrd_start,  -- I
                     mrd_done_i  => mrd_done,   -- I
                     mrd_addr_i  => mrd_addr,   -- I [31:0]
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
                     mwr_len_i   => mwr_len,    -- I [31:0]
                     mwr_count_i => mwr_count,  -- I [31:0]
                     mwr_base_i  => mwr_base,   -- I [31:0] 
                     mwr_lbe_i   => x"F",
                     mwr_fbe_i   => x"F",                     

                     cfg_interrupt_n_o => cfg_interrupt_n,  -- O
                     cfg_interrupt_rdy_n_i => cfg_interrupt_rdy_n,  -- I

                     completer_id_i        => cfg_completer_id,     -- I [15:0]
                     cfg_ext_tag_en_i      => cfg_ext_tag_en,       -- I
                     cfg_bus_mstr_enable_i => cfg_bus_mstr_enable);  -- I
    end generate gen_64bit_rx_tx;



end structural;

