
typedef struct
{
    Bit#(64) operandA;
    Bit#(64) operandB;
    Bit#(6)  operation;
}
FP_INPUT deriving (Eq, Bits);

typedef struct
{
    Bit#(64) result;
    Bit#(1) overflow;
    Bit#(1) underflow;
    Bit#(1) invalidOp;
    Bit#(1) divideByZero;
}
FP_OUTPUT deriving (Eq, Bits);


typedef GUARDED_PIPELINE#(FP_INPUT, FP_OUTPUT) FP_ACCEL;



module mkUnguardedFPAdd 
    // interface:
        (SYNC_PIPELINE#(FP_INPUT, FP_OUTPUT));

    PRIMITIVE_FP_ADD fp <- mkPrimitiveFPAdd();

    method Action operate(FP_INPUT in);
        fp.operate(in.operandA, in.operandB, in.operation);
    endmethod

    method FP_OUTPUT result();
        FP_OUTPUT res;
        res.result = fp.result();
        res.overflow = fp.overflow();
        res.underflow = fp.underflow();
        res.invalidOp = fp.invalidOp();
        res.divideByZero = 0;
        return res;
    endmethod

endmodule


module mkUnguardedFPMul
    // interface:
        (SYNC_PIPELINE#(FP_INPUT, FP_OUTPUT));

    PRIMITIVE_FP_MUL fp <- mkPrimitiveFPMul();

    method Action operate(FP_INPUT in);
        fp.operate(in.operandA, in.operandB);
    endmethod

    method FP_OUTPUT result();
        FP_OUTPUT res;
        res.result = fp.result();
        res.overflow = fp.overflow();
        res.underflow = fp.underflow();
        res.invalidOp = fp.invalidOp();
        res.divideByZero = 0;
        return res;
    endmethod

endmodule


module mkUnguardedFPDiv 
    // interface:
        (SYNC_PIPELINE#(FP_INPUT, FP_OUTPUT));

    PRIMITIVE_FP_DIV fp <- mkPrimitiveFPDiv();

    method Action operate(FP_INPUT in);
        fp.operate(in.operandA, in.operandB);
    endmethod

    method FP_OUTPUT result();
        FP_OUTPUT res;
        res.result = fp.result();
        res.overflow = fp.overflow();
        res.underflow = fp.underflow();
        res.invalidOp = fp.invalidOp();
        res.divideByZero = fp.divideByZero();
        return res;
    endmethod

endmodule


module mkUnguardedFPSqrt
    // interface:
        (SYNC_PIPELINE#(FP_INPUT, FP_OUTPUT));

    PRIMITIVE_FP_SQRT fp <- mkPrimitiveFPSqrt();

    method Action operate(FP_INPUT in);
        fp.operate(in.operandA);
    endmethod

    method FP_OUTPUT result();
        FP_OUTPUT res;
        res.result = fp.result();
        res.overflow = 0;
        res.underflow = 0;
        res.invalidOp = fp.invalidOp();
        res.divideByZero = 0;
        return res;
    endmethod

endmodule


module mkUnguardedFPCmp
    // interface:
        (SYNC_PIPELINE#(FP_INPUT, FP_OUTPUT));

    PRIMITIVE_FP_CMP fp <- mkPrimitiveFPCmp();

    method Action operate(FP_INPUT in);
        fp.operate(in.operandA, in.operandB, in.operation);
    endmethod

    method FP_OUTPUT result();
        FP_OUTPUT res;
        res.result = zeroExtend(fp.result());
        res.overflow = 0;
        res.underflow = 0;
        res.invalidOp = fp.invalidOp();
        res.divideByZero = 0;
        return res;
    endmethod

endmodule


module mkUnguardedFPCvtDtoI
    // interface:
        (SYNC_PIPELINE#(FP_INPUT, FP_OUTPUT));

    PRIMITIVE_FP_CVT_D_TO_I fp <- mkPrimitiveFPCvtDtoI();

    method Action operate(FP_INPUT in);
        fp.operate(in.operandA);
    endmethod

    method FP_OUTPUT result();
        FP_OUTPUT res;
        res.result = fp.result();
        res.overflow = fp.overflow();
        res.underflow = 0;
        res.invalidOp = fp.invalidOp();
        res.divideByZero = 0;
        return res;
    endmethod

endmodule


module mkUnguardedFPCvtDtoS
    // interface:
        (SYNC_PIPELINE#(FP_INPUT, FP_OUTPUT));

    PRIMITIVE_FP_CVT_D_TO_S fp <- mkPrimitiveFPCvtDtoS();

    method Action operate(FP_INPUT in);
        fp.operate(in.operandA);
    endmethod

    method FP_OUTPUT result();
        FP_OUTPUT res;
        let prim_res = fp.result();
        // 32-bit single stored in low 32 bits
        res.result = zeroExtend(prim_res);
        res.overflow = fp.overflow();
        res.underflow = fp.underflow();
        res.invalidOp = 0;
        res.divideByZero = 0;
        return res;
    endmethod

endmodule


module mkUnguardedFPCvtItoD
    // interface:
        (SYNC_PIPELINE#(FP_INPUT, FP_OUTPUT));

    PRIMITIVE_FP_CVT_I_TO_D fp <- mkPrimitiveFPCvtItoD();

    method Action operate(FP_INPUT in);
        fp.operate(in.operandA);
    endmethod

    method FP_OUTPUT result();
        FP_OUTPUT res;
        res.result = fp.result();
        res.overflow = 0;
        res.underflow = 0;
        res.invalidOp = 0;
        res.divideByZero = 0;
        return res;
    endmethod

endmodule


module mkUnguardedFPCvtItoS
    // interface:
        (SYNC_PIPELINE#(FP_INPUT, FP_OUTPUT));

    PRIMITIVE_FP_CVT_I_TO_S fp <- mkPrimitiveFPCvtItoS();

    method Action operate(FP_INPUT in);
        fp.operate(truncate(in.operandA));
    endmethod

    method FP_OUTPUT result();
        FP_OUTPUT res;
        let prim_res = fp.result();
        // 32-bit single stored in low 32 bits
        res.result = zeroExtend(prim_res);
        res.overflow = 0;
        res.underflow = 0;
        res.invalidOp = 0;
        res.divideByZero = 0;
        return res;
    endmethod

endmodule


module mkUnguardedFPCvtStoD
    // interface:
        (SYNC_PIPELINE#(FP_INPUT, FP_OUTPUT));

    PRIMITIVE_FP_CVT_S_TO_D fp <- mkPrimitiveFPCvtStoD();

    method Action operate(FP_INPUT in);
        let op = in.operandA;
        // 64-bit "single" to true single.
        Bit#(32) true_s = {op[63:62], op[58:29]};
        fp.operate(true_s);
    endmethod

    method FP_OUTPUT result();
        FP_OUTPUT res;
        res.result = fp.result();
        res.overflow = fp.overflow();
        res.underflow = fp.underflow();
        res.invalidOp = 0;
        res.divideByZero = 0;
        return res;
    endmethod

endmodule



module mkFPAcceleratorAdd (FP_ACCEL);

    let ung  <- mkUnguardedFPAdd();
    let pipe <- mkGuardedPipeline(ung);
    return pipe;

endmodule


module mkFPAcceleratorMul (FP_ACCEL);

    let ung  <- mkUnguardedFPMul();
    let pipe <- mkGuardedPipeline(ung);
    return pipe;

endmodule


module mkFPAcceleratorDiv (FP_ACCEL);

    let ung  <- mkUnguardedFPDiv();
    let pipe <- mkGuardedPipeline(ung);
    return pipe;

endmodule


module mkFPAcceleratorSqrt (FP_ACCEL);

    let ung  <- mkUnguardedFPSqrt();
    let pipe <- mkGuardedPipeline(ung);
    return pipe;

endmodule


module mkFPAcceleratorCmp (FP_ACCEL);

    let ung  <- mkUnguardedFPCmp();
    let pipe <- mkGuardedPipeline(ung);
    return pipe;

endmodule


module mkFPAcceleratorCvtDtoI (FP_ACCEL);

    let ung  <- mkUnguardedFPCvtDtoI();
    let pipe <- mkGuardedPipeline(ung);
    return pipe;

endmodule


module mkFPAcceleratorCvtDtoS (FP_ACCEL);

    let ung  <- mkUnguardedFPCvtDtoS();
    let pipe <- mkGuardedPipeline(ung);
    return pipe;

endmodule


module mkFPAcceleratorCvtItoD (FP_ACCEL);

    let ung  <- mkUnguardedFPCvtItoD();
    let pipe <- mkGuardedPipeline(ung);
    return pipe;

endmodule


module mkFPAcceleratorCvtItoS (FP_ACCEL);

    let ung  <- mkUnguardedFPCvtItoS();
    let pipe <- mkGuardedPipeline(ung);
    return pipe;

endmodule


module mkFPAcceleratorCvtStoD (FP_ACCEL);

    let ung  <- mkUnguardedFPCvtStoD();
    let pipe <- mkGuardedPipeline(ung);
    return pipe;

endmodule


//
// Helper function for storing 32-bit singles in 64-bit format.
//
function Bit#(12) fpSingleInDoubleExp(Bit#(32) s);

    Bit#(1) sign = s[31];
    Bit#(1) start = s[30];
    Bit#(7) rest = s[29:23];
    Bit#(8) exp = s[30:23];
    
    Bit#(11) new_exp;

    case (exp)
        8'b11111111:   new_exp = 11'b11111111111;
        8'b00000000:   new_exp = 11'b00000000000;
        default:
            if (start == 0)
                new_exp = {4'b0111, rest};
            else
                new_exp = {4'b1000, rest};
    endcase

    return {sign, new_exp};

endfunction


//
// Single precision stored as double, Alpha-ISA style.
//
function Bit#(64) fpSingleInDouble(Bit#(32) s);
    return {fpSingleInDoubleExp(s), s[22:0], 29'b0};
endfunction


//
// Helper function for rounding to single precision.
// Uses IEEE "round to nearest, even wins ties"
//
function Bit#(32) roundToSingle(Bit#(64) d);

    Bit#(1) sign = d[63];
    Bit#(8) exp = {d[62], d[58:52]};
    Bit#(23) significand = d[51:29];
    Bit#(29) truncated_bits = d[28:0];
    
    // See if we need to round.
    Bool adding_one = False;

    if (truncated_bits > 29'b10000000000000000000000000000)
    begin
        adding_one = True;
    end
    else if (truncated_bits == 29'b10000000000000000000000000000 &&
             significand[0] == 1'b1)
    begin
        adding_one = True;
    end
    
    if (adding_one)
    begin
        significand = significand + 1;   
    end
    
    Bit#(32) res = {sign, exp, significand};
    return res;

endfunction
