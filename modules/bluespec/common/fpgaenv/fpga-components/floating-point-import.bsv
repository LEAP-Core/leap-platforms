

// Import primitive floating point modules.
// These are all systolic pipelines and can drop
// responses if we're not ready for them. Another
// layer will wrap these in "latency-insensitive"
// pipelines.

// Unfortunately these all have /slightly/ different
// interfaces. The next level will wrap these in a 
// convenient standard wrapper.

// Do to the fact that BVI won't allow us to leave fields
// undefined, we have to define separate interfaces for
// each type.


interface PRIMITIVE_FP_ADD;

    method Action operate(Bit#(64) a, Bit#(64) b, Bit#(6) op);
    method Bit#(64) result();
    method Bit#(1)  underflow();
    method Bit#(1)  overflow();
    method Bit#(1)  invalidOp();

endinterface

import "BVI" fp_add = module mkPrimitiveFPAdd
    // interface:
        (PRIMITIVE_FP_ADD);

    default_reset no_reset; 
    default_clock (clk) <- exposeCurrentClock;

    method operate(a, b, operation) ready (operation_rfd) enable (operation_nd);
    method result result() ready (rdy);
    method underflow underflow() ready (rdy);
    method overflow overflow() ready (rdy);
    method invalid_op invalidOp() ready (rdy);

    schedule operate C operate;
    schedule operate CF (result, underflow, overflow, invalidOp);
    
    schedule result       CF (result, underflow, overflow, invalidOp);
    schedule underflow    CF (underflow, overflow, invalidOp);
    schedule overflow     CF (overflow, invalidOp);
    schedule invalidOp    CF (invalidOp);

endmodule

interface PRIMITIVE_FP_MUL;

    method Action operate(Bit#(64) a, Bit#(64) b);
    method Bit#(64) result();
    method Bit#(1)  underflow();
    method Bit#(1)  overflow();
    method Bit#(1)  invalidOp();

endinterface

import "BVI" fp_mul = module mkPrimitiveFPMul
    // interface:
        (PRIMITIVE_FP_MUL);

    default_reset no_reset; 
    default_clock (clk) <- exposeCurrentClock;

    method operate(a, b) ready (operation_rfd) enable (operation_nd);
    method result result() ready (rdy);
    method underflow underflow() ready (rdy);
    method overflow overflow() ready (rdy);
    method invalid_op invalidOp() ready (rdy);

    schedule operate C operate;
    schedule operate CF (result, underflow, overflow, invalidOp);
    
    schedule result       CF (result, underflow, overflow, invalidOp);
    schedule underflow    CF (underflow, overflow, invalidOp);
    schedule overflow     CF (overflow, invalidOp);
    schedule invalidOp    CF (invalidOp);

endmodule

interface PRIMITIVE_FP_DIV;

    method Action operate(Bit#(64) a, Bit#(64) b);
    method Bit#(64) result();
    method Bit#(1)  underflow();
    method Bit#(1)  overflow();
    method Bit#(1)  invalidOp();
    method Bit#(1)  divideByZero();

endinterface

import "BVI" fp_div = module mkPrimitiveFPDiv
    // interface:
        (PRIMITIVE_FP_DIV);

    default_reset no_reset; 
    default_clock (clk) <- exposeCurrentClock;

    method operate(a, b) ready (operation_rfd) enable (operation_nd);
    method result result() ready (rdy);
    method underflow underflow() ready (rdy);
    method overflow overflow() ready (rdy);
    method invalid_op invalidOp() ready (rdy);
    method divide_by_zero divideByZero() ready (rdy);

    schedule operate C operate;
    schedule operate CF (result, underflow, overflow, invalidOp, divideByZero);
    
    schedule result       CF (result, underflow, overflow, invalidOp, divideByZero);
    schedule underflow    CF (underflow, overflow, invalidOp, divideByZero);
    schedule overflow     CF (overflow, invalidOp, divideByZero);
    schedule invalidOp    CF (invalidOp, divideByZero);
    schedule divideByZero CF (divideByZero);

endmodule


interface PRIMITIVE_FP_SQRT;

    method Action operate(Bit#(64) a);
    method Bit#(64) result();
    method Bit#(1)  invalidOp();

endinterface

import "BVI" fp_sqrt = module mkPrimitiveFPSqrt
    // interface:
        (PRIMITIVE_FP_SQRT);

    default_reset no_reset; 
    default_clock (clk) <- exposeCurrentClock;

    method operate(a) ready (operation_rfd) enable (operation_nd);
    method result result() ready (rdy);
    method invalid_op invalidOp() ready (rdy);

    schedule operate C operate;
    schedule operate CF (result, invalidOp);
    
    schedule result       CF (result, invalidOp);
    schedule invalidOp    CF (invalidOp);

endmodule


interface PRIMITIVE_FP_CMP;

    method Action operate(Bit#(64) a, Bit#(64) b, Bit#(6) op);
    method Bit#(1)  result();
    method Bit#(1)  invalidOp();

endinterface

import "BVI" fp_cmp = module mkPrimitiveFPCmp
    // interface:
        (PRIMITIVE_FP_CMP);

    default_reset no_reset; 
    default_clock (clk) <- exposeCurrentClock;

    method operate(a, b, operation) ready (operation_rfd) enable (operation_nd);
    method result result() ready (rdy);
    method invalid_op invalidOp() ready (rdy);

    schedule operate C operate;
    schedule operate CF (result, invalidOp);
    
    schedule result       CF (result, invalidOp);
    schedule invalidOp    CF (invalidOp);

endmodule


interface PRIMITIVE_FP_CVT_D_TO_I;

    method Action operate(Bit#(64) a);
    method Bit#(64) result();
    method Bit#(1)  overflow();
    method Bit#(1)  invalidOp();

endinterface

import "BVI" fp_cvt_d_to_i = module mkPrimitiveFPCvtDtoI
    // interface:
        (PRIMITIVE_FP_CVT_D_TO_I);

    default_reset no_reset; 
    default_clock (clk) <- exposeCurrentClock;

    method operate(a) ready (operation_rfd) enable (operation_nd);
    method result result() ready (rdy);
    method overflow overflow() ready (rdy);
    method invalid_op invalidOp() ready (rdy);

    schedule operate C operate;
    schedule operate CF (result, overflow, invalidOp);
    
    schedule result       CF (result, overflow, invalidOp);
    schedule overflow     CF (overflow, invalidOp);
    schedule invalidOp    CF (invalidOp);

endmodule


interface PRIMITIVE_FP_CVT_D_TO_S;

    method Action operate(Bit#(64) a);
    method Bit#(32) result();
    method Bit#(1)  underflow();
    method Bit#(1)  overflow();

endinterface

import "BVI" fp_cvt_d_to_s = module mkPrimitiveFPCvtDtoS
    // interface:
        (PRIMITIVE_FP_CVT_D_TO_S);

    default_reset no_reset; 
    default_clock (clk) <- exposeCurrentClock;

    method operate(a) ready (operation_rfd) enable (operation_nd);
    method result result() ready (rdy);
    method underflow underflow() ready (rdy);
    method overflow overflow() ready (rdy);

    schedule operate C operate;
    schedule operate CF (result, underflow, overflow);
    
    schedule result       CF (result, underflow, overflow);
    schedule underflow    CF (underflow, overflow);
    schedule overflow     CF (overflow);

endmodule


interface PRIMITIVE_FP_CVT_I_TO_D;

    method Action operate(Bit#(64) a);
    method Bit#(64) result();

endinterface

import "BVI" fp_cvt_i_to_d = module mkPrimitiveFPCvtItoD
    // interface:
        (PRIMITIVE_FP_CVT_I_TO_D);

    default_reset no_reset; 
    default_clock (clk) <- exposeCurrentClock;

    method operate(a) ready (operation_rfd) enable (operation_nd);
    method result result() ready (rdy);

    schedule operate C operate;
    schedule operate CF (result);
    
    schedule result       CF (result);

endmodule



interface PRIMITIVE_FP_CVT_I_TO_S;

    method Action operate(Bit#(32) a);
    method Bit#(32) result();

endinterface

import "BVI" fp_cvt_i_to_s = module mkPrimitiveFPCvtItoS
    // interface:
        (PRIMITIVE_FP_CVT_I_TO_S);

    default_reset no_reset; 
    default_clock (clk) <- exposeCurrentClock;

    method operate(a) ready (operation_rfd) enable (operation_nd);
    method result result() ready (rdy);

    schedule operate C operate;
    schedule operate CF (result);
    
    schedule result       CF (result);

endmodule


interface PRIMITIVE_FP_CVT_S_TO_D;

    method Action operate(Bit#(32) a);
    method Bit#(64) result();
    method Bit#(1)  underflow();
    method Bit#(1)  overflow();

endinterface

import "BVI" fp_cvt_s_to_d = module mkPrimitiveFPCvtStoD
    // interface:
        (PRIMITIVE_FP_CVT_S_TO_D);

    default_reset no_reset; 
    default_clock (clk) <- exposeCurrentClock;

    method operate(a) ready (operation_rfd) enable (operation_nd);
    method result result() ready (rdy);
    method underflow underflow() ready (rdy);
    method overflow overflow() ready (rdy);

    schedule operate C operate;
    schedule operate CF (result, underflow, overflow);
    
    schedule result       CF (result, underflow, overflow);
    schedule underflow    CF (underflow, overflow);
    schedule overflow     CF (overflow);

endmodule

