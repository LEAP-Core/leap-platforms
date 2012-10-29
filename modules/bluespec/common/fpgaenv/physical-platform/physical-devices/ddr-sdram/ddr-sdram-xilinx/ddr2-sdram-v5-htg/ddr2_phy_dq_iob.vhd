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
--  /   /         Filename: ddr2_phy_dq_iob.vhd
-- /___/   /\     Date Last Modified: $Date: 2008/07/17 07:52:29 $
-- \   \  /  \    Date Created: Wed Jan 10 2007
--  \___\/\___\
--
--Device: Virtex-5
--Design Name: DDR2
--Purpose:
--   This module places the data in the IOBs.
--Reference:
--Revision History:
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

entity ddr2_phy_dq_iob is
  generic (
    DQ_COL                : bit_vector(0 to 1) := "00";
    DQ_MS                 : bit := '0';
    HIGH_PERFORMANCE_MODE : boolean := TRUE
    );
  port (
    clk0          : in std_logic;
    clk90         : in std_logic;
    clkdiv0       : in std_logic;
    rst90         : in std_logic;
    dlyinc        : in std_logic;
    dlyce         : in std_logic;
    dlyrst        : in std_logic;
    dq_oe_n       : in std_logic_vector(1 downto 0);
    dqs           : in std_logic;
    ce            : in std_logic;
    rd_data_sel   : in std_logic;
    wr_data_rise  : in std_logic;
    wr_data_fall  : in std_logic;
    rd_data_rise  : out std_logic;
    rd_data_fall  : out std_logic;
    ddr_dq        : inout std_logic
  );
end entity ddr2_phy_dq_iob;

architecture syn of ddr2_phy_dq_iob is

  -- only need explicit component declarations for IODELAY and LUT6_2
  -- for pre-Synplify Pro 8.8 (Synplify Pro 8.8+ and XST understands this
  -- primitive)
  component IODELAY
    generic (
      DELAY_SRC             : string;
      HIGH_PERFORMANCE_MODE : boolean;
      IDELAY_TYPE           : string;
      IDELAY_VALUE          : integer;
      ODELAY_VALUE          : integer);
    port (
      DATAOUT : out std_ulogic;
      C       : in  std_ulogic;
      CE      : in  std_ulogic;
      DATAIN  : in  std_ulogic;
      IDATAIN : in  std_ulogic;
      INC     : in  std_ulogic;
      ODATAIN : in  std_ulogic;
      RST     : in  std_ulogic;
      T       : in  std_ulogic);
  end component;

  signal dq_iddr_clk       : std_logic;
  signal dq_idelay         : std_logic;
  signal dq_in             : std_logic;
  signal dq_oe_n_r         : std_logic;
  signal dq_out            : std_logic;
  signal stg2a_out_fall    : std_logic;
  signal stg2a_out_rise    : std_logic;
  signal stg2b_out_fall    : std_logic;
  signal stg2b_out_rise    : std_logic;
  signal stg3a_out_fall    : std_logic;
  signal stg3a_out_rise    : std_logic;
  signal stg3b_out_fall    : std_logic;
  signal stg3b_out_rise    : std_logic;

  attribute AREA_GROUP    : string;
  attribute BEL           : string;
  attribute HU_SET        : string;
  attribute IOB           : string;
  attribute KEEP          : string;
  attribute RLOC          : string;
  attribute syn_black_box : boolean;
  attribute syn_keep      : boolean;
  attribute syn_useioff   : boolean;
  attribute syn_preserve  : boolean;
  attribute syn_replicate : boolean;

  attribute syn_black_box of IODELAY : component is true;
  attribute IOB of u_tri_state_dq : label is "true";
  attribute syn_useioff of u_tri_state_dq : label is true;

  --***************************************************************************
  -- Directed routing constraints for route between IDDR and stage 2 capture
  -- in fabric.
  -- Only 2 out of the 12 wire declarations will be used for any given
  -- instantiation of this module.
  -- Varies according:
  --  (1) I/O column (left, center, right) used
  --  (2) Which I/O in I/O pair (master, slave) used
  -- Nomenclature: _Xy, X = column (0 = left, 1 = center, 2 = right),
  --  y = master or slave
  --***************************************************************************

  -- master, left
  signal stg1_out_rise_0m  : std_logic;
  signal stg1_out_fall_0m  : std_logic;
  -- slave, left
  signal stg1_out_rise_0s  : std_logic;
  signal stg1_out_fall_0s  : std_logic;
  -- master, center
  signal stg1_out_rise_1m  : std_logic;
  signal stg1_out_fall_1m  : std_logic;
  -- slave, center
  signal stg1_out_rise_1s  : std_logic;
  signal stg1_out_fall_1s  : std_logic;
  -- master, right
  signal stg1_out_rise_2m  : std_logic;
  signal stg1_out_fall_2m  : std_logic;
  -- slave, right
  signal stg1_out_rise_2s  : std_logic;
  signal stg1_out_fall_2s  : std_logic;

  attribute ROUTE    : string;
  attribute syn_keep of stg1_out_rise_0m : signal is true;
  attribute KEEP     of stg1_out_rise_0m : signal is "TRUE";
  attribute ROUTE    of stg1_out_rise_0m : signal is "{3;1;5vlx50tff1136;93a1e3bb!-1;-78112;-4200;S!0;-143;-1248!1;-452;0!2;2747;1575!3;2461;81!4;2732;-960!4;2732;-984!5;404;8!6;404;8!7;683;-568;L!8;843;24;L!}";
  attribute syn_keep of stg1_out_fall_0m : signal is true;
  attribute KEEP     of stg1_out_fall_0m : signal is "TRUE";
  attribute ROUTE    of stg1_out_fall_0m : signal is "{3;1;5vlx50tff1136;907923a!-1;-78112;-4192;S!0;-143;-1192!0;-143;-1272!1;-452;0!2;-452;0!3;2723;-385!4;2731;-311!5;3823;-1983!6;5209;1271!7;1394;3072!8;0;-8!9;404;8!10;0;-144!11;683;-536;L!12;404;8!14;843;8;L!}";
  attribute syn_keep of stg1_out_rise_0s : signal is true;
  attribute KEEP     of stg1_out_rise_0s : signal is "TRUE";
  attribute ROUTE    of stg1_out_rise_0s : signal is "{3;1;5vlx50tff1136;53bb9d6f!-1;-78112;-4600;S!0;-143;-712!1;-452;0!2;1008;-552!3;2780;1360!4;0;-8!5;0;-240!5;0;-264!6;404;8!7;404;8!8;683;-568;L!9;843;24;L!}";
  attribute syn_keep of stg1_out_fall_0s : signal is true;
  attribute KEEP     of stg1_out_fall_0s : signal is "TRUE";
  attribute ROUTE    of stg1_out_fall_0s : signal is "{3;1;5vlx50tff1136;46bf60d8!-1;-78112;-4592;S!0;-143;-800!1;-452;0!2;1040;1592!3;5875;-85!4;-3127;-843!4;-3127;-939!5;404;8!6;404;8!7;683;-696;L!8;843;-136;L!}";
  attribute syn_keep of stg1_out_rise_1m : signal is true;
  attribute KEEP     of stg1_out_rise_1m : signal is "TRUE";
  attribute ROUTE    of stg1_out_rise_1m : signal is "{3;1;5vlx50tff1136;9ee47800!-1;-6504;-50024;S!0;-175;-1136!1;-484;0!2;-3208;1552!3;-4160;-2092!4;-1428;1172!4;-1428;1076!5;404;8!6;404;8!7;843;-152;L!8;683;-728;L!}";
  attribute syn_keep of stg1_out_fall_1m : signal is true;
  attribute KEEP     of stg1_out_fall_1m : signal is "TRUE";
  attribute ROUTE    of stg1_out_fall_1m : signal is "{3;1;5vlx50tff1136;e7df31c2!-1;-6504;-50016;S!0;-175;-1192!1;-484;0!2;-5701;1523!3;-3095;-715!3;-4423;2421!4;0;-8!5;1328;-3288!6;0;-240!7;404;8!8;404;8!9;683;-696;L!10;843;-136;L!}";
  attribute syn_keep of stg1_out_rise_1s : signal is true;
  attribute KEEP     of stg1_out_rise_1s : signal is "TRUE";
  attribute ROUTE    of stg1_out_rise_1s : signal is "{3;1;5vlx50tff1136;a8c11eb3!-1;-6504;-50424;S!0;-175;-856!1;-484;0!2;-5677;-337!3;1033;1217!3;-295;4353!4;0;-8!5;1328;-3288!6;0;-120!7;404;8!8;404;8!9;683;-696;L!10;843;-152;L!}";
  attribute syn_keep of stg1_out_fall_1s : signal is true;
  attribute KEEP     of stg1_out_fall_1s : signal is "TRUE";
  attribute ROUTE    of stg1_out_fall_1s : signal is "{3;1;5vlx50tff1136;ed30cce!-1;-6504;-50416;S!0;-175;-848!1;-484;0!2;-3192;-432!3;-1452;1368!3;-6645;85!4;0;-8!5;5193;1035!6;0;-264!7;404;8!8;404;8!9;683;-568;L!10;843;24;L!}";
  attribute syn_keep of stg1_out_rise_2m : signal is true;
  attribute KEEP     of stg1_out_rise_2m : signal is "TRUE";
  attribute ROUTE    of stg1_out_rise_2m : signal is "{3;1;5vlx50tff1136;4d035a44!-1;54728;-108896;S!0;-175;-1248!1;-484;0!2;-3192;-424!3;-4208;2092!4;-1396;-972!4;-1396;-996!5;404;8!6;404;8!7;683;-568;L!8;843;24;L!}";
  attribute syn_keep of stg1_out_fall_2m : signal is true;
  attribute KEEP     of stg1_out_fall_2m : signal is "TRUE";
  attribute ROUTE    of stg1_out_fall_2m : signal is "{3;1;5vlx50tff1136;92ae8739!-1;54728;-108888;S!0;-175;-1272!1;-484;0!2;-5677;-329!3;-1691;-83!4;-1428;1076!4;-1428;1052!5;404;8!6;404;8!7;683;-728;L!8;843;-136;L!}";
  attribute syn_keep of stg1_out_rise_2s : signal is true;
  attribute KEEP     of stg1_out_rise_2s : signal is "TRUE";
  attribute ROUTE    of stg1_out_rise_2s : signal is "{3;1;5vlx50tff1136;9de34bf1!-1;54728;-109296;S!0;-175;-712!1;-484;0!2;-5685;-475!3;1041;1107!3;1041;1011!4;404;8!5;404;8!6;683;-536;L!7;843;24;L!}";
  attribute syn_keep of stg1_out_fall_2s : signal is true;
  attribute KEEP     of stg1_out_fall_2s : signal is "TRUE";
  attribute ROUTE    of stg1_out_fall_2s : signal is "{3;1;5vlx50tff1136;1df9e65d!-1;54728;-109288;S!0;-175;-800!1;-484;0!2;-3208;1608!3;-1436;-792!4;0;-8!5;0;-240!5;0;-144!6;404;8!7;404;8!8;843;-136;L!9;683;-696;L!}";

begin

  --***************************************************************************
  -- Bidirectional I/O
  --***************************************************************************

  u_iobuf_dq : IOBUF
    port map (
      I   => dq_out,
      T   => dq_oe_n_r,
      IO  => ddr_dq,
      O   => dq_in
    );

  --***************************************************************************
  -- Write (output) path
  --***************************************************************************

  -- on a write, rising edge of DQS corresponds to rising edge of CLK180
  -- (aka falling edge of CLK0 -> rising edge DQS). We also know:
  --  1. data must be driven 1/4 clk cycle before corresponding DQS edge
  --  2. first rising DQS edge driven on falling edge of CLK0
  --  3. rising data must be driven 1/4 cycle before falling edge of CLK0
  --  4. therefore, rising data driven on rising edge of CLK
  u_oddr_dq : ODDR
    generic map (
      SRTYPE        => "SYNC",
      DDR_CLK_EDGE  => "SAME_EDGE"
      )
    port map (
      Q  => dq_out,
      C  => clk90,
      CE => '1',
      D1 => wr_data_rise,
      D2 => wr_data_fall,
      R  => '0',
      S  => '0'
      );

  -- make sure output is tri-state during reset (DQ_OE_N_R = 1)
  u_tri_state_dq : ODDR
    generic map (
      SRTYPE        => "ASYNC",
      DDR_CLK_EDGE  => "SAME_EDGE"
      )
    port map (
      Q  => dq_oe_n_r,
      C  => clk90,
      CE => '1',
      D1 => dq_oe_n(0),
      D2 => dq_oe_n(1),
      R  => '0',
      S  => rst90
      );

  --***************************************************************************
  -- Read data capture scheme description:
  -- Data capture consists of 3 ranks of flops, and a MUX
  --  1. Rank 1 ("Stage 1"): IDDR captures delayed DDR DQ from memory using
  --     delayed DQS.
  --     - Data is split into 2 SDR streams, one each for rise and fall data.
  --     - BUFIO (DQS) input inverted to IDDR. IDDR configured in SAME_EDGE
  --       mode. This means that: (1) Q1 = fall data, Q2 = rise data,
  --       (2) Both rise and fall data are output on falling edge of DQS -
  --       rather than rise output being output on one edge of DQS, and fall
  --       data on the other edge if the IDDR were configured in OPPOSITE_EDGE
  --       mode. This simplifies Stage 2 capture (only one core clock edge
  --       used, removing effects of duty-cycle-distortion), and saves one
  --       fabric flop in Rank 3.
  --  2. Rank 2 ("Stage 2"): Fabric flops are used to capture output of first
  --     rank into FPGA clock (CLK) domain. Each rising/falling SDR stream
  --     from IDDR is feed into two flops, one clocked off rising and one off
  --     falling edge of CLK. One of these flops is chosen, with the choice
  --     being the one that reduces # of DQ/DQS taps necessary to align Stage
  --     1 and Stage 2. Same edge is used to capture both rise and fall SDR
  --     streams.
  --  3. Rank 3 ("Stage 3"): Removes half-cycle paths in CLK domain from
  --     output of Rank 2. This stage, like Stage 2, is clocked by CLK. Note
  --     that Stage 3 can be expanded to also support SERDES functionality
  --  4. Output MUX: Selects whether Stage 1 output is aligned to rising or
  --     falling edge of CLK (i.e. specifically this selects whether IDDR
  --     rise/fall output is transfered to rising or falling edge of CLK).
  -- Implementation:
  --  1. Rank 1 is implemented using an IDDR primitive
  --  2. Rank 2 is implemented using:
  --     - An RPM to fix the location of the capture flops near the DQ I/O.
  --       The exact RPM used depends on which I/O column (left, center,
  --       right) the DQ I/O is placed at - this affects the optimal location
  --       of the slice flops (or does it - can we always choose the two
  --       columns to slices to the immediate right of the I/O to use, no
  --       matter what the column?). The origin of the RPM must be set in the
  --       UCF file using the RLOC_ORIGIN constraint (where the original is
  --       based on the DQ I/O location).
  --     - Directed Routing Constraints ("DIRT strings") to fix the routing
  --       to the rank 2 fabric flops. This is done to minimize: (1) total
  --       route delay (and therefore minimize voltage/temperature-related
  --       variations), and (2) minimize skew both within each rising and
  --       falling data net, as well as between the rising and falling nets.
  --       The exact DIRT string used depends on: (1) which I/O column the
  --       DQ I/O is placed, and (2) whether the DQ I/O is placed on the
  --       "Master" or "Slave" I/O of a diff pair (DQ is not differential, but
  --       the routing will be affected by which of each I/O pair is used)
  -- 3. Rank 3 is implemented using fabric flops. No LOC or DIRT contraints
  --    are used, tools are expected to place these and meet PERIOD timing
  --    without constraints (constraints may be necessary for "full" designs,
  --    in this case, user may need to add LOC constraints - if this is the
  --    case, there are no constraints - other than meeting PERIOD timing -
  --    for rank 3 flops.
  --***************************************************************************

  --***************************************************************************
  -- MIG 2.2: Define AREA_GROUP = "DDR_CAPTURE_FFS" contain all RPM flops in
  --          design. In UCF file, add constraint:
  --             AREA_GROUP "DDR_CAPTURE_FFS" GROUP = CLOSED;
  --          This is done to prevent MAP from packing unrelated logic into
  --          the slices used by the RPMs. Doing so may cause the DIRT strings
  --          that define the IDDR -> fabric flop routing to later become
  --          unroutable during PAR because the unrelated logic placed by MAP
  --          may use routing resources required by the DIRT strings. MAP
  --          does not currently take into account DIRT strings when placing
  --          logic
  --***************************************************************************

  -- IDELAY to delay incoming data for synchronization purposes
  u_idelay_dq : IODELAY
    generic map (
      DELAY_SRC             => "I",
      IDELAY_TYPE           => "VARIABLE",
      HIGH_PERFORMANCE_MODE => HIGH_PERFORMANCE_MODE,
      IDELAY_VALUE          => 0,
      ODELAY_VALUE          => 0
      )
    port map (
      DATAOUT => dq_idelay,
      C       => clkdiv0,
      CE      => dlyce,
      DATAIN  => '0',
      IDATAIN => dq_in,
      INC     => dlyinc,
      ODATAIN => '0',
      RST     => dlyrst,
      T       => '0'
      );

  --***************************************************************************
  -- Rank 1 capture: Use IDDR to generate two SDR outputs
  --***************************************************************************

  -- invert clock to IDDR in order to use SAME_EDGE mode (otherwise, we "run
  -- out of clocks" because DQS is not continuous
  dq_iddr_clk <= not(dqs);

  --***************************************************************************
  -- Rank 2 capture: Use fabric flops to capture Rank 1 output. Use RPM and
  -- DIRT strings here.
  -- BEL ("Basic Element of Logic") and relative location constraints for
  -- second stage capture. C
  -- Varies according:
  --  (1) I/O column (left, center, right) used
  --  (2) Which I/O in I/O pair (master, slave) used
  --***************************************************************************

  -- Six different cases for the different I/O column, master/slave
  -- combinations (can't seem to do this using a localparam, which
  -- would be easier, XST doesn't allow it)

  --*****************************************************************
  -- master, left
  --*****************************************************************

  gen_stg2_0m: if ((DQ_MS = '1') and (DQ_COL = "00")) generate
    attribute HU_SET of u_ff_stg2a_fall     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg2a_rise     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg3b_fall     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg3b_rise     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg2b_fall     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg2b_rise     : label is "stg2_capture";

    attribute RLOC of u_ff_stg2a_fall     : label is "X2Y0";
    attribute RLOC of u_ff_stg2a_rise     : label is "X2Y0";
    attribute RLOC of u_ff_stg3b_fall     : label is "X2Y0";
    attribute RLOC of u_ff_stg3b_rise     : label is "X2Y0";
    attribute RLOC of u_ff_stg2b_fall     : label is "X3Y0";
    attribute RLOC of u_ff_stg2b_rise     : label is "X3Y0";

    attribute BEL  of u_ff_stg2a_fall     : label is "DFF";
    attribute BEL  of u_ff_stg2a_rise     : label is "CFF";
    attribute BEL  of u_ff_stg3b_fall     : label is "BFF";
    attribute BEL  of u_ff_stg3b_rise     : label is "AFF";
    attribute BEL  of u_ff_stg2b_fall     : label is "DFF";
    attribute BEL  of u_ff_stg2b_rise     : label is "CFF";

    attribute AREA_GROUP  of u_ff_stg2a_fall  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg2a_rise  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg3b_fall  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg3b_rise  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg2b_fall  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg2b_rise  : label is "DDR_CAPTURE_FFS";

    attribute syn_preserve of  u_ff_stg2a_fall : label is true;
    attribute syn_replicate of u_ff_stg2a_fall : label is false;
    attribute syn_preserve of  u_ff_stg2a_rise : label is true;
    attribute syn_replicate of u_ff_stg2a_rise : label is false;
    attribute syn_preserve of  u_ff_stg3b_fall : label is true;
    attribute syn_replicate of u_ff_stg3b_fall : label is false;
    attribute syn_preserve of  u_ff_stg3b_rise : label is true;
    attribute syn_replicate of u_ff_stg3b_rise : label is false;
    attribute syn_preserve of  u_ff_stg2b_fall : label is true;
    attribute syn_replicate of u_ff_stg2b_fall : label is false;
    attribute syn_preserve of  u_ff_stg2b_rise : label is true;
    attribute syn_replicate of u_ff_stg2b_rise : label is false;

  begin
    u_iddr_dq : IDDR
      generic map (
        DDR_CLK_EDGE  => "SAME_EDGE"
        )
      port map (
        Q1 => stg1_out_fall_0m,
        Q2 => stg1_out_rise_0m,
        C  => dq_iddr_clk,
        CE => ce,
        D  => dq_idelay,
        R  => '0',
        S  => '0'
        );

    --*********************************************************
    -- Slice #1 (posedge CLK): Used for:
    --  1. IDDR transfer to CLK0 rising edge domain ("stg2a")
    --  2. stg2 falling edge -> stg3 rising edge transfer
    --*********************************************************

    -- Stage 2 capture
    u_ff_stg2a_fall : FDRSE
      port map (
        Q    => stg2a_out_fall,
        C    => clk0,
        CE   => '1',
    D    => stg1_out_fall_0m,
        R    => '0',
        S    => '0'
        );
    u_ff_stg2a_rise : FDRSE
      port map (
        Q    => stg2a_out_rise,
        C    => clk0,
        CE   => '1',
    D    => stg1_out_rise_0m,
        R    => '0',
        S    => '0'
        );
    -- Stage 3 falling -> rising edge translation
    u_ff_stg3b_fall : FDRSE
      port map (
        Q    => stg3b_out_fall,
        C    => clk0,
        CE   => '1',
    D    => stg2b_out_fall,
        R    => '0',
        S    => '0'
        );
    u_ff_stg3b_rise : FDRSE
      port map (
        Q    => stg3b_out_rise,
        C    => clk0,
        CE   => '1',
    D    => stg2b_out_rise,
        R    => '0',
        S    => '0'
        );

    --*********************************************************
    -- Slice #2 (posedge CLK): Used for:
    --  1. IDDR transfer to CLK0 falling edge domain ("stg2b")
    --*********************************************************

    u_ff_stg2b_fall : FDRSE_1
      port map (
        Q    => stg2b_out_fall,
        C    => clk0,
        CE   => '1',
    D    => stg1_out_fall_0m,
        R    => '0',
        S    => '0'
        );

    u_ff_stg2b_rise : FDRSE_1
      port map (
        Q    => stg2b_out_rise,
        C    => clk0,
        CE   => '1',
    D    => stg1_out_rise_0m,
        R    => '0',
        S    => '0'
        );

  end generate;

  --*****************************************************************
  -- slave, left
  --*****************************************************************

  gen_stg2_0s: if ((DQ_MS = '0') and (DQ_COL = "00")) generate
    attribute HU_SET of u_ff_stg2a_fall     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg2a_rise     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg3b_fall     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg3b_rise     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg2b_fall     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg2b_rise     : label is "stg2_capture";

    attribute RLOC of u_ff_stg2a_fall     : label is "X0Y0";
    attribute RLOC of u_ff_stg2a_rise     : label is "X0Y0";
    attribute RLOC of u_ff_stg3b_fall     : label is "X0Y0";
    attribute RLOC of u_ff_stg3b_rise     : label is "X0Y0";
    attribute RLOC of u_ff_stg2b_fall     : label is "X1Y0";
    attribute RLOC of u_ff_stg2b_rise     : label is "X1Y0";

    attribute BEL  of u_ff_stg2a_fall     : label is "BFF";
    attribute BEL  of u_ff_stg2a_rise     : label is "CFF";
    attribute BEL  of u_ff_stg3b_fall     : label is "DFF";
    attribute BEL  of u_ff_stg3b_rise     : label is "AFF";
    attribute BEL  of u_ff_stg2b_fall     : label is "AFF";
    attribute BEL  of u_ff_stg2b_rise     : label is "CFF";

    attribute AREA_GROUP  of u_ff_stg2a_fall  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg2a_rise  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg3b_fall  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg3b_rise  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg2b_fall  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg2b_rise  : label is "DDR_CAPTURE_FFS";

    attribute syn_preserve of  u_ff_stg2a_fall : label is true;
    attribute syn_replicate of u_ff_stg2a_fall : label is false;
    attribute syn_preserve of  u_ff_stg2a_rise : label is true;
    attribute syn_replicate of u_ff_stg2a_rise : label is false;
    attribute syn_preserve of  u_ff_stg3b_fall : label is true;
    attribute syn_replicate of u_ff_stg3b_fall : label is false;
    attribute syn_preserve of  u_ff_stg3b_rise : label is true;
    attribute syn_replicate of u_ff_stg3b_rise : label is false;
    attribute syn_preserve of  u_ff_stg2b_fall : label is true;
    attribute syn_replicate of u_ff_stg2b_fall : label is false;
    attribute syn_preserve of  u_ff_stg2b_rise : label is true;
    attribute syn_replicate of u_ff_stg2b_rise : label is false;

  begin
    u_iddr_dq : IDDR
      generic map (
        DDR_CLK_EDGE  => "SAME_EDGE"
        )
      port map (
        Q1 => stg1_out_fall_0s,
        Q2 => stg1_out_rise_0s,
        C  => dq_iddr_clk,
        CE => ce,
        D  => dq_idelay,
        R  => '0',
        S  => '0'
        );

    u_ff_stg2a_fall : FDRSE
      port map (
        Q    => stg2a_out_fall,
        C    => clk0,
        CE   => '1',
    D    => stg1_out_fall_0s,
        R    => '0',
        S    => '0'
    );
    u_ff_stg2a_rise : FDRSE
      port map (
        Q    => stg2a_out_rise,
        C    => clk0,
        CE   => '1',
    D    => stg1_out_rise_0s,
        R    => '0',
        S    => '0'
        );

    u_ff_stg3b_fall : FDRSE
      port map (
        Q    => stg3b_out_fall,
        C    => clk0,
        CE   => '1',
    D    => stg2b_out_fall,
        R    => '0',
        S    => '0'
        );
    u_ff_stg3b_rise : FDRSE
      port map (
        Q    => stg3b_out_rise,
        C    => clk0,
        CE   => '1',
    D    => stg2b_out_rise,
        R    => '0',
        S    => '0'
        );

    u_ff_stg2b_fall : FDRSE_1
      port map (
        Q    => stg2b_out_fall,
        C    => clk0,
        CE   => '1',
    D    => stg1_out_fall_0s,
        R    => '0',
        S    => '0'
        );

    u_ff_stg2b_rise : FDRSE_1
      port map (
        Q    => stg2b_out_rise,
        C    => clk0,
        CE   => '1',
    D    => stg1_out_rise_0s,
        R    => '0',
        S    => '0'
        );

  end generate;

  --*****************************************************************
  -- master, center
  --*****************************************************************

  gen_stg2_1m: if ((DQ_MS = '1') and (DQ_COL = "01")) generate
    attribute HU_SET of u_ff_stg2a_fall     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg2a_rise     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg3b_fall     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg3b_rise     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg2b_fall     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg2b_rise     : label is "stg2_capture";

    attribute RLOC of u_ff_stg2a_fall     : label is "X0Y0";
    attribute RLOC of u_ff_stg2a_rise     : label is "X0Y0";
    attribute RLOC of u_ff_stg3b_fall     : label is "X0Y0";
    attribute RLOC of u_ff_stg3b_rise     : label is "X0Y0";
    attribute RLOC of u_ff_stg2b_fall     : label is "X1Y0";
    attribute RLOC of u_ff_stg2b_rise     : label is "X1Y0";

    attribute BEL  of u_ff_stg2a_fall     : label is "BFF";
    attribute BEL  of u_ff_stg2a_rise     : label is "AFF";
    attribute BEL  of u_ff_stg3b_fall     : label is "DFF";
    attribute BEL  of u_ff_stg3b_rise     : label is "CFF";
    attribute BEL  of u_ff_stg2b_fall     : label is "AFF";
    attribute BEL  of u_ff_stg2b_rise     : label is "BFF";

    attribute AREA_GROUP  of u_ff_stg2a_fall  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg2a_rise  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg3b_fall  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg3b_rise  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg2b_fall  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg2b_rise  : label is "DDR_CAPTURE_FFS";

    attribute syn_preserve of  u_ff_stg2a_fall : label is true;
    attribute syn_replicate of u_ff_stg2a_fall : label is false;
    attribute syn_preserve of  u_ff_stg2a_rise : label is true;
    attribute syn_replicate of u_ff_stg2a_rise : label is false;
    attribute syn_preserve of  u_ff_stg3b_fall : label is true;
    attribute syn_replicate of u_ff_stg3b_fall : label is false;
    attribute syn_preserve of  u_ff_stg3b_rise : label is true;
    attribute syn_replicate of u_ff_stg3b_rise : label is false;
    attribute syn_preserve of  u_ff_stg2b_fall : label is true;
    attribute syn_replicate of u_ff_stg2b_fall : label is false;
    attribute syn_preserve of  u_ff_stg2b_rise : label is true;
    attribute syn_replicate of u_ff_stg2b_rise : label is false;

  begin
    u_iddr_dq : IDDR
      generic map (
        DDR_CLK_EDGE  => "SAME_EDGE"
        )
      port map (
        Q1 => stg1_out_fall_1m,
        Q2 => stg1_out_rise_1m,
        C  => dq_iddr_clk,
        CE => ce,
        D  => dq_idelay,
        R  => '0',
        S  => '0'
        );

    u_ff_stg2a_fall : FDRSE
      port map (
        Q    => stg2a_out_fall,
        C    => clk0,
        CE   => '1',
    D    => stg1_out_fall_1m,
        R    => '0',
        S    => '0'
        );
    u_ff_stg2a_rise : FDRSE
      port map (
        Q    => stg2a_out_rise,
        C    => clk0,
        CE   => '1',
    D    => stg1_out_rise_1m,
        R    => '0',
        S    => '0'
        );

    u_ff_stg3b_fall : FDRSE
      port map (
        Q    => stg3b_out_fall,
        C    => clk0,
        CE   => '1',
    D    => stg2b_out_fall,
        R    => '0',
        S    => '0'
        );
    u_ff_stg3b_rise : FDRSE
      port map (
        Q    => stg3b_out_rise,
        C    => clk0,
        CE   => '1',
    D    => stg2b_out_rise,
        R    => '0',
        S    => '0'
        );

    u_ff_stg2b_fall : FDRSE_1
      port map (
        Q    => stg2b_out_fall,
        C    => clk0,
        CE   => '1',
    D    => stg1_out_fall_1m,
        R    => '0',
        S    => '0'
        );

    u_ff_stg2b_rise : FDRSE_1
      port map (
        Q    => stg2b_out_rise,
        C    => clk0,
        CE   => '1',
    D    => stg1_out_rise_1m,
        R    => '0',
        S    => '0'
        );

  end generate;

  --*****************************************************************
  -- slave, center
  --*****************************************************************

  gen_stg2_1s: if ((DQ_MS = '0') and (DQ_COL = "01")) generate
    attribute HU_SET of u_ff_stg2a_fall     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg2a_rise     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg3b_fall     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg3b_rise     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg2b_fall     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg2b_rise     : label is "stg2_capture";

    attribute RLOC of u_ff_stg2a_fall     : label is "X2Y0";
    attribute RLOC of u_ff_stg2a_rise     : label is "X2Y0";
    attribute RLOC of u_ff_stg3b_fall     : label is "X2Y0";
    attribute RLOC of u_ff_stg3b_rise     : label is "X2Y0";
    attribute RLOC of u_ff_stg2b_fall     : label is "X3Y0";
    attribute RLOC of u_ff_stg2b_rise     : label is "X3Y0";

    attribute BEL  of u_ff_stg2a_fall     : label is "CFF";
    attribute BEL  of u_ff_stg2a_rise     : label is "BFF";
    attribute BEL  of u_ff_stg3b_fall     : label is "DFF";
    attribute BEL  of u_ff_stg3b_rise     : label is "AFF";
    attribute BEL  of u_ff_stg2b_fall     : label is "CFF";
    attribute BEL  of u_ff_stg2b_rise     : label is "BFF";

    attribute AREA_GROUP  of u_ff_stg2a_fall  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg2a_rise  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg3b_fall  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg3b_rise  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg2b_fall  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg2b_rise  : label is "DDR_CAPTURE_FFS";

    attribute syn_preserve of  u_ff_stg2a_fall : label is true;
    attribute syn_replicate of u_ff_stg2a_fall : label is false;
    attribute syn_preserve of  u_ff_stg2a_rise : label is true;
    attribute syn_replicate of u_ff_stg2a_rise : label is false;
    attribute syn_preserve of  u_ff_stg3b_fall : label is true;
    attribute syn_replicate of u_ff_stg3b_fall : label is false;
    attribute syn_preserve of  u_ff_stg3b_rise : label is true;
    attribute syn_replicate of u_ff_stg3b_rise : label is false;
    attribute syn_preserve of  u_ff_stg2b_fall : label is true;
    attribute syn_replicate of u_ff_stg2b_fall : label is false;
    attribute syn_preserve of  u_ff_stg2b_rise : label is true;
    attribute syn_replicate of u_ff_stg2b_rise : label is false;

  begin
    u_iddr_dq : IDDR
      generic map (
        DDR_CLK_EDGE  => "SAME_EDGE"
        )
      port map (
        Q1 => stg1_out_fall_1s,
        Q2 => stg1_out_rise_1s,
        C  => dq_iddr_clk,
        CE => ce,
        D  => dq_idelay,
        R  => '0',
        S  => '0'
        );

    u_ff_stg2a_fall : FDRSE
      port map (
        Q    => stg2a_out_fall,
        C    => clk0,
        CE   => '1',
    D    => stg1_out_fall_1s,
        R    => '0',
        S    => '0'
        );
    u_ff_stg2a_rise : FDRSE
      port map (
        Q    => stg2a_out_rise,
        C    => clk0,
        CE   => '1',
    D    => stg1_out_rise_1s,
        R    => '0',
        S    => '0'
        );

    u_ff_stg3b_fall : FDRSE
      port map (
        Q    => stg3b_out_fall,
        C    => clk0,
        CE   => '1',
    D    => stg2b_out_fall,
        R    => '0',
        S    => '0'
        );
    u_ff_stg3b_rise : FDRSE
      port map (
        Q    => stg3b_out_rise,
        C    => clk0,
        CE   => '1',
    D    => stg2b_out_rise,
        R    => '0',
        S    => '0'
        );

    u_ff_stg2b_fall : FDRSE_1
      port map (
        Q    => stg2b_out_fall,
        C    => clk0,
        CE   => '1',
    D    => stg1_out_fall_1s,
        R    => '0',
        S    => '0'
        );

    u_ff_stg2b_rise : FDRSE_1
      port map (
        Q    => stg2b_out_rise,
        C    => clk0,
        CE   => '1',
    D    => stg1_out_rise_1s,
        R    => '0',
        S    => '0'
        );

  end generate;

  --*****************************************************************
  -- master, right
  --*****************************************************************

  gen_stg2_2m: if ((DQ_MS = '1') and (DQ_COL = "10")) generate
    attribute HU_SET of u_ff_stg2a_fall     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg2a_rise     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg3b_fall     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg3b_rise     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg2b_fall     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg2b_rise     : label is "stg2_capture";

    attribute RLOC of u_ff_stg2a_fall     : label is "X0Y0";
    attribute RLOC of u_ff_stg2a_rise     : label is "X0Y0";
    attribute RLOC of u_ff_stg3b_fall     : label is "X0Y0";
    attribute RLOC of u_ff_stg3b_rise     : label is "X0Y0";
    attribute RLOC of u_ff_stg2b_fall     : label is "X1Y0";
    attribute RLOC of u_ff_stg2b_rise     : label is "X1Y0";

    attribute BEL  of u_ff_stg2a_fall     : label is "AFF";
    attribute BEL  of u_ff_stg2a_rise     : label is "CFF";
    attribute BEL  of u_ff_stg3b_fall     : label is "DFF";
    attribute BEL  of u_ff_stg3b_rise     : label is "BFF";
    attribute BEL  of u_ff_stg2b_fall     : label is "AFF";
    attribute BEL  of u_ff_stg2b_rise     : label is "CFF";

    attribute AREA_GROUP  of u_ff_stg2a_fall  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg2a_rise  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg3b_fall  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg3b_rise  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg2b_fall  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg2b_rise  : label is "DDR_CAPTURE_FFS";

    attribute syn_preserve of  u_ff_stg2a_fall : label is true;
    attribute syn_replicate of u_ff_stg2a_fall : label is false;
    attribute syn_preserve of  u_ff_stg2a_rise : label is true;
    attribute syn_replicate of u_ff_stg2a_rise : label is false;
    attribute syn_preserve of  u_ff_stg3b_fall : label is true;
    attribute syn_replicate of u_ff_stg3b_fall : label is false;
    attribute syn_preserve of  u_ff_stg3b_rise : label is true;
    attribute syn_replicate of u_ff_stg3b_rise : label is false;
    attribute syn_preserve of  u_ff_stg2b_fall : label is true;
    attribute syn_replicate of u_ff_stg2b_fall : label is false;
    attribute syn_preserve of  u_ff_stg2b_rise : label is true;
    attribute syn_replicate of u_ff_stg2b_rise : label is false;

  begin
    u_iddr_dq : IDDR
      generic map (
        DDR_CLK_EDGE  => "SAME_EDGE"
        )
      port map (
        Q1 => stg1_out_fall_2m,
        Q2 => stg1_out_rise_2m,
        C  => dq_iddr_clk,
        CE => ce,
        D  => dq_idelay,
        R  => '0',
        S  => '0'
        );

    u_ff_stg2a_fall : FDRSE
      port map (
        Q    => stg2a_out_fall,
        C    => clk0,
        CE   => '1',
    D    => stg1_out_fall_2m,
        R    => '0',
        S    => '0'
        );
    u_ff_stg2a_rise : FDRSE
      port map (
        Q    => stg2a_out_rise,
        C    => clk0,
        CE   => '1',
    D    => stg1_out_rise_2m,
        R    => '0',
        S    => '0'
        );

    u_ff_stg3b_fall : FDRSE
      port map (
        Q    => stg3b_out_fall,
        C    => clk0,
        CE   => '1',
    D    => stg2b_out_fall,
        R    => '0',
        S    => '0'
        );
    u_ff_stg3b_rise : FDRSE
      port map (
        Q    => stg3b_out_rise,
        C    => clk0,
        CE   => '1',
    D    => stg2b_out_rise,
        R    => '0',
        S    => '0'
        );

    u_ff_stg2b_fall : FDRSE_1
      port map (
        Q    => stg2b_out_fall,
        C    => clk0,
        CE   => '1',
    D    => stg1_out_fall_2m,
        R    => '0',
        S    => '0'
        );

    u_ff_stg2b_rise : FDRSE_1
      port map (
        Q    => stg2b_out_rise,
        C    => clk0,
        CE   => '1',
    D    => stg1_out_rise_2m,
        R    => '0',
        S    => '0'
        );

  end generate;

  --*****************************************************************
  -- slave, right
  --*****************************************************************

  gen_stg2_2s: if ((DQ_MS = '0') and (DQ_COL = "10")) generate
    attribute HU_SET of u_ff_stg2a_fall     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg2a_rise     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg3b_fall     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg3b_rise     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg2b_fall     : label is "stg2_capture";
    attribute HU_SET of u_ff_stg2b_rise     : label is "stg2_capture";

    attribute RLOC of u_ff_stg2a_fall     : label is "X2Y0";
    attribute RLOC of u_ff_stg2a_rise     : label is "X2Y0";
    attribute RLOC of u_ff_stg3b_fall     : label is "X2Y0";
    attribute RLOC of u_ff_stg3b_rise     : label is "X2Y0";
    attribute RLOC of u_ff_stg2b_fall     : label is "X3Y0";
    attribute RLOC of u_ff_stg2b_rise     : label is "X3Y0";

    attribute BEL  of u_ff_stg2a_fall     : label is "BFF";
    attribute BEL  of u_ff_stg2a_rise     : label is "DFF";
    attribute BEL  of u_ff_stg3b_fall     : label is "CFF";
    attribute BEL  of u_ff_stg3b_rise     : label is "AFF";
    attribute BEL  of u_ff_stg2b_fall     : label is "AFF";
    attribute BEL  of u_ff_stg2b_rise     : label is "CFF";

    attribute AREA_GROUP  of u_ff_stg2a_fall  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg2a_rise  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg3b_fall  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg3b_rise  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg2b_fall  : label is "DDR_CAPTURE_FFS";
    attribute AREA_GROUP  of u_ff_stg2b_rise  : label is "DDR_CAPTURE_FFS";

    attribute syn_preserve of  u_ff_stg2a_fall : label is true;
    attribute syn_replicate of u_ff_stg2a_fall : label is false;
    attribute syn_preserve of  u_ff_stg2a_rise : label is true;
    attribute syn_replicate of u_ff_stg2a_rise : label is false;
    attribute syn_preserve of  u_ff_stg3b_fall : label is true;
    attribute syn_replicate of u_ff_stg3b_fall : label is false;
    attribute syn_preserve of  u_ff_stg3b_rise : label is true;
    attribute syn_replicate of u_ff_stg3b_rise : label is false;
    attribute syn_preserve of  u_ff_stg2b_fall : label is true;
    attribute syn_replicate of u_ff_stg2b_fall : label is false;
    attribute syn_preserve of  u_ff_stg2b_rise : label is true;
    attribute syn_replicate of u_ff_stg2b_rise : label is false;

  begin
    u_iddr_dq : IDDR
      generic map (
        DDR_CLK_EDGE  => "SAME_EDGE"
        )
      port map (
        Q1 => stg1_out_fall_2s,
        Q2 => stg1_out_rise_2s,
        C  => dq_iddr_clk,
        CE => ce,
        D  => dq_idelay,
        R  => '0',
        S  => '0'
        );

    u_ff_stg2a_fall : FDRSE
      port map (
        Q    => stg2a_out_fall,
        C    => clk0,
        CE   => '1',
    D    => stg1_out_fall_2s,
        R    => '0',
        S    => '0'
        );
    u_ff_stg2a_rise : FDRSE
      port map (
        Q    => stg2a_out_rise,
        C    => clk0,
        CE   => '1',
    D    => stg1_out_rise_2s,
        R    => '0',
        S    => '0'
        );

    u_ff_stg3b_fall : FDRSE
      port map (
        Q    => stg3b_out_fall,
        C    => clk0,
        CE   => '1',
    D    => stg2b_out_fall,
        R    => '0',
        S    => '0'
        );
    u_ff_stg3b_rise : FDRSE
      port map (
        Q    => stg3b_out_rise,
        C    => clk0,
        CE   => '1',
    D    => stg2b_out_rise,
        R    => '0',
        S    => '0'
        );

    u_ff_stg2b_fall : FDRSE_1
      port map (
        Q    => stg2b_out_fall,
        C    => clk0,
        CE   => '1',
    D    => stg1_out_fall_2s,
        R    => '0',
        S    => '0'
        );

    u_ff_stg2b_rise : FDRSE_1
      port map (
        Q    => stg2b_out_rise,
        C    => clk0,
        CE   => '1',
    D    => stg1_out_rise_2s,
        R    => '0',
        S    => '0'
        );

  end generate;

  --***************************************************************************
  -- Second stage flops clocked by posedge CLK0 don't need another layer of
  -- registering
  --***************************************************************************

  stg3a_out_rise <= stg2a_out_rise;
  stg3a_out_fall <= stg2a_out_fall;

  --*******************************************************************

  rd_data_rise <= stg3a_out_rise when (rd_data_sel = '1') else
                  stg3b_out_rise;
  rd_data_fall <= stg3a_out_fall when (rd_data_sel = '1') else
                  stg3b_out_fall;

end architecture syn;


