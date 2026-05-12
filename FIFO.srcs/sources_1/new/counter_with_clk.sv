`timescale 1ns / 1ps

module counter_with_clk#(
    parameter stop = 3,
    parameter start = 0
    )(
    input logic clk,reset,
    output logic [$clog2(stop)-1:0] count_value,
    output logic done_tick,
    output logic clk_out
    );
    
reg [$clog2(stop)-1:0] count_value_i;
    
always_ff @(posedge clk or posedge reset) begin
if(reset) begin
clk_out <= 0;
count_value_i <= 0;
done_tick <= 0;
end
else begin
count_value_i <= count_value_i + 1;
if(count_value_i == stop) begin
done_tick = 1'b1;
clk_out <= ~clk_out;
end
end
end   

always_ff @(posedge clk) begin
count_value <= count_value_i;
end
    
endmodule
