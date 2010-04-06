//
// Copyright (C) 2008 Intel Corporation
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//

//
// Generate clocks of requested frequency.
//

import Clocks::*;
import Real::*;


//
// computePLLParams --
//
//    Compute the input divider, multiplier and output divider in a PLL
//    that yields output frequency fTGT given input frequency fIN.
//
//    For now all parameters are set for the Virtex-5 330-2 in the ACP
//    platform.
//
function Tuple4#(Integer, Integer, Integer, Real) computePLLParams(Real fIN,
                                                                   Real fTGT);

    Integer fail = 0;

    // ACP's Virtex-5 330-2 parameters...
    Real fINmin  = 19;
    Real fINmax  = 710;
    Real fVCOmin = 400;
    Real fVCOmax = 1200;
    Real fPFDmin = 19;
    Real fPFDmax = 500;
    Real fOUTmin = 3.125;
    Real fOUTmax = 500;

    if ((fIN < fINmin) || (fIN > fINmax))
    begin
        // Signal an error.  (Can't raise error in the function.)
        fail = 1;
    end

    if ((fTGT < fOUTmin) || (fTGT > fOUTmax))
    begin
        fail = 2;
    end

    //
    // Compute min/max values of divider and multiplier.  Formulas are found in
    // the Virtex-5 FPGA User Guide.
    //
    Integer d_min = ceil(fIN / fPFDmax);
    Integer d_max = floor(fIN / fPFDmin);
    Integer m_min = ceil(fVCOmin / fIN) * d_min;
    Integer m_max = floor((fromInteger(d_max) * fVCOmax) / fIN);
    Real m_ideal = (fromInteger(d_min) * fVCOmax) / fIN;

    if (d_max > 52)
        d_max = 52;

    if (m_max > 64)
        m_max = 64;

    //
    // These variables will hold the best solution.  Pick non-zero dividers and
    // a big starting error percentage.
    //
    Integer d_best = 1;
    Integer m_best = 1;
    Integer d_out_best = 1;
    Real err_best = 1.1;
    Real i_delta_best = 10000;

    //
    // Loop through all possible parameters
    //
    for (Integer d = d_min; d <= d_max; d = d + 1)
    begin
        // Is PFD frequency legal?
        Real pfd_freq = fIN / fromInteger(d);
        if ((pfd_freq >= fPFDmin) && (pfd_freq <= fPFDmax))
        begin
            for (Integer m = m_min; m <= m_max; m = m + 1)
            begin
                Real vco_freq = pfd_freq * fromInteger(m);
                // Is VCO frequency legal?
                if ((vco_freq >= fVCOmin) && (vco_freq <= fVCOmax))
                begin
                    //
                    // D and M result in a legal frequency.  Pick the output divider
                    // closest to the target frequency.
                    Integer out_div = round(vco_freq / fTGT);
                    Real out_freq = vco_freq / fromInteger(out_div);
                    Real err = abs(out_freq - fTGT) / fTGT;

                    // Is divisor a legal value?
                    if (out_div <= 128)
                    begin
                        // Delta from the ideal VCO multiplier
                        Real delta_ideal = abs(fromInteger(m) - m_ideal);

                        // Picking the best solution is a compromise between hitting
                        // the best frequency and picking a multiplier closest to
                        // ideal.  This code picks a new solution if it is either:
                        //   - Closer to the target frequency by at least 2% compared
                        //     to the current best known solution.
                        //   - Within 2% of the best known solution and a "better"
                        //     multiplier.
                        //
                        if (((err_best - err) > 0.02) ||
                           ((err <= err_best + 0.02) && (delta_ideal < i_delta_best)))
                        begin
                            d_best = d;
                            m_best = m;
                            d_out_best = out_div;
                            err_best = err;
                            i_delta_best = delta_ideal;
                        end
                    end
                end
            end
        end
    end

    // Compute output frequency as a sanity check
    Real true_out_freq = ((fIN / fromInteger(d_best)) * fromInteger(m_best)) / fromInteger(d_out_best);

    if (fail == 0)
        return tuple4(d_best, m_best, d_out_best, true_out_freq);
    else
        return tuple4(0, fail, 0, 0);
endfunction


// verilog only
import "BVI"
module mkUserClock_Ratio_PLL#(Integer inFreq,
                              Integer clockInDivider,
                              Integer clockMultiplier,
                              Integer clockOutDivider)
    // Interface:
        (UserClock);

    default_clock (CLK);
    default_reset (RST_N);
    output_clock clk (CLK_OUT);
    output_reset rst (RST_N_OUT) clocked_by (clk);

    // Convert frequency (MHz) to period (ns)
    parameter CR_CLKIN_PERIOD = 1000 / inFreq;
    parameter CR_DIVCLK_DIVIDE = clockInDivider;
    parameter CR_CLKFBOUT_MULT = clockMultiplier;
    parameter CR_CLKOUT0_DIVIDE = clockOutDivider;

endmodule

//
// mkUserClock_PLL --
//   Generate a user clock based on the incoming frequency that is multiplied
//   by clockMultiplier and divided by clockDivider.
//
//   Uses a PLL instead of a DCM.
//
//   Picks the best source given a few standard ratios.
//
module mkUserClock_PLL#(Integer inFreq,
                        Integer outFreq)
    // Interface:
        (UserClock);

    UserClock clk = ?;

    // FPGA synthesis...

    if (inFreq == outFreq)
        clk <- mkUserClock_Same;
    else if (inFreq == outFreq * 2)
        clk <- mkUserClock_DivideByTwo;
    else
    begin
        // Compute PLL parameters for desired frequency
        match {.d_in, .mul, .d_out, .out_freq} = computePLLParams(fromInteger(inFreq),
                                                                  fromInteger(outFreq));

        // Check for errors
        if (d_in == 0)
        begin
            case (mul)
                1: error("Input frequency is out of legal range");
                2: error("Output frequency is out of legal range");
                default: error("Something failed");
            endcase
        end

        messageM(strConcat("PLL DIVCLK_DIVIDE:    ", integerToString(d_in)));
        messageM(strConcat("PLL CLKFBOUT_MULT:    ", integerToString(mul)));
        messageM(strConcat("PLL CLKOUT0_DIVIDE:   ", integerToString(d_out)));
        messageM(strConcat("PLL Output frequency: ", realToString(out_freq)));

        clk <- mkUserClock_Ratio_PLL(inFreq, d_in, mul, d_out);
    end


    return clk;

endmodule
