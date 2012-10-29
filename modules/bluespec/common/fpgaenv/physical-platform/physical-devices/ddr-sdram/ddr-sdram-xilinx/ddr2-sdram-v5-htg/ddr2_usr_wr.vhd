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
--  /   /         Filename: ddr2_usr_wr.v
-- /___/   /\     Date Last Modified: $Date: 2008/05/08 15:20:48 $
-- \   \  /  \    Date Created: Tue Aug 14 2007
--  \___\/\___\
--
--Device: Virtex-5
--Design Name: DDR/DDR2
--Purpose:
--   This module instantiates the modules containing internal FIFOs
--Reference:
--Revision History:
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

entity ddr2_usr_wr is
  generic (
    -- Following parameters are for 72-bit RDIMM design (for ML561 Reference 
    -- board design). Actual values may be different. Actual parameters values 
    -- are passed from design top module ddr2_sdram module. Please refer to
    -- the ddr2_sdram module for actual values.
    BANK_WIDTH         : integer := 2;
    COL_WIDTH          : integer := 10;
    CS_BITS            : integer := 0;
    DQ_WIDTH           : integer := 72;
    APPDATA_WIDTH      : integer := 144;
    ECC_ENABLE         : integer := 0;
    ROW_WIDTH          : integer := 14
  );
  port (
    clk0               : in std_logic;
    clk90              : in std_logic;
    rst0               : in std_logic;
    -- Write data FIFO interface
    app_wdf_wren       : in std_logic;
    app_wdf_data       : in std_logic_vector(APPDATA_WIDTH-1 downto 0);
    app_wdf_mask_data  : in std_logic_vector((APPDATA_WIDTH/8)-1 downto 0);
    wdf_rden           : in std_logic;
    app_wdf_afull      : out std_logic;
    wdf_data           : out std_logic_vector((2*DQ_WIDTH)-1 downto 0);
    wdf_mask_data      : out std_logic_vector(((2*DQ_WIDTH)/8)-1 downto 0)
  );
end entity ddr2_usr_wr;

architecture syn of ddr2_usr_wr is

  function CALC_WDF_FIFO_NUM return integer is
  begin
    if (ECC_ENABLE /= 0) then
      return ((APPDATA_WIDTH)+63)/64;
    else
      return ((2*DQ_WIDTH)+63)/64;
    end if;
  end function CALC_WDF_FIFO_NUM;

  -- determine number of FIFO72's to use based on data width
  -- round up to next integer value when determining WDF_FIFO_NUM
  constant WDF_FIFO_NUM : integer := CALC_WDF_FIFO_NUM;
  -- MASK_WIDTH = number of bytes in data bus
  constant MASK_WIDTH   : integer := DQ_WIDTH/8;

  signal i_wdf_afull              : std_logic_vector(WDF_FIFO_NUM-1 downto 0);
  signal i_wdf_data_fall_in       : std_logic_vector(DQ_WIDTH-1 downto 0);
  signal i_wdf_data_fall_out      : std_logic_vector(DQ_WIDTH-1 downto 0);
  signal i_wdf_data_in            : std_logic_vector((64*WDF_FIFO_NUM)-1
                                                     downto 0);
  signal i_wdf_data_out           : std_logic_vector((64*WDF_FIFO_NUM)-1
                                                     downto 0);
  signal i_wdf_data_rise_in       : std_logic_vector(DQ_WIDTH-1 downto 0);
  signal i_wdf_data_rise_out      : std_logic_vector(DQ_WIDTH-1 downto 0);
  signal i_wdf_mask_data_fall_in  : std_logic_vector(MASK_WIDTH-1 downto 0);
  signal i_wdf_mask_data_fall_out : std_logic_vector(MASK_WIDTH-1 downto 0);
  signal i_wdf_mask_data_in       : std_logic_vector((8*WDF_FIFO_NUM)-1
                                                     downto 0);
  signal i_wdf_mask_data_out      : std_logic_vector((8*WDF_FIFO_NUM)-1
                                                     downto 0);
  signal i_wdf_mask_data_rise_in  : std_logic_vector(MASK_WIDTH-1 downto 0);
  signal i_wdf_mask_data_rise_out : std_logic_vector(MASK_WIDTH-1 downto 0);
  signal rst_r                    : std_logic;

  -- ECC signals
  signal i_wdf_data_out_ecc           : std_logic_vector((2*DQ_WIDTH)-1
                                                         downto 0);
  signal i_wdf_mask_data_out_ecc      : std_logic_vector(((2*DQ_WIDTH)/8)-1
                                                    downto 0);
  signal i_wdf_mask_data_out_ecc_wire : std_logic_vector(63 downto 0);
  signal mask_data_in_ecc             : std_logic_vector(((2*DQ_WIDTH)/8)-1
                                                         downto 0);
  signal mask_data_in_ecc_wire        : std_logic_vector(63 downto 0);

begin

  --***************************************************************************

  app_wdf_afull <= i_wdf_afull(0);

  process (clk0)
  begin
    if (rising_edge(clk0)) then
      rst_r <= rst0;
    end if;
  end process;

  gen_ecc: if (ECC_ENABLE /= 0) generate     -- ECC code

    wdf_data <= i_wdf_data_out_ecc;

    -- the byte 9 dm is always held to 0
    wdf_mask_data <= i_wdf_mask_data_out_ecc;

    -- generate for write data fifo .
    gen_wdf: for wdf_i in 0 to WDF_FIFO_NUM-1 generate
      u_wdf_ecc : FIFO36_72
        generic map (
          ALMOST_EMPTY_OFFSET      => X"007",
          ALMOST_FULL_OFFSET       => X"00F",
          DO_REG                   => 1,      -- extra CC output delay
          EN_ECC_WRITE             => true,
          EN_ECC_READ              => false,
          EN_SYN                   => false,
          FIRST_WORD_FALL_THROUGH  => false
        )
        port map (
          ALMOSTEMPTY => open,
          ALMOSTFULL  => i_wdf_afull(wdf_i),
          DBITERR     => open,
          DO          => i_wdf_data_out_ecc(((64*(wdf_i+1))+(wdf_i*8))-1
                                            downto (64*wdf_i)+(wdf_i*8)),
          DOP         => i_wdf_data_out_ecc((72*(wdf_i+1))-1 downto
                                            (64*(wdf_i + 1))+(8*wdf_i)),
          ECCPARITY   => open,
          EMPTY       => open,
          FULL        => open,
          RDCOUNT     => open,
          RDERR       => open,
          SBITERR     => open,
          WRCOUNT     => open,
          WRERR       => open,
          DI          => app_wdf_data((64*(wdf_i+1))-1 downto (64*wdf_i)),
          DIP         => "00000000",
          RDCLK       => clk90,
          RDEN        => wdf_rden,
          RST         => rst_r,         -- or can use rst0
          WRCLK       => clk0,
          WREN        => app_wdf_wren
          );
    end generate;

    -- remapping the mask data. The mask data from user i/f does not have
    -- the mask for the ECC byte. Assigning 0 to the ECC mask byte.
    gen_mask: for mask_i in 0 to (DQ_WIDTH/36)-1 generate
      mask_data_in_ecc(((8*(mask_i+1))+mask_i)-1 downto
                       ((8*mask_i)+mask_i)) <=
        app_wdf_mask_data((8*(mask_i+1))-1 downto 8*(mask_i));
      mask_data_in_ecc(((8*(mask_i+1))+mask_i)) <= '0';
    end generate;

    -- assign ecc bits to temp variables to avoid
    -- sim warnings. Not all the 64 bits of the fifo
    -- are used in ECC mode.
    mask_data_in_ecc_wire(((2*DQ_WIDTH)/8)-1 downto 0) <= mask_data_in_ecc;
    mask_data_in_ecc_wire(63 downto ((2*DQ_WIDTH)/8)) <= (others => '0');
    i_wdf_mask_data_out_ecc <=
      i_wdf_mask_data_out_ecc_wire(((2*DQ_WIDTH)/8)-1 downto 0);

    u_wdf_ecc_mask : FIFO36_72
      generic map (
        ALMOST_EMPTY_OFFSET      => X"007",
        ALMOST_FULL_OFFSET       => X"00F",
        DO_REG                   => 1,         -- extra CC output delay
        EN_ECC_WRITE             => true,
        EN_ECC_READ              => false,
        EN_SYN                   => false,
        FIRST_WORD_FALL_THROUGH  => false
      )
      port map (
        ALMOSTEMPTY  => open,
        ALMOSTFULL   => open,
        DBITERR      => open,
        DO           => i_wdf_mask_data_out_ecc_wire,
        DOP          => open,
        ECCPARITY    => open,
        EMPTY        => open,
        FULL         => open,
        RDCOUNT      => open,
        RDERR        => open,
        SBITERR      => open,
        WRCOUNT      => open,
        WRERR        => open,
        DI           => mask_data_in_ecc_wire,
        DIP          => "00000000",
        RDCLK        => clk90,
        RDEN         => wdf_rden,
        RST          => rst_r,          -- or can use rst0
        WRCLK        => clk0,
        WREN         => app_wdf_wren
      );
  end generate;

  gen_no_ecc: if (ECC_ENABLE = 0) generate   -- if (ECC_ENABLE) non ECC code

    --*************************************************************************

    -- Define intermediate buses:
    i_wdf_data_rise_in <=
      app_wdf_data(DQ_WIDTH-1 downto 0);
    i_wdf_data_fall_in <=
      app_wdf_data((2*DQ_WIDTH)-1 downto DQ_WIDTH);
    i_wdf_mask_data_rise_in <=
      app_wdf_mask_data(MASK_WIDTH-1 downto 0);
    i_wdf_mask_data_fall_in <=
      app_wdf_mask_data((2*MASK_WIDTH)-1 downto MASK_WIDTH);

    --*************************************************************************
    -- Write data FIFO Input:
    -- Arrange DQ's so that the rise data and fall data are interleaved.
    -- the data arrives at the input of the wdf fifo as {fall,rise}.
    -- It is remapped as:
    --     {...fall[15:8],rise[15:8],fall[7:0],rise[7:0]}
    -- This is done to avoid having separate fifo's for rise and fall data
    -- and to keep rise/fall data for the same DQ's on same FIFO
    -- Data masks are interleaved in a similar manner
    -- NOTE: Initialization data from PHY_INIT module does not need to be
    --  interleaved - it's already in the correct format - and the same
    --  initialization pattern from PHY_INIT is sent to all write FIFOs
    --*************************************************************************

    gen_wdf_data_in: for wdf_di_i in 0 to MASK_WIDTH-1 generate
      i_wdf_data_in((16*wdf_di_i)+15 downto (16*wdf_di_i)) <=
        (i_wdf_data_fall_in((8*wdf_di_i)+7 downto (8*wdf_di_i)) &
         i_wdf_data_rise_in((8*wdf_di_i)+7 downto (8*wdf_di_i)));
      i_wdf_mask_data_in((2*wdf_di_i)+1 downto (2*wdf_di_i)) <=
        (i_wdf_mask_data_fall_in(wdf_di_i) &
         i_wdf_mask_data_rise_in(wdf_di_i));
    end generate;

    --*************************************************************************
    -- Write data FIFO Output:
    -- FIFO DQ and mask outputs must be untangled and put in the standard
    -- format of {fall,rise}. Same goes for mask output
    --*************************************************************************

    gen_wdf_data_out: for wdf_do_i in 0 to MASK_WIDTH-1 generate
      i_wdf_data_rise_out((8*wdf_do_i)+7 downto (8*wdf_do_i)) <=
        i_wdf_data_out((16*wdf_do_i)+7 downto (16*wdf_do_i));
      i_wdf_data_fall_out((8*wdf_do_i)+7 downto (8*wdf_do_i)) <=
        i_wdf_data_out((16*wdf_do_i)+15 downto (16*wdf_do_i)+8);
      i_wdf_mask_data_rise_out(wdf_do_i) <=
        i_wdf_mask_data_out(2*wdf_do_i);
      i_wdf_mask_data_fall_out(wdf_do_i) <=
        i_wdf_mask_data_out((2*wdf_do_i)+1);
    end generate;

    wdf_data <= (i_wdf_data_fall_out &
                 i_wdf_data_rise_out);

    wdf_mask_data <= (i_wdf_mask_data_fall_out &
                      i_wdf_mask_data_rise_out);

    --*************************************************************************

    gen_wdf: for wdf_i in 0 to WDF_FIFO_NUM-1 generate
      u_wdf : FIFO36_72
        generic map (
          ALMOST_EMPTY_OFFSET      => X"007",
          ALMOST_FULL_OFFSET       => X"00F",
          DO_REG                   => 1,       -- extra CC output delay
          EN_ECC_WRITE             => false,
          EN_ECC_READ              => false,
          EN_SYN                   => false,
          FIRST_WORD_FALL_THROUGH  => false
          )
        port map (
          ALMOSTEMPTY => open,
          ALMOSTFULL  => i_wdf_afull(wdf_i),
          DBITERR     => open,
          DO          => i_wdf_data_out((64*(wdf_i+1))-1 downto 64*wdf_i),
          DOP         => i_wdf_mask_data_out((8*(wdf_i+1))-1 downto 8*wdf_i),
          ECCPARITY   => open,
          EMPTY       => open,
          FULL        => open,
          RDCOUNT     => open,
          RDERR       => open,
          SBITERR     => open,
          WRCOUNT     => open,
          WRERR       => open,
          DI          => i_wdf_data_in((64*(wdf_i+1))-1 downto 64*wdf_i),
          DIP         => i_wdf_mask_data_in((8*(wdf_i+1))-1 downto 8*wdf_i),
          RDCLK       => clk90,
          RDEN        => wdf_rden,
          RST         => rst_r,         -- or can use rst0
          WRCLK       => clk0,
          WREN        => app_wdf_wren
          );
    end generate;
  end generate;

end architecture syn;


