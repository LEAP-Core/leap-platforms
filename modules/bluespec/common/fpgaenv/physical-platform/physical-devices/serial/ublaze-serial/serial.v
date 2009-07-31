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
    dummy_enable);

/* synthesis syn_black_box black_box_pad_pin="fpga_0_RS232_Uart_1_RX_pin,fpga_0_RS232_Uart_1_TX_pin" */
   

    input  fpga_0_RS232_Uart_1_RX_pin;
    output fpga_0_RS232_Uart_1_TX_pin;
    input  sys_clk_pin; 
    input  sys_rst_pin; 
    output bramfeeder_0_RDY_ppcMessageOutput_get_pin; 
    input  [31:0] bramfeeder_0_ppcMessageInput_put_pin; 
    output [31:0] bramfeeder_0_ppcMessageOutput_get_pin; 
    output bramfeeder_0_EN_ppcMessageOutput_get_pin; 
    output bramfeeder_0_RDY_ppcMessageInput_put_pin; 
    output bramfeeder_0_EN_ppcMessageInput_put_pin;
    output dummy_enable;    

    // flip the polarity of bsv's reset.
    wire rst_p;
    assign rst_p = ~sys_rst_pin;
    assign dummy_enable = 1;

    system s( .fpga_0_RS232_Uart_1_RX_pin(fpga_0_RS232_Uart_1_RX_pin),
              .fpga_0_RS232_Uart_1_TX_pin(fpga_0_RS232_Uart_1_TX_pin),
              .sys_clk_pin(sys_clk_pin), 
              .sys_rst_pin(rst_p), 
              .bramfeeder_0_RDY_ppcMessageOutput_get_pin(bramfeeder_0_RDY_ppcMessageOutput_get_pin), 
              .bramfeeder_0_ppcMessageInput_put_pin(bramfeeder_0_ppcMessageInput_put_pin), 
              .bramfeeder_0_ppcMessageOutput_get_pin(bramfeeder_0_ppcMessageOutput_get_pin), 
              .bramfeeder_0_EN_ppcMessageOutput_get_pin(bramfeeder_0_EN_ppcMessageOutput_get_pin), 
              .bramfeeder_0_RDY_ppcMessageInput_put_pin(bramfeeder_0_RDY_ppcMessageInput_put_pin), 
              .bramfeeder_0_EN_ppcMessageInput_put_pin(bramfeeder_0_EN_ppcMessageInput_put_pin)
            );

endmodule