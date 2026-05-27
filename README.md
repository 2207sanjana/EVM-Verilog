# Electronic Voting Machine (EVM) using Verilog

A hardware-level implementation of an Electronic Voting Machine using Verilog HDL on an FPGA platform.

## Overview
Designed and simulated a fully functional EVM with voting, vote counting, and result display logic using Verilog hardware description language.

## Features
- Voter input via push buttons
- Vote counting logic per candidate
- Result display on 7-segment display
- Reset and lock mechanism to prevent double voting

## Tools & platform
- Verilog HDL
- Xilinx Vivado (simulation & synthesis)
- FPGA development board

## How it works
1. Each button corresponds to a candidate
2. On button press, the vote register for that candidate increments
3. After the voting period, results are displayed on the 7-segment output
4. A lock signal disables further input once voting closes

## Technologies
`Verilog HDL` `FPGA` `Vivado` `Digital logic design` `Hardware description`

## Status
Source files being re-uploaded. Simulation screenshots coming soon.# EVM-Verilog
