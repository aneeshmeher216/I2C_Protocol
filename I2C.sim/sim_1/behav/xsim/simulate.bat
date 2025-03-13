@echo off
REM ****************************************************************************
REM Vivado (TM) v2019.1 (64-bit)
REM
REM Filename    : simulate.bat
REM Simulator   : Xilinx Vivado Simulator
REM Description : Script for simulating the design by launching the simulator
REM
REM Generated by Vivado on Thu Mar 13 16:19:28 +0530 2025
REM SW Build 2552052 on Fri May 24 14:49:42 MDT 2019
REM
REM Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
REM
REM usage: simulate.bat
REM
REM ****************************************************************************
echo "xsim i2c_tb_behav -key {Behavioral:sim_1:Functional:i2c_tb} -tclbatch i2c_tb.tcl -view E:/Electronics/Vivado/I2C/i2c_tb_behav.wcfg -log simulate.log"
call xsim  i2c_tb_behav -key {Behavioral:sim_1:Functional:i2c_tb} -tclbatch i2c_tb.tcl -view E:/Electronics/Vivado/I2C/i2c_tb_behav.wcfg -log simulate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
