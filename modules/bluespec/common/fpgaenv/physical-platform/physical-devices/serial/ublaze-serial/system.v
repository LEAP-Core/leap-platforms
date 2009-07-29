module system( fpga_0_RS232_Uart_1_RX_pin,
    fpga_0_RS232_Uart_1_TX_pin,
    fpga_0_net_gnd_pin, 
    fpga_0_net_gnd_1_pin, 
    fpga_0_net_gnd_2_pin, 
    fpga_0_net_gnd_3_pin,
    fpga_0_net_gnd_4_pin,
    fpga_0_net_gnd_5_pin,
    fpga_0_net_gnd_6_pin,
    sys_clk_pin, 
    sys_rst_pin, 
    bramfeeder_0_RDY_ppcMessageOutput_get_pin, 
    bramfeeder_0_ppcMessageInput_put_pin, 
    bramfeeder_0_ppcMessageOutput_get_pin, 
    bramfeeder_0_EN_ppcMessageOutput_get_pin, 
    bramfeeder_0_RDY_ppcMessageInput_put_pin, 
    bramfeeder_0_EN_ppcMessageInput_put_pin);
   

    input  fpga_0_RS232_Uart_1_RX_pin;
    output fpga_0_RS232_Uart_1_TX_pin;
    output fpga_0_net_gnd_pin; 
    output fpga_0_net_gnd_1_pin; 
    output fpga_0_net_gnd_2_pin; 
    output fpga_0_net_gnd_3_pin;
    output fpga_0_net_gnd_4_pin;
    output fpga_0_net_gnd_5_pin;
    output fpga_0_net_gnd_6_pin;
    input  sys_clk_pin; 
    input  sys_rst_pin; 
    output bramfeeder_0_RDY_ppcMessageOutput_get_pin; 
    input  [31:0] bramfeeder_0_ppcMessageInput_put_pin; 
    output [31:0] bramfeeder_0_ppcMessageOutput_get_pin; 
    output bramfeeder_0_EN_ppcMessageOutput_get_pin; 
    output bramfeeder_0_RDY_ppcMessageInput_put_pin; 
    output bramfeeder_0_EN_ppcMessageInput_put_pin;

endmodule