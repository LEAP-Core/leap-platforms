----------------------------------------------------------------------------------
----
----
----------------------------------------------------------------------------------
---- Filename: BMD_64_TX_ENGINE.vhd
---- Li, Zheng Intel
---- Description: 64 bit Local-Link Transmit Unit.
----
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.bmd_pak.all;

entity BMD_64_TX_ENGINE is
    port ( clk   : in std_logic;
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

           req_tc_i   : in std_logic_vector(2 downto 0);
           req_td_i   : in std_logic;
           req_ep_i   : in std_logic;
           req_attr_i : in std_logic_vector(1 downto 0);
           req_len_i  : in std_logic_vector(9 downto 0);
           req_rid_i  : in std_logic_vector(15 downto 0);
           req_tag_i  : in std_logic_vector(7 downto 0);
           req_be_i   : in std_logic_vector(3 downto 0);
           req_addr_i : in std_logic_vector(10 downto 0);
    	   req_bar_i  : in std_logic;

    	   
    	  -- read control 5

           rd_addr_o : out std_logic_vector(10 downto 0);
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
           mrd_count_i : in std_logic_vector(31 downto 0);
           mrd_base_i  : in std_logic_vector(31 downto 0);
           mrd_done_i  : in std_logic; --no use signal

           cfg_interrupt_n_o     : out std_logic;
           cfg_interrupt_rdy_n_i : in  std_logic;

           completer_id_i        : in std_logic_vector(15 downto 0);
           cfg_ext_tag_en_i      : in std_logic;
           cfg_bus_mstr_enable_i : in std_logic);
    
end BMD_64_TX_ENGINE;

architecture rtl of BMD_64_TX_ENGINE is

--      component ila
--    port
--    (
--      control     : in    std_logic_vector(35 downto 0);
--      clk         : in    std_logic;
--      trig0       : in    std_logic_vector(49 downto 0)
--    );
--  end component;
--  
--    component icon
--    port
--    (
--      control0    :   out std_logic_vector(35 downto 0)
--    );
--  end component;

    component BMD_INTR_CTRL
        port (clk   : in std_logic;
              rst_n : in std_logic;

              init_rst_i : in std_logic;

              mrd_done_i : in std_logic;
              mwr_done_i : in std_logic;

              cfg_interrupt_rdy_n_i : in  std_logic;
              cfg_interrupt_n_o     : out std_logic);
    end component;

    constant BMD_64_CPLD_FMT_TYPE : std_logic_vector(6 downto 0) := "1001010";
    constant BMD_64_MWR_FMT_TYPE  : std_logic_vector(6 downto 0) := "1000000";
    constant BMD_64_MRD_FMT_TYPE  : std_logic_vector(6 downto 0) := "0000000";

    type bmd_64_tx_state_type is (BMD_64_TX_RST_STATE,
   				  BMD_64_TX_CPLD_QW1,
				  BMD_64_TX_CPLD_WIT, 
				  BMD_64_TX_MWR_QW1,
				  BMD_64_TX_MWR_QWNH, 
				  BMD_64_TX_MWR_QWNL,
				  BMD_64_TX_MRD_QW1);
    signal bmd_64_tx_state : bmd_64_tx_state_type;
    
----    -----chipscope------
----    
--      signal control    : std_logic_vector(35 downto 0);
-- -- signal clk        : std_logic;
--  signal trig0      : std_logic_vector(49 downto 0);
----    ----------

    -- DMA read
    signal mwr_done_internal : std_logic;
    signal mrd_done : std_logic;
    signal cur_rd_count : std_logic_vector(15 downto 0);
	 signal cur_data_size : std_logic_vector (31 downto 0);
    signal mrd_len_byte : std_logic_vector(11 downto 0);
    signal tmrd_addr : std_logic_vector(31 downto 0);
    signal rmrd_count_sub : std_logic_vector(15 downto 0);

    signal serv_mrd : std_logic;



    -- DMA write

    signal compl_done_internal : std_logic;
    signal req_compl_q : std_logic;
    signal cur_wr_count : std_logic_vector(15 downto 0);
	 signal cur_wr_count_eq_zero : std_logic;
    signal cur_mwr_dw_count : std_logic_vector(9 downto 0);
    signal mwr_len_byte : std_logic_vector(11 downto 0);
    signal tmwr_addr : std_logic_vector(31 downto 0);
    signal rmwr_count : std_logic_vector(15 downto 0);
    signal cpld_addr : std_logic_vector(10 downto 0);
	 signal cpld_addr_plus : std_logic_vector(10 downto 0);
    signal serv_mwr : std_logic;
    signal rd_data_tmp : std_logic_vector(31 downto 0);
    signal rd_data_tmp_hi: std_logic_vector(31 downto 0);
	 signal rd_data_tmp1 : std_logic_vector(31 downto 0);
    signal rd_data_hi_1 : std_logic_vector(31 downto 0);
    signal rd_data_hi_2 : std_logic_vector(31 downto 0);
    signal rd_data_sel : std_logic;

	 signal dst_rdy_n: std_logic;

    -- Read Completion
    signal byte_count : std_logic_vector(11 downto 0);
    signal lower_addr : std_logic_vector(6 downto 0);

    signal cfg_bm_en : std_logic;
    signal mwr_addr  : std_logic_vector(31 downto 0);
    signal mrd_addr  : std_logic_vector(31 downto 0);

    
begin  -- rtl

    mwr_done_o <= mwr_done_internal;
    compl_done_o <= compl_done_internal;

    cfg_bm_en <= cfg_bus_mstr_enable_i;
--    cfg_bm_en <= '1';
    mwr_addr <= mwr_addr_i;
    mrd_addr <= mrd_addr_i;
	 mrd_cur_count_o <= cur_rd_count;
	 mrd_cur_data_size_o <= cur_data_size;

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

    BMD_INTR_CTRL_inst: BMD_INTR_CTRL
        port map(clk                   => clk,
              rst_n                 => rst_n,
              init_rst_i            => init_rst_i,
              mrd_done_i            => mrd_done_i,
              mwr_done_i            => mwr_done_internal,
              cfg_interrupt_rdy_n_i => cfg_interrupt_rdy_n_i,
              cfg_interrupt_n_o     => cfg_interrupt_n_o);

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
      		rd_addr_o <= mwr_base_i(12 downto 2);
				rd_be_o <= x"F";
				rd_be_hi_o <= x"F";
				rd_select_o <= '1';
		elsif (bmd_64_tx_state = BMD_64_TX_RST_STATE and req_compl_q = '1') or bmd_64_tx_state = BMD_64_TX_CPLD_QW1 then
			    rd_addr_o <= req_addr_i;
			    rd_be_o <= req_be_i;
			    rd_be_hi_o <= x"0";
			    rd_select_o <= req_bar_i;
		else 
				rd_addr_o <= cpld_addr;
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
         cur_data_size	         <= (others => '0');
         tmrd_addr               <= (others => '0');
         tmwr_addr               <= (others => '0');
         serv_mwr                <= '1';
         serv_mrd                <= '1';
         bmd_64_tx_state         <= BMD_64_TX_RST_STATE;
         dst_rdy_n               <= '0';
         cpld_addr               <= (others => '0');
         cpld_addr_plus          <= (others => '0');
         rd_data_tmp             <= (others => '0');
--         rd_data_tmp_hi          <= (others => '0');
         rd_data_sel             <= '0';
         rd_data_hi_1            <= (others => '0');
         rd_data_hi_2            <= (others => '0');
      
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
--            rd_data_tmp_hi          <= (others => '0');
            rd_data_sel             <= '0';
            rd_data_hi_1            <= (others => '0');
            rd_data_hi_2            <= (others => '0');
            
            
         else
            case bmd_64_tx_state is
               when BMD_64_TX_RST_STATE =>
                  compl_done_internal       <= '0';

                    -- PIO read completions always get highest priority

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

                     bmd_64_tx_state   <= BMD_64_TX_CPLD_QW1;

                  elsif (mwr_start_i = '1' and mwr_done_internal = '0' and
                        serv_mwr = '1' and trn_tdst_dsc_n = '1' and 
                        cfg_bm_en = '1') then
                     trn_tsof_n       <= '0';
                     trn_teof_n       <= '1';
                     trn_tsrc_rdy_n   <= '0';
                     -- trn_td
                     ---------------------------------------------------
                     trn_td(63 downto 16) <= ( '0' &  --1
                                                 BMD_64_MWR_FMT_TYPE &  --7
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
                        tmwr_addr       <= mwr_addr;
                        cpld_addr <= mwr_base_i(13 downto 3) + 1;
                        rd_data_hi_1 <= rd_data_hi_i;
                        rd_data_sel <= '0';
--                        cpld_addr_plus <= mwr_base_i(12 downto 2) + 2;
                     else 
                        tmwr_addr       <= tmwr_addr + mwr_len_byte;
                        cpld_addr <= cpld_addr + 1;
                        
--                        cpld_addr_plus <= cpld_addr_plus + 1;						 
                     end if;
                     
--                     rd_data_hi_1 <= rd_data_hi_i;
--                     rd_data_sel <= '0';

                     -- Round robin
                     if (mrd_start_i = '1' and mrd_done = '0') then
                        serv_mwr        <= '0';
                        serv_mrd        <= '1';
                     else
                        serv_mwr        <= '1';
                        serv_mrd        <= '0';
                     end if;

                     bmd_64_tx_state   <= BMD_64_TX_MWR_QW1;
                     dst_rdy_n <= '0';
                
                  elsif (mrd_start_i = '1' and mrd_done = '0' and
                          serv_mrd = '1' and trn_tdst_dsc_n = '1' and
                          cfg_bm_en = '1' and mrd_suspend_i = '0') then
             
                     trn_tsof_n       <= '0';
                     trn_teof_n       <= '1';
                     trn_tsrc_rdy_n   <= '0';
                     -- trn_td
                     ---------------------------------------------------
                     trn_td(63 downto 16) <= ( '0' &  --1
                                                 BMD_64_MRD_FMT_TYPE &  --7
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
                        tmrd_addr       <= mrd_addr;
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
               
               when BMD_64_TX_CPLD_QW1 =>
                  if (trn_tdst_rdy_n = '0' and trn_tdst_dsc_n = '1') then
                     trn_tsof_n       <= '1';
                     trn_teof_n       <= '0';
                     trn_tsrc_rdy_n   <= '0';
                     trn_td           <= ( req_rid_i & 
                                            req_tag_i &
                                            '0' &
                                            lower_addr &
                                            rd_data_i );

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
                     bmd_64_tx_state  <= BMD_64_TX_RST_STATE;
                  else
                     bmd_64_tx_state  <= BMD_64_TX_CPLD_WIT;
                  end if;

               when BMD_64_TX_MWR_QW1 =>

                  if (trn_tdst_rdy_n = '0' and trn_tdst_dsc_n = '1') then
                     trn_tsof_n       <= '1';
                     if dst_rdy_n = '0' then 
                        trn_td  <= (tmwr_addr(31 downto 2) & "00" & rd_data_i); --edit
                        rd_data_hi_1 <= rd_data_hi_i;
                        rd_data_hi_2 <= rd_data_hi_2;
                     else  
                        trn_td  <= (tmwr_addr(31 downto 2) & "00" & rd_data_tmp);
                        rd_data_hi_1 <= rd_data_tmp_hi;
                        rd_data_hi_2 <= rd_data_hi_2;
                     end if;
                     
--                     rd_data_hi_1 <= rd_data_hi_i;
                     
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
							
                     trn_tsrc_rdy_n   <= '0';

                     if cur_mwr_dw_count = "0000000001" then
                        trn_teof_n       <= '0';
                        cur_mwr_dw_count <= cur_mwr_dw_count - 1; 
                        trn_trem_n       <= (others => '0');
                        bmd_64_tx_state  <= BMD_64_TX_RST_STATE;										  
                     else
                        cur_mwr_dw_count <= cur_mwr_dw_count - 1; 
                        trn_trem_n       <= (others => '1');
--                        bmd_64_tx_state  <= BMD_64_TX_MWR_QWNH;
                        bmd_64_tx_state <= BMD_64_TX_MWR_QWNL;
                        cpld_addr <= cpld_addr + 1;
--                        cpld_addr_plus <= cpld_addr_plus +1;
                     end if;

                  elsif trn_tdst_dsc_n = '0' then
                     bmd_64_tx_state    <= BMD_64_TX_RST_STATE;
                     trn_tsrc_dsc_n     <= '0';
                  
                  else
                     bmd_64_tx_state    <= BMD_64_TX_MWR_QW1;
							if dst_rdy_n = '1' then
                        rd_data_tmp <= rd_data_tmp;
--                        rd_data_hi_1 <= rd_data_hi_1;
                        rd_data_tmp_hi <= rd_data_tmp_hi;
							else
								rd_data_tmp <= rd_data_i;
                        rd_data_tmp_hi <= rd_data_hi_i;
--                        rd_data_hi_2 <= rd_data_hi_i;
--                        rd_data_sel <= '0';
								dst_rdy_n <= '1';
							end if;					
						end if;
                  
               when BMD_64_TX_MWR_QWNH =>
--                  if (trn_tdst_rdy_n = '0' and trn_tdst_dsc_n = '1') then
--                     trn_tsrc_rdy_n   <= '1';			
--                     if cur_mwr_dw_count /= "0000000001"  then 
--                        cpld_addr <= cpld_addr_plus;
--                        cpld_addr_plus <= cpld_addr_plus + 1;
--                     else 
--                        cpld_addr <= cpld_addr;
--                     end if;
--
--                     if dst_rdy_n = '0' then
--                        rd_data_tmp <= rd_data_i;
--                     else
--                        rd_data_tmp <= rd_data_tmp1;
--                     end if;
--
--                     bmd_64_tx_state <= BMD_64_TX_MWR_QWNL;
--                     dst_rdy_n <= '0';
--                  elsif trn_tdst_dsc_n = '0' then
--                     bmd_64_tx_state    <= BMD_64_TX_RST_STATE;
--                     trn_tsrc_dsc_n     <= '0';
--                  else
--                     bmd_64_tx_state    <= BMD_64_TX_MWR_QWNH;
--                     if dst_rdy_n = '1' then
--                        rd_data_tmp1 <= rd_data_tmp1;
--                     else
--                        rd_data_tmp1 <= rd_data_i;
--                        dst_rdy_n <= '1';
--                     end if;
--                  end if;
                  if (trn_tdst_rdy_n = '0' and trn_tdst_dsc_n = '1') then
                      if rd_data_sel = '0' then
                          trn_td <= (rd_data_hi_1 & x"D0DAD0DA");
                      else
                          trn_td <= (rd_data_hi_2 & x"D0DAD0DA");
                      end if;
                      trn_trem_n <= x"0F";
                      trn_teof_n <= '0';
                      cur_mwr_dw_count <= cur_mwr_dw_count - 1;
                      if cur_wr_count = x"00000000" then
                          mwr_done_internal <= '1';
                      end if;
                      bmd_64_tx_state <= BMD_64_TX_RST_STATE;
                      rd_data_hi_1 <= rd_data_hi_i;
                      rd_data_sel <= '0';
                  elsif trn_tdst_dsc_n = '0' then
                      bmd_64_tx_state <= BMD_64_TX_RST_STATE;
                      trn_tsrc_dsc_n <= '0';
                  else
                      bmd_64_tx_state <= BMD_64_TX_MWR_QWNH;                     
                  end if;
		
               when BMD_64_TX_MWR_QWNL =>

                  if trn_tdst_rdy_n = '0' and trn_tdst_dsc_n = '1' then
                     trn_tsrc_rdy_n   <= '0';
                     dst_rdy_n <= '0';
                     if cur_mwr_dw_count = "0000000001" then
                        if rd_data_sel = '0' then
                           if dst_rdy_n = '0' then
                              trn_td <= (rd_data_hi_1 & rd_data_i);
                              rd_data_hi_2 <= rd_data_hi_i;      
--                              rd_data_hi_1 <= rd_data_hi_i;                         
                           else
                              trn_td <= (rd_data_hi_1 & rd_data_tmp);
                              rd_data_hi_2 <= rd_data_tmp_hi;
--                              rd_data_hi_1 <= rd_data_tmp_hi;
                           end if;
--                           rd_data_hi_2 <= rd_data_hi_i;
                           rd_data_sel <= '1';
                        else
                           if dst_rdy_n = '0' then
                              trn_td <= (rd_data_hi_2 & rd_data_i);
                              rd_data_hi_1 <= rd_data_hi_i;
--                              rd_data_hi_2 <= rd_data_hi_i;
                           else
                              trn_td <= (rd_data_hi_2 & rd_data_tmp);
--                              rd_data_hi_2 <= rd_data_tmp_hi;
                              rd_data_hi_1 <= rd_data_tmp_hi;
                           end if;
--                           rd_data_hi_1 <= rd_data_hi_i;
                           rd_data_sel <= '0';
                        end if;
                        --trn_td           <= (rd_data_tmp & x"D0DAD0DA");
                        trn_trem_n       <= x"0F";
                        trn_teof_n       <= '0';
                        cur_mwr_dw_count <= cur_mwr_dw_count - 1;
                        if cur_wr_count = x"00000000" then 
                           mwr_done_internal   <= '1'; 
                        end if;

                        cpld_addr <= cpld_addr - 1;
                        bmd_64_tx_state  <= BMD_64_TX_RST_STATE;

                      -- data should be 64bit aligned, then this case will never occured
                      -- in 32bit-address TLPs. actually the logic in this case is currently wrong.
                     elsif (cur_mwr_dw_count = "10") then
								cpld_addr        <= cpld_addr; -- + 1;
--								if dst_rdy_n = '0' then
--									trn_td  <= (rd_data_tmp  & rd_data_i);
--								else
--									trn_td  <= ( rd_data_tmp & rd_data_tmp1);
--								end if;
                        if rd_data_sel = '0' then
                           if dst_rdy_n = '0' then
                              trn_td <= (rd_data_hi_1 & rd_data_i);
                              rd_data_hi_2 <= rd_data_hi_i;      
--                              rd_data_hi_1 <= rd_data_hi_i;                         
                           else
                              trn_td <= (rd_data_hi_1 & rd_data_tmp);
                              rd_data_hi_2 <= rd_data_tmp_hi;
--                              rd_data_hi_1 <= rd_data_tmp_hi;
                           end if;
--                           rd_data_hi_2 <= rd_data_hi_i;
                           rd_data_sel <= '1';
                        else
                           if dst_rdy_n = '0' then
                              trn_td <= (rd_data_hi_2 & rd_data_i);
                              rd_data_hi_1 <= rd_data_hi_i;
--                              rd_data_hi_2 <= rd_data_hi_i;
                           else
                              trn_td <= (rd_data_hi_2 & rd_data_tmp);
--                              rd_data_hi_2 <= rd_data_tmp_hi;
                              rd_data_hi_1 <= rd_data_tmp_hi;
                           end if;
--                           rd_data_hi_1 <= rd_data_hi_i;
                           rd_data_sel <= '0';
                        end if;
--                                trn_td           <= (rd_data_tmp & rd_data_i);
                        trn_trem_n       <= (others => '0');
                        trn_teof_n       <= '0';
                        cur_mwr_dw_count <= cur_mwr_dw_count - 2; 
								if cur_wr_count = x"00000000" then
                           mwr_done_internal   <= '1'; 
                        end if;
                        
                        bmd_64_tx_state  <= BMD_64_TX_RST_STATE;
                        
                     elsif cur_mwr_dw_count = "11" then
                        cpld_addr <= cpld_addr;
                        if rd_data_sel = '0' then
                           if dst_rdy_n = '0' then
                              trn_td <= (rd_data_hi_1 & rd_data_i);
                              rd_data_hi_2 <= rd_data_hi_i;      
--                              rd_data_hi_1 <= rd_data_hi_i;                         
                           else
                              trn_td <= (rd_data_hi_1 & rd_data_tmp);
                              rd_data_hi_2 <= rd_data_tmp_hi;
--                              rd_data_hi_1 <= rd_data_tmp_hi;
                           end if;
--                           rd_data_hi_2 <= rd_data_hi_i;
                           rd_data_sel <= '1';
                        else
                           if dst_rdy_n = '0' then
                              trn_td <= (rd_data_hi_2 & rd_data_i);
                              rd_data_hi_1 <= rd_data_hi_i;
--                              rd_data_hi_2 <= rd_data_hi_i;
                           else
                              trn_td <= (rd_data_hi_2 & rd_data_tmp);
--                              rd_data_hi_2 <= rd_data_tmp_hi;
                              rd_data_hi_1 <= rd_data_tmp_hi;
                           end if;
--                           rd_data_hi_1 <= rd_data_hi_i;
                           rd_data_sel <= '0';
                        end if;
                        bmd_64_tx_state <= BMD_64_TX_MWR_QWNH;   
                     else 
--                        if dst_rdy_n = '0' then
--									trn_td  <= (rd_data_tmp  & rd_data_i);
--								else
--									trn_td  <= ( rd_data_tmp & rd_data_tmp1);
--								end if;
                        if rd_data_sel = '0' then
                           if dst_rdy_n = '0' then
                              trn_td <= (rd_data_hi_1 & rd_data_i);
                              rd_data_hi_2 <= rd_data_hi_i;      
--                              rd_data_hi_1 <= rd_data_hi_i;                         
                           else
                              trn_td <= (rd_data_hi_1 & rd_data_tmp);
                              rd_data_hi_2 <= rd_data_tmp_hi;
--                              rd_data_hi_1 <= rd_data_tmp_hi;
                           end if;
--                           rd_data_hi_2 <= rd_data_hi_i;
                           rd_data_sel <= '1';
                        else
                           if dst_rdy_n = '0' then
                              trn_td <= (rd_data_hi_2 & rd_data_i);
                              rd_data_hi_1 <= rd_data_hi_i;
--                              rd_data_hi_2 <= rd_data_hi_i;
                           else
                              trn_td <= (rd_data_hi_2 & rd_data_tmp);
--                              rd_data_hi_2 <= rd_data_tmp_hi;
                              rd_data_hi_1 <= rd_data_tmp_hi;
                           end if;
--                           rd_data_hi_1 <= rd_data_hi_i;
                           rd_data_sel <= '0';
                        end if;
--										  trn_td           <= (rd_data_tmp & rd_data_i);
                        trn_trem_n       <= (others => '1');
                        cur_mwr_dw_count <= cur_mwr_dw_count - 2;
								cpld_addr <= cpld_addr + 1;--cpld_addr_plus;
--								cpld_addr_plus <= cpld_addr_plus+1;
                        bmd_64_tx_state  <= BMD_64_TX_MWR_QWNL;
                     end if;
                  
                  elsif trn_tdst_dsc_n = '0' then
                     bmd_64_tx_state    <= BMD_64_TX_RST_STATE;
                     trn_tsrc_dsc_n     <= '0';
                  
                  else
                     bmd_64_tx_state    <= BMD_64_TX_MWR_QWNL;
--							if dst_rdy_n = '1' then
--								rd_data_tmp1 <= rd_data_tmp1;
--							else
--								rd_data_tmp1 <= rd_data_i;
--								dst_rdy_n <= '1';
--							end if;
							if dst_rdy_n = '1' then
								rd_data_tmp <= rd_data_tmp;
--                        if rd_data_sel = '0' then
--                           rd_data_hi_2 <= rd_data_hi_2;
--                        else
--                           rd_data_hi_1 <= rd_data_hi_1;
--                        end if;
                        rd_data_tmp_hi <= rd_data_tmp_hi;
							else
								rd_data_tmp <= rd_data_i;
                        rd_data_tmp_hi <= rd_data_hi_i;
--                        if rd_data_sel = '0' then
--                           rd_data_hi_2 <= rd_data_hi_i;
--                        else
--                           rd_data_hi_1 <= rd_data_hi_i;
--                        end if;
								dst_rdy_n <= '1';
							end if;


                  end if;
                  
               when BMD_64_TX_MRD_QW1 =>
                  if trn_tdst_rdy_n = '0' and trn_tdst_dsc_n = '1' then
                     trn_tsof_n       <= '1';
                     trn_teof_n       <= '0';
                     trn_tsrc_rdy_n   <= '0';
                     trn_td           <= (tmrd_addr(31 downto 2) & "00" & x"D0DAD0DA");
                     trn_trem_n       <= x"0F";
                              
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
--
--  i_ila : ila
--    port map
--    (
--      control   => control,
--      clk       => clk,
--      trig0     => trig0
--    );
--    
--     i_icon : icon
--    port map
--    (
--      control0    => control
--    );
-- 
-- 
-- trig0(10 downto 0) <= cpld_addr;
-- trig0(11) <=trn_tdst_rdy_n ;
-- trig0(12) <= trn_tdst_dsc_n;
-- trig0(13) <= dst_rdy_n ;
-- trig0(14) <= cur_wr_count_eq_zero;
-- trig0(24 downto 15) <= cur_mwr_dw_count;
end rtl;
