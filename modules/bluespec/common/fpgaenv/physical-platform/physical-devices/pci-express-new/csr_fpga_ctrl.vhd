-------------------------------------------------------------------------------
-- Title        : csr_fpga_ctrl.vhd
-- Project      : 
-------------------------------------------------------------------------------
-- File         : csr_fpga_ctrl.vhd
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
-- Description: Control the access from/to fpga side
-------------------------------------------------------------------------------
-- Copyright (c) 2008 CTL Beijing, Intel
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2008-10-20  1.0      lwang12 Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity csr_fpga_ctrl is
  port(
    clk   : in std_logic;
    rst_n : in std_logic;

    hw_chnl_rst : in std_logic;

    bram_addr : out std_logic_vector(7 downto 0);
    bram_din  : out std_logic_vector(31 downto 0);
    bram_dout : in  std_logic_vector(31 downto 0);
    bram_wen  : out std_logic;

    csr_out_rd_ready : out std_logic;
    csr_out_rd_done  : out std_logic;
    csr_in_rd_en     : in  std_logic;
    csr_in_rd_ack    : in  std_logic;
    csr_out_rd_data  : out std_logic_vector((32 - 1) downto 0);
    csr_in_rd_index  : in  std_logic_vector((8 - 1) downto 0);
    csr_out_wr_ready : out std_logic;
    csr_in_wr_en     : in  std_logic;
    csr_in_wr_data   : in  std_logic_vector((32 - 1) downto 0);
    csr_in_wr_index  : in  std_logic_vector((8 - 1) downto 0));
end csr_fpga_ctrl;

architecture rtl of csr_fpga_ctrl is
  
  type csr_ctrl_state_type is (
    CSR_RST,
    CSR_READ,
    CSR_READ_ACK,
    CSR_WRITE);
  signal csr_st : csr_ctrl_state_type;

  signal csr_ready : std_logic;

  signal csr_wr_index : std_logic_vector(7 downto 0);
  signal csr_wr_data  : std_logic_vector(31 downto 0);

  signal do_write     : std_logic;
  signal csr_rd_delay : std_logic;


  --wires for chipscope
  signal bram_addr_c : std_logic_vector(7 downto 0);
  signal bram_din_c  : std_logic_vector(31 downto 0);
  signal bram_wen_c  : std_logic;

  signal csr_out_rd_ready_c : std_logic;
  signal csr_out_rd_done_c  : std_logic;
  signal csr_in_rd_en_c     : std_logic;
  signal csr_in_rd_ack_c    : std_logic;
  signal csr_out_rd_data_c  : std_logic_vector((32 - 1) downto 0);
  signal csr_in_rd_index_c  : std_logic_vector((8 - 1) downto 0);
  signal csr_out_wr_ready_c : std_logic;
  signal csr_in_wr_en_c     : std_logic;
  signal csr_in_wr_data_c   : std_logic_vector((32 - 1) downto 0);
  signal csr_in_wr_index_c  : std_logic_vector((8 - 1) downto 0);
  
  
begin  -- rtl

  csr_out_rd_ready  <= csr_out_rd_ready_c;
  csr_out_rd_done   <= csr_out_rd_done_c;
  csr_in_rd_en_c    <= csr_in_rd_en;
  csr_in_rd_ack_c   <= csr_in_rd_ack;
  csr_out_rd_data   <= csr_out_rd_data_c;
  csr_in_rd_index_c <= csr_in_rd_index;
  csr_out_wr_ready  <= csr_out_wr_ready_c;
  csr_in_wr_en_c    <= csr_in_wr_en;
  csr_in_wr_data_c  <= csr_in_wr_data;
  csr_in_wr_index_c <= csr_in_wr_index;



  bram_din  <= bram_din_c;
  bram_addr <= bram_addr_c;
  bram_wen  <= bram_wen_c;


  csr_out_rd_ready_c <= csr_ready;
  csr_out_wr_ready_c <= csr_ready;

  -- purpose: main state machine to the control CSR of FPGA side
  -- type   : sequential
  -- inputs : clk, rst_n
  -- outputs: 
  main_sm : process (clk, rst_n)
  begin  -- process regular_csr_sm
    if (rst_n = '0') then               -- asynchronous reset (active low)
      csr_ready <= '1';

      csr_out_rd_done_c <= '0';
      csr_out_rd_data_c <= (others => '0');

      csr_wr_index <= (others => '0');
      csr_wr_data  <= (others => '0');

      do_write <= '0';

      bram_addr_c <= (others => '0');
      bram_din_c  <= (others => '0');
      bram_wen_c  <= '0';

      csr_rd_delay <= '0';

      csr_st <= CSR_RST;
    elsif (rising_edge(clk)) then       -- rising clock edge
      if (hw_chnl_rst = '1') then
        csr_ready <= '1';

        csr_out_rd_done_c <= '0';
        csr_out_rd_data_c <= (others => '0');

        csr_wr_index <= (others => '0');
        csr_wr_data  <= (others => '0');

        do_write <= '0';

        bram_addr_c <= (others => '0');
        bram_din_c  <= (others => '0');
        bram_wen_c  <= '0';

        csr_rd_delay <= '0';

        csr_st <= CSR_RST;
        
      else
        case csr_st is
          when CSR_RST =>
            if (csr_in_rd_en_c = '1') then
              if (csr_in_wr_en_c = '1') then
                csr_wr_index <= csr_in_wr_index_c;
                csr_wr_data  <= csr_in_wr_data_c;

                do_write <= '1';
              else
                do_write <= '0';
              end if;

              csr_ready <= '0';

              bram_addr_c <= csr_in_rd_index_c;
              bram_wen_c  <= '0';

              csr_st <= CSR_READ;
            elsif (csr_in_wr_en_c = '1') then

              bram_addr_c <= csr_in_wr_index_c;
              bram_din_c  <= csr_in_wr_data_c;
              bram_wen_c  <= '1';

              csr_ready <= '0';

              csr_st <= CSR_WRITE;
            else
              csr_ready <= '1';

              csr_st <= CSR_RST;
            end if;

          when CSR_READ =>
            if (csr_rd_delay = '0') then
              csr_rd_delay <= '1';
              csr_st       <= CSR_READ;
            else
              csr_out_rd_data_c <= bram_dout;
              csr_out_rd_done_c <= '1';

              csr_rd_delay <= '0';

              csr_st <= CSR_READ_ACK;
            end if;
          when CSR_READ_ACK =>
            if (csr_in_rd_ack_c = '1') then
              if (do_write = '1') then
                bram_addr_c <= csr_wr_index;
                bram_din_c  <= csr_wr_data;
                bram_wen_c  <= '1';

                csr_st <= CSR_WRITE;
              else
                
                csr_ready <= '1';
                csr_st    <= CSR_RST;
              end if;
            else
              csr_st <= CSR_READ_ACK;
            end if;

          when CSR_WRITE =>
            bram_wen_c <= '0';

            csr_ready <= '1';
            csr_st    <= CSR_RST;
        end case;
      end if;
    end if;
  end process main_sm;

  
end rtl;
