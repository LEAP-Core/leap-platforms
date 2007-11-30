----------------------------------------------------------------------------------
---- Li, Zheng Intel
----
----------------------------------------------------------------------------------
---- Filename: BMD_EP_MEM_ACCESS.vhd
----
---- Description: Endpoint Memory Access Unit. This module provides access functions
----              to the Endpoint memory aperture.
----
----              Read Access: Module returns data for the specifed address and
----              byte enables selected. 
---- 
----              Write Access: Module accepts data, byte enables and updates
----              data when write enable is asserted. Modules signals write busy 
----              when data write is in progress. 
----
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library work;
use work.bmd_pak.all;

entity BMD_EP_MEM_ACCESS is
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

          init_rst_o : out std_logic;
--          rd_intr_proc_o : out std_logic;
--          wr_intr_proc_o : out std_logic;

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

          cpl_ur_found_i : in std_logic_vector(7 downto 0);
          cpl_ur_tag_i   : in std_logic_vector(7 downto 0);
			 
			 led_switch     : out std_logic;

          cpld_found_i     : in std_logic_vector(31 downto 0);
          cpld_data_size_i : in std_logic_vector(31 downto 0);
          cpld_malformed_i : in std_logic);
    
end BMD_EP_MEM_ACCESS;

architecture rtl of BMD_EP_MEM_ACCESS is
    component BMD_EP_MEM 
        port ( clk   : in std_logic;
               rst_n : in std_logic;

               cfg_max_rd_req_size  : in  std_logic_vector(2 downto 0);
               cfg_max_payload_size : in  std_logic_vector(2 downto 0);
               rd_a_i                  : in  std_logic_vector(6 downto 0);
					wr_a_i					: in std_logic_vector(6 downto 0);
               wr_en_i              : in  std_logic;
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

--	       wr_intr_proc_o : out std_logic;
--               rd_intr_proc_o : out std_logic;

               cpl_ur_found_i : in std_logic_vector(7 downto 0);
               cpl_ur_tag_i   : in std_logic_vector(7 downto 0);
					
				  led_switch     : out std_logic;

               cpld_found_i     : in std_logic_vector(31 downto 0);
               cpld_data_size_i : in std_logic_vector(31 downto 0);
               cpld_malformed_i : in std_logic);
    end component BMD_EP_MEM;

--signal mem_rd_data : std_logic_vector(31 downto 0);
--    signal w_pre_wr_data : std_logic_vector(31 downto 0);
--
--    signal mem_write_en : std_logic;
--    signal pre_wr_data : std_logic_vector(31 downto 0);
--    signal mem_wr_data : std_logic_vector(31 downto 0);
--
--
--    signal mem_addr : std_logic_vector(6 downto 0); 
--
--    signal w_pre_wr_data_b3 : std_logic_vector(7 downto 0);
--    signal w_pre_wr_data_b2 : std_logic_vector(7 downto 0);
--    signal w_pre_wr_data_b1 : std_logic_vector(7 downto 0);
--    signal w_pre_wr_data_b0 : std_logic_vector(7 downto 0);
--
--    signal w_wr_data_b3 : std_logic_vector(7 downto 0);
--    signal w_wr_data_b2 : std_logic_vector(7 downto 0);
--    signal w_wr_data_b1 : std_logic_vector(7 downto 0);
--    signal w_wr_data_b0 : std_logic_vector(7 downto 0);
--
--    type mem_state_type is (BMD_MEM_ACCESS_WR_RST, --BMD_MEM_ACCESS_WR_WAIT,
--                            BMD_MEM_ACCESS_WR_READ, BMD_MEM_ACCESS_WR_WRITE);
--    signal wr_mem_state : mem_state_type;
    
begin  -- rtl
    ------------------------------------------------------------------
    -- Memory Write Controller 
    ------------------------------------------------------------------

----    mem_addr <= wr_addr_i when wr_en_i = '1' or wr_mem_state /= BMD_MEM_ACCESS_WR_RST or mem_write_en = '1' else rd_addr_i; 
--
--    ------------------------------------------------------------------
--    -- Extract current data bytes. These need to be swizzled
--    -- memory storage format :
--    -- data[31:0] <= byte(3) & byte(2) & byte(1) & byte(0);
--    ------------------------------------------------------------------
--
--    w_pre_wr_data_b3 <= pre_wr_data(31 downto 24);
--    w_pre_wr_data_b2 <= pre_wr_data(23 downto 16);
--    w_pre_wr_data_b1 <= pre_wr_data(15 downto 08);
--    w_pre_wr_data_b0 <= pre_wr_data(07 downto 00);
--
--    ------------------------------------------------------------------
--    -- Extract new data bytes from payload
--    -- TLP Payload format : 
--    -- data <= byte(0) & byte(2) & byte(1) & byte(3);
--    ------------------------------------------------------------------
--
--    w_wr_data_b3 <= wr_data_i(7 downto 0);
--    w_wr_data_b2 <= wr_data_i(15 downto 8);
--    w_wr_data_b1 <= wr_data_i(23 downto 16);
--    w_wr_data_b0 <= wr_data_i(31 downto 24);
--
--    process (clk, rst_n)
--    begin
--        if rst_n = '0' then
--            pre_wr_data <= (others => '0');  
--            mem_write_en <= '0';  
--            mem_wr_data <= (others => '0');
--            wr_mem_state <= BMD_MEM_ACCESS_WR_RST;
--        elsif rising_edge(clk) then
--            -- default
--            mem_write_en <= '0';
--            
--            case wr_mem_state is
--                when BMD_MEM_ACCESS_WR_RST =>
--                    if wr_en_i = '1' then -- read state
--                        wr_mem_state <= BMD_MEM_ACCESS_WR_READ ;
--                    else
--                        wr_mem_state <= BMD_MEM_ACCESS_WR_RST;
--                    end if;
--                when BMD_MEM_ACCESS_WR_READ =>
--                    wr_mem_state <= BMD_MEM_ACCESS_WR_WRITE;
--                    pre_wr_data  <= mem_rd_data; 
--                when BMD_MEM_ACCESS_WR_WRITE =>
--                -------------------------------------------------------
--                -- Merge new enabled data and write target location
--                -------------------------------------------------------
--                    mem_write_en <= '1';
--                    wr_mem_state <= BMD_MEM_ACCESS_WR_RST;
--                    if wr_be_i(3) = '1' then
--                        mem_wr_data(31 downto 24) <= w_wr_data_b3;
--                    else
--                        mem_wr_data(31 downto 24) <= w_pre_wr_data_b3;
--                    end if;
--                    if wr_be_i(2) = '1' then
--                        mem_wr_data(23 downto 16) <= w_wr_data_b2;
--                    else
--                        mem_wr_data(23 downto 16) <= w_pre_wr_data_b2;
--                    end if;
--                    if wr_be_i(1) = '1' then
--                        mem_wr_data(15 downto 8) <= w_wr_data_b1;
--                    else
--                        mem_wr_data(15 downto 8) <= w_pre_wr_data_b1;
--                    end if;
--                    if wr_be_i(0) = '1' then
--                        mem_wr_data(7 downto 0) <= w_wr_data_b0;
--                    else
--                        mem_wr_data(7 downto 0) <= w_pre_wr_data_b0;
--                    end if;
--            end case;
--        end if;
--    end process;
--
--    -------------------------------------------------------------------
--    -- Write controller busy 
--    -------------------------------------------------------------------
--
--    wr_busy_o <= '1' when (wr_en_i = '1' or
--                 (wr_mem_state /= BMD_MEM_ACCESS_WR_RST)) else '0';
--
--    -------------------------------------------------------------------
--    -- Memory Read Controller
--    -------------------------------------------------------------------
--
--    -- Handle Read byte enables 
--
--    rd_data_o(31 downto 24) <= mem_rd_data(7 downto 0) when rd_be_i(0) = '1'
--                               else (others => '0');
--    rd_data_o(23 downto 16) <= mem_rd_data(15 downto 8) when rd_be_i(1) = '1'
--                               else (others => '0');
--    rd_data_o(15 downto 8) <= mem_rd_data(23 downto 16) when rd_be_i(2) = '1'
--                               else (others => '0');
--    rd_data_o(7 downto 0) <= mem_rd_data(31 downto 24) when rd_be_i(3) = '1'
--                               else (others => '0');

    wr_busy_o <= '0';
	 BMD_EP_MEM_INST:  BMD_EP_MEM
        port map( clk   => clk,
                  rst_n => rst_n,

                  cfg_max_rd_req_size  => cfg_max_rd_req_size,   -- I (2   : 0)
                  cfg_max_payload_size => cfg_max_payload_size,  -- I (2 : 0)

                  wr_a_i     => wr_addr_i,  -- I (6 : 0)
						rd_a_i => rd_addr_i,
                  wr_en_i => wr_en_i,          -- I
                  rd_d_o  => rd_data_o,           -- O (31      : 0)
                  wr_d_i  => wr_data_i,           -- I (31      : 0)

                  init_rst_o => init_rst_o,  -- O

                  mrd_start_o => mrd_start_o,  -- O
                  mrd_done_o  => mrd_done_o,   -- O
                  mrd_addr_o  => mrd_addr_o,   -- O (31   : 0)
                  mrd_len_o   => mrd_len_o,    -- O (31     : 0)
                  mrd_count_o => mrd_count_o,  -- O (31 : 0)
						mrd_base_o  => mrd_base_o,   -- O (31   : 0)
						mrd_suspend_o => mrd_suspend_o,
						mrd_cur_count_i => mrd_cur_count_i,
						mrd_cur_data_size_i => mrd_cur_data_size_i,

                  mwr_start_o => mwr_start_o,  -- O
                  mwr_done_i  => mwr_done_i,   -- I
                  mwr_addr_o  => mwr_addr_o,   -- O (31   : 0)
                  mwr_len_o   => mwr_len_o,    -- O (31     : 0)
                  mwr_count_o => mwr_count_o,  -- O (31 : 0)
                  mwr_base_o  => mwr_base_o,   -- O (31   : 0)

--		  wr_intr_proc_o => wr_intr_proc_o,
--		  rd_intr_proc_o => rd_intr_proc_o,

                  cpl_ur_found_i => cpl_ur_found_i,  -- I
                  cpl_ur_tag_i   => cpl_ur_tag_i,    -- I (7 : 0)
						
						led_switch => led_switch,

                  cpld_found_i     => cpld_found_i,       -- I (31         : 0)
                  cpld_data_size_i => cpld_data_size_i,   -- I (31 : 0)
                  cpld_malformed_i => cpld_malformed_i);  -- I

end rtl;
