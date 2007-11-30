----------------------------------------------------------------------------------

----
----------------------------------------------------------------------------------
---- Filename: BMD_64_RX_ENGINE.vhd
---- Li, Zheng Intel
---- Description: 64 bit Local-Link Receive Unit.
----
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library work;
use work.bmd_pak.all;

entity BMD_64_RX_ENGINE is
    port(clk   : in std_logic;
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
         req_addr_o : out std_logic_vector(10 downto 0); --MEM_RD hand shake with TX
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
         wr_addr_o : out std_logic_vector(10 downto 0);
	 			
         mrd_addr_i : in std_logic_vector (31 downto 0);
         mrd_base_i : in std_logic_vector (31 downto 0);

         cpl_ur_found_o : out std_logic_vector(7 downto 0);
         cpl_ur_tag_o   : out std_logic_vector(7 downto 0);
         cpld_found_o     : out std_logic_vector(31 downto 0);
         cpld_data_size_o : out std_logic_vector(31 downto 0);
         cpld_malformed_o : out std_logic);
			
end BMD_64_RX_ENGINE;

architecture rtl of BMD_64_RX_ENGINE is

    type bmd_64_rx_state_type is (
      BMD_64_RX_RST,
    	BMD_64_RX_MEM_RD32_QW1,
      BMD_64_RX_MEM_RD32_WT,
      BMD_64_RX_MEM_WR32_QW1,
      BMD_64_RX_MEM_WR32_WT, 
		BMD_64_RX_CPL_QW1,
      BMD_64_RX_CPLD_QW1, 
		BMD_64_RX_CPLD_QWN, 
		BMD_64_RX_CPLD_QWNT);
    signal bmd_64_rx_state : bmd_64_rx_state_type;
    
    constant BMD_MEM_RD32_FMT_TYPE : std_logic_vector(6 downto 0) := "0000000";
    constant BMD_MEM_WR32_FMT_TYPE : std_logic_vector(6 downto 0) := "1000000";
    constant BMD_CPL_FMT_TYPE      : std_logic_vector(6 downto 0) := "0001010";
    constant BMD_CPLD_FMT_TYPE     : std_logic_vector(6 downto 0) := "1001010";
    
    -- Local Registers
    signal cpld_found_internal : std_logic_vector(31 downto 0); -- How many CPLD
    signal cpld_data_size_internal : std_logic_vector(31 downto 0); --How many dw received, count using packet head
    signal cpl_ur_found_internal : std_logic_vector(7 downto 0);
    signal trn_rdst_rdy_n_internal : std_logic;

    signal cpld_real_size : std_logic_vector(9 downto 0);
    signal cpld_tlp_size  : std_logic_vector(9 downto 0);
    signal last_be : std_logic_vector(3 downto 0);
      --    signal wr_addr_cal : std_logic_vector (31 downto 0);
	 signal wr_addr : std_logic_vector (10 downto 0);
    signal	wr_data_tmp :  std_logic_vector (31 downto 0);
	 signal wr_eof : std_logic;
    
    signal wr_data_pre1    : std_logic_vector ( 31 downto 0);
    signal wr_data_pre2    : std_logic_vector ( 31 downto 0);
    signal wr_data_sel  : std_logic;
				


begin  -- rtl
    cpld_found_o <= cpld_found_internal;
    cpld_data_size_o <= cpld_data_size_internal;
    cpl_ur_found_o <= cpl_ur_found_internal;
    trn_rdst_rdy_n <= trn_rdst_rdy_n_internal;
--    wr_addr_cal <= trn_rd(63 downto 32) - mrd_addr_i + mrd_base_i;
    wr_addr_o <= wr_addr;
    
--    process (wr_data_sel)
--    begin
--      if wr_data_sel = '0' then
--         wr_data_o <= wr_data_1(31 downto 0);
--         wr_data_hi_o <= wr_data_1 (63 downto 32);
--      else
--         wr_data_o <= wr_data_2(31 downto 0);
--         wr_data_hi_o <= wr_data_2(63 downto 32);
--      end if;
--    end process;
	 
	 
    process (clk, rst_n )
    begin
        if rst_n = '0' then
            bmd_64_rx_state  <= BMD_64_RX_RST;
            trn_rdst_rdy_n_internal   <= '0';
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
        
        elsif rising_edge(clk) then
            -- default
            -- wr_en_o        <= '0';
            -- req_compl_o    <= '0';
            -- trn_rdst_rdy_n_internal <= '0';
 
            if init_rst_i = '1' then
                bmd_64_rx_state  <= BMD_64_RX_RST;
                
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
            end if;
            
            case bmd_64_rx_state is

                when BMD_64_RX_RST =>
                  wr_en_o <= '0';
                  if trn_rsof_n = '0' and  
                     trn_rsrc_rdy_n = '0' and
                     trn_rdst_rdy_n_internal = '0' then
                     
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
                  if trn_reof_n = '0' and trn_rsrc_rdy_n = '0' and
                     trn_rdst_rdy_n_internal = '0' then
                     
                     req_addr_o            <= trn_rd(44 downto 34);
                     req_bar_o		<= trn_rbar_hit_n(0);			 
                     req_compl_o       <= '1';
                     trn_rdst_rdy_n_internal    <= '1';
                     bmd_64_rx_state   <= BMD_64_RX_MEM_RD32_WT;
                  else
                     bmd_64_rx_state   <= BMD_64_RX_MEM_RD32_QW1;
                  end if;
                  
                when BMD_64_RX_MEM_RD32_WT =>
                  if compl_done_i = '1' then
                     bmd_64_rx_state   <= BMD_64_RX_RST;
                     req_compl_o       <= '0';
                     trn_rdst_rdy_n_internal    <= '0';
                  else 
                     req_compl_o       <= '1';
                     trn_rdst_rdy_n_internal    <= '1';
                     bmd_64_rx_state   <= BMD_64_RX_MEM_RD32_WT;
                  end if;
                  
                when BMD_64_RX_MEM_WR32_QW1 =>
                  if trn_reof_n = '0' and trn_rsrc_rdy_n = '0' and 
                     trn_rdst_rdy_n_internal = '0' then
                     wr_addr           <= trn_rd(44 downto 34);
                     wr_data_o        <= trn_rd(31 downto 0);
                     wr_en_o          <= '1';
--                     wr_select_o <= trn_rbar_hit_n(0);
                     trn_rdst_rdy_n_internal   <= '1';
                     bmd_64_rx_state  <= BMD_64_RX_MEM_WR32_WT;
                  else
                     bmd_64_rx_state  <= BMD_64_RX_MEM_WR32_QW1;
                  end if;
                
                when BMD_64_RX_MEM_WR32_WT =>
                  wr_en_o <= '0';
                  if wr_busy_i = '0' then
                     bmd_64_rx_state  <= BMD_64_RX_RST;
                     trn_rdst_rdy_n_internal <= '0';
                  else
                     bmd_64_rx_state  <= BMD_64_RX_MEM_WR32_WT;
                     trn_rdst_rdy_n_internal <= '1';
                  end if;
                     
                when BMD_64_RX_CPL_QW1 =>
                  if trn_reof_n = '0' and trn_rsrc_rdy_n = '0' and 
                     trn_rdst_rdy_n_internal = '0' then
                     cpl_ur_tag_o     <= trn_rd(47 downto 40);
                     bmd_64_rx_state  <= BMD_64_RX_RST;
                  else
                     bmd_64_rx_state  <= BMD_64_RX_CPL_QW1;
                  end if;
                     
                when BMD_64_RX_CPLD_QW1 =>
                  --- CPLD with only 1DW
                  if trn_reof_n = '0' and trn_rsrc_rdy_n = '0' and
                     trn_rdst_rdy_n_internal = '0' then

                     if cpld_found_internal = x"00000001" then 
                        wr_addr <= mrd_base_i(13 downto 3) ; 
                     else 
                        wr_addr <= wr_addr+1; 
                     end if;
                     wr_data_o         <= trn_rd(31 downto 0);
                     wr_select_o      <= '1';
                     wr_be_hi_o <= (others => '0');
                     	 
                     if trn_rrem_n = x"00" then
                        bmd_64_rx_state  <=  BMD_64_RX_RST;
                        wr_en_o          <= '1';
                        trn_rdst_rdy_n_internal   <= '0';
                        if cpld_tlp_size /= "0000000001" then
                           cpld_malformed_o <= '1';
                        end if;
                     else 
                        cpld_malformed_o <= '1';
                     end if;

                  --- wr_en_o deasserted, 
                  
                  elsif trn_rsrc_rdy_n = '0' and 
                        trn_rdst_rdy_n_internal = '0' then
                      
                     if cpld_found_internal = x"00000001"  then 
                        wr_addr <= mrd_base_i(13 downto 3) ; 
                     else 
                        wr_addr <= wr_addr+1; 
                     end if;
                     
                     wr_data_pre1 <= trn_rd(31 downto 0);
                     wr_data_sel <= '0';
                     --wr_data_1(31 downto 0)         <= trn_rd(31 downto 0);
                     wr_select_o      <= trn_rbar_hit_n(0);

                     cpld_real_size   <= cpld_real_size  + 1;
                     bmd_64_rx_state  <= BMD_64_RX_CPLD_QWN;
                     wr_en_o          <= '0';
                     trn_rdst_rdy_n_internal   <= '0';
                  
                  else
                     bmd_64_rx_state   <= BMD_64_RX_CPLD_QW1;
                  end if;
               
               when BMD_64_RX_CPLD_QWN =>
                  
                  if trn_reof_n = '0' and trn_rsrc_rdy_n = '0' and  
                     trn_rdst_rdy_n_internal = '0' then								 								 
                  --- it's the last QW, we should check whether 1DW or 2DW, if only 1DW, the next state will be RST, 
                  --- otherwise, the next state will be a new one to handle the last DW.
                  --- if wr_data_sel = '0'  then
                  ---    wr_data_o <= wr_data_pre1;
                  ---    wr_data_hi_o <= trn_rd(63 downto 32);
                  ---    wr_data_pre2 <= trn_rd(31 downto 0);
                  ---    wr_data_sel <= '1';
                  --- else
                  ---    wr_data_o <= wr_data_pre2;
                  ---    wr_data_hi_o <= trn_rd(63 downto 32);
                  ---    wr_data_pre1 <= trn_rd(31 downto 0);
                  ---    wr_data_sel <= '0';
                  --- end if;
                  --- 
                  --- !!!consider how to address in this new mode!!!
                     if trn_rrem_n = x"0F" then
                        bmd_64_rx_state  <= BMD_64_RX_RST;
                        
                        if wr_data_sel = '0'  then
                           wr_data_o <= wr_data_pre1;
                           wr_data_hi_o <= trn_rd(63 downto 32);
                           wr_data_pre2 <= trn_rd(31 downto 0);
                           wr_data_sel <= '1';
                        else
                           wr_data_o <= wr_data_pre2;
                           wr_data_hi_o <= trn_rd(63 downto 32);
                           wr_data_pre1 <= trn_rd(31 downto 0);
                           wr_data_sel <= '0';
                        end if;      
                        
                        if cpld_real_size /= "0000000001" then               
                           wr_addr <= wr_addr + 1;
                        else
                           wr_addr <= wr_addr;
                        end if;
                        --wr_data_1(31 downto 0)   <= trn_rd(63 downto 32);
                        wr_en_o <= '1';
                        wr_be_o <= last_be;
                        wr_be_hi_o <= "1111";
                        trn_rdst_rdy_n_internal   <= '0';

                        if cpld_tlp_size /= (cpld_real_size + 1) then
                           cpld_malformed_o <= '1';
                        end if;
                        
                     elsif trn_rrem_n = x"00" then
                        bmd_64_rx_state  <= BMD_64_RX_CPLD_QWNT;	

                        if wr_data_sel = '0'  then
                           wr_data_o <= wr_data_pre1;
                           wr_data_hi_o <= trn_rd(63 downto 32);
                           wr_data_pre2 <= trn_rd(31 downto 0);
                           wr_data_sel <= '1';
                        else
                           wr_data_o <= wr_data_pre2;
                           wr_data_hi_o <= trn_rd(63 downto 32);
                           wr_data_pre1 <= trn_rd(31 downto 0);
                           wr_data_sel <= '0';
                        end if;                 
                        
                        if cpld_real_size /= "0000000001" then               
                           wr_addr <= wr_addr + 1;
                        else
                           wr_addr <= wr_addr;
                        end if;
                        --wr_data_1(31 downto 0)   <= trn_rd(63 downto 32);
                        --wr_data_tmp <= trn_rd (31 downto 0);
                        wr_eof <= '1';
                        wr_en_o <= '1';
                        wr_be_o <= "1111";
                        wr_be_hi_o <= "1111";
                        trn_rdst_rdy_n_internal   <= '1';
                        							 
                        
                        if cpld_tlp_size /= (cpld_real_size  + 2) then
                           cpld_malformed_o <= '1';
                        end if;
                     else
                        cpld_malformed_o <= '1';                             
                     end if;
                  elsif trn_rsrc_rdy_n = '0' and trn_rdst_rdy_n_internal = '0' then
                     cpld_real_size   <= cpld_real_size + 2;
                        
                     if cpld_real_size /= "0000000001" then               
                        wr_addr <= wr_addr + 1;
                     else
                        wr_addr <= wr_addr;
                     end if;			 

                     if wr_data_sel = '0'  then
                        wr_data_o <= wr_data_pre1;
                        wr_data_hi_o <= trn_rd(63 downto 32);
                        wr_data_pre2 <= trn_rd(31 downto 0);
                        wr_data_sel <= '1';
                     else
                        wr_data_o <= wr_data_pre2;
                        wr_data_hi_o <= trn_rd(63 downto 32);
                        wr_data_pre1 <= trn_rd(31 downto 0);
                        wr_data_sel <= '0';
                     end if;                 

--                     wr_data_1(31 downto 0)   <= trn_rd(63 downto 32);
--                     wr_data_tmp <= trn_rd(31 downto 0);
                     wr_eof <= '0';

                     wr_en_o <= '1';
                     wr_be_o <= "1111";
                     wr_be_hi_o <= "1111";
                     trn_rdst_rdy_n_internal   <= '0';
                     bmd_64_rx_state  <= BMD_64_RX_CPLD_QWN;
                  
                  else
                     bmd_64_rx_state   <= BMD_64_RX_CPLD_QWN;
                  end if;
                  
               when BMD_64_RX_CPLD_QWNT => --There must be another DW
                  bmd_64_rx_state  <= BMD_64_RX_RST;
                  trn_rdst_rdy_n_internal <= '0';
                  wr_addr <= wr_addr + 1;
 --                 wr_data_1(31 downto 0)   <= wr_data_tmp;
                         if wr_data_sel = '0'  then
                           wr_data_o <= wr_data_pre1;
                           wr_data_hi_o <= trn_rd(63 downto 32);
                           wr_data_pre2 <= trn_rd(31 downto 0);
                           wr_data_sel <= '1';
                        else
                           wr_data_o <= wr_data_pre2;
                           wr_data_hi_o <= trn_rd(63 downto 32);
                           wr_data_pre1 <= trn_rd(31 downto 0);
                           wr_data_sel <= '0';
                        end if;                 
                  if (cpld_tlp_size /= (cpld_real_size  + 2)) then 
                     wr_be_o <= "1111"; 
                  else 
                     wr_be_o <= last_be; 
                  end if;	
                  wr_be_hi_o <= "0000";
                  wr_en_o <= '1';
                  bmd_64_rx_state <= BMD_64_RX_RST;
--                  if wr_eof = '0' then 
--                     bmd_64_rx_state  <= BMD_64_RX_CPLD_QWN;
--                  else
--                     bmd_64_rx_state <= BMD_64_RX_RST;
--                  end if;
            end case;
        end if;
    end process;
end rtl;

