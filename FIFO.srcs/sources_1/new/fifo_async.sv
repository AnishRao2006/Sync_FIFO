`timescale 1ns / 1ps

module fifo_async#(
    parameter data_width = 8,
    parameter depth = 8
    )(
    input logic reset,
    input logic clk,
    //write
    input logic [data_width-1:0] wr_data,
    input logic wr_en,
    output logic full,
    //read
    output logic [data_width-1:0] rd_data,
    input logic rd_en,
    output logic empty,
    //state output
    output logic level
    );
    
reg [data_width-1:0] PROGMEM [0:depth-1];

typedef enum {
    EMPTY,
    DATA,
    FULL
    }state_type;
    
state_type state_reg,state_next;    

logic [$clog2(depth)-1:0] wr_ptr,rd_ptr;
logic [$clog2(depth)-1:0] count;

always_ff @(posedge clk or posedge reset) begin
if(reset) begin
wr_ptr <= 0;
rd_ptr <= 0;
end
else begin
if(wr_en && ~full) begin
PROGMEM[wr_ptr] <= wr_data;
wr_ptr += 1;
count += 1;
end
else if(rd_en && ~empty) begin
rd_data <= PROGMEM[rd_ptr];
rd_ptr += 1;
count -= 1;
end
end
end

assign level = count;
assign full = (count == depth);
assign empty = (count == 0);
    
endmodule
