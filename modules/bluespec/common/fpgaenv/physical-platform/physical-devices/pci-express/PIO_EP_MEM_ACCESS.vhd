-- DISCLAIMER OF LIABILITY

-- Li, Zheng Intel
---- Filename: PIO_EP_MEM_ACCESS.vhd
----
---- Description: Endpoint Memory Access Unit. This module provides access functions
----              to the Endpoint memory aperture.
----
----              Read Access: Module returns data for the specifed address and
----              byte enables selected. 
---- 
----              Write Access: Module accepts data and byte enables and updates
----              data when write enable is asserted. Modules signals write busy 
----              write is in progress.
----
----------------------------------------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all;

entity PIO_EP_MEM_ACCESS is port (

  clk          : in std_logic;
  rst_n        : in std_logic;

  --  Read Port

  rd_addr_i    : in std_logic_vector(10 downto 0);
  rd_be_i      : in std_logic_vector(3 downto 0);
  rd_be_hi_i   : in std_logic_vector(3 downto 0);
  rd_data_o    : out std_logic_vector(31 downto 0);
  rd_data_hi_o : out std_logic_vector(31 downto 0);

  --  Write Port
		
  wr_addr_i    : in std_logic_vector(10 downto 0);
  wr_be_i      : in std_logic_vector(3 downto 0);
  wr_be_hi_i   : in std_logic_vector(3 downto 0);
  wr_data_i    : in std_logic_vector(31 downto 0);
  wr_data_hi_i : in std_logic_vector(31 downto 0);
  wr_en_i      : in std_logic;
  wr_busy_o    : out std_logic

);

end PIO_EP_MEM_ACCESS;

architecture rtl of PIO_EP_MEM_ACCESS is

component ram port (

	clka: IN std_logic;
	dina: IN std_logic_VECTOR(63 downto 0);
	addra: IN std_logic_VECTOR(10 downto 0);
	ena: IN std_logic;
	wea: IN std_logic_VECTOR(7 downto 0);
	clkb: IN std_logic;
	addrb: IN std_logic_VECTOR(10 downto 0);
	enb: IN std_logic;
	doutb: OUT std_logic_VECTOR(63 downto 0));

end component;

signal temp : std_logic;
signal wea_i : std_logic_vector (7 downto 0);
signal data_i : std_logic_vector (63 downto 0);
signal data_o : std_logic_vector (63 downto 0);
begin
temp <= (rd_be_i(0) or rd_be_i(1) or rd_be_i(2) or rd_be_i(3) or 
          rd_be_hi_i(0) or rd_be_hi_i(1) or rd_be_hi_i(2) or rd_be_hi_i(3));
wea_i <= wr_be_hi_i & wr_be_i;
data_i <= wr_data_hi_i & wr_data_i;
rd_data_o <= data_o(31 downto 0);
rd_data_hi_o <= data_o(63 downto 32);

ram_inst : ram port map (

clka => clk,
dina => data_i,
addra => wr_addr_i,
ena => wr_en_i,
wea => wea_i,
clkb => clk,
addrb => rd_addr_i,
enb => temp,
doutb => data_o
);
wr_busy_o <= '0';



end; -- PIO_EP_MEM_ACCESS

