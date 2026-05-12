`timescale 1ns / 1ps
//sync fifo
module fifo_sync#(
    parameter data_width = 8,
    parameter depth = 8,
    parameter addr_width = $clog2(depth)
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
    output logic empty
    );
    
//internal counter for decreasing the rate of read/write (1 sec)
wire clk_out;
counter_with_clk #(.stop(49999999),.start(0)) freq (.clk(clk),
                                                    .reset(reset),
                                                    .count_value(),
                                                    .done_tick(),
                                                    .clk_out(clk_out)
                                                    );    

//internal memory    
reg [data_width-1:0] PROGMEM [0:depth-1];
   
//internal pointers
logic [addr_width:0] wr_ptr,rd_ptr;

//fifo logic
always_ff @(posedge clk_out or posedge reset) begin
if(reset) begin
wr_ptr <= 0;
rd_ptr <= 0;
end
else begin
if(wr_en && ~full) begin
PROGMEM[wr_ptr[addr_width-1:0]] <= wr_data;
wr_ptr += 1;
end
else if(rd_en && ~empty) begin
rd_data <= PROGMEM[rd_ptr[addr_width-1:0]];
rd_ptr += 1;
end
end
end

//output logic
assign empty = (wr_ptr == rd_ptr);
assign full = ((wr_ptr[addr_width] != rd_ptr[addr_width]) & (wr_ptr[addr_width-1:0] == rd_ptr[addr_width-1:0]));
    
endmodule
