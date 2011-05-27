module single_ended_clocks_device #(RESET_ACTIVE_HIGH=0) (clk, rst_n, clk_out, rst_n_out);
  input clk;
  input rst_n;
  output clk_out;
  output rst_n_out;

  assign clk_out = clk;
  assign rst_n_out = RESET_ACTIVE_HIGH ? !rst_n : rst_n;

endmodule
