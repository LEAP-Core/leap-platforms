-------------------------------------------------------------------------------
-- Title        : CSR Controller
-- Project      : 
-------------------------------------------------------------------------------
-- File         : csr_ctrl.vhd
-- Author       : Wang, Liang  <liang.wang@intel.com>
-- Company      : CTL Beijing, Intel
-- Created      : 2008-10-20
-- Last update  : 2008-10-20
-- Platform     : Virtex 5 vlx110t-ff1136-1
-- Targets      : XC5VLX110T-FF1136-1
-- Simulators   : ModelSim SE 6.2e
-- Synthesizers : XST embedded in ISE
-- Standard     : VHDL'87
-------------------------------------------------------------------------------
-- Description: CSR Controller
-------------------------------------------------------------------------------
-- Copyright (c) 2008 CTL Beijing, Intel
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2008-10-20  1.0      lwang12 Created
-------------------------------------------------------------------------------



library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity csr_ctrl is
  port(
    clk   : in std_logic;
    rst_n : in std_logic;

    hw_chnl_rst : in std_logic;

    -- csr ports for hardware channel application use   
    csr_out_rd_ready : out std_logic;
    csr_out_rd_done  : out std_logic;
    csr_in_rd_en     : in  std_logic;
    csr_in_rd_ack    : in  std_logic;
    csr_out_rd_data  : out std_logic_vector((32 - 1) downto 0);
    csr_in_rd_index  : in  std_logic_vector((8 - 1) downto 0);
    csr_out_wr_ready : out std_logic;
    csr_in_wr_en     : in  std_logic;
    csr_in_wr_data   : in  std_logic_vector((32 - 1) downto 0);
    csr_in_wr_index  : in  std_logic_vector((8 - 1) downto 0);

    --------------system CSR SIGNAL-------------------
    csr_out_h2f_reg0 : out std_logic_vector((32 - 1) downto 0);

    csr_in_f2h_reg0_wr_en : in std_logic;
    csr_in_f2h_reg0       : in std_logic_vector((32 - 1) downto 0);

    -- ports with pcie_rx_wrapper
    mrd32_req_addr : in std_logic_vector(31 downto 0);
    csr_rd_start   : in std_logic;

    mwr32_addr : in std_logic_vector(31 downto 0);
    mwr32_data : in std_logic_vector(31 downto 0);

    csr_wr_start : in std_logic;

    -- ports with pcie_tx_wrapper
    cpld_start     : out std_logic;
    cpld_start_ack : in  std_logic;
    cpld_finish    : in  std_logic;
    mrd32_req_data : out std_logic_vector(31 downto 0);

    -- ports with pcie_bar0
    bar0_wr_addr : out std_logic_vector(7 downto 0);
    bar0_wr_en   : out std_logic;
    bar0_wr_data : out std_logic_vector(31 downto 0);

    bar0_rd_addr : out std_logic_vector(7 downto 0);
    bar0_rd_data : in  std_logic_vector(31 downto 0);

    -- system csr ports with pcie_bar0
    pcie_csr_in_h2f_reg0_wr_en : in  std_logic;
    pcie_csr_in_h2f_reg0       : in  std_logic_vector((32 - 1) downto 0);
    pcie_csr_out_f2h_reg0      : out std_logic_vector((32 - 1) downto 0));
end csr_ctrl;

architecture rtl of csr_ctrl is

  component CSR_BRAM
    port (
      clka  : in  std_logic;
      dina  : in  std_logic_vector(31 downto 0);
      addra : in  std_logic_vector(7 downto 0);
      wea   : in  std_logic_vector(0 downto 0);
      douta : out std_logic_vector(31 downto 0);
      clkb  : in  std_logic;
      dinb  : in  std_logic_vector(31 downto 0);
      addrb : in  std_logic_vector(7 downto 0);
      web   : in  std_logic_vector(0 downto 0);
      doutb : out std_logic_vector(31 downto 0));
  end component;

  component csr_fpga_ctrl
    port (
      clk                   : in  std_logic;
      rst_n                 : in  std_logic;
      hw_chnl_rst           : in  std_logic;
      bram_addr             : out std_logic_vector(7 downto 0);
      bram_din              : out std_logic_vector(31 downto 0);
      bram_dout             : in  std_logic_vector(31 downto 0);
      bram_wen              : out std_logic;
      csr_out_rd_ready      : out std_logic;
      csr_out_rd_done       : out std_logic;
      csr_in_rd_en          : in  std_logic;
      csr_in_rd_ack         : in  std_logic;
      csr_out_rd_data       : out std_logic_vector((32 - 1) downto 0);
      csr_in_rd_index       : in  std_logic_vector((8 - 1) downto 0);
      csr_out_wr_ready      : out std_logic;
      csr_in_wr_en          : in  std_logic;
      csr_in_wr_data        : in  std_logic_vector((32 - 1) downto 0);
      csr_in_wr_index       : in  std_logic_vector((8 - 1) downto 0));
  end component;

  component csr_host_ctrl
    port (
      clk            : in  std_logic;
      rst_n          : in  std_logic;
      hw_chnl_rst    : in  std_logic;
      mrd32_req_addr : in  std_logic_vector(31 downto 0);
      csr_rd_start   : in  std_logic;
      mwr32_addr     : in  std_logic_vector(31 downto 0);
      mwr32_data     : in  std_logic_vector(31 downto 0);
      csr_wr_start   : in  std_logic;
      cpld_start     : out std_logic;
      cpld_start_ack : in  std_logic;
      cpld_finish    : in  std_logic;
      mrd32_req_data : out std_logic_vector(31 downto 0);
      bar0_wr_addr   : out std_logic_vector(7 downto 0);
      bar0_wr_en     : out std_logic;
      bar0_wr_data   : out std_logic_vector(31 downto 0);
      bar0_rd_addr   : out std_logic_vector(7 downto 0);
      bar0_rd_data   : in  std_logic_vector(31 downto 0);
      bram_addr      : out std_logic_vector(7 downto 0);
      bram_din       : out std_logic_vector(31 downto 0);
      bram_dout      : in  std_logic_vector(31 downto 0);
      bram_wen       : out std_logic);
  end component;

  -- Implementation of system CSR
  signal csr_h2f_reg0_c : std_logic_vector((32 - 1) downto 0);
  signal csr_f2h_reg0_c : std_logic_vector((32 - 1) downto 0);

  -- BRAM ports A, for FPGA use
  signal bram_rst       : std_logic;
  signal bram_addr_fpga : std_logic_vector(7 downto 0);
  signal bram_din_fpga  : std_logic_vector(31 downto 0);
  signal bram_dout_fpga : std_logic_vector(31 downto 0);
  signal bram_we_fpga  : std_logic;
  signal bram_wea : std_logic_vector(0 downto 0);

    -- BRAM ports B, for host use
    signal bram_addr_host : std_logic_vector(7 downto 0);
  signal bram_din_host  : std_logic_vector(31 downto 0);
  signal bram_dout_host : std_logic_vector(31 downto 0);
  signal bram_we_host  : std_logic;
  signal bram_web : std_logic_vector(0 downto 0);
  
begin

  bram_wea(0) <= bram_we_fpga;
  bram_web(0) <= bram_we_host;
  regular_csr : csr_bram
    port map (
      clka  => clk,
      dina  => bram_din_fpga,
      addra => bram_addr_fpga,
      wea   => bram_wea,
      douta => bram_dout_fpga,
      clkb  => clk,
      dinb  => bram_din_host,
      addrb => bram_addr_host,
      web   => bram_web,
      doutb => bram_dout_host);

  csr_fpga_ctrl_inst : csr_fpga_ctrl
    port map (
      clk              => clk,
      rst_n            => rst_n,
      hw_chnl_rst      => hw_chnl_rst,
      bram_addr        => bram_addr_fpga,
      bram_din         => bram_din_fpga,
      bram_dout        => bram_dout_fpga,
      bram_wen         => bram_we_fpga,
      csr_out_rd_ready => csr_out_rd_ready,
      csr_out_rd_done  => csr_out_rd_done,
      csr_in_rd_en     => csr_in_rd_en,
      csr_in_rd_ack    => csr_in_rd_ack,
      csr_out_rd_data  => csr_out_rd_data,
      csr_in_rd_index  => csr_in_rd_index,
      csr_out_wr_ready => csr_out_wr_ready,
      csr_in_wr_en     => csr_in_wr_en,
      csr_in_wr_data   => csr_in_wr_data,
      csr_in_wr_index  => csr_in_wr_index);


  csr_host_ctrl_inst : csr_host_ctrl
    port map (
      clk            => clk,
      rst_n          => rst_n,
      hw_chnl_rst    => hw_chnl_rst,
      mrd32_req_addr => mrd32_req_addr,
      csr_rd_start   => csr_rd_start,
      mwr32_addr     => mwr32_addr,
      mwr32_data     => mwr32_data,
      csr_wr_start   => csr_wr_start,
      cpld_start     => cpld_start,
      cpld_start_ack => cpld_start_ack,
      cpld_finish    => cpld_finish,
      mrd32_req_data => mrd32_req_data,
      bar0_wr_addr   => bar0_wr_addr,
      bar0_wr_en     => bar0_wr_en,
      bar0_wr_data   => bar0_wr_data,
      bar0_rd_addr   => bar0_rd_addr,
      bar0_rd_data   => bar0_rd_data,
      bram_addr      => bram_addr_host,
      bram_din       => bram_din_host,
      bram_dout      => bram_dout_host,
      bram_wen       => bram_we_host);


  -----------------------------------------------------------------------------
  -- system CSR implementation
  --   system CSR is implemented as "signals" in VHDL, they are low overheaded
  --   comparint to the regular CSR
  -----------------------------------------------------------------------------
  -- h2f system CSR
  csr_out_h2f_reg0 <= csr_h2f_reg0_c;
  process (clk, rst_n)
  begin
    if (rst_n = '0' or hw_chnl_rst = '1') then
      csr_h2f_reg0_c <= (others => '0');
    elsif(rising_edge(clk)) then
      if (pcie_csr_in_h2f_reg0_wr_en = '1') then
        csr_h2f_reg0_c <= pcie_csr_in_h2f_reg0;
      else
        csr_h2f_reg0_c <= csr_h2f_reg0_c;
      end if;
    end if;
  end process;

  -- f2h system CSR
  pcie_csr_out_f2h_reg0 <= csr_f2h_reg0_c;
  process (clk, rst_n)
  begin
    if (rst_n = '0' or hw_chnl_rst = '1') then
      csr_f2h_reg0_c <= X"0a0b0c0d";    --(others => '0');
    elsif (rising_edge(clk)) then
      if (csr_in_f2h_reg0_wr_en = '1') then
        csr_f2h_reg0_c <= csr_in_f2h_reg0;
      else
        csr_f2h_reg0_c <= csr_f2h_reg0_c;
      end if;
    end if;
  end process;

end rtl;

