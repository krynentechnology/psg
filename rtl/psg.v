/**
 *  Copyright (C) 2024, Kees Krijnen.
 *
 *  This program is free software: you can redistribute it and/or modify it
 *  under the terms of the GNU Lesser General Public License as published by the
 *  Free Software Foundation, either version 3 of the License, or (at your
 *  option) any later version.
 *
 *  This program is distributed WITHOUT ANY WARRANTY; without even the implied
 *  warranty of MERCHANTIBILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this program. If not, see <https://www.gnu.org/licenses/> for a
 *  copy.
 *
 *  License: LGPL, v3, as defined and found on www.gnu.org,
 *           https://www.gnu.org/licenses/lgpl-3.0.html
 *
 *  Description: PSG - Programmable Sound Generator
 */

`resetall
`timescale 1ns / 1ps
`default_nettype none

// Dependencies:
// `include "../lib/equalizer.v"
// `include "../lib/interpolator.v"
// `include "../lib/randomizer.v"
// `include "../lib/sine_wg_cor.v"

/*============================================================================*/
module psg #(
/*============================================================================*/
    parameter NR_CHANNELS = 3,
    parameter OUTPUT_WIDTH = 24,
    parameter NR_EQ_BANDS = 4,
    parameter EQ_COEFF_WIDTH = 32, // S3.EQ_COEFF_WIDTH-4 fractional value
    parameter EQ_HEADROOM_BITS = 6,
    parameter [0:0] PHASE_MODULATION = 0,
    parameter [0:0] NOISE_GENERATOR = 0
    )
    (
    clk, rst_n, // Synchronous reset, high when clk is stable!
    s_phase_swg_d, s_phase_swg_ch,
    s_phase_swg_dv, s_phase_swg_dr, s_phase_swg_nchr,
    // _d = data, _ch = channel, _dv = data valid, _dr = data ready
    phase_swg_fraction, phase_swg_select,
    s_sine_zero, s_sine_dr,
    s_vol_swg_d, s_vol_swg_ch,
    s_vol_swg_dv, s_vol_swg_dr, s_vol_swg_nchr,
    vol_swg_fraction, vol_swg_select, vol_swg_stop_attn,
    m_signal_d, m_signal_dv, m_signal_dr,
    mixed_d, mixed_dv,
    rndm_ch, rndm_seed, rndm_init,
    eq_coeff_addr, eq_coeff
    );

localparam MAX_CLOG2_WIDTH = 8;
/*============================================================================*/
function integer clog2( input [MAX_CLOG2_WIDTH-1:0] value );
/*============================================================================*/
reg [MAX_CLOG2_WIDTH-1:0] depth;
begin
    clog2 = 1; // Minimum bit width
    if ( value > 1 ) begin
        depth = value - 1;
        clog2 = 0;
        while ( depth > 0 ) begin
            depth = depth >> 1;
            clog2 = clog2 + 1;
        end
    end
end
endfunction

localparam CHW = clog2( NR_CHANNELS ); // Channel width
localparam FRACTION_WIDTH = 32;
localparam INW = OUTPUT_WIDTH; // Input  width
localparam OUTW = OUTPUT_WIDTH; // Output width
localparam MIXW = OUTPUT_WIDTH + CHW;
localparam CNTRW = FRACTION_WIDTH; // Fraction and counter width
localparam NR_EQ_BAND_COEFF = 5; // a0, a1, a2, b1 and b2
localparam NR_EQ_COEFF = NR_CHANNELS * NR_EQ_BANDS * NR_EQ_BAND_COEFF;
localparam EQ_COEFF_ADDR_WIDTH = clog2( NR_EQ_COEFF );

input  wire clk;
input  wire rst_n;

input  wire [INW-1:0] s_phase_swg_d;
input  wire [CHW-1:0] s_phase_swg_ch;
input  wire s_phase_swg_dv;
output wire s_phase_swg_dr;
output wire s_phase_swg_nchr;
input  wire [CNTRW-1:0] phase_swg_fraction; // 1.CNTRW-1 fraction value
input  wire [2:0] phase_swg_select;
input  wire s_sine_zero;
output wire s_sine_dr;
input  wire [INW-1:0] s_vol_swg_d;
input  wire [CHW-1:0] s_vol_swg_ch;
input  wire s_vol_swg_dv;
output wire s_vol_swg_dr;
output wire s_vol_swg_nchr;
input  wire [CNTRW-1:0] vol_swg_fraction; // 1.CNTRW-1 fraction value
input  wire [2:0] vol_swg_select;
input  wire vol_swg_stop_attn;
output wire [OUTW-1:0] m_signal_d;
output wire  m_signal_dv;
input  wire  m_signal_dr;
output reg  [MIXW-1:0] mixed_d = 0;
output reg   mixed_dv = 0;
input  wire [CHW-1:0] rndm_ch;
input  wire [OUTW-1:0] rndm_seed;
input  wire rndm_init;
output wire [EQ_COEFF_ADDR_WIDTH-1:0] eq_coeff_addr;
input  wire [EQ_COEFF_WIDTH-1:0] eq_coeff; // S3.EQ_COEFF_WIDTH-4 fractional value

// Parameter checks
/*============================================================================*/
initial begin : param_check
/*============================================================================*/
    if ( NR_CHANNELS > (( 2 ** MAX_CLOG2_WIDTH ) - 1 )) begin
        $display( "NR_CHANNELS > (( 2 ** MAX_CLOG2_WIDTH ) - 1 )!" );
        $finish;
    end
    if ( EQ_COEFF_WIDTH > 36 ) begin
        $display( "EQ_COEFF_WIDTH > 36 (MAX BLOCK RAM WIDTH)!" );
        $finish;
    end
    if (( EQ_HEADROOM_BITS + OUTPUT_WIDTH ) > EQ_COEFF_WIDTH ) begin
        $display( "( EQ_HEADROOM_BITS + OUTPUT_WIDTH ) > EQ_COEFF_WIDTH!" );
        $finish;
    end
    if ( OUTPUT_WIDTH > FRACTION_WIDTH ) begin
        $display( "OUTPUT_WIDTH > FRACTION_WIDTH!" );
        $finish;
    end
end // param_check


wire s_phase_swg_dr_i;
wire [OUTW-1:0] m_phase_swg_d;
wire [CHW-1:0] m_phase_swg_ch = 0;
wire  m_phase_swg_dv;
wire  phase_overflow;

interpolator #(
    .POLYNOMIAL( "LINEAR" ),
    .NR_CHANNELS( NR_CHANNELS ),
    .INPUT_WIDTH( OUTPUT_WIDTH ),
    .FRACTION_WIDTH( FRACTION_WIDTH ),
    .ATTENUATION( 0 ))
phase_swg(
    .clk(clk),
    .rst_n(rst_n),
    .s_intrp_d(s_phase_swg_d),
    .s_intrp_ch(s_phase_swg_ch),
    .s_intrp_dv(s_phase_swg_dv & PHASE_MODULATION),
    .s_intrp_dr(s_phase_swg_dr_i),
    .s_intrp_nchr(s_phase_swg_nchr),
    .fraction(phase_swg_fraction),
    .select(phase_swg_select),
    .m_intrp_d(m_phase_swg_d),
    .m_intrp_ch(m_phase_swg_ch),
    .m_intrp_dv(m_phase_swg_dv),
    .m_intrp_dr(s_sine_dr),
    .overflow(phase_overflow)
    );

wire [INW-1:0] s_sine_d;
wire [CHW-1:0] s_sine_ch;
wire s_sine_dv;
wire [OUTPUT_WIDTH-1:0] m_sine_d;
wire [CHW-1:0] m_sine_ch;
wire m_sine_dv;
reg  m_sine_dv_i = 0;
wire m_sine_dr;

assign s_phase_swg_dr = ( s_phase_swg_dr_i & PHASE_MODULATION ) |
    ( s_sine_dr & ~PHASE_MODULATION );
assign s_sine_d = PHASE_MODULATION ? m_phase_swg_d : s_phase_swg_d;
assign s_sine_ch = PHASE_MODULATION ? m_phase_swg_ch : s_phase_swg_ch;
assign s_sine_dv = PHASE_MODULATION ? m_phase_swg_dv : s_phase_swg_dv;

sine_wg_cor #(
    .NR_CHANNELS( NR_CHANNELS ),
    .RADIAN_WIDTH( OUTPUT_WIDTH ),
    .PRECISION( OUTPUT_WIDTH - 3 ))
swg(
    .clk(clk),
    .rst_n(rst_n),
    .s_sine_d(s_sine_d),
    .s_sine_zero(s_sine_zero),
    .s_sine_ch(s_sine_ch),
    .s_sine_dv(s_sine_dv),
    .s_sine_dr(s_sine_dr),
    .m_sine_d(m_sine_d),
    .m_sine_ch(m_sine_ch),
    .m_sine_dv(m_sine_dv),
    .m_sine_dr(m_sine_dr)
    );

reg  s_vol_swg_dv_i = 0;
wire [OUTW-1:0] m_vol_swg_d;
wire [CHW-1:0] m_vol_swg_ch;
wire m_vol_swg_dv;
wire m_vol_swg_dr;
wire vol_overflow;
reg  [CHW-1:0] vol_swg_ch = 0;
wire signed [OUTW-1:0] sine_plus_noise;

interpolator #(
    .POLYNOMIAL( "2ND_ORDER" ),
    .NR_CHANNELS( NR_CHANNELS ),
    .INPUT_WIDTH( OUTPUT_WIDTH ),
    .FRACTION_WIDTH( FRACTION_WIDTH ),
    .ATTENUATION( 1 ))
vol_swg(
    .clk(clk),
    .rst_n(rst_n),
    .s_intrp_d(s_vol_swg_d),
    .s_intrp_ch(( s_vol_swg_dv || s_vol_swg_dv_i || vol_swg_stop_attn ) ? s_vol_swg_ch : vol_swg_ch ),
    .s_intrp_dv(s_vol_swg_dv),
    .s_intrp_dr(s_vol_swg_dr),
    .s_intrp_nchr(s_vol_swg_nchr),
    .fraction(vol_swg_fraction),
    .select(vol_swg_select),
    .m_intrp_d(m_vol_swg_d),
    .m_intrp_ch(m_vol_swg_ch),
    .m_intrp_dv(m_vol_swg_dv),
    .m_intrp_dr(m_vol_swg_dr),
    .s_signal_d(NOISE_GENERATOR ? sine_plus_noise : m_sine_d),
    .s_signal_dv(m_sine_dv),
    .s_signal_dr(m_sine_dr),
    .m_signal_d(m_signal_d),
    .m_signal_dv(m_signal_dv),
    .stop_attn(vol_swg_stop_attn),
    .overflow(vol_overflow)
    );

/*============================================================================*/
always @(posedge clk) begin : delayed_signals
/*============================================================================*/
    s_vol_swg_dv_i <= s_vol_swg_dv;
    m_sine_dv_i <= m_sine_dv;
end // delayed_signals

assign m_vol_swg_dr = ( m_sine_dv_i | m_sine_dv ) & m_vol_swg_dv;

/*============================================================================*/
always @(posedge clk) begin : track_sine_channel
/*============================================================================*/
    if ( s_sine_dv ) begin
        vol_swg_ch <= s_sine_ch;
    end
end // track_sine_channel

reg [CHW-1:0] m_vol_swg_ch_prev = NR_CHANNELS - 1;
reg signed [MIXW-1:0] mixed_d_i = 0;
wire signed [MIXW-1:0] sum_signal = mixed_d_i +
    $signed( {{( CHW ){m_signal_d[OUTW-1]}}, m_signal_d[OUTW-1:0]} );

/*============================================================================*/
always @(posedge clk) begin : mix_signals
/*============================================================================*/
    mixed_dv <= 0;
    if ( m_signal_dv && ( m_vol_swg_ch != m_vol_swg_ch_prev )) begin
        m_vol_swg_ch_prev <= m_vol_swg_ch;
        mixed_d_i <= sum_signal;
        if (( NR_CHANNELS - 1 ) == m_vol_swg_ch ) begin
            mixed_d_i <= 0; // Reset
            mixed_d <= sum_signal;
            mixed_dv <= 1;
        end
    end
    if ( !rst_n ) begin
        mixed_d_i <= 0;
        mixed_d <= 0;
        mixed_dv <= 0;
        m_vol_swg_ch_prev <= NR_CHANNELS - 1;
    end
end // mix_signals

wire [OUTW-1:0] rndm_out;
wire s_eq_dr;

randomizer #(
    .NR_CHANNELS( NR_CHANNELS ),
    .OUTPUT_WIDTH( OUTPUT_WIDTH ))
rndm(
    .clk(clk),
    .rndm_ch(rndm_ch),
    .rndm_seed(rndm_seed),
    .rndm_init(rndm_init),
    .rndm_out(rndm_out),
    .rndm_ready(s_eq_dr && NOISE_GENERATOR)
    );

reg  s_eq_dv = 0;
wire [OUTW-1:0] m_eq_d;
wire [CHW-1:0] m_eq_ch;
wire m_eq_dv;
reg  m_eq_dr = 1;
wire overflow;

equalizer #(
    .NR_CHANNELS( NR_CHANNELS ),
    .INPUT_WIDTH( OUTPUT_WIDTH ),
    .NR_EQ_BANDS( NR_EQ_BANDS ),
    .EQ_COEFF_WIDTH( EQ_COEFF_WIDTH ),
    .EQ_HEADROOM_BITS( EQ_HEADROOM_BITS ))
eq(
    .clk(clk),
    .rst_n(rst_n),
    .eq_coeff(eq_coeff),
    .eq_coeff_addr(eq_coeff_addr),
    .s_eq_d(rndm_out),
    .s_eq_ch(rndm_ch),
    .s_eq_dv(s_eq_dv && NOISE_GENERATOR),
    .s_eq_dr(s_eq_dr),
    .m_eq_d(m_eq_d),
    .m_eq_ch(m_eq_ch),
    .m_eq_dv(m_eq_dv),
    .m_eq_dr(m_eq_dr),
    .overflow(overflow)
    );

localparam [OUTW-2:0] ALL_ZERO = 0; // 00000...
localparam [OUTW-2:0] ALL_ONES = -1; // 11111...

wire signed [OUTW:0] sine_plus_noise_i;
assign sine_plus_noise_i = $signed( m_sine_d ) + $signed( m_eq_d );
assign sine_plus_noise[OUTW-1] = sine_plus_noise_i[OUTW-1]; // Copy sign
// Check for positive and negative overflow
assign sine_plus_noise[OUTW-2:0] =
    ( sine_plus_noise_i[OUTW-1] && !sine_plus_noise_i[OUTW-2] ) ? ALL_ZERO : // Maximum negative
    ( !sine_plus_noise_i[OUTW-1] && sine_plus_noise_i[OUTW-2] ) ? ALL_ONES : // Maximum positive
    sine_plus_noise_i[OUTW-2:0];

endmodule // psg