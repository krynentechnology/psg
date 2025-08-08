echo off
:: make file for Icarus Verilog simulator
if not "%1"=="" (
  if not defined IVERILOG (
    set IVERILOG=%1
    set PATH=%PATH%;%1\bin
  )
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
  iverilog.exe -o psg_tb.out -I .. -g2009 -c ..\psg_tb_files.txt ..\psg_tb.sv
) else (
  if "%1"=="VCD" (
    iverilog.exe -DGTK_WAVE -o psg_tb.out -I .. -g2009 -c ..\psg_tb_files.txt ..\psg_tb.sv
  ) else (
    iverilog.exe -I .. -g2009 -c ..\psg_tb_files.txt ..\psg_tb.sv
  )
)
if exist psg_tb.out vvp.exe psg_tb.out
cd ..
:END
