module v6_icon_wrapper(
    CLK,
    CONTROL0);
   
    input CLK;
   
    inout [35 : 0] CONTROL0;

    v6_icon icon(.CONTROL0(CONTROL0));
   
endmodule