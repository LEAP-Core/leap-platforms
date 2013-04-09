module icon_wrapper #
(
     parameter GENERATION = 6
)
(
    CLK,
    CONTROL0);
   
    input CLK;
   
    inout [35 : 0] CONTROL0;

    generate
    if (GENERATION==6)
    begin 
        v6_icon icon(.CONTROL0(CONTROL0));
    end
    endgenerate

    generate
    if (GENERATION==7)
    begin 
        v7_icon icon(.CONTROL0(CONTROL0));
    end
    endgenerate

endmodule