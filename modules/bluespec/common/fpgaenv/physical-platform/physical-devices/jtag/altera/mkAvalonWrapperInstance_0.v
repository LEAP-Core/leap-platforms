// mkAvalonWrapperInstance_0.v

// This file was auto-generated as part of a SOPC Builder generate operation.
// If you edit it your changes will probably be lost.

module mkAvalonWrapperInstance_0 (
		output wire        masterWires_read,                 // avalon_master.read
		output wire        masterWires_write,                //              .write
		output wire [31:0] masterWires_address,              //              .address
		output wire [31:0] masterWires_writedata,            //              .writedata
		input  wire [31:0] masterWires_readdata,             //              .readdata
		input  wire        masterWires_waitrequest,          //              .waitrequest
		input  wire        masterWires_readdatavalid,        //              .readdatavalid
		input  wire        CLK,                              //    clock_sink.clk
		input  wire        RST_N,                            //              .reset_n
		input  wire        masterInverseWires_read,          //   conduit_end.read
		input  wire [31:0] masterInverseWires_writedata,     //              .writedata
		input  wire        masterInverseWires_write,         //              .write
		input  wire [31:0] masterInverseWires_address,       //              .address
		output wire [31:0] masterInverseWires_readdata,      //              .readdata
		output wire        masterInverseWires_waitrequest,   //              .waitrequest
		output wire        masterInverseWires_readdatavalid  //              .readdatavalid
	);

	mkAvalonWrapperInstance mkavalonwrapperinstance_0 (
		.masterWires_read                 (masterWires_read),                 // avalon_master.read
		.masterWires_write                (masterWires_write),                //              .write
		.masterWires_address              (masterWires_address),              //              .address
		.masterWires_writedata            (masterWires_writedata),            //              .writedata
		.masterWires_readdata             (masterWires_readdata),             //              .readdata
		.masterWires_waitrequest          (masterWires_waitrequest),          //              .waitrequest
		.masterWires_readdatavalid        (masterWires_readdatavalid),        //              .readdatavalid
		.CLK                              (CLK),                              //    clock_sink.clk
		.RST_N                            (RST_N),                            //              .reset_n
		.masterInverseWires_read          (masterInverseWires_read),          //   conduit_end.read
		.masterInverseWires_writedata     (masterInverseWires_writedata),     //              .writedata
		.masterInverseWires_write         (masterInverseWires_write),         //              .write
		.masterInverseWires_address       (masterInverseWires_address),       //              .address
		.masterInverseWires_readdata      (masterInverseWires_readdata),      //              .readdata
		.masterInverseWires_waitrequest   (masterInverseWires_waitrequest),   //              .waitrequest
		.masterInverseWires_readdatavalid (masterInverseWires_readdatavalid)  //              .readdatavalid
	);

endmodule
