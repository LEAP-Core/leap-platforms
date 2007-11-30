----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
---- Filename: BMD.vhd
---- Li, Zheng Intel
---- Description: Bus Master Device (BMD) Module
----              
----              The entity BMD_64 is used for 64 bit interface.
----              The entity BMD_32 is used for 32 bit interface.
----
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library work;
use work.bmd_pak.all;

entity BMD is
    
    port (
        
	trn_clk              : in  std_logic;
        trn_reset_n          : in  std_logic;
        trn_lnk_up_n         : in  std_logic;
        
        -- 8 
	trn_td               : out std_logic_vector(msb_64_32 downto 0);
        trn_trem_n           : out std_logic_vector(7 downto 0);
        trn_tsof_n           : out std_logic;
        trn_teof_n           : out std_logic;
        trn_tsrc_rdy_n       : out std_logic;
        trn_tsrc_dsc_n       : out std_logic;
        trn_tdst_rdy_n       : in  std_logic;
        trn_tdst_dsc_n       : in  std_logic;
        
        -- 8
	trn_rd               : in  std_logic_vector(msb_64_32 downto 0);
        trn_rrem_n           : in  std_logic_vector(7 downto 0);
        trn_rsof_n           : in  std_logic;
        trn_reof_n           : in  std_logic;
        trn_rsrc_rdy_n       : in  std_logic;
        trn_rsrc_dsc_n       : in  std_logic;
	trn_rbar_hit_n       : in  std_logic_vector (6 downto 0);
        trn_rdst_rdy_n       : out std_logic;
		  
		  led_switch     : out std_logic;

        -- 7
        cfg_interrupt_n      : out std_logic;
        cfg_interrupt_rdy_n  : in  std_logic;
        cfg_completer_id     : in  std_logic_vector(15 downto 0);
        cfg_ext_tag_en       : in  std_logic;
        cfg_bus_mstr_enable  : in  std_logic;
        cfg_max_payload_size : in  std_logic_vector(2 downto 0);
        cfg_max_rd_req_size  : in  std_logic_vector(2 downto 0));

end BMD;

architecture structural of BMD is
    component BMD_EP
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
            trn_rbar_hit_n : in  std_logic_vector(6 downto 0);
            trn_rdst_rdy_n : out std_logic;
				
				led_switch     : out std_logic;

            cfg_interrupt_n      : out std_logic;
            cfg_interrupt_rdy_n  : in  std_logic;
            cfg_completer_id     : in  std_logic_vector(15 downto 0);
            cfg_ext_tag_en       : in  std_logic;
            cfg_max_rd_req_size  : in  std_logic_vector(2 downto 0);
            cfg_max_payload_size : in  std_logic_vector(2 downto 0);
            cfg_bus_mstr_enable  : in  std_logic);
    end component;

    signal bmd_reset_n : std_logic;
begin  -- structural

    bmd_reset_n <= trn_reset_n and not trn_lnk_up_n;
    
    BMD_EP_INST : BMD_EP
        port map( clk   => trn_clk,      -- I
                  rst_n => bmd_reset_n,  -- I

                  trn_td         => trn_td,          -- O [63/31:0]
                  trn_trem_n     => trn_trem_n,      -- O [7:0]
                  trn_tsof_n     => trn_tsof_n,      -- O
                  trn_teof_n     => trn_teof_n,      -- O
                  trn_tsrc_rdy_n => trn_tsrc_rdy_n,  -- O
                  trn_tsrc_dsc_n => trn_tsrc_dsc_n,  -- O
                  trn_tdst_rdy_n => trn_tdst_rdy_n,  -- I
                  trn_tdst_dsc_n => trn_tdst_dsc_n,  -- I

                  trn_rd         => trn_rd,          -- I [63/31:0]
                  trn_rrem_n     => trn_rrem_n,      -- I
                  trn_rsof_n     => trn_rsof_n,      -- I
                  trn_reof_n     => trn_reof_n,      -- I
                  trn_rsrc_rdy_n => trn_rsrc_rdy_n,  -- I
                  trn_rsrc_dsc_n => trn_rsrc_dsc_n,  -- I
         	  trn_rbar_hit_n => trn_rbar_hit_n,  -- I
                  trn_rdst_rdy_n => trn_rdst_rdy_n,  -- O
						
						led_switch     => led_switch,

                  
                  cfg_interrupt_n     => cfg_interrupt_n,      -- O
                  cfg_interrupt_rdy_n => cfg_interrupt_rdy_n,  -- I
                  cfg_completer_id => cfg_completer_id,  -- I [15:0]
                  cfg_ext_tag_en       => cfg_ext_tag_en,        -- I
                  cfg_max_payload_size => cfg_max_payload_size,  -- I [2:0]
                  cfg_max_rd_req_size  => cfg_max_rd_req_size,   -- I [2:0]
                  cfg_bus_mstr_enable => cfg_bus_mstr_enable );  -- I



end structural;   
