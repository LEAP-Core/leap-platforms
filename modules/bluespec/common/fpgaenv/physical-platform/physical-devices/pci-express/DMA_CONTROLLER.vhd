-------------------------------------------------------------------------------
-- Title      : DMA Controller
-- Project    : PCI Express Hardware Channel
-------------------------------------------------------------------------------
-- File       : DMA_CONTROLLER.vhd
-- Author     : Wang, Liang  <liang.wang@intel.com>
-- Company    : CTL Beijing
-- Created    : 2008-05-29
-- Last update: 2008-06-04
-- Platform   : Xilinx ISE9.2(IP update4), ModelSim SE 6.2e
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2008 CTL Beijing
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2007-12-25  0.9      lwang12 Created
-- 2008-05-29  1.0      lwang12 Prepare code for release
-------------------------------------------------------------------------------




library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;


entity DMA_CONTROLLER is
  port(
    ------ ports to high-level, h2f ports
    dma_out_h2f_ready          : out std_logic;
    dma_out_h2f_fifo_ready     : out std_logic;
    dma_in_h2f_en              : in  std_logic;
    dma_in_h2f_fifo_ack        : in  std_logic;
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

    ------ ports with TX_ENGINE
    mwr_start_o   : out std_logic;
    mwr_addr_o    : out std_logic_vector(31 downto 0);
    mwr_addr_hi_o : out std_logic_vector(31 downto 0);
    mwr_len_o     : out std_logic_vector(31 downto 0);
    mwr_count_o   : out std_logic_vector(31 downto 0);


    mrd_start_o   : out std_logic;
    mrd_addr_o    : out std_logic_vector(31 downto 0);
    mrd_addr_hi_o : out std_logic_vector(31 downto 0);
    mrd_len_o     : out std_logic_vector(31 downto 0);
    mrd_count_o   : out std_logic_vector(31 downto 0);

    f2h_fifo_empty : out std_logic;
    f2h_fifo_valid : out std_logic;
    f2h_fifo_ren   : in  std_logic;
    dma_f2h_data   : out std_logic_vector(63 downto 0);
    dma_f2h_done   : in  std_logic;

    ------- ports with RX_ENGINE
    dma_h2f_data_len : out std_logic_vector(31 downto 0);
    dma_h2f_done     : in  std_logic;
    wr_data_full     : out std_logic;
    wr_data_fen      : in  std_logic;
    dma_h2f_data     : in  std_logic_vector(63 downto 0);


    cfg_max_rd_req_size  : in std_logic_vector(2 downto 0);
    cfg_max_payload_size : in std_logic_vector(2 downto 0);

    hw_chnl_rst : in std_logic;
    clk         : in std_logic;
    rst_n       : in std_logic);
end DMA_CONTROLLER;

architecture rtl of DMA_CONTROLLER is
  component h2f_data_fifo
    port (
      din         : in  std_logic_vector(63 downto 0);
      rd_clk      : in  std_logic;
      rd_en       : in  std_logic;
      rst         : in  std_logic;
      wr_clk      : in  std_logic;
      wr_en       : in  std_logic;
      dout        : out std_logic_vector(63 downto 0);
      empty       : out std_logic;
      valid       : out std_logic;
      almost_full : out std_logic;
      full        : out std_logic);
  end component h2f_data_fifo;

  component f2h_data_fifo
    port (
      din         : in  std_logic_vector(63 downto 0);
      rd_clk      : in  std_logic;
      rd_en       : in  std_logic;
      rst         : in  std_logic;
      wr_clk      : in  std_logic;
      wr_en       : in  std_logic;
      dout        : out std_logic_vector(63 downto 0);
      valid       : out std_logic;
      empty       : out std_logic;
      almost_full : out std_logic;
      full        : out std_logic);
  end component;

  type h2f_state_type is (
    H2F_IDLE,
    H2F_DMA_1,
    H2F_DMA_2);
  signal H2F_STATE : h2f_state_type;
  signal h2f_len   : std_logic_vector(31 downto 0);


  type f2h_state_type is (
    F2H_IDLE,
    F2H_DMA_1,
    F2H_DMA_2);
  signal F2H_STATE            : f2h_state_type;
  signal f2h_len              : std_logic_vector(31 downto 0);
  signal f2h_fifo_almost_full : std_logic;


  signal clk_fifo   : std_logic;
  signal fifo_rst_p : std_logic;
begin


  clk_fifo   <= clk;
  fifo_rst_p <= (not rst_n) or (hw_chnl_rst);


  -- calculate mrd_len_o 
  process (cfg_max_rd_req_size, h2f_len)
  begin
    case cfg_max_rd_req_size is
      when "000" =>
        mrd_len_o                 <= x"00000020";
        mrd_count_o(31 downto 25) <= (others => '0');
        mrd_count_o(24 downto 0)  <= h2f_len(31 downto 7);
      when "001" =>
        mrd_len_o                 <= x"00000040";
        mrd_count_o(31 downto 24) <= (others => '0');
        mrd_count_o(23 downto 0)  <= h2f_len(31 downto 8);
      when "010" =>
        mrd_len_o                 <= x"00000080";
        mrd_count_o(31 downto 23) <= (others => '0');
        mrd_count_o(22 downto 0)  <= h2f_len(31 downto 9);
      when "011" =>
        mrd_len_o                 <= x"00000100";
        mrd_count_o(31 downto 22) <= (others => '0');
        mrd_count_o(21 downto 0)  <= h2f_len(31 downto 10);
      when "100" =>
        mrd_len_o                 <= x"00000200";
        mrd_count_o(31 downto 21) <= (others => '0');
        mrd_count_o(20 downto 0)  <= h2f_len(31 downto 11);
      when "101" =>
        mrd_len_o                 <= x"00000400";
        mrd_count_o(31 downto 20) <= (others => '0');
        mrd_count_o(19 downto 0)  <= h2f_len(31 downto 12);
      when others =>
        mrd_len_o   <= (others => '0');
        mrd_count_o <= (others => '0');
    end case;
  end process;

  -- calculate mwr_len_o
  process(cfg_max_payload_size, f2h_len)
  begin
    case cfg_max_payload_size is
      when "000" =>
        mwr_len_o                 <= x"00000020";
        mwr_count_o(31 downto 25) <= (others => '0');
        mwr_count_o(24 downto 0)  <= f2h_len(31 downto 7);
      when "001" =>
        mwr_len_o                 <= x"00000040";
        mwr_count_o(31 downto 24) <= (others => '0');
        mwr_count_o(23 downto 0)  <= f2h_len(31 downto 8);
      when "010" =>
        mwr_len_o                 <= x"00000080";
        mwr_count_o(31 downto 23) <= (others => '0');
        mwr_count_o(22 downto 0)  <= f2h_len(31 downto 9);
      when "011" =>
        mwr_len_o                 <= x"00000100";
        mwr_count_o(31 downto 22) <= (others => '0');
        mwr_count_o(21 downto 0)  <= f2h_len(31 downto 10);
      when "100" =>
        mwr_len_o                 <= x"00000200";
        mwr_count_o(31 downto 21) <= (others => '0');
        mwr_count_o(20 downto 0)  <= f2h_len(31 downto 11);
      when "101" =>
        mwr_len_o                 <= x"00000400";
        mwr_count_o(31 downto 20) <= (others => '0');
        mwr_count_o(19 downto 0)  <= f2h_len(31 downto 12);
      when others =>
        mwr_len_o   <= (others => '0');
        mwr_count_o <= (others => '0');
    end case;
  end process;


  h2f_data : h2f_data_fifo port map (
    rst => fifo_rst_p,

    rd_clk => clk_fifo,
    rd_en  => dma_in_h2f_fifo_ack,
    dout   => dma_out_h2f_fifo_data,
    empty  => open,
    valid  => dma_out_h2f_fifo_ready,

    wr_clk      => clk,
    din         => dma_h2f_data,
    wr_en       => wr_data_fen,
    full        => open,
    almost_full => wr_data_full);
  -- end port map of "h2f_data"
  
  f2h_data : f2h_data_fifo port map (
    rst => fifo_rst_p,

    dout   => dma_f2h_data,
    empty  => f2h_fifo_empty,
    valid  => f2h_fifo_valid,
    rd_clk => clk,
    rd_en  => f2h_fifo_ren,

    din         => dma_in_f2h_fifo_data,
    wr_clk      => clk_fifo,
    wr_en       => dma_in_f2h_fifo_data_valid,
    full        => open,
    almost_full => f2h_fifo_almost_full);     
  -- end port map of "f2h_data"
  dma_out_f2h_fifo_ready <= not (f2h_fifo_almost_full);

  -- h2f state machine
  process (clk, rst_n, hw_chnl_rst)
  begin
    if (rst_n = '0' or hw_chnl_rst = '1') then
      dma_out_h2f_ready <= '1';
      h2f_len           <= (others => '0');
      mrd_start_o       <= '0';

      mrd_addr_o       <= (others => '0');
      mrd_addr_hi_o    <= (others => '0');
      dma_h2f_data_len <= (others => '0');

    elsif rising_edge(clk) then
      case H2F_STATE is
        when H2F_IDLE =>
          if (dma_in_h2f_en = '1') then
            dma_out_h2f_ready <= '0';
            mrd_addr_o        <= dma_in_h2f_paddr(31 downto 0);
            mrd_addr_hi_o     <= dma_in_h2f_paddr(63 downto 32);
            h2f_len           <= dma_in_h2f_len;
            dma_h2f_data_len  <= dma_in_h2f_len;
            mrd_start_o       <= '1';
            H2F_STATE         <= H2F_DMA_1;
          else
            dma_out_h2f_ready <= '1';
            mrd_addr_o        <= (others => '0');
            mrd_addr_hi_o     <= (others => '0');
            h2f_len           <= (others => '0');
            H2F_STATE         <= H2F_IDLE;
          end if;
          
        when H2F_DMA_1 =>
          mrd_start_o <= '0';
          H2F_STATE   <= H2F_DMA_2;
          
        when H2F_DMA_2 =>
          if (dma_h2f_done = '1') then
            dma_out_h2f_ready <= '1';
            H2F_STATE         <= H2F_IDLE;
          else
            H2F_STATE <= H2F_DMA_2;
          end if;
      end case;
    end if;
  end process;

  -- f2h state machine
  process (clk, rst_n, hw_chnl_rst)
  begin
    if (rst_n = '0' or hw_chnl_rst = '1') then
      dma_out_f2h_ready <= '1';
      f2h_len           <= (others => '0');
      mwr_start_o       <= '0';
      mwr_addr_o        <= (others => '0');
      mwr_addr_hi_o     <= (others => '0');
    elsif rising_edge(clk) then
      case F2H_STATE is
        when F2H_IDLE =>

          if (dma_in_f2h_en = '1') then
            dma_out_f2h_ready <= '0';
            mwr_addr_o        <= dma_in_f2h_paddr(31 downto 0);
            mwr_addr_hi_o     <= dma_in_f2h_paddr(63 downto 32);
            f2h_len           <= dma_in_f2h_len;
            mwr_start_o       <= '1';
            F2H_STATE         <= F2H_DMA_1;
          else
            dma_out_f2h_ready <= '1';
            mwr_addr_o        <= (others => '0');
            mwr_addr_hi_o     <= (others => '0');
            f2h_len           <= (others => '0');
            mwr_start_o       <= '0';
            F2H_STATE         <= F2H_IDLE;
          end if;
          
        when F2H_DMA_1 =>
          mwr_start_o <= '0';
          F2H_STATE   <= F2H_DMA_2;
          
        when F2H_DMA_2 =>
          if (dma_f2h_done = '1') then
            dma_out_f2h_ready <= '1';
            F2H_STATE         <= F2H_IDLE;
          else
            F2H_STATE <= F2H_DMA_2;
          end if;
      end case;
    end if;
  end process;
  
end rtl;

