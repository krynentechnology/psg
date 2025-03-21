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
 *  Description: Equalizer module simulation
 */

`resetall
`timescale 1ns / 1ps
`default_nettype none

module equalizer_tb;

localparam NR_CHANNELS = 3;
localparam INPUT_WIDTH = 24;
localparam NR_EQ_BANDS = 8;
localparam EQ_COEFF_WIDTH = 32;

localparam CHANNEL_WIDTH = $clog2( NR_CHANNELS );
localparam NR_EQ_BAND_COEFF = 5; // a0, a1, a2, b1 and b2
localparam NR_EQ_COEFF = NR_CHANNELS * NR_EQ_BANDS * NR_EQ_BAND_COEFF;
localparam EQ_COEFF_ADDR_WIDTH = $clog2( NR_EQ_COEFF );

reg clk = 0;
reg rst_n = 0;
reg mute = 0;

wire [EQ_COEFF_WIDTH-1:0] eq_coeff;
wire [EQ_COEFF_ADDR_WIDTH-1:0] eq_coeff_addr;
wire [INPUT_WIDTH-1:0] s_eq_d;
wire [CHANNEL_WIDTH-1:0] s_eq_ch;
wire s_eq_dv;
wire s_eq_dr;
wire [INPUT_WIDTH-1:0] m_eq_d;
wire [CHANNEL_WIDTH-1:0] m_eq_ch;
wire m_eq_dv;
reg  m_eq_dr = 0;
wire overflow;

localparam [INPUT_WIDTH-1:0] ZERO = 0; // 00000...

equalizer eq1(
    .clk(clk),
    .rst_n(rst_n),
    .eq_coeff(eq_coeff),
    .eq_coeff_addr(eq_coeff_addr),
    .s_eq_d(mute ? ZERO : s_eq_d),
    .s_eq_ch(s_eq_ch),
    .s_eq_dv(s_eq_dv),
    .s_eq_dr(s_eq_dr),
    .m_eq_d(m_eq_d),
    .m_eq_ch(m_eq_ch),
    .m_eq_dv(m_eq_dv),
    .m_eq_dr(m_eq_dr),
    .overflow(overflow));

defparam eq1.NR_CHANNELS = NR_CHANNELS;
defparam eq1.INPUT_WIDTH = INPUT_WIDTH;
defparam eq1.NR_EQ_BANDS = NR_EQ_BANDS;
defparam eq1.EQ_COEFF_WIDTH = EQ_COEFF_WIDTH;
defparam eq1.EQ_HEADROOM_BITS = 6;

reg [1:0] eq_coeff_sel = 0;

always #5 clk = ~clk; // 100 MHz clock

/*============================================================================*/
initial begin
/*============================================================================*/
    rst_n = 0;
    mute = 0;
    eq_coeff_sel = 1; // A0 factor = 1.0
    $display( "Equalizer simulation started" );
    #100     // 0.1us
    $display( "Set A0 factor = 1.0" );
    rst_n = 1;
    m_eq_dr = 1;
    #1000000 // 1ms
    eq_coeff_sel = 0;
    #1000000 // 1ms
    $display( "Mute signal" );
    mute = 1;
    #1000000 // 1ms
    $display( "Unmute signal" );
    mute = 0;
    eq_coeff_sel = 2; // A0 factor = 1.5
    $display( "Set A0 factor = 1.5" );
    #1000000 // 1ms
    eq_coeff_sel = 3; // A0 factor = 0.5
    $display( "Set A0 factor = 0.5" );
    #1000000 // 1ms
    mute = 1;
    #100000 // 0.1ms
   $finish;
end

reg signed [INPUT_WIDTH-1:0] data_eq_in_0 = 0;
reg signed [INPUT_WIDTH-1:0] data_eq_in_1 = 0;
reg signed [INPUT_WIDTH-1:0] data_eq_in_2 = 0;
reg signed [INPUT_WIDTH-1:0] data_eq_out_0 = 0;
reg signed [INPUT_WIDTH-1:0] data_eq_out_1 = 0;
reg signed [INPUT_WIDTH-1:0] data_eq_out_2 = 0;

/*============================================================================*/
always @(posedge clk) begin : collect_eq_data
/*============================================================================*/
    if ( s_eq_dv  ) begin
        case ( s_eq_ch )
            0 : begin
                data_eq_in_0 <= s_eq_d;
            end
            1 : begin
                data_eq_in_1 <= s_eq_d;
            end
            2 : begin
                data_eq_in_2 <= s_eq_d;
            end
        endcase
    end
    if ( m_eq_dv ) begin
        case ( m_eq_ch )
            0 : begin
                data_eq_out_0 <= m_eq_d;
            end
            1 : begin
                data_eq_out_1 <= m_eq_d;
            end
            2 : begin
                data_eq_out_2 <= m_eq_d;
            end
        endcase
    end
end // collect_eq_data

////////////////// Initializing EQ coefficients ////////////////////////////////
/*============================================================================*/
function signed [EQ_COEFF_WIDTH-1:0] signed_eq_coeff( input real eq_coeff );
/*============================================================================*/
    reg [EQ_COEFF_WIDTH-1:0] eq_coeff_r;
    begin
        if ( eq_coeff >= 0.0 ) begin
            eq_coeff_r = (( 2.0 ** ( EQ_COEFF_WIDTH - 4 ) - 1 ) * eq_coeff );
            signed_eq_coeff = $signed( eq_coeff_r );
        end
        else begin
            eq_coeff_r = (( 2.0 ** ( EQ_COEFF_WIDTH - 4 ) - 1 ) * eq_coeff );
            signed_eq_coeff = $signed( eq_coeff_r );
        end
    end
endfunction // signed_eq_coeff

// 1000Hz notch filter (Q = 0.7071)
localparam signed [EQ_COEFF_WIDTH-1:0] A0_1KHz = signed_eq_coeff( 0.9155020528055772 );
localparam signed [EQ_COEFF_WIDTH-1:0] A1_1KHz = signed_eq_coeff( -1.8153396116625289 );
localparam signed [EQ_COEFF_WIDTH-1:0] A2_1KHz = signed_eq_coeff( 0.9155020528055772 );
localparam signed [EQ_COEFF_WIDTH-1:0] B1_1KHz = signed_eq_coeff( 1.8153396116625289 );  // A1 (== -B1)
localparam signed [EQ_COEFF_WIDTH-1:0] B2_1KHz = signed_eq_coeff( -0.8310041056111546 );
// 4000Hz notch filter (Q = 0.7071)
localparam signed [EQ_COEFF_WIDTH-1:0] A0_4KHz = signed_eq_coeff( 0.7387942743704942 );
localparam signed [EQ_COEFF_WIDTH-1:0] A1_4KHz = signed_eq_coeff( -1.2796292195506773 );
localparam signed [EQ_COEFF_WIDTH-1:0] A2_4KHz = signed_eq_coeff( 0.7387942743704942 );
localparam signed [EQ_COEFF_WIDTH-1:0] B1_4KHz = signed_eq_coeff( 1.2796292195506773 );   // A1 (== -B1)
localparam signed [EQ_COEFF_WIDTH-1:0] B2_4KHz = signed_eq_coeff( -0.47758854874098844 );
// 16000Hz notch filter (Q = 4.0)
localparam signed [EQ_COEFF_WIDTH-1:0] A0_16KHz = signed_eq_coeff( 0.9023208975450513 );
localparam signed [EQ_COEFF_WIDTH-1:0] A1_16KHz = signed_eq_coeff( 0.902320897545051 );
localparam signed [EQ_COEFF_WIDTH-1:0] A2_16KHz = signed_eq_coeff( 0.9023208975450513 );
localparam signed [EQ_COEFF_WIDTH-1:0] B1_16KHz = signed_eq_coeff( -0.902320897545051 );  // -A1 (== B1)
localparam signed [EQ_COEFF_WIDTH-1:0] B2_16KHz = signed_eq_coeff( -0.8046417950901026 );

integer i;
reg signed [EQ_COEFF_WIDTH-1:0] eq_ram_coeff[NR_EQ_COEFF-1:0];

/*============================================================================*/
initial begin : init_eq_ram_coeff
/*============================================================================*/
    for (i = 0; i < ( NR_CHANNELS * NR_EQ_BANDS ); i = i + 1 ) begin
        case ( i % NR_EQ_BANDS )
            0 : begin
                // 1st band
                eq_ram_coeff[( i* NR_EQ_BAND_COEFF ) + 0] = A0_1KHz;
                eq_ram_coeff[( i* NR_EQ_BAND_COEFF ) + 1] = A1_1KHz;
                eq_ram_coeff[( i* NR_EQ_BAND_COEFF ) + 2] = A2_1KHz;
                eq_ram_coeff[( i* NR_EQ_BAND_COEFF ) + 3] = B1_1KHz;
                eq_ram_coeff[( i* NR_EQ_BAND_COEFF ) + 4] = B2_1KHz;
            end
            1 : begin
                // 2nd band
                eq_ram_coeff[( i * NR_EQ_BAND_COEFF ) + 0] = A0_4KHz;
                eq_ram_coeff[( i * NR_EQ_BAND_COEFF ) + 1] = A1_4KHz;
                eq_ram_coeff[( i * NR_EQ_BAND_COEFF ) + 2] = A2_4KHz;
                eq_ram_coeff[( i * NR_EQ_BAND_COEFF ) + 3] = B1_4KHz;
                eq_ram_coeff[( i * NR_EQ_BAND_COEFF ) + 4] = B2_4KHz;
            end
            2 : begin
                // 3rd band
                eq_ram_coeff[( i* NR_EQ_BAND_COEFF ) + 0] = A0_16KHz;
                eq_ram_coeff[( i* NR_EQ_BAND_COEFF ) + 1] = A1_16KHz;
                eq_ram_coeff[( i* NR_EQ_BAND_COEFF ) + 2] = A2_16KHz;
                eq_ram_coeff[( i* NR_EQ_BAND_COEFF ) + 3] = B1_16KHz;
                eq_ram_coeff[( i* NR_EQ_BAND_COEFF ) + 4] = B2_16KHz;
            end
            default : begin
                eq_ram_coeff[( i * NR_EQ_BAND_COEFF ) + 0] = 0;
                eq_ram_coeff[( i * NR_EQ_BAND_COEFF ) + 0][EQ_COEFF_WIDTH-4] = 1; // Set A0 parameter to 1.0 { in a range (-8.0, 8.0) }
                eq_ram_coeff[( i * NR_EQ_BAND_COEFF ) + 1] = 0;
                eq_ram_coeff[( i * NR_EQ_BAND_COEFF ) + 2] = 0;
                eq_ram_coeff[( i * NR_EQ_BAND_COEFF ) + 3] = 0;
                eq_ram_coeff[( i * NR_EQ_BAND_COEFF ) + 4] = 0;
            end
        endcase
    end
end // init_eq_ram_coeff

reg signed [EQ_COEFF_WIDTH-1:0] eq_ram_coeff_A0_10[NR_EQ_COEFF-1:0];
/*============================================================================*/
initial begin : init_eq_ram_coeff_A0_10
/*============================================================================*/
    for ( i = 0; i < NR_EQ_COEFF; i = i + 1 ) begin
        eq_ram_coeff_A0_10[i] = 0;
        if (( i % NR_EQ_BAND_COEFF ) == 0 ) begin
            eq_ram_coeff_A0_10[i][EQ_COEFF_WIDTH-4] = 1; // Set every A0 parameter to 1.0 { in a range (-8.0, 8.0) }
        end
    end
end // init_eq_ram_coeff_A0_10

reg signed [EQ_COEFF_WIDTH-1:0] eq_ram_coeff_A0_15[NR_EQ_COEFF-1:0];
/*============================================================================*/
initial begin : init_eq_ram_coeff_A0_15
/*============================================================================*/
    for ( i = 0; i < NR_EQ_COEFF; i = i + 1 ) begin
        eq_ram_coeff_A0_15[i] = 0;
        if ( 0 == i ) begin
            eq_ram_coeff_A0_15[i][EQ_COEFF_WIDTH-5] = 1; // Set every A0 parameter to 1.5 { in a range (-8.0, 8.0) }
        end
        if ((i % NR_EQ_BAND_COEFF) == 0) begin
            eq_ram_coeff_A0_15[i][EQ_COEFF_WIDTH-4] = 1; // Set all other A0 parameter to 1.0 { in a range (-8.0, 8.0) }
        end
    end
end // init_eq_ram_coeff_A0_15

reg signed [EQ_COEFF_WIDTH-1:0] eq_ram_coeff_A0_05[NR_EQ_COEFF-1:0];
/*============================================================================*/
initial begin : init_eq_ram_coeff_A0_05
/*============================================================================*/
    for ( i = 0; i < NR_EQ_COEFF; i = i + 1 ) begin
        eq_ram_coeff_A0_05[i] = 0;
        if ( 0 == i ) begin
            eq_ram_coeff_A0_05[i][EQ_COEFF_WIDTH-5] = 1; // Set every A0 parameter to 0.5 { in a range (-8.0, 8.0) }
        end
        else if (( i % NR_EQ_BAND_COEFF ) == 0 ) begin
            eq_ram_coeff_A0_05[i][EQ_COEFF_WIDTH-4] = 1; // Set all other A0 parameter to 1.0 { in a range (-8.0, 8.0) }
        end
    end
end // init_eq_ram_coeff_A0_05

////////////////// Selection EQ coefficients ///////////////////////////////////
reg [EQ_COEFF_WIDTH-1:0] i_eq_coeff;
/*============================================================================*/
always @(posedge clk) begin : eq_coeff_access
/*============================================================================*/
    case ( eq_coeff_sel )
        2'b00 : begin
            i_eq_coeff <= eq_ram_coeff[eq_coeff_addr];
        end
        2'b01 : begin
            i_eq_coeff <= eq_ram_coeff_A0_10[eq_coeff_addr];
        end
        2'b10 : begin
            i_eq_coeff <= eq_ram_coeff_A0_15[eq_coeff_addr];
        end
        2'b11 : begin
            i_eq_coeff <= eq_ram_coeff_A0_05[eq_coeff_addr];
        end
    endcase
end // eq_coeff_access

assign eq_coeff = i_eq_coeff;

////////////////// Sine generator for NR_CHANNELS-1 channels ///////////////////
reg signed [INPUT_WIDTH-1:0] sg_d = 0;
reg signed [INPUT_WIDTH-1:0] sg_d_c;
reg [CHANNEL_WIDTH-1:0] sg_ch = 0;
reg sg_dv = 0;

localparam real MATH_2_PI = 2 * 3.14159265358979323846;
localparam integer SAMPLE_FREQUENCY = 48000;
localparam real MULTIPLIER = ( 2.0 ** ( INPUT_WIDTH - 1 )) - 1;
real step[NR_CHANNELS-1:0];
real sine_counter[NR_CHANNELS-1:0];
/*============================================================================*/
initial begin
/*============================================================================*/
    step[0] = MATH_2_PI * 1000 / SAMPLE_FREQUENCY;
    step[1] = MATH_2_PI * 4000 / SAMPLE_FREQUENCY;
    step[2] = MATH_2_PI * 16000 / SAMPLE_FREQUENCY;
    sine_counter[0] = 0;
    sine_counter[1] = 0;
    sine_counter[2] = 0;
end

/*============================================================================*/
always @(posedge clk) begin : sine_generator
/*============================================================================*/
    sg_dv <= sg_dv & ~s_eq_dr;
    if ( !sg_dv ) begin
        sg_d_c = MULTIPLIER * $sin( sine_counter[sg_ch] );
        sg_d <= $signed( sg_d_c );
        sine_counter[sg_ch] <= sine_counter[sg_ch] + step[sg_ch];
        sg_dv <= 1;
    end
    else if ( s_eq_dr ) begin
        sg_ch <= sg_ch + 1;
        if (( NR_CHANNELS - 1 ) == sg_ch ) begin
            sg_ch <= 0;
        end
    end
    if ( !rst_n ) begin
        sine_counter[0] <= 0;
        sine_counter[1] <= 0;
        sine_counter[2] <= 0;
        sg_d <= 0;
        sg_dv <= 0;
        sg_ch <= 0;
    end
end // sine_generator

assign s_eq_d = sg_d;
assign s_eq_ch = sg_ch;
assign s_eq_dv = sg_dv;

/*============================================================================*/
initial begin // Generate VCD file for GTKwave
/*============================================================================*/
`ifdef GTK_WAVE
    $dumpfile( "equalizer_tb.vcd" );
    $dumpvars( 0 );
`endif
end

endmodule
