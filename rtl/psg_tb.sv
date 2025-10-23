/**
 *  Copyright (C) 2024, Kees Krijnen.
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
 *  Description: PSG - Programmable Sound Generator test bench
 */

`resetall
`timescale 1ns / 1ps
`default_nettype none

// Dependencies:
// `include "psg.v"

/*============================================================================*/
module psg_tb;
/*============================================================================*/

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

reg clk = 0;
reg rst_n = 0;

localparam NR_CHANNELS = 3;
localparam OUTPUT_WIDTH = 24;
localparam NR_EQ_BANDS = 4;
localparam EQ_COEFF_WIDTH = 32; // S3.EQ_COEFF_WIDTH-4 fractional value
localparam EQ_HEADROOM_BITS = 6;
localparam CHW = clog2( NR_CHANNELS ); // Channel width
localparam FRACTION_WIDTH = 32;
localparam INW = OUTPUT_WIDTH; // Input  width
localparam OUTW = OUTPUT_WIDTH; // Output width
localparam MIXW = OUTPUT_WIDTH + CHW;
localparam CNTRW = FRACTION_WIDTH; // Fraction and counter width
localparam NR_EQ_BAND_COEFF = 5; // a0, a1, a2, b1 and b2
localparam NR_EQ_COEFF = NR_CHANNELS * NR_EQ_BANDS * NR_EQ_BAND_COEFF;
localparam EQ_COEFF_ADDR_WIDTH = clog2( NR_EQ_COEFF );

reg  [INW-1:0] s_phase_swg1_d = 0; // _d = data
reg  [CHW-1:0] s_phase_swg1_ch = 0; // _ch = channel
reg  s_phase_swg1_dv = 0; // _dv = data valid
wire s_phase_swg1_dr; // _dr = data ready
wire s_phase_swg1_nchr; // _nchr = next channel ready
reg  [CNTRW-1:0] phase_swg1_fraction = 0; // 1.CNTRW-1 fraction value
reg  [2:0] phase_swg1_select = 0;
reg  s_sine1_zero = 0;
wire s_sine1_dr;
reg  [INW-1:0] s_vol_swg1_d = 0;
reg  [CHW-1:0] s_vol_swg1_ch = 0;
reg  s_vol_swg1_dv = 0;
wire s_vol_swg1_dr;
wire s_vol_swg1_nchr;
reg  [CNTRW-1:0] vol_swg1_fraction = 0; // 1.CNTRW-1 fraction value
reg  [2:0] vol_swg1_select = 0;
reg  vol_swg1_stop_attn = 0;
wire [OUTW-1:0] m_signal1_d;
wire m_signal1_dv;
reg  m_signal1_dr = 0;
wire [MIXW-1:0] mixed1_d;
wire mixed1_dv;
reg  [CHW-1:0] rndm1_ch = 0;
reg  [OUTPUT_WIDTH-1:0] rndm1_seed = 0;
reg  rndm1_init = 0;
wire [EQ_COEFF_ADDR_WIDTH-1:0] eq1_coeff_addr;
wire [EQ_COEFF_WIDTH-1:0] eq1_coeff; // S3.EQ_COEFF_WIDTH-4 fractional value

psg #(
    .NR_CHANNELS( NR_CHANNELS ),
    .OUTPUT_WIDTH( OUTPUT_WIDTH ),
    .NR_EQ_BANDS( NR_EQ_BANDS ),
    .EQ_COEFF_WIDTH( EQ_COEFF_WIDTH ),
    .EQ_HEADROOM_BITS( EQ_HEADROOM_BITS ),
    .PHASE_MODULATION( 0 ),
    .NOISE_GENERATOR( 0 ))
psg1(
    .clk(clk),
    .rst_n(rst_n),
    .s_phase_swg_d(s_phase_swg1_d),
    .s_phase_swg_ch(s_phase_swg1_ch),
    .s_phase_swg_dv(s_phase_swg1_dv),
    .s_phase_swg_dr(s_phase_swg1_dr),
    .s_phase_swg_nchr(s_phase_swg1_nchr),
    .phase_swg_fraction(phase_swg1_fraction),
    .phase_swg_select(phase_swg1_select),
    .s_sine_zero(s_sine1_zero),
    .s_sine_dr(s_sine1_dr),
    .s_vol_swg_d(s_vol_swg1_d),
    .s_vol_swg_ch(s_vol_swg1_ch),
    .s_vol_swg_dv(s_vol_swg1_dv),
    .s_vol_swg_dr(s_vol_swg1_dr),
    .s_vol_swg_nchr(s_vol_swg1_nchr),
    .vol_swg_fraction(vol_swg1_fraction),
    .vol_swg_select(vol_swg1_select),
    .vol_swg_stop_attn(vol_swg1_stop_attn),
    .m_signal_d(m_signal1_d),
    .m_signal_dv(m_signal1_dv),
    .m_signal_dr(m_signal1_dr),
    .mixed_d(mixed1_d),
    .mixed_dv(mixed1_dv),
    .rndm_ch(rndm1_ch),
    .rndm_seed(rndm1_seed),
    .rndm_init(rndm1_init),
    .eq_coeff_addr(eq1_coeff_addr),
    .eq_coeff(eq1_coeff)
    );

reg  [INW-1:0] s_phase_swg2_d = 0; // _d = data
reg  [CHW-1:0] s_phase_swg2_ch = 0; // _ch = channel
reg  s_phase_swg2_dv = 0; // _dv = data valid
wire s_phase_swg2_dr; // _dr = data ready
wire s_phase_swg2_nchr; // _nchr = next channel ready
reg  [CNTRW-1:0] phase_swg2_fraction = 0; // 1.CNTRW-1 fraction value
reg  [2:0] phase_swg2_select = 0;
reg  s_sine2_zero = 0;
wire s_sine2_dr;
reg  [INW-1:0] s_vol_swg2_d = 0;
reg  [CHW-1:0] s_vol_swg2_ch = 0;
reg  s_vol_swg2_dv = 0;
wire s_vol_swg2_dr;
wire s_vol_swg2_nchr;
reg  [CNTRW-1:0] vol_swg2_fraction = 0; // 1.CNTRW-1 fraction value
reg  [2:0] vol_swg2_select = 0;
reg  vol_swg2_stop_attn = 0;
wire [OUTW-1:0] m_signal2_d;
wire m_signal2_dv;
reg  m_signal2_dr = 0;
wire [MIXW-1:0] mixed2_d;
wire mixed2_dv;
reg  [CHW-1:0] rndm2_ch = 0;
reg  [OUTPUT_WIDTH-1:0] rndm2_seed = 0;
reg  rndm2_init = 0;
wire [EQ_COEFF_ADDR_WIDTH-1:0] eq2_coeff_addr;
wire [EQ_COEFF_WIDTH-1:0] eq2_coeff; // S3.EQ_COEFF_WIDTH-4 fractional value

psg #(
    .NR_CHANNELS( NR_CHANNELS ),
    .OUTPUT_WIDTH( OUTPUT_WIDTH ),
    .NR_EQ_BANDS( NR_EQ_BANDS ),
    .EQ_COEFF_WIDTH( EQ_COEFF_WIDTH ),
    .EQ_HEADROOM_BITS( EQ_HEADROOM_BITS ),
    .PHASE_MODULATION( 1 ),
    .NOISE_GENERATOR( 0 ))
psg2(
    .clk(clk),
    .rst_n(rst_n),
    .s_phase_swg_d(s_phase_swg2_d),
    .s_phase_swg_ch(s_phase_swg2_ch),
    .s_phase_swg_dv(s_phase_swg2_dv),
    .s_phase_swg_dr(s_phase_swg2_dr),
    .s_phase_swg_nchr(s_phase_swg2_nchr),
    .phase_swg_fraction(phase_swg2_fraction),
    .phase_swg_select(phase_swg2_select),
    .s_sine_zero(s_sine2_zero),
    .s_sine_dr(s_sine2_dr),
    .s_vol_swg_d(s_vol_swg2_d),
    .s_vol_swg_ch(s_vol_swg2_ch),
    .s_vol_swg_dv(s_vol_swg2_dv),
    .s_vol_swg_dr(s_vol_swg2_dr),
    .s_vol_swg_nchr(s_vol_swg2_nchr),
    .vol_swg_fraction(vol_swg2_fraction),
    .vol_swg_select(vol_swg2_select),
    .vol_swg_stop_attn(vol_swg2_stop_attn),
    .m_signal_d(m_signal2_d),
    .m_signal_dv(m_signal2_dv),
    .m_signal_dr(m_signal2_dr),
    .mixed_d(mixed2_d),
    .mixed_dv(mixed2_dv),
    .rndm_ch(rndm2_ch),
    .rndm_seed(rndm2_seed),
    .rndm_init(rndm2_init),
    .eq_coeff_addr(eq2_coeff_addr),
    .eq_coeff(eq2_coeff)
    );

always #5 clk = ~clk; // 100 MHz clock

localparam real MATH_2_PI = 2 * 3.14159265358979323846;
localparam real SAMPLE_FREQUENCY = 32000.0;
localparam real FULL_SCALE = ( 2.0 ** ( OUTW - 1 )) - 1;
localparam real RAMP_DOWN_THRESHOLD = 1000.0;
localparam real FS_FRACTION = RAMP_DOWN_THRESHOLD / FULL_SCALE;
localparam real FACTOR_1 = 2.0 ** ( CNTRW - 1 ); // 1.0 == power 2 fraction width

real rd_fraction = 0.0; // Ramp down fraction

/*============================================================================*/
function signed [OUTW-1:0] freq2rad( input real hz );
/*============================================================================*/
begin
    freq2rad = MATH_2_PI * hz * ( 2.0 ** ( OUTW - 3 )) / SAMPLE_FREQUENCY;
end
endfunction

reg phase_swg1_dv = 0;
reg phase_swg2_dv = 0;
reg vol_swg1_dv = 0;
reg vol_swg2_dv = 0;

/*============================================================================*/
always @(posedge clk) begin : clock_signals
/*============================================================================*/
    s_phase_swg1_dv <= phase_swg1_dv;
    s_phase_swg2_dv <= phase_swg2_dv;
    s_vol_swg1_dv <= vol_swg1_dv;
    s_vol_swg2_dv <= vol_swg2_dv;
end // clock_signals

localparam [2:0] STORE = 3'b001;
localparam [2:0] HEAD = 3'b010;
localparam [2:0] EXPONENTIAL = 3'b011; // Exponential signal attenuation!
localparam [2:0] RESET = 3'b111; // Reset internal state

/*============================================================================*/
task setup_linear( input integer inst,
                   input [INW-1:0] data,
                   input [CHW-1:0] channel,
                   input [CNTRW-1:0] fraction,
                   input [2:0] select );
/*============================================================================*/
begin
    case ( inst )
    1 : begin
        wait( s_phase_swg1_dr );
        s_phase_swg1_d = data;
        s_phase_swg1_ch = channel;
        phase_swg1_fraction = fraction;
        phase_swg1_select = select;
        wait ( clk ) @( negedge clk );
        phase_swg1_dv = 1;
        wait ( clk ) @( negedge clk );
        phase_swg1_dv = 0;
        if ( RESET == select ) begin
            wait ( clk ) @( posedge clk );
            phase_swg1_select = 0;
        end else begin
            wait( !s_phase_swg1_dr );
        end
    end
    2 : begin
        wait( s_phase_swg2_dr );
        s_phase_swg2_d = data;
        s_phase_swg2_ch = channel;
        phase_swg2_fraction = fraction;
        phase_swg2_select = select;
        wait ( clk ) @( negedge clk );
        phase_swg2_dv = 1;
        wait ( clk ) @( negedge clk );
        phase_swg2_dv = 0;
        if ( RESET == select ) begin
            wait ( clk ) @( posedge clk );
            phase_swg2_select = 0;
        end else begin
            wait( !s_phase_swg2_dr );
        end
    end
    endcase
end
endtask // setup_linear

/*============================================================================*/
task setup_quadratic( input integer inst,
                      input [INW-1:0] data,
                      input [CHW-1:0] channel,
                      input [CNTRW-1:0] fraction,
                      input [2:0] select );
/*============================================================================*/
begin
    case ( inst )
    1 : begin
        wait( s_vol_swg1_dr );
        s_vol_swg1_d = data;
        s_vol_swg1_ch = channel;
        vol_swg1_fraction = fraction;
        vol_swg1_select = select;
        wait ( clk ) @( negedge clk );
        vol_swg1_dv = 1;
        wait ( clk ) @( negedge clk );
        vol_swg1_dv = 0;
        if ( RESET == select ) begin
            wait ( clk ) @( posedge clk );
            vol_swg1_select = 0;
        end else begin
            wait( !s_vol_swg1_dr );
        end
    end
    2 : begin
        wait( s_vol_swg2_dr );
        s_vol_swg2_d = data;
        s_vol_swg2_ch = channel;
        vol_swg2_fraction = fraction;
        vol_swg2_select = select;
        wait ( clk ) @( negedge clk );
        vol_swg2_dv = 1;
        wait ( clk ) @( negedge clk );
        vol_swg2_dv = 0;
        if ( RESET == select ) begin
            wait ( clk ) @( posedge clk );
            vol_swg2_select = 0;
        end else begin
            wait( !s_vol_swg2_dr );
        end
    end
    endcase
end
endtask // setup_quadratic

integer file = 0;
/*============================================================================*/
task fw_16( input integer a );
/*============================================================================*/
integer temp;
begin // Write little endian!
    temp = a & 8'hff;
    $fwrite( file, "%c", temp );
    temp =  ( a >> 8 ) & 8'hff;
    $fwrite( file, "%c", temp );
end
endtask // swap

/*============================================================================*/
task fw_32( input integer a );
/*============================================================================*/
integer temp;
begin // Write little endian!
    fw_16( a );
    fw_16(( a >> 16 ) & 16'hffff );
end
endtask // swap

integer error = 0;
// Little endian WAV tags
localparam [31:0] RIFF_TAG = "RIFF";
localparam [31:0] WAVE_TAG = "WAVE";
localparam [31:0] FMT_TAG = "fmt ";
localparam [31:0] DATA_TAG = "data";

reg file_write = 0;

/*============================================================================*/
always @(posedge clk) begin : fwrite_mixed1
/*============================================================================*/
    if ( file ) begin
        if ( mixed1_dv ) begin
            if ( !file_write ) begin
                file_write <= 1;
                // mixed1_d[MIXW-2] is ignored, signal x 2!
                fw_16( { mixed1_d[MIXW-1], mixed1_d[MIXW-3:MIXW-17]} );
            end
        end else begin
            file_write <= 0;
        end
    end
end // fwrite_mixed1

/*============================================================================*/
always @(posedge clk) begin : fwrite_signal2
/*============================================================================*/
    if ( file ) begin
        if ( m_signal2_dv ) begin
            if ( !file_write ) begin
                file_write <= 1;
                fw_16( m_signal2_d[OUTW-1:OUTW-16] );
            end
        end else begin
            file_write <= 0;
        end
    end
end // fwrite_signal2

// Use string and byte file writes for verilog file I/O!
/*============================================================================*/
task open_wav_file( string file_name, input integer total_samples );
/*============================================================================*/
begin
    file = 0;
    file = $fopen( file_name, "wb" );
    if ( !file ) begin
        $display( "Failed to open file %s!", file_name );
        $finish;
    end
    // Write WAVE header; WAVE header numbers are little endian
    $fwrite( file, "%s", RIFF_TAG );
    fw_32( 0 ); // file length - 8
    $fwrite( file, "%s", WAVE_TAG );
    $fwrite( file, "%s", FMT_TAG );
    fw_32( 16 ); // FMT size 16 bytes
    fw_16( 1 ); // Format tag: 1 = PCM
    fw_16( 1 ); // Channels: 1 = mono, 2 = stereo
    fw_32( SAMPLE_FREQUENCY ); // Samples per second: e.g., 32000
    fw_32( SAMPLE_FREQUENCY * 2 ); // Bytes per second
    fw_16( 2 ); // Channels * bits per sample / 8
    fw_16( 16 ); // Bits per sample
    $fwrite( file, "%s", DATA_TAG );
    fw_32( 2 * total_samples ); // Length of the data block
end
endtask // open_wav_file

/*============================================================================*/
task close_wav_file( input integer total_samples );
/*============================================================================*/
begin
    error = $fseek( file, 4, 0 ); // SEEK set
    fw_32(( 2 * total_samples ) + 36 );
    $fclose( file );
    file = 0;
end
endtask // close_wav_file

localparam real DECAY_ADJUSTMENT = 2.0; // Decay adjustment fixed point calculation
integer i = 0;
integer j = 0;
integer interval_samples = 0;
integer duration_samples = 0;
integer total_samples = 0;

/*============================================================================*/
task chime_2_tone( input real hz1, // Hertz
                   input real hz2, // Hertz
                   input real interval, // Seconds
                   input real duration ); // Seconds
/*============================================================================*/
begin
    $display( "2-tone chime generation" );
    s_phase_swg1_dv = 0;
    s_vol_swg1_dv = 0;
    m_signal1_dr = 0;
    vol_swg1_stop_attn = 0;
    interval_samples = interval * SAMPLE_FREQUENCY;
    duration_samples = duration * SAMPLE_FREQUENCY;
    total_samples = duration_samples + interval_samples;
    open_wav_file( "2-tone chime.wav", total_samples );

    // Exponential ramp down function for channel 0!
    rd_fraction = FS_FRACTION ** ( 1.0 / ( DECAY_ADJUSTMENT * duration_samples ));
    setup_quadratic( 1, -FULL_SCALE, 0, 0, STORE ); // P1
    setup_quadratic( 1, 0, 0, 0, STORE ); // P0
    setup_quadratic( 1, FULL_SCALE, 0, 0, STORE ); // N1
    // Setup single interpolation pass for channel 1 (with fraction > 0.0 && < 1.0)!
    setup_quadratic( 1, 0, 1, 0, STORE ); // P1
    setup_quadratic( 1, 0, 1, 0, STORE ); // P0
    setup_quadratic( 1, 0, 1, 0, STORE ); // N1
    // Setup single interpolation pass for channel 2 (with fraction > 0.0 && < 1.0)!
    setup_quadratic( 1, 0, 2, 0, STORE ); // P1
    setup_quadratic( 1, 0, 2, 0, STORE ); // P0
    setup_quadratic( 1, 0, 2, 0, STORE ); // N1

    m_signal1_dr = 1;
    for ( i = 0; i < total_samples; i = i + 1 ) begin
        for ( j = 0; j < NR_CHANNELS; j = j + 1 ) begin
            s_phase_swg1_ch = j;
            s_vol_swg1_ch = j;
            wait ( s_phase_swg1_dr );
            case ( j )
            0 : s_phase_swg1_d = freq2rad( hz1 );
            1 : s_phase_swg1_d = ( i >= interval_samples ) ? freq2rad( hz2 ) : 0;
            2 : s_phase_swg1_d = 0;
            endcase
            s_sine1_zero = ((( 0 == i ) && ( 0 == j )) ||
                            (( interval_samples == i ) && ( 1 == j ))) ? 1 : 0;
            wait ( clk ) @( negedge clk );
            s_phase_swg1_dv = 1;
            wait ( clk ) @( negedge clk );
            s_phase_swg1_dv = 0;
            wait ( !s_phase_swg1_dr );
            if ( 0 == i ) begin
                case ( j ) // Start interpolation!
                0 : setup_quadratic( 1, RAMP_DOWN_THRESHOLD, 0, ( FACTOR_1 * rd_fraction ), EXPONENTIAL ); // N2
                1 : setup_quadratic( 1, RAMP_DOWN_THRESHOLD, 1, 1, EXPONENTIAL ); // N2
                2 : setup_quadratic( 1, RAMP_DOWN_THRESHOLD, 2, 1, EXPONENTIAL ); // N2
                endcase
            end
            if (( interval_samples == i ) && ( 1 == j )) begin // Start interpolation!
                setup_quadratic( 1, RAMP_DOWN_THRESHOLD, j, ( FACTOR_1 * rd_fraction ), EXPONENTIAL ); // N2
            end
            wait ( s_vol_swg1_nchr );
            if (( interval_samples == i ) && ( 0 == j )) begin
                s_vol_swg1_ch = 1; // Next channel = 1
                vol_swg1_stop_attn = 1; // Stop attenuation when channel = 0
                // Exponential ramp down function for channel 1!
                setup_quadratic( 1, -FULL_SCALE, 1, 0, STORE ); // P1
                setup_quadratic( 1, 0, 1, 0, STORE ); // P0
                setup_quadratic( 1, FULL_SCALE, 1, 0, STORE ); // N1
                vol_swg1_stop_attn = 0;
            end
        end
    end
    vol_swg1_stop_attn = 1; // Stop attenuation
    setup_quadratic( 1, 0, 0, 0, RESET );
    vol_swg1_stop_attn = 0;

    close_wav_file( total_samples );
end
endtask

integer interval2_samples = 0;

/*============================================================================*/
task chime_3_tone( input real hz1, // Hertz
                   input real hz2, // Hertz
                   input real hz3, // Hertz
                   input real interval, // Seconds
                   input real duration ); // Seconds
/*============================================================================*/
begin
    $display( "3-tone chime generation" );
    s_phase_swg1_dv = 0;
    s_vol_swg1_dv = 0;
    m_signal1_dr = 0;
    vol_swg1_stop_attn = 0;
    interval_samples = interval * SAMPLE_FREQUENCY;
    interval2_samples = 2 * interval_samples;
    duration_samples = duration * SAMPLE_FREQUENCY;
    total_samples = interval2_samples + duration_samples;
    open_wav_file( "3-tone chime.wav", total_samples );

    // Exponential ramp down function for channel 0!
    rd_fraction = FS_FRACTION ** ( 1.0 / ( DECAY_ADJUSTMENT * duration_samples ));
    setup_quadratic( 1, -FULL_SCALE, 0, 0, STORE ); // P1
    setup_quadratic( 1, 0, 0, 0, STORE ); // P0
    setup_quadratic( 1, FULL_SCALE, 0, 0, STORE ); // N1
    // Setup single interpolation pass for channel 1 (with fraction > 0.0 && < 1.0)!
    setup_quadratic( 1, 0, 1, 0, STORE ); // P1
    setup_quadratic( 1, 0, 1, 0, STORE ); // P0
    setup_quadratic( 1, 0, 1, 0, STORE ); // N1
    // Setup single interpolation pass for channel 2 (with fraction > 0.0 && < 1.0)!
    setup_quadratic( 1, 0, 2, 0, STORE ); // P1
    setup_quadratic( 1, 0, 2, 0, STORE ); // P0
    setup_quadratic( 1, 0, 2, 0, STORE ); // N1

    m_signal1_dr = 1;
    for ( i = 0; i < total_samples; i = i + 1 ) begin
        for ( j = 0; j < NR_CHANNELS; j = j + 1 ) begin
            s_phase_swg1_ch = j;
            s_vol_swg1_ch = j;
            wait ( s_phase_swg1_dr );
            case ( j )
            0 : s_phase_swg1_d = freq2rad( hz1 );
            1 : s_phase_swg1_d = ( i >= interval_samples ) ? freq2rad( hz2 ) : 0;
            2 : s_phase_swg1_d = ( i >= interval2_samples ) ? freq2rad( hz3 ) : 0;
            endcase
            s_sine1_zero = ((( 0 == i ) && ( 0 == j )) ||
                            (( interval_samples == i ) && ( 1 == j )) ||
                            (( interval2_samples == i ) && ( 2 == j ))) ? 1 : 0;
            wait ( clk ) @( negedge clk );
            s_phase_swg1_dv = 1;
            wait ( clk ) @( negedge clk );
            s_phase_swg1_dv = 0;
            wait ( !s_phase_swg1_dr );
            if ( 0 == i ) begin
                case ( j ) // Start interpolation!
                0 : setup_quadratic( 1, RAMP_DOWN_THRESHOLD, 0, ( FACTOR_1 * rd_fraction ), EXPONENTIAL ); // N2
                1 : setup_quadratic( 1, RAMP_DOWN_THRESHOLD, 1, 1, EXPONENTIAL ); // N2
                2 : setup_quadratic( 1, RAMP_DOWN_THRESHOLD, 2, 1, EXPONENTIAL ); // N2
                endcase
            end
            if (( interval_samples == i ) && ( 1 == j )) begin // Start interpolation!
                setup_quadratic( 1, RAMP_DOWN_THRESHOLD, j, ( FACTOR_1 * rd_fraction ), EXPONENTIAL ); // N2
            end
            if (( interval2_samples == i ) && ( 2 == j )) begin // Start interpolation!
                setup_quadratic( 1, RAMP_DOWN_THRESHOLD, j, ( FACTOR_1 * rd_fraction ), EXPONENTIAL ); // N2
            end
            wait ( s_vol_swg1_nchr );
            if (( interval_samples == i ) && ( 0 == j )) begin
                s_vol_swg1_ch = 1; // Next channel = 1
                vol_swg1_stop_attn = 1; // Stop attenuation when channel = 0
                // Exponential ramp down function for channel 1!
                setup_quadratic( 1, -FULL_SCALE, 1, 0, STORE ); // P1
                setup_quadratic( 1, 0, 1, 0, STORE ); // P0
                setup_quadratic( 1, FULL_SCALE, 1, 0, STORE ); // N1
                vol_swg1_stop_attn = 0;
            end
            if (( interval2_samples == i ) && ( 1 == j )) begin
                s_vol_swg1_ch = 2; // Next channel = 2
                vol_swg1_stop_attn = 1; // Stop attenuation when channel = 1
                // Exponential ramp down function for channel 2!
                setup_quadratic( 1, -FULL_SCALE, 2, 0, STORE ); // P1
                setup_quadratic( 1, 0, 2, 0, STORE ); // P0
                setup_quadratic( 1, FULL_SCALE, 2, 0, STORE ); // N1
                vol_swg1_stop_attn = 0;
            end
        end
    end
    vol_swg1_stop_attn = 1; // Stop attenuation
    setup_quadratic( 1, 0, 0, 0, RESET );
    vol_swg1_stop_attn = 0;

    close_wav_file( total_samples );
end
endtask

integer interval3_samples = 0;

/*============================================================================*/
task chime_4_tone( input real hz1, // Hertz
                   input real hz2, // Hertz
                   input real hz3, // Hertz
                   input real hz4, // Hertz
                   input real interval, // Seconds
                   input real duration ); // Seconds
/*============================================================================*/
begin
    $display( "4-tone chime generation" );
    s_phase_swg1_dv = 0;
    s_vol_swg1_dv = 0;
    m_signal1_dr = 0;
    vol_swg1_stop_attn = 0;
    interval_samples = interval * SAMPLE_FREQUENCY;
    interval2_samples = 2 * interval_samples;
    interval3_samples = 3 * interval_samples;
    duration_samples = duration * SAMPLE_FREQUENCY;
    total_samples = interval3_samples + duration_samples;
    open_wav_file( "4-tone chime.wav", total_samples );

    // Exponential ramp down function for channel 0!
    rd_fraction = FS_FRACTION ** ( 1.0 / ( DECAY_ADJUSTMENT * duration_samples ));
    setup_quadratic( 1, -FULL_SCALE, 0, 0, STORE ); // P1
    setup_quadratic( 1, 0, 0, 0, STORE ); // P0
    setup_quadratic( 1, FULL_SCALE, 0, 0, STORE ); // N1
    // Setup single interpolation pass for channel 1 (with fraction > 0.0 && < 1.0)!
    setup_quadratic( 1, 0, 1, 0, STORE ); // P1
    setup_quadratic( 1, 0, 1, 0, STORE ); // P0
    setup_quadratic( 1, 0, 1, 0, STORE ); // N1
    // Setup single interpolation pass for channel 2 (with fraction > 0.0 && < 1.0)!
    setup_quadratic( 1, 0, 2, 0, STORE ); // P1
    setup_quadratic( 1, 0, 2, 0, STORE ); // P0
    setup_quadratic( 1, 0, 2, 0, STORE ); // N1

    m_signal1_dr = 1;
    for ( i = 0; i < total_samples; i = i + 1 ) begin
        for ( j = 0; j < NR_CHANNELS; j = j + 1 ) begin
            s_phase_swg1_ch = j;
            s_vol_swg1_ch = j;
            wait ( s_phase_swg1_dr );
            case ( j )
            0 : s_phase_swg1_d = ( i >= interval3_samples ) ? freq2rad( hz4 ) : freq2rad( hz1 );
            1 : s_phase_swg1_d = ( i >= interval_samples ) ? freq2rad( hz2 ) : 0;
            2 : s_phase_swg1_d = ( i >= interval2_samples ) ? freq2rad( hz3 ) : 0;
            endcase
            s_sine1_zero = ((( 0 == i ) && ( 0 == j )) ||
                            (( interval_samples == i ) && ( 1 == j )) ||
                            (( interval2_samples == i ) && ( 2 == j ))) ? 1 : 0;
            wait ( clk ) @( negedge clk );
            s_phase_swg1_dv = 1;
            wait ( clk ) @( negedge clk );
            s_phase_swg1_dv = 0;
            wait ( !s_phase_swg1_dr );
            if ( 0 == i ) begin
                case ( j ) // Start interpolation!
                0 : setup_quadratic( 1, RAMP_DOWN_THRESHOLD, 0, ( FACTOR_1 * rd_fraction ), EXPONENTIAL ); // N2
                1 : setup_quadratic( 1, RAMP_DOWN_THRESHOLD, 1, 1, EXPONENTIAL ); // N2
                2 : setup_quadratic( 1, RAMP_DOWN_THRESHOLD, 2, 1, EXPONENTIAL ); // N2
                endcase
            end
            if (( interval3_samples == i ) && ( 0 == j )) begin // Start interpolation!
                setup_quadratic( 1, RAMP_DOWN_THRESHOLD, j, ( FACTOR_1 * rd_fraction ), EXPONENTIAL ); // N2
            end
            if (( interval_samples == i ) && ( 1 == j )) begin // Start interpolation!
                setup_quadratic( 1, RAMP_DOWN_THRESHOLD, j, ( FACTOR_1 * rd_fraction ), EXPONENTIAL ); // N2
            end
            if (( interval2_samples == i ) && ( 2 == j )) begin // Start interpolation!
                setup_quadratic( 1, RAMP_DOWN_THRESHOLD, j, ( FACTOR_1 * rd_fraction ), EXPONENTIAL ); // N2
            end
            wait ( s_vol_swg1_nchr );
            if (( interval_samples == i ) && ( 0 == j )) begin
                s_vol_swg1_ch = 1; // Next channel = 1
                vol_swg1_stop_attn = 1; // Stop attenuation when channel = 0
                // Exponential ramp down function for channel 1!
                setup_quadratic( 1, -FULL_SCALE, 1, 0, STORE ); // P1
                setup_quadratic( 1, 0, 1, 0, STORE ); // P0
                setup_quadratic( 1, FULL_SCALE, 1, 0, STORE ); // N1
                vol_swg1_stop_attn = 0;
            end
            if (( interval2_samples == i ) && ( 1 == j )) begin
                s_vol_swg1_ch = 2; // Next channel = 2
                vol_swg1_stop_attn = 1; // Stop attenuation when channel = 1
                // Exponential ramp down function for channel 2!
                setup_quadratic( 1, -FULL_SCALE, 2, 0, STORE ); // P1
                setup_quadratic( 1, 0, 2, 0, STORE ); // P0
                setup_quadratic( 1, FULL_SCALE, 2, 0, STORE ); // N1
                vol_swg1_stop_attn = 0;
            end
            // Check interval3_samples - 1 because j == last channel!
            if ((( interval3_samples - 1 ) == i ) && ( 2 == j )) begin
                s_vol_swg1_ch = 0; // Next channel = 0
                vol_swg1_stop_attn = 1; // Stop attenuation when channel = 2
                // Exponential ramp down function for channel 0!
                setup_quadratic( 1, -FULL_SCALE, 0, 0, STORE ); // P1
                setup_quadratic( 1, 0, 0, 0, STORE ); // P0
                setup_quadratic( 1, FULL_SCALE, 0, 0, STORE ); // N1
                vol_swg1_stop_attn = 0;
            end
        end
    end
    vol_swg1_stop_attn = 1; // Stop attenuation
    setup_quadratic( 1, 0, 0, 0, RESET );
    vol_swg1_stop_attn = 0;

    close_wav_file( total_samples );
end
endtask

localparam real FADE_OUT_MS = 10.0;
integer sweep_samples = 0;
integer silence_samples = 0;
integer fade_out_samples = 0;

/*============================================================================*/
task whoop( input real hz1, // Hertz
            input real hz2, // Hertz
            input real sweep, // Seconds
            input real silence, // Seconds
            input integer iteration,
            input string display_txt,
            input string file_name );
/*============================================================================*/
begin
    $display( display_txt );
    // A single channel is required, m_signal2_d is collected!
    s_phase_swg2_ch = 0;
    s_vol_swg2_ch = 0;
    m_signal2_dr = 0;
    vol_swg1_stop_attn = 0;
    sweep_samples = sweep * SAMPLE_FREQUENCY;
    silence_samples = silence * SAMPLE_FREQUENCY;
    total_samples = iteration * ( sweep_samples + silence_samples );
    open_wav_file( file_name, total_samples );
    // Exponential fade out (ramp down) function for channel s_vol_swg2_ch!
    fade_out_samples = (( FADE_OUT_MS * SAMPLE_FREQUENCY ) / 1000.0 );
    rd_fraction = FS_FRACTION ** ( 1.0 / ( DECAY_ADJUSTMENT * fade_out_samples ));

    m_signal2_dr = 1;
    for ( i = 0; i < iteration; i = i + 1 ) begin
        setup_quadratic( 2, -FULL_SCALE, s_vol_swg2_ch, 0, STORE ); // P1
        setup_quadratic( 2, 0, s_vol_swg2_ch, 0, STORE ); // P0
        setup_quadratic( 2, FULL_SCALE, s_vol_swg2_ch, 0, STORE ); // N1
        setup_quadratic( 2, 0, s_vol_swg2_ch, FACTOR_1, EXPONENTIAL ); // N2
        setup_linear( 2, freq2rad( hz1 ), s_phase_swg2_ch, 0, STORE ); // P0
        setup_linear( 2, freq2rad( hz2 ), s_phase_swg2_ch, ( FACTOR_1 / sweep_samples ), 0 ); // N1
        wait( s_sine2_dr );
        s_sine2_zero = 1;
        wait( !s_sine2_dr );
        s_sine2_zero = 0;
        wait( s_phase_swg2_dr ); // Wait for sweep is finished, setup fade out and silence!
        setup_quadratic( 2, -FULL_SCALE, s_vol_swg2_ch, 0, STORE ); // P1
        setup_quadratic( 2, 0, s_vol_swg2_ch, 0, STORE ); // P0
        setup_quadratic( 2, FULL_SCALE, s_vol_swg2_ch, 0, STORE ); // N1
        setup_quadratic( 2, 0, s_phase_swg2_ch, ( FACTOR_1 * rd_fraction ), EXPONENTIAL ); // N2
        setup_linear( 2, freq2rad( hz2 ), s_phase_swg2_ch, ( FACTOR_1 / silence_samples ), 0 );
        wait( s_phase_swg2_dr ); // Wait for silence is finished!
        wait ( s_vol_swg2_nchr );
        vol_swg2_stop_attn = 1; // Stop attenuation
        setup_quadratic( 2, 0, s_vol_swg2_ch, 0, RESET );
        vol_swg2_stop_attn = 0;
    end

    setup_linear( 2, 0, s_phase_swg2_ch, 0, RESET );

    close_wav_file( total_samples );
end
endtask

integer sweep1_samples = 0;
integer sweep2_samples = 0;

/*============================================================================*/
task alarm( input real hz1, // Hertz
            input real hz2, // Hertz
            input real sweep1, // Seconds
            input real sweep2, // Seconds
            input integer iteration,
            input string display_txt,
            input string file_name );
/*============================================================================*/
begin
    $display( display_txt );
    // A single channel is required, m_signal2_d is collected!
    s_phase_swg2_ch = 0;
    s_vol_swg2_ch = 0;
    m_signal2_dr = 0;
    vol_swg2_stop_attn = 0;
    sweep1_samples = sweep1 * SAMPLE_FREQUENCY;
    sweep2_samples = sweep2 * SAMPLE_FREQUENCY;
    total_samples = iteration * ( sweep1_samples + sweep2_samples );
    open_wav_file( file_name, total_samples );

    setup_quadratic( 2, FULL_SCALE, s_vol_swg2_ch, 0, STORE ); // P1
    setup_quadratic( 2, FULL_SCALE, s_vol_swg2_ch, 0, STORE ); // P0
    setup_quadratic( 2, FULL_SCALE, s_vol_swg2_ch, 0, STORE ); // N1
    setup_quadratic( 2, FULL_SCALE, 0, FACTOR_1, EXPONENTIAL ); // N2

    m_signal2_dr = 1;
    for ( i = 0; i < iteration; i = i + 1 ) begin
        setup_linear( 2, freq2rad( hz1 ), 0, 0, STORE ); // P0
        setup_linear( 2, freq2rad( hz2 ), 0, ( FACTOR_1 / sweep1_samples ), 0 ); // N1
        wait( s_sine2_dr );
        s_sine2_zero = 1;
        wait( !s_sine2_dr );
        s_sine2_zero = 0;
        setup_linear( 2, freq2rad( hz1 ), 0, ( FACTOR_1 / sweep2_samples ), 0 ); // N1
        wait( s_sine2_dr );
        s_sine2_zero = 1;
        wait( !s_sine2_dr );
        s_sine2_zero = 0;
    end

    wait( s_phase_swg2_dr ); // Wait for last sweep is finished!
    wait ( s_vol_swg2_nchr );
    vol_swg2_stop_attn = 1; // Stop attenuation
    setup_quadratic( 2, 0, 0, 0, RESET );
    vol_swg2_stop_attn = 0;
    setup_linear( 2, 0, 0, 0, RESET );

    close_wav_file( total_samples );
end
endtask

/*============================================================================*/
initial begin
/*============================================================================*/
    rst_n = 0;
    m_signal1_dr = 0;
    m_signal2_dr = 0;
    #100 // 0.1us
    rst_n  = 1;
    $display( "PSG simulation started" );
    chime_2_tone( 554, 440, 1.0, 2.0 );
    chime_3_tone( 659, 523, 392, 1.0, 2.0 );
    chime_4_tone( 659, 523, 392, 330, 1.0, 2.0 );
    whoop( 700, 880, 0.4, 0.4, 6, "Fast whoop generation", "fast whoop.wav" );
    whoop( 500, 1200, 3.5, 0.5, 2, "Fire Dutch generation", "fire dutch.wav" );
    alarm( 650, 850, 0.5, 0.5, 5, "Police alarm generation", "police alarm.wav" );
    #10000 // 10us
    $display( "Simulation finished" );
    $finish;
end

/*============================================================================*/
initial begin // Generate VCD file for GTKwave
/*============================================================================*/
`ifdef GTK_WAVE
    $dumpfile( "psg_tb.vcd" );
    $dumpvars( 0 );
`endif
end

endmodule // psg_tb