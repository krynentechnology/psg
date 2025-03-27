echo off
:: make file for Icarus Verilog simulator
if not defined IVERILOG (
  set IVERILOG=%1
  set PATH=%PATH%;%1\bin
)
if not defined IVERILOG (
  echo Run batch file with path to Icarus Verilog simulator installed directory
  echo as first argument. "VCD" argument is optional afterwards for defining
  echo GTK_WAVE to generate VCD file. Other argument skips vvp execution.
  goto :END
)
if exist .\bin rmdir /Q/S bin
if not exist .\bin mkdir bin
cd .\bin
if "%1"=="" (
  iverilog.exe -o equalizer_tb.out -I .. ..\equalizer.v ..\equalizer_tb.sv
  iverilog.exe -o interpolator_tb.out -I .. ..\interpolator.v ..\interpolator_tb.sv
  iverilog.exe -o randomizer_tb.out -I .. ..\randomizer.v ..\randomizer_tb.sv
  iverilog.exe -o sine_wg_cor_tb.out -I .. ..\sine_wg_cor.v ..\sine_wg_cor_tb.sv
) else (
  if "%1"=="VCD" (
    iverilog.exe -DGTK_WAVE -o equalizer_tb.out -I .. ..\equalizer.v ..\equalizer_tb.sv
    iverilog.exe -DGTK_WAVE -o interpolator_tb.out -I .. ..\interpolator.v ..\interpolator_tb.sv
    iverilog.exe -DGTK_WAVE -o randomizer_tb.out -I .. ..\randomizer.v ..\randomizer_tb.sv
    iverilog.exe -DGTK_WAVE -o sine_wg_cor_tb.out -I .. ..\sine_wg_cor.v ..\sine_wg_cor_tb.sv
  ) else (
    iverilog.exe -I .. ..\equalizer.v ..\equalizer_tb.sv
    iverilog.exe -I .. ..\interpolator.v ..\interpolator_tb.sv
    iverilog.exe -I .. ..\randomizer.v ..\randomizer_tb.sv
    iverilog.exe -I .. ..\sine_wg_cor.v ..\sine_wg_cor_tb.sv
  )
)
if exist equalizer_tb.out vvp.exe equalizer_tb.out
if exist interpolator_tb.out vvp.exe interpolator_tb.out
if exist randomizer_tb.out vvp.exe randomizer_tb.out
if exist sine_wg_cor_tb.out vvp.exe sine_wg_cor_tb.out
cd ..
:END
