`timescale 1ns / 1ps

module ssd_interface#(
    parameter stop = 1,
    parameter start = 0
    )(
    input logic clk,reset,
    //data input from the rd_data 
    input logic [7:0] data_in,
    //outputs
    output logic [3:0] d_en,
    output logic [7:0] d_seg
    ); 
//internal signals        
logic [3:0] lower_bits;
logic [3:0] upper_bits;
wire clk_out;
reg [3:0] bit_select;
logic [$clog2(stop):0] internal_counter;
//bit slicing
assign lower_bits = data_in[3:0];
assign upper_bits = data_in[7:4];
//function for decoding value
function logic [7:0] decode_value(input logic [3:0] data);
logic [7:0] data_out;
unique case(data)
4'b0000 : data_out = 8'b1100_0000;
4'b0001 : data_out = 8'b1111_1001;
4'b0010 : data_out = 8'b1010_0100;
4'b0011 : data_out = 8'b1011_0000;
4'b0100 : data_out = 8'b1001_1001;
4'b0101 : data_out = 8'b1001_0010;
4'b0110 : data_out = 8'b1000_0010;
4'b0111 : data_out = 8'b1111_1000;
4'b1000 : data_out = 8'b1000_0000;
4'b1001 : data_out = 8'b1001_1000;
4'b1010 : data_out = 8'b1000_1000;
4'b1011 : data_out = 8'b1000_0011;
4'b1100 : data_out = 8'b1100_0110;
4'b1101 : data_out = 8'b1010_0001;
4'b1110 : data_out = 8'b1000_0110;
4'b1111 : data_out = 8'b1000_1110;
default : data_out = 8'b0000_0000;
endcase
return data_out;
endfunction

always_comb begin
case(internal_counter) 
0 : begin
d_en = 4'b1110;
bit_select = lower_bits;
end
1 : begin
d_en = 4'b1101;
bit_select = upper_bits;
end
default : begin
d_en = 4'b1111;
bit_select = 0;
end
endcase
d_seg = decode_value(bit_select);
end

//counter for the ssd
counter_with_clk #(.stop(stop),.start(start)) counter (.clk(clk_out),
                                                       .reset(reset),
                                                       .count_value(internal_counter),
                                                       .done_tick(),
                                                       .clk_out()
                                                       ); 

//counter for the producing lower clk freq (100Hz)
counter_with_clk #(.stop(499999),.start(0)) freq (.clk(clk),
                                                    .reset(reset),
                                                    .count_value(),
                                                    .done_tick(),
                                                    .clk_out(clk_out)
                                                    );                                                        
    
endmodule
