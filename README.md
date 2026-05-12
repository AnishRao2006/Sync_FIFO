# Synchronous FIFO

**Date:** May 2026  
**Board:** Spartan7
**Vivado Version:** 2025.1

## Description
This project implements a Synchronous FIFO (First-In-First-Out) buffer
designed for high-speed data intergrity in FPGA-based digital systems.
Operating on a single clock domain, this module serves as a reliable 
intermediate storage element to manage data flow between logic blocks.

## Files
- `top_module.sv` - Top level 
- `fifo_sync.sv` - Parameterized FIFO
- `ss_interface.sv` - Used for interfacing the seven-segment display  
- `top_module.xdc` - Pin mappings
- `sync_fifo_tb.sv` - UVM lite SV based testbench

## How to run
1. Clone repo
2. Open `FIFO.xpr` in Vivado
3. Generate bitstream
4. Program FPGA

## Status
✅ Working: Waveform Verified and Implemented on Spartan7 FPGA  

## Notes
- Clock frequency: 100 MHz
- Uses active-high reset
