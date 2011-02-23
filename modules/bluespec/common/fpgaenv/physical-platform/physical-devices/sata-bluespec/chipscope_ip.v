module chipscope_ip
  (txclk,
   rxclk0,
   rxclk1,
   tx_vio_in0_i,
   tx_vio_out0_i,
   rx_vio_in0_i,
   rx_vio_out0_i,
   rx_data_ila_in0_i,
   rx_err_ila_in0_i,
   rx_cnt_ila_in0_i,
   tx_vio_in1_i,
   tx_vio_out1_i,
   rx_vio_in1_i,
   rx_vio_out1_i,
   rx_data_ila_in1_i,
   rx_err_ila_in1_i,
   rx_cnt_ila_in1_i);

   input         txclk;	
   input         rxclk0;
   input         rxclk1;
   input  [31:0] tx_vio_in0_i;
   output [31:0] tx_vio_out0_i;
   input  [31:0] rx_vio_in0_i;
   output [31:0] rx_vio_out0_i;
   input  [47:0] rx_data_ila_in0_i;
   input  [47:0] rx_err_ila_in0_i;
   input  [47:0] rx_cnt_ila_in0_i;
   input  [31:0] tx_vio_in1_i;
   output [31:0] tx_vio_out1_i;
   input  [31:0] rx_vio_in1_i;
   output [31:0] rx_vio_out1_i;
   input  [47:0] rx_data_ila_in1_i;
   input  [47:0] rx_err_ila_in1_i;
   input  [47:0] rx_cnt_ila_in1_i;

   wire   [35:0] tx_vio_control0_i;
   wire   [35:0] rx_vio_control0_i;
   wire   [35:0] rx_data_ila_control0_i;
   wire   [35:0] rx_err_ila_control0_i;
   wire   [35:0] rx_cnt_ila_control0_i;
   wire   [35:0] tx_vio_control1_i;
   wire   [35:0] rx_vio_control1_i;
   wire   [35:0] rx_data_ila_control1_i;
   wire   [35:0] rx_err_ila_control1_i;
   wire   [35:0] rx_cnt_ila_control1_i;
    
    // ICON for all VIOs 
    icon i_icon
    (
      .CONTROL0                         (tx_vio_control0_i),
      .CONTROL1                         (rx_vio_control0_i),
      .CONTROL2                         (rx_data_ila_control0_i),
      .CONTROL3                         (rx_err_ila_control0_i),
      .CONTROL4                         (rx_cnt_ila_control0_i), 
      .CONTROL5                         (tx_vio_control1_i),
      .CONTROL6                         (rx_vio_control1_i),
      .CONTROL7                         (rx_data_ila_control1_i),
      .CONTROL8                         (rx_err_ila_control1_i),
      .CONTROL9                         (rx_cnt_ila_control1_i)
    );

    // TX VIO 
    shared_vio tx_vio0_i
    (
      .CONTROL                          (tx_vio_control0_i),
      .ASYNC_IN                         (tx_vio_in0_i),
      .ASYNC_OUT                        (tx_vio_out0_i)  
    );
    
    // RX VIO 
    shared_vio rx_vio0_i
    (
      .CONTROL                          (rx_vio_control0_i),
      .ASYNC_IN                         (rx_vio_in0_i),
      .ASYNC_OUT                        (rx_vio_out0_i)  
    );
    
    // RX ILA
    ila rx_data_ila0_i
    (
      .CONTROL                          (rx_data_ila_control0_i),
      .CLK                              (rxclk0),
      .TRIG0                            (rx_data_ila_in0_i)
    );

    // RX ILA
    ila rx_err_ila0_i
    (
      .CONTROL                          (rx_err_ila_control0_i),
      .CLK                              (rxclk0),
      .TRIG0                            (rx_err_ila_in0_i)
    );

    // RX ILA
    ila rx_cnt_ila0_i
    (
      .CONTROL                          (rx_cnt_ila_control0_i),
      .CLK                              (rxclk0),
      .TRIG0                            (rx_cnt_ila_in0_i)
    );
              
    // TX VIO 
    shared_vio tx_vio1_i
    (
      .CONTROL                          (tx_vio_control1_i),
      .ASYNC_IN                         (tx_vio_in1_i),
      .ASYNC_OUT                        (tx_vio_out1_i)  
    );
    
    // RX VIO 
    shared_vio rx_vio1_i
    (
      .CONTROL                          (rx_vio_control1_i),
      .ASYNC_IN                         (rx_vio_in1_i),
      .ASYNC_OUT                        (rx_vio_out1_i)  
    );
    
    // RX ILA
    ila rx_data_ila1_i
    (
      .CONTROL                          (rx_data_ila_control1_i),
      .CLK                              (rxclk1),
      .TRIG0                            (rx_data_ila_in1_i)
    );

    // RX ILA
    ila rx_err_ila1_i
    (
      .CONTROL                          (rx_err_ila_control1_i),
      .CLK                              (rxclk1),
      .TRIG0                            (rx_err_ila_in1_i)
    );

    // RX ILA
    ila rx_cnt_ila1_i
    (
      .CONTROL                          (rx_cnt_ila_control1_i),
      .CLK                              (rxclk1),
      .TRIG0                            (rx_cnt_ila_in1_i)
    );

endmodule
   
        
//-------------------------------------------------------------------
//
//  VIO core module declaration 
//  This one is for driving shared ports and is asynchronous
//
//-------------------------------------------------------------------
module shared_vio
  (
    CONTROL,
    ASYNC_IN,
    ASYNC_OUT
  );
  input  [35:0] CONTROL;
  input  [31:0] ASYNC_IN;
  output [31:0] ASYNC_OUT;
endmodule

//-------------------------------------------------------------------
//
//  ICON core module declaration
//
//-------------------------------------------------------------------
module icon 
  (
      CONTROL0,
      CONTROL1,
      CONTROL2,
      CONTROL3,
      CONTROL4,
      CONTROL5,
      CONTROL6,
      CONTROL7,
      CONTROL8,
      CONTROL9
  );
  output [35:0] CONTROL0;
  output [35:0] CONTROL1;
  output [35:0] CONTROL2;
  output [35:0] CONTROL3;
  output [35:0] CONTROL4;
  output [35:0] CONTROL5;
  output [35:0] CONTROL6;
  output [35:0] CONTROL7;
  output [35:0] CONTROL8;
  output [35:0] CONTROL9;
endmodule


//-------------------------------------------------------------------
//
//  ILA core module declaration
//  This is used to allow RX signals to be monitored
//
//-------------------------------------------------------------------
module ila
  (
    CONTROL,
    CLK,
    TRIG0
  );
  input [35:0] CONTROL;
  input CLK;
  input [47:0] TRIG0;
endmodule


