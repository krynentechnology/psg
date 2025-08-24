/**
 *  Copyright (C) 2025, Kees Krijnen.
 *
 *  This program is free software: you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License as published by the Free
 *  Software Foundation, either version 3 of the License, or (at your option)
 *  any later version.
 *
 *  This program is distributed WITHOUT ANY WARRANTY; without even the implied
 *  warranty of MERCHANTIBILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along with
 *  this program. If not, see <https://www.gnu.org/licenses/> for a copy.
 *
 *  License: GPL, v3, as defined and found on www.gnu.org,
 *           https://www.gnu.org/licenses/gpl-3.0.html
 *
 *  Description: PSG - Programmable Sound Generator C++ test bench
 */

#include <memory>
#include <verilated.h>
#include "Vpsg.h"

int main( int argc, char** argv ) {
    const std::unique_ptr<VerilatedContext> contextp{ new VerilatedContext };
    contextp->debug( 0 );
    contextp->randReset( 2 );
    contextp->traceEverOn( false );
    contextp->commandArgs( argc, argv );
    const std::unique_ptr<Vpsg> psg{ new Vpsg{ contextp.get(), "PSG" }};

    // Set Vpsg's input signals
    psg->clk = 0;
    psg->rst_n = 1;

    psg->s_phase_swg_d = 0;
    psg->s_phase_swg_ch = 0;
    psg->s_phase_swg_dv = 0;
    psg->phase_swg_fraction = 0;
    psg->phase_swg_select = 0;
    psg->s_sine_zero = 0;
    psg->s_vol_swg_d = 0;
    psg->s_vol_swg_ch = 0;
    psg->s_vol_swg_dv = 0;
    psg->vol_swg_fraction = 0;
    psg->vol_swg_select = 0;
    psg->vol_swg_stop_attn = 0;
    psg->m_signal_dr = 0;
    psg->rndm_ch = 0;
    psg->rndm_seed = 0;
    psg->rndm_init = 0;
    psg->eq_coeff = 0;

    while ( !contextp->gotFinish() ) {
        contextp->timeInc( 1 );
        psg->clk = !psg->clk;
        psg->eval();
        
        // TO DO
        // Test psg.v module
        break;
    }
/*
    while ( !contextp->gotFinish() ) {
        contextp->timeInc( 1 );
        psg->clk = !psg->clk;
        psg->eval();
        
        // TO DO
        // Next test psg.v module
    }
*/
    psg->final();
    contextp->statsPrintSummary();

    return 0;
}
