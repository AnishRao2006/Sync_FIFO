`timescale 1ns / 1ps
//simple testing of the ssd interface
module ssd_interface_tb();

localparam stop = 0;
localparam start = 1;

logic clk,reset;
logic [7:0] data_in;
logic [3:0] d_en;
logic [7:0] d_seg;

initial clk = 0;
always #5 clk = ~clk;

ssd_interface #(stop,start) inst1 (.*);

initial begin
reset = 1;data_in = 8'h00;
#10 reset = 0;
//stimulus
data_in = 8'hef;

#100;
$finish;
end

endmodule
