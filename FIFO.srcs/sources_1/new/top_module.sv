`timescale 1ns / 1ps
//top module of the entire system
module top_module#(
    parameter stop = 1,
    parameter start = 0,
    parameter data_width = 8,
    parameter depth = 8,
    parameter addr_width = $clog2(depth)
    )(
    input logic clk,reset,
    input logic wr_en,rd_en,
    output logic full,empty,
    output logic [3:0] d_en,
    output logic [7:0] d_seg,
    input logic [data_width-1:0] wr_data
    );
//rd_data and data_in wire   
logic [7:0] data_out;
//fifo
fifo_sync #(.data_width(data_width),.depth(depth),.addr_width(addr_width)) inst1 (.*,.rd_data(data_out));
//ssd_interface
ssd_interface #(.stop(stop),.start(start)) inst2 (.*,.data_in(data_out));  
    
endmodule
