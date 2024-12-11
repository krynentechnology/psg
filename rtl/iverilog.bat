echo off
:: make file for Icarus Verilog simulator
if not defined IVERILOG (
  set IVERILOG=%1
  set ADD_IVERILOG_PATH=Y
)
if not defined IVERILOG (
  echo Run batch file with path to Icarus Verilog simulator installed directory
  echo as first argument. "VCD" argument is optional afterwards for defining
  echo GTK_WAVE to generate VCD file. Other argument skips vvp execution.
  goto :END
)
if %ADD_IVERILOG_PATH%==Y set PATH=%PATH%;%IVERILOG%\bin
set ADD_IVERILOG_PATH=N
if exist .\bin rmdir /Q/S bin
if not exist .\bin mkdir bin
cd .\bin
if "%1"=="" (
  iverilog -o psg_tb.out -I .. -g2009 -c ..\psg_tb_files.txt ..\psg_tb.sv
) else (
  if "%1"=="VCD" (
    iverilog -DGTK_WAVE -o psg_tb.out -I .. -g2009 -c ..\psg_tb_files.txt ..\psg_tb.sv
  ) else (
    iverilog -I .. -g2009 -c ..\psg_tb_files.txt ..\psg_tb.sv
  )
)
if exist psg_tb.out vvp psg_tb.out
cd ..
:END
