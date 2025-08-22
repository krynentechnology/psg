@echo off
:: make file for Yosys/OSS/Verilator delvelopment suite
if not [%1]==[] (
  if not defined VERILATOR_INCLUDE (
    set VERILATOR_INCLUDE=%1
  )
  if not defined VERILATOR_ROOT (
    set VERILATOR_ROOT=%1\yosyshq\share\verilator
    set PATH=%PATH%;%1\yosyshq\bin;%1\yosyshq\lib
  )
)
if not defined VERILATOR_ROOT (
  echo Run batch file with path to YosysHQ or OSS CAD Suite installed directory
  echo as first argument. If this dirctory holds the folder 'oss-cad-suite',
  echo rename this 'oss-cad-suite' folder to 'yosyshq'. The PATH environment
  echo variable should include a GNU GCC distrubution, 'make.exe' for windows,
  echo Python3 and perl.
  goto :END
)
echo PSG simulation started %time%
verilator_bin.exe -F verilator.arg psg_tb.cpp
make -j -C obj_dir -f Vpsg.mk
if exist obj_dir\psg_tb.exe obj_dir\psg_tb.exe
echo PSG simulation finished %time%
:END
