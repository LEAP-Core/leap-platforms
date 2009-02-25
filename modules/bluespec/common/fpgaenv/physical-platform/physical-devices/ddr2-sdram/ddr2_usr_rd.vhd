--*****************************************************************************
-- DISCLAIMER OF LIABILITY
-- 
-- This text/file contains proprietary, confidential
-- information of Xilinx, Inc., is distributed under license
-- from Xilinx, Inc., and may be used, copied and/or
-- disclosed only pursuant to the terms of a valid license
-- agreement with Xilinx, Inc. Xilinx hereby grants you a 
-- license to use this text/file solely for design, simulation, 
-- implementation and creation of design files limited 
-- to Xilinx devices or technologies. Use with non-Xilinx 
-- devices or technologies is expressly prohibited and 
-- immediately terminates your license unless covered by
-- a separate agreement.
--
-- Xilinx is providing this design, code, or information 
-- "as-is" solely for use in developing programs and 
-- solutions for Xilinx devices, with no obligation on the 
-- part of Xilinx to provide support. By providing this design, 
-- code, or information as one possible implementation of 
-- this feature, application or standard, Xilinx is making no 
-- representation that this implementation is free from any 
-- claims of infringement. You are responsible for 
-- obtaining any rights you may require for your implementation. 
-- Xilinx expressly disclaims any warranty whatsoever with 
-- respect to the adequacy of the implementation, including 
-- but not limited to any warranties or representations that this
-- implementation is free from claims of infringement, implied 
-- warranties of merchantability or fitness for a particular 
-- purpose.
--
-- Xilinx products are not intended for use in life support
-- appliances, devices, or systems. Use in such applications is
-- expressly prohibited.
--
-- Any modifications that are made to the Source Code are 
-- done at the user's sole risk and will be unsupported.
--
-- Copyright (c) 2006-2007 Xilinx, Inc. All rights reserved.
--
-- This copyright and support notice must be retained as part 
-- of this text at all times.
--*****************************************************************************
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor: Xilinx
-- \   \   \/     Version: 2.3
--  \   \         Application: MIG
--  /   /         Filename: ddr2_usr_rd.vhd
-- /___/   /\     Date Last Modified: $Date: 2008/07/02 14:03:08 $
-- \   \  /  \    Date Created: Wed Jan 10 2007
--  \___\/\___\
--
--Device: Virtex-5
--Design Name: DDR2
--Purpose:
--   The delay between the read data with respect to the command issued is
--   calculted in terms of no. of clocks. This data is then stored into the
--   FIFOs and then read back and given as the ouput for comparison.
--Reference:
--Revision History:
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

entity ddr2_usr_rd is
  generic (
    -- Following parameters are for 72-bit RDIMM design (for ML561 Reference 
    -- board design). Actual values may be different. Actual parameters values 
    -- are passed from design top module ddr2_sdram module. Please refer to
    -- the ddr2_sdram module for actual values.
    DQ_PER_DQS       :     integer := 8;
    DQS_WIDTH        :     integer := 9;
    APPDATA_WIDTH    :     integer := 144;
    ECC_ENABLE       :     integer := 0
    );
  port (
    clk0             : in  std_logic;
    rst0             : in  std_logic;
    rd_data_in_rise  : in  std_logic_vector((DQS_WIDTH*DQ_PER_DQS)-1 downto 0);
    rd_data_in_fall  : in  std_logic_vector((DQS_WIDTH*DQ_PER_DQS)-1 downto 0);
    ctrl_rden        : in  std_logic_vector(DQS_WIDTH-1 downto 0);
    ctrl_rden_sel    : in  std_logic_vector(DQS_WIDTH-1 downto 0);
    rd_ecc_error     : out std_logic_vector(1 downto 0);
    rd_data_valid    : out std_logic;
    rd_data_out_rise : out std_logic_vector((APPDATA_WIDTH/2)-1 downto 0);
    rd_data_out_fall : out std_logic_vector((APPDATA_WIDTH/2)-1 downto 0)
    );
end entity ddr2_usr_rd;

architecture syn of ddr2_usr_rd is

  function or_br (val : std_logic_vector) return std_logic is
    variable rtn : std_logic := '0';
  begin
    for index in val'range loop
      rtn := rtn or val(index);
    end loop;
    return(rtn);
  end or_br;

  -- determine number of FIFO72's to use based on data width
  constant RDF_FIFO_NUM    : integer := ((APPDATA_WIDTH/2)+63)/64;

  signal ctrl_rden_r       : std_logic_vector(DQS_WIDTH - 1 downto 0);
  signal fall_data         : std_logic_vector((DQS_WIDTH*DQ_PER_DQS)-1
                                              downto 0);
  signal rd_data_in_fall_r : std_logic_vector((DQS_WIDTH*DQ_PER_DQS)-1
                                              downto 0);
  signal rd_data_in_rise_r : std_logic_vector((DQS_WIDTH*DQ_PER_DQS)-1
                                              downto 0);
  signal rden              : std_logic;
  signal rden_sel_r        : std_logic_vector(DQS_WIDTH-1 downto 0);
  signal rden_sel_mux      : std_logic_vector(DQS_WIDTH-1 downto 0);
  signal rise_data         : std_logic_vector((DQS_WIDTH*DQ_PER_DQS)-1
                                              downto 0);

   -- ECC specific signals
  signal db_ecc_error          : std_logic_vector(((RDF_FIFO_NUM-1)*2)+1
                                                  downto 0);
  signal fall_data_r           : std_logic_vector((DQS_WIDTH*DQ_PER_DQS)-1
                                                  downto 0);
  signal fifo_rden_r0          : std_logic;
  signal fifo_rden_r1          : std_logic;
  signal fifo_rden_r2          : std_logic;
  signal fifo_rden_r3          : std_logic;
  signal fifo_rden_r4          : std_logic;
  signal fifo_rden_r5          : std_logic;
  signal fifo_rden_r6          : std_logic;
  signal rd_data_out_fall_temp : std_logic_vector((APPDATA_WIDTH/2)-1
                                                  downto 0);
  signal rd_data_out_rise_temp : std_logic_vector((APPDATA_WIDTH/2)-1
                                                  downto 0);
  signal rst_r                 : std_logic;
  signal rise_data_r           : std_logic_vector((DQS_WIDTH*DQ_PER_DQS)-1
                                                  downto 0);
  signal sb_ecc_error          : std_logic_vector(((RDF_FIFO_NUM-1)*2)+1
                                                  downto 0);

  signal i_rst_r_n             : std_logic;

  attribute syn_preserve : boolean;
  attribute syn_preserve of rden_sel_r : signal is true;

begin

  i_rst_r_n <= not(rst_r);

  --***************************************************************************

  process (clk0)
  begin
    if (rising_edge(clk0)) then
      rden_sel_r        <= ctrl_rden_sel;
      ctrl_rden_r       <= ctrl_rden;
      rd_data_in_rise_r <= rd_data_in_rise;
      rd_data_in_fall_r <= rd_data_in_fall;
    end if;
  end process;

  -- Instantiate primitive to allow this flop to be attached to multicycle
  -- path constraint in UCF. Multicycle path allowed for data from read FIFO.
  -- This is the same signal as RDEN_SEL_R, but is only used to select data
  -- (does not affect control signals)
  gen_rden_sel_mux: for rd_i in 0 to DQS_WIDTH-1 generate
    attribute syn_preserve of u_ff_rden_sel_mux : label is true;
  begin
    u_ff_rden_sel_mux : FDRSE
      port map (
        Q    => rden_sel_mux(rd_i),
        C    => clk0,
        CE   => '1',
        D    => ctrl_rden_sel(rd_i),
        R    => '0',
        S    => '0'
        );
  end generate;

  -- determine correct read data valid signal timing
  rden <= ctrl_rden(0) when (rden_sel_r(0) = '1') else
          ctrl_rden_r(0);

  -- assign data based on the skew
  gen_data: for data_i in 0 to DQS_WIDTH-1 generate
    rise_data((data_i*DQ_PER_DQS)+(DQ_PER_DQS-1) downto
              (data_i*DQ_PER_DQS)) <=
      rd_data_in_rise((data_i*DQ_PER_DQS)+(DQ_PER_DQS-1) downto
                      (data_i*DQ_PER_DQS))
      when (rden_sel_mux(data_i) = '1') else
      rd_data_in_rise_r((data_i*DQ_PER_DQS)+(DQ_PER_DQS-1) downto
                        (data_i*DQ_PER_DQS));

    fall_data((data_i*DQ_PER_DQS)+(DQ_PER_DQS-1) downto
              (data_i*DQ_PER_DQS)) <=
      rd_data_in_fall((data_i*DQ_PER_DQS)+(DQ_PER_DQS-1) downto
                      (data_i*DQ_PER_DQS))
      when (rden_sel_mux(data_i) = '1') else
      rd_data_in_fall_r((data_i*DQ_PER_DQS)+(DQ_PER_DQS-1) downto
                        (data_i*DQ_PER_DQS));
  end generate;

  -- Generate RST for FIFO reset AND for read/write enable:
  -- ECC FIFO always being read from and written to
  process (clk0)
  begin
    if (rising_edge(clk0)) then
      rst_r <= rst0;
    end if;
  end process;

  gen_ecc: if (ECC_ENABLE /= 0) generate
    process (clk0)
    begin
      if (rising_edge(clk0)) then
        rd_ecc_error(0)  <= (or_br(sb_ecc_error)) and fifo_rden_r5;
        rd_ecc_error(1)  <= (or_br(db_ecc_error)) and fifo_rden_r5;
        rd_data_out_rise <= rd_data_out_rise_temp;
        rd_data_out_fall <= rd_data_out_fall_temp;
        rise_data_r      <= rise_data;
        fall_data_r      <= fall_data;
      end if;
    end process;

    -- can use any of the read valids, they're all delayed by same amount
    rd_data_valid <= fifo_rden_r6;

    -- delay read valid to take into account max delay difference btw
    -- the read enable coming from the different DQS groups
    process (clk0)
    begin
      if (rising_edge(clk0)) then
        if (rst0 = '1') then
          fifo_rden_r0 <= '0';
          fifo_rden_r1 <= '0';
          fifo_rden_r2 <= '0';
          fifo_rden_r3 <= '0';
          fifo_rden_r4 <= '0';
          fifo_rden_r5 <= '0';
          fifo_rden_r6 <= '0';
        else
          fifo_rden_r0 <= rden;
          fifo_rden_r1 <= fifo_rden_r0;
          fifo_rden_r2 <= fifo_rden_r1;
          fifo_rden_r3 <= fifo_rden_r2;
          fifo_rden_r4 <= fifo_rden_r3;
          fifo_rden_r5 <= fifo_rden_r4;
          fifo_rden_r6 <= fifo_rden_r5;
        end if;
      end if;
    end process;

    gen_rdf : for rdf_i in 0 to RDF_FIFO_NUM-1 generate
      u_rdf : FIFO36_72                  -- rise fifo
        generic map (
          ALMOST_EMPTY_OFFSET     => X"007",
          ALMOST_FULL_OFFSET      => X"00F",
          DO_REG                  => 1,  -- extra CC output delay
          EN_ECC_WRITE            => false,
          EN_ECC_READ             => true,
          EN_SYN                  => false,
          FIRST_WORD_FALL_THROUGH => false
          )
        port map (
          ALMOSTEMPTY => open,
          ALMOSTFULL  => open,
          DBITERR     => db_ecc_error(rdf_i + rdf_i),
          DO          => rd_data_out_rise_temp((64*(rdf_i+1))-1 downto
                                               (64*rdf_i)),
          DOP         => open,
          ECCPARITY   => open,
          EMPTY       => open,
          FULL        => open,
          RDCOUNT     => open,
          RDERR       => open,
          SBITERR     => sb_ecc_error(rdf_i + rdf_i),
          WRCOUNT     => open,
          WRERR       => open,
          DI          => rise_data_r(((64*(rdf_i+1))+(rdf_i*8))-1 downto
                                     (64*rdf_i)+(rdf_i*8)),
          DIP         => rise_data_r((72*(rdf_i+1))-1 downto
                                     (64*(rdf_i+1))+(8*rdf_i)),
          RDCLK       => clk0,
          RDEN        => i_rst_r_n,
          RST         => rst_r,
          WRCLK       => clk0,
          WREN        => i_rst_r_n
          );

      -- fall_fifo
      u_rdf1 : FIFO36_72
        generic map (
          ALMOST_EMPTY_OFFSET      => X"007",
          ALMOST_FULL_OFFSET       => X"00F",
          DO_REG                   => 1,
          EN_ECC_WRITE             => false,
          EN_ECC_READ              => true,
          EN_SYN                   => false,
          FIRST_WORD_FALL_THROUGH  => false
        )
        port map (
          ALMOSTEMPTY  => open,
          ALMOSTFULL   => open,
          DBITERR      => db_ecc_error((rdf_i+1) + rdf_i),
          DO           => rd_data_out_fall_temp((64*(rdf_i+1))-1 downto
                                                (64*rdf_i)),
          DOP          => open,
          ECCPARITY    => open,
          EMPTY        => open,
          FULL         => open,
          RDCOUNT      => open,
          RDERR        => open,
          SBITERR      => sb_ecc_error((rdf_i+1) + rdf_i),
          WRCOUNT      => open,
          WRERR        => open,
          DI           => fall_data_r(((64*(rdf_i+1))+(rdf_i*8))-1 downto
                                      (64*rdf_i)+(rdf_i*8)),
          DIP          => fall_data_r((72*(rdf_i+1))-1 downto
                                      (64*(rdf_i+1))+(8*rdf_i)),
          RDCLK        => clk0,
          RDEN         => i_rst_r_n,
          RST          => rst_r,       -- or can use rst0
          WRCLK        => clk0,
          WREN         => i_rst_r_n
        );
    end generate;
  end generate;

  gen_no_ecc: if (ECC_ENABLE = 0) generate
    rd_data_valid <= fifo_rden_r0;
    process (clk0)
    begin
      if (rising_edge(clk0)) then
        rd_data_out_rise <= rise_data;
        rd_data_out_fall <= fall_data;
        fifo_rden_r0 <= rden;
      end if;
    end process;
  end generate;

end architecture syn;


