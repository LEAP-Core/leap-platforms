module primitive_clock_device(clk,
                              rst,
                              clk_out,
                              rst_out);

  parameter RESET_ACTIVE_HIGH = 0;

  input clk;
  input rst;
  output clk_out;
  output rst_out;

  assign clk_out = clk;
  assign rst_out = rst;

endmodule
