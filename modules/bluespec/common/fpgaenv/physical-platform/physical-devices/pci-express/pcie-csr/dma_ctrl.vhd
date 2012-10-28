-------------------------------------------------------------------------------
-- Title        : DMA controller
-- Project      : 
-------------------------------------------------------------------------------
-- File         : dma_ctrl.vhd
-- Author       : Wang, Liang  <liang.wang@intel.com>
-- Company      : CTL Beijing, Intel
-- Created      : 2008-10-17
-- Last update  : 2008-10-17
-- Platform     : Virtex 5 vlx110t-ff1136-1
-- Targets      : XC5VLX110T-FF1136-1
-- Simulators   : ModelSim SE 6.2e
-- Synthesizers : XST embedded in ISE
-- Standard     : VHDL'87
-------------------------------------------------------------------------------
-- Description: control the DMA transactions
-------------------------------------------------------------------------------
-- Copyright (c) 2008 CTL Beijing, Intel
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2008-10-17  1.0      lwang12 Created
-------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use ieee.numeric_std.all;

entity dma_ctrl is
  port(
    ------ ports to high-level, h2f ports
    dma_out_h2f_ready          : out std_logic;
    dma_out_h2f_fifo_ready     : out std_logic;
    dma_in_h2f_en              : in  std_logic;
    dma_in_h2f_fifo_ack        : in  std_logic;
    dma_out_h2f_fifo_empty     : out std_logic;
    dma_in_h2f_paddr           : in  std_logic_vector(63 downto 0);
    dma_in_h2f_len             : in  std_logic_vector(31 downto 0);
    dma_out_h2f_fifo_data      : out std_logic_vector(63 downto 0);

    ------ ports to high-level, f2h ports
    dma_out_f2h_ready          : out std_logic;
    dma_out_f2h_fifo_ready     : out std_logic;
    dma_in_f2h_en              : in  std_logic;
    dma_in_f2h_fifo_data_valid : in  std_logic;
    dma_in_f2h_paddr           : in  std_logic_vector(63 downto 0);
    dma_in_f2h_len             : in  std_logic_vector(31 downto 0);
    dma_in_f2h_fifo_data       : in  std_logic_vector(63 downto 0);

    ------ ports with tx_wrapper
    mwr64_start     : out std_logic;
    mwr64_start_ack : in  std_logic;
    mwr64_finish    : in  std_logic;
    mwr64_len       : out std_logic_vector(9 downto 0);
    mwr64_tag       : out std_logic_vector(7 downto 0);
    mwr64_addr      : out std_logic_vector(63 downto 0);

    f2h_fifo_valid : out std_logic;
    f2h_fifo_ren   : in  std_logic;
    f2h_fifo_data  : out std_logic_vector(63 downto 0);

    mrd64_req_start     : out std_logic;
    mrd64_req_start_ack : in  std_logic;
    mrd64_req_finish    : in  std_logic;
    mrd64_req_tag       : out std_logic_vector(7 downto 0);
    mrd64_req_len       : out std_logic_vector(9 downto 0);
    mrd64_req_addr      : out std_logic_vector(63 downto 0);

    ------ ports with rx_wrapper
    h2f_fifo_data : in  std_logic_vector(63 downto 0);
    h2f_fifo_full : out std_logic;
    h2f_fifo_wen  : in  std_logic;

    cpld_recv_finish : in std_logic;
    cpld_recv_len    : in std_logic_vector(9 downto 0);

    ------ PCIe Endpoint ports(CFG)
    cfg_max_rd_req_size  : in std_logic_vector(2 downto 0);
    cfg_max_payload_size : in std_logic_vector(2 downto 0);
    cfg_ext_tag_en       : in std_logic;

    hw_chnl_rst : in std_logic;
    clk         : in std_logic;
    rst_n       : in std_logic);
end dma_ctrl;

architecture rtl of dma_ctrl is
  component h2f_data_fifo
    port (
      clk         : in  std_logic;
      din         : in  std_logic_vector(63 downto 0);
      rd_en       : in  std_logic;
      rst         : in  std_logic;
      wr_en       : in  std_logic;
      almost_full : out std_logic;
      dout        : out std_logic_vector(63 downto 0);
      empty       : out std_logic;
      full        : out std_logic;
      valid       : out std_logic);
  end component;

  component f2h_data_fifo
    port (
      clk         : in  std_logic;
      din         : in  std_logic_vector(63 downto 0);
      rd_en       : in  std_logic;
      rst         : in  std_logic;
      wr_en       : in  std_logic;
      almost_full : out std_logic;
      dout        : out std_logic_vector(63 downto 0);
      empty       : out std_logic;
      full        : out std_logic;
      valid       : out std_logic);
  end component;
  
  type h2f_recv_state_type is (
    H2F_RECV_IDLE,
    H2F_RECV_ST_1);
  signal h2f_recv_state : h2f_recv_state_type;

  signal h2f_req_len_rem  : std_logic_vector(31 downto 0);
  signal h2f_recv_finish  : std_logic;
  signal h2f_recv_len_rem : std_logic_vector(31 downto 0);

  type f2h_state_type is (
    F2H_IDLE,
    F2H_DMA_1,
    F2H_DMA_2
    );
  signal F2H_STATE : f2h_state_type;

  signal f2h_cur_addr64 : std_logic_vector(63 downto 0);
  signal f2h_len_rem    : std_logic_vector(31 downto 0);
  signal f2h_finish     : std_logic;

  signal f2h_fifo_full        : std_logic;
  signal f2h_fifo_almost_full : std_logic;

  signal mwr64_max_len      : std_logic_vector(31 downto 0);
  signal mwr64_max_len_code : std_logic_vector(9 downto 0);
  signal mwr64_count        : std_logic_vector(7 downto 0);
  signal h2f_cur_addr64     : std_logic_vector(63 downto 0);
  signal h2f_req_finish     : std_logic;

  signal mrd64_req_max_len      : std_logic_vector(31 downto 0);
  signal mrd64_req_max_len_code : std_logic_vector(9 downto 0);
  signal mrd64_req_count        : std_logic_vector(7 downto 0);

  type h2f_req_state_type is (
    H2F_REQ_IDLE,
    H2F_REQ_DMA_1,
    H2F_REQ_DMA_2,
    H2F_REQ_DMA_3);
  signal h2f_req_state  : h2f_req_state_type;
  signal h2f_recv_start : std_logic;

  signal clk_d2     : std_logic;
  signal clk_cnt    : std_logic_vector(3 downto 0);
  signal clk_fifo   : std_logic;
  signal fifo_rst_p : std_logic;
begin

  h2f_data : h2f_data_fifo
    port map (
      rst => fifo_rst_p,

      clk   => clk_fifo,
      rd_en => dma_in_h2f_fifo_ack,
      dout  => dma_out_h2f_fifo_data,
      empty => dma_out_h2f_fifo_empty,
      valid => dma_out_h2f_fifo_ready,

      din         => h2f_fifo_data,
      wr_en       => h2f_fifo_wen,
      full        => open,
      almost_full => h2f_fifo_full);
  -- end port map of "h2f_data"

  f2h_data : f2h_data_fifo
    port map (
      rst => fifo_rst_p,

      dout  => f2h_fifo_data,
      empty => open,                    --f2h_fifo_empty,
      valid => f2h_fifo_valid,
      clk   => clk,
      rd_en => f2h_fifo_ren,

      din         => dma_in_f2h_fifo_data,
      wr_en       => dma_in_f2h_fifo_data_valid,
      full        => f2h_fifo_full,
      almost_full => f2h_fifo_almost_full);     
  -- end port map of "f2h_data"

  dma_out_f2h_fifo_ready <= not (f2h_fifo_almost_full);
  -- clock generator
  process (clk, rst_n)
  begin
    if (rst_n = '0') then
      clk_cnt <= "0000";
    elsif (rising_edge(clk)) then
      clk_cnt <= clk_cnt + 1;
    end if;
  end process;
  clk_d2     <= clk_cnt(0);
--      clk_fifo <= clk_d2;
  clk_fifo   <= clk;
  fifo_rst_p <= (not rst_n) or (hw_chnl_rst);


  -- purpose: Calculate max read request TLP length
  -- type   : combinational
  -- inputs : cfg_max_rd_req_size
  -- outputs: mrd64_req_max_len
  calc_req_size : process (cfg_max_rd_req_size)
  begin  -- process calc_req_size
    case cfg_max_rd_req_size is
      when "000"  => mrd64_req_max_len <= x"00000080"; mrd64_req_max_len_code <= "0000100000";
      when "001"  => mrd64_req_max_len <= x"00000100"; mrd64_req_max_len_code <= "0001000000";
      when "010"  => mrd64_req_max_len <= x"00000200"; mrd64_req_max_len_code <= "0010000000";
      when "011"  => mrd64_req_max_len <= x"00000400"; mrd64_req_max_len_code <= "0100000000";
      when "100"  => mrd64_req_max_len <= x"00000800"; mrd64_req_max_len_code <= "1000000000";
      when "101"  => mrd64_req_max_len <= x"00001000"; mrd64_req_max_len_code <= "0000000000";
      when others => mrd64_req_max_len <= (others => '0');
    end case;
  end process calc_req_size;

  -- purpose: Calculate max memory write TLP length
  -- type   : combinational
  -- inputs : cfg_max_payload_size
  -- outputs: mwr64_max_len
  calc_tlp_size : process (cfg_max_payload_size)
  begin  -- process calc_tlp_size
    case cfg_max_payload_size is
      when "000"  => mwr64_max_len <= x"00000080"; mwr64_max_len_code <= "0000100000";
      when "001"  => mwr64_max_len <= x"00000100"; mwr64_max_len_code <= "0001000000";
      when "010"  => mwr64_max_len <= x"00000200"; mwr64_max_len_code <= "0010000000";
      when "011"  => mwr64_max_len <= x"00000400"; mwr64_max_len_code <= "0100000000";
      when "100"  => mwr64_max_len <= x"00000800"; mwr64_max_len_code <= "1000000000";
      when "101"  => mwr64_max_len <= x"00001000"; mwr64_max_len_code <= "0000000000";
      when others => mwr64_max_len <= (others => '0');
    end case;
  end process calc_tlp_size;

  -- purpose: Calculate mrd64_req_count
  -- type   : combinational
  -- inputs : cfg_max_rd_req_size, h2f_req_len_rem
  -- outputs: mrd64_req_count
  calc_req_tag : process (cfg_max_rd_req_size, h2f_req_len_rem)
  begin  -- process calc_req_tag
    case cfg_max_rd_req_size is
      when "000"  => mrd64_req_count <= h2f_req_len_rem(14 downto 7);
      when "001"  => mrd64_req_count <= h2f_req_len_rem(15 downto 8);
      when "010"  => mrd64_req_count <= h2f_req_len_rem(16 downto 9);
      when "011"  => mrd64_req_count <= h2f_req_len_rem(17 downto 10);
      when "100"  => mrd64_req_count <= h2f_req_len_rem(18 downto 11);
      when "101"  => mrd64_req_count <= h2f_req_len_rem(19 downto 12);
      when others => mrd64_req_count <= (others => '0');
    end case;
  end process calc_req_tag;
  -- if cfg_ext_tag_en = '1', the request tag is 8bits
  -- else, the request tag is 5bits, higher bits is reserved
  mrd64_req_tag <= mrd64_req_count when (cfg_ext_tag_en = '1') else ("000" & mrd64_req_count(4 downto 0));


  -- h2f state machine
  mrd64_req_addr <= h2f_cur_addr64;
  mrd64_req_len  <= h2f_req_len_rem(11 downto 2) when (h2f_req_len_rem < mrd64_req_max_len) else mrd64_req_max_len_code;

  h2f_req_sm : process (clk, rst_n)
  begin
    if (rst_n = '0') then
      dma_out_h2f_ready <= '1';

      mrd64_req_start <= '0';
      h2f_recv_start  <= '0';

      h2f_cur_addr64  <= (others => '0');
      h2f_req_len_rem <= (others => '0');

      h2f_req_finish <= '0';

      h2f_req_state <= H2F_REQ_IDLE;
    elsif rising_edge(clk) then
      if (hw_chnl_rst = '1') then
        -- signals reset
        h2f_cur_addr64  <= (others => '0');
        h2f_req_len_rem <= (others => '0');

        mrd64_req_start <= '0';
        h2f_recv_start  <= '0';

        h2f_req_finish <= '0';

        h2f_req_state <= H2F_REQ_IDLE;
      else
        case h2f_req_state is
          when H2F_REQ_IDLE =>
            if (dma_in_h2f_en = '1') then
              dma_out_h2f_ready <= '0';

              h2f_cur_addr64  <= dma_in_h2f_paddr;
              h2f_req_len_rem <= dma_in_h2f_len;

              mrd64_req_start <= '1';
              h2f_recv_start  <= '1';  --local signal communicate with H2F_REQ_RECV_SM
              h2f_req_finish  <= '0';

              h2f_req_state <= H2F_REQ_DMA_1;
            else
              dma_out_h2f_ready <= '1';

              h2f_cur_addr64  <= (others => '0');
              h2f_req_len_rem <= (others => '0');

              mrd64_req_start <= '0';
              h2f_recv_start  <= '0';
              h2f_req_finish  <= '0';

              h2f_req_state <= H2F_REQ_IDLE;
            end if;
          when H2F_REQ_DMA_1 =>
            if (mrd64_req_start_ack = '1') then
              if (h2f_req_len_rem > mrd64_req_max_len) then
                mrd64_req_start <= '1';
                h2f_req_finish  <= '0';

                h2f_cur_addr64  <= h2f_cur_addr64 + mrd64_req_max_len;
                h2f_req_len_rem <= h2f_req_len_rem - mrd64_req_max_len;
              else
                mrd64_req_start <= '0';
                h2f_req_finish  <= '1';
              end if;
              h2f_req_state <= H2F_REQ_DMA_2;
            else
              mrd64_req_start <= '1';
              h2f_req_state   <= H2F_REQ_DMA_1;
            end if;

            h2f_recv_start <= '0';

          when H2F_REQ_DMA_2 =>
            if (mrd64_req_finish = '1') then
              if (h2f_req_finish = '1') then
                h2f_req_state <= H2F_REQ_DMA_3;  -- goto wait receive finish
              else
                h2f_req_state <= H2F_REQ_DMA_1;
              end if;
            else
              h2f_req_state <= H2F_REQ_DMA_2;
            end if;

          when H2F_REQ_DMA_3 =>
            if (h2f_recv_finish = '1') then
              dma_out_h2f_ready <= '1';

              h2f_req_state <= H2F_REQ_IDLE;

            else
              h2f_req_state <= H2F_REQ_DMA_3;
            end if;
        end case;
        
      end if;
    end if;
  end process h2f_req_sm;

  -- purpose: control of receive in Host2FPGA transaction
  -- type   : sequential
  -- inputs : clk, rst_n
  -- outputs: 
  h2f_recv_sm : process (clk, rst_n)
  begin  -- process h2f_recv_sm
    if (rst_n = '0') then               -- asynchronous reset (active low)

      h2f_recv_finish <= '0';

      h2f_recv_len_rem <= (others => '0');

      h2f_recv_state <= H2F_RECV_IDLE;
    elsif (rising_edge(clk)) then       -- rising clock edge
      if (hw_chnl_rst = '1') then
        --do reset
        h2f_recv_finish <= '0';
      else
        case h2f_recv_state is
          when H2F_RECV_IDLE =>
            if (h2f_recv_start = '1') then
              h2f_recv_len_rem <= h2f_req_len_rem;

              h2f_recv_finish <= '0';

              h2f_recv_state <= H2F_RECV_ST_1;
            else
              h2f_recv_finish <= '0';

              h2f_recv_state <= H2F_RECV_IDLE;
            end if;

          when H2F_RECV_ST_1 =>
            if (cpld_recv_finish = '1') then
              if (h2f_recv_len_rem = (cpld_recv_len&"00")) then
                h2f_recv_finish <= '1';

                h2f_recv_state <= H2F_RECV_IDLE;
              else
                --cpld_recv_len is counted in DWords
                --h2f_recv_len_rem is counted in Bytes
                h2f_recv_len_rem <= h2f_recv_len_rem - (cpld_recv_len & "00");

                h2f_recv_state <= H2F_RECV_ST_1;
              end if;
            else
              h2f_recv_state <= H2F_RECV_ST_1;
            end if;
        end case;
      end if;
    end if;
  end process h2f_recv_sm;


  -- f2h state machine  
  mwr64_addr <= f2h_cur_addr64;
  mwr64_len  <= f2h_len_rem(11 downto 2) when (f2h_len_rem < mwr64_max_len) else mwr64_max_len_code;


  -- purpose: Calculate mwr64_count
  -- type   : combinational
  -- inputs : cfg_max_payload_size, f2h_len_rem
  -- outputs: mrd64_req_count
  calc_tag : process (cfg_max_payload_size, f2h_len_rem)
  begin  -- process calc_req_tag
    case cfg_max_payload_size is
      when "000"  => mwr64_count <= f2h_len_rem(14 downto 7);
      when "001"  => mwr64_count <= f2h_len_rem(15 downto 8);
      when "010"  => mwr64_count <= f2h_len_rem(16 downto 9);
      when "011"  => mwr64_count <= f2h_len_rem(17 downto 10);
      when "100"  => mwr64_count <= f2h_len_rem(18 downto 11);
      when "101"  => mwr64_count <= f2h_len_rem(19 downto 12);
      when others => mwr64_count <= (others => '0');
    end case;
  end process calc_tag;

  mwr64_tag <= mwr64_count when (cfg_ext_tag_en = '1') else ("000" & mwr64_count(4 downto 0));

  -- purpose: control logic of Host2FPGA
  -- type   : sequential
  -- inputs : clk, rst_n
  -- outputs: 
  F2H_SM : process (clk, rst_n)
  begin  -- process F2H_SM
    if (rst_n = '0') then               -- asynchronous reset (active low)
      dma_out_f2h_ready <= '1';
      mwr64_start       <= '0';
      f2h_cur_addr64    <= (others => '0');
      f2h_len_rem       <= (others => '0');

      f2h_finish <= '0';

      f2h_state <= F2H_IDLE;
      
    elsif rising_edge(clk) then         -- rising clock edge
      if (hw_chnl_rst = '1') then
        dma_out_f2h_ready <= '1';
        mwr64_start       <= '0';
        f2h_cur_addr64    <= (others => '0');
        f2h_len_rem       <= (others => '0');

        F2H_STATE <= F2H_IDLE;
      else
        case F2H_STATE is
          when F2H_IDLE =>
            if (dma_in_f2h_en = '1') then
              dma_out_f2h_ready <= '0';

              f2h_cur_addr64 <= dma_in_f2h_paddr;
              f2h_len_rem    <= dma_in_f2h_len;

              mwr64_start <= '1';

              F2H_STATE <= F2H_DMA_1;
            else
              dma_out_f2h_ready <= '1';
              mwr64_start       <= '0';

              f2h_cur_addr64 <= (others => '0');
              f2h_len_rem    <= (others => '0');

              F2H_STATE <= F2H_IDLE;
            end if;

          when F2H_DMA_1 =>
            if (mwr64_start_ack = '1') then
              if (f2h_len_rem > mwr64_max_len) then
                f2h_finish     <= '0';
                f2h_cur_addr64 <= f2h_cur_addr64 + mwr64_max_len;
                f2h_len_rem    <= f2h_len_rem - mwr64_max_len;
              else
                mwr64_start <= '0';
                f2h_finish  <= '1';
              end if;
              F2H_STATE <= F2H_DMA_2;
            else
              mwr64_start <= '1';
              F2H_STATE   <= F2H_DMA_1;
            end if;

          when F2H_DMA_2 =>
            if (mwr64_finish = '1') then
              if (f2h_finish = '1') then
                dma_out_f2h_ready <= '1';
                F2H_STATE         <= F2H_IDLE;
              else
                F2H_STATE <= F2H_DMA_1;
              end if;
            else
              f2h_state <= F2H_DMA_2;
            end if;
        end case;
      end if;
    end if;
  end process;

end rtl;

