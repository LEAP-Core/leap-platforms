module serial( fpga_0_RS232_Uart_1_RX_pin,
    fpga_0_RS232_Uart_1_TX_pin,
    sys_clk_pin, 
    sys_rst_pin, 
    bramfeeder_0_RDY_ppcMessageOutput_get_pin, 
    bramfeeder_0_ppcMessageInput_put_pin, 
    bramfeeder_0_ppcMessageOutput_get_pin, 
    bramfeeder_0_EN_ppcMessageOutput_get_pin, 
    bramfeeder_0_RDY_ppcMessageInput_put_pin, 
    bramfeeder_0_EN_ppcMessageInput_put_pin,
    serial_clk_pin,
    serial_rst_pin,
    dummy_enable);


   

    input  fpga_0_RS232_Uart_1_RX_pin;
    output fpga_0_RS232_Uart_1_TX_pin;
    input  sys_clk_pin; 
    input  sys_rst_pin; 
    output bramfeeder_0_RDY_ppcMessageOutput_get_pin; 
    input  [31:0] bramfeeder_0_ppcMessageInput_put_pin; 
    output [31:0] bramfeeder_0_ppcMessageOutput_get_pin; 
    input bramfeeder_0_EN_ppcMessageOutput_get_pin; 
    output bramfeeder_0_RDY_ppcMessageInput_put_pin; 
    input bramfeeder_0_EN_ppcMessageInput_put_pin;
    output dummy_enable;    
    output serial_clk_pin;
    output serial_rst_pin;

    // Do not flip the polarity of bsv's reset.
    wire rst_p;
    assign rst_p = sys_rst_pin;
    assign dummy_enable = 1;
    // negate the output reset.
    wire  out_rst;
    assign serial_rst_pin = ~out_rst;
   
   
    system s( .fpga_0_RS232_Uart_1_RX_pin(fpga_0_RS232_Uart_1_RX_pin),
              .fpga_0_RS232_Uart_1_TX_pin(fpga_0_RS232_Uart_1_TX_pin),
              .sys_clk_pin(sys_clk_pin), 
              .sys_rst_pin(rst_p), 
              .bramfeeder_0_RDY_ppcMessageOutput_get_pin(bramfeeder_0_RDY_ppcMessageOutput_get_pin), 
              .bramfeeder_0_ppcMessageInput_put_pin(bramfeeder_0_ppcMessageInput_put_pin), 
              .bramfeeder_0_ppcMessageOutput_get_pin(bramfeeder_0_ppcMessageOutput_get_pin), 
              .bramfeeder_0_EN_ppcMessageOutput_get_pin(bramfeeder_0_EN_ppcMessageOutput_get_pin), 
              .bramfeeder_0_RDY_ppcMessageInput_put_pin(bramfeeder_0_RDY_ppcMessageInput_put_pin), 
              .bramfeeder_0_EN_ppcMessageInput_put_pin(bramfeeder_0_EN_ppcMessageInput_put_pin),
              .fpga_0_net_gnd_pin(),
              .fpga_0_net_gnd_1_pin(),
              .fpga_0_net_gnd_2_pin(),
              .fpga_0_net_gnd_3_pin(),
              .fpga_0_net_gnd_4_pin(),
              .fpga_0_net_gnd_5_pin(),
              .fpga_0_net_gnd_6_pin(),
              .clock_generator_0_RSTOUT0_pin(out_rst),
              .clock_generator_0_CLKOUT0_pin(serial_clk_pin)
            );

endmodule