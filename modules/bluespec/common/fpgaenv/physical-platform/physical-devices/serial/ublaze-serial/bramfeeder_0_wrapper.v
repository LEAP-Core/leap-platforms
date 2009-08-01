//-----------------------------------------------------------------------------
// bramfeeder_0_wrapper.v
//-----------------------------------------------------------------------------

module bramfeeder_0_wrapper
  (
    CLK,
    RST,
    ppcMessageInput_put,
    EN_ppcMessageInput_put,
    RDY_ppcMessageInput_put,
    EN_ppcMessageOutput_get,
    ppcMessageOutput_get,
    RDY_ppcMessageOutput_get,
    bramInitiatorWires_bramCLK,
    bramInitiatorWires_bramRST,
    bramInitiatorWires_bramAddr,
    bramInitiatorWires_bramDout,
    bramInitiatorWires_bramWEN,
    bramInitiatorWires_bramEN,
    bramInitiatorWires_bramDin
  );
  input CLK;
  input RST;
  input [31:0] ppcMessageInput_put;
  input EN_ppcMessageInput_put;
  output RDY_ppcMessageInput_put;
  input EN_ppcMessageOutput_get;
  output [31:0] ppcMessageOutput_get;
  output RDY_ppcMessageOutput_get;
  output bramInitiatorWires_bramCLK;
  output bramInitiatorWires_bramRST;
  output [31:0] bramInitiatorWires_bramAddr;
  output [31:0] bramInitiatorWires_bramDout;
  output [3:0] bramInitiatorWires_bramWEN;
  output bramInitiatorWires_bramEN;
  input [31:0] bramInitiatorWires_bramDin;

  bramfeeder
    bramfeeder_0 (
      .CLK ( CLK ),
      .RST ( RST ),
      .ppcMessageInput_put ( ppcMessageInput_put ),
      .EN_ppcMessageInput_put ( EN_ppcMessageInput_put ),
      .RDY_ppcMessageInput_put ( RDY_ppcMessageInput_put ),
      .EN_ppcMessageOutput_get ( EN_ppcMessageOutput_get ),
      .ppcMessageOutput_get ( ppcMessageOutput_get ),
      .RDY_ppcMessageOutput_get ( RDY_ppcMessageOutput_get ),
      .bramInitiatorWires_bramCLK ( bramInitiatorWires_bramCLK ),
      .bramInitiatorWires_bramRST ( bramInitiatorWires_bramRST ),
      .bramInitiatorWires_bramAddr ( bramInitiatorWires_bramAddr ),
      .bramInitiatorWires_bramDout ( bramInitiatorWires_bramDout ),
      .bramInitiatorWires_bramWEN ( bramInitiatorWires_bramWEN ),
      .bramInitiatorWires_bramEN ( bramInitiatorWires_bramEN ),
      .bramInitiatorWires_bramDin ( bramInitiatorWires_bramDin )
    );

endmodule

// synthesis attribute x_core_info of bramfeeder_0_wrapper is bramfeeder_v;

