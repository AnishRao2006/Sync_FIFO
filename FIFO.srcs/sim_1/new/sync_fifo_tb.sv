`timescale 1ns / 1ps
//interface
interface fifo_if#(
    parameter data_width = 8,
    parameter depth = 8,
    parameter addr_width = $clog2(depth)
)(
    input logic clk
);
    
logic reset;
// Write
logic [data_width-1:0] wr_data;
logic wr_en;
logic full;
// Read
logic [data_width-1:0] rd_data;
logic rd_en;
logic empty_flag;

clocking driver_cb @(posedge clk);
default input #1ns output #1ns;
input full,empty_flag;
output wr_en,rd_en,reset,wr_data;
endclocking

clocking monitor_cb @(posedge clk);
default input #1ns output #1ns;
input rd_data,wr_data,rd_en,wr_en,empty_flag;
endclocking

modport driver (clocking driver_cb,input clk);
modport monitor (clocking monitor_cb,input clk);
    
endinterface : fifo_if
//transaction
class transaction#(
    parameter data_width = 8,
    parameter depth = 8
    );
 
rand logic [data_width-1:0] wr_data;
logic [data_width-1:0] rd_data;
rand logic wr_en;
rand logic rd_en;
logic [data_width-1:0] expected_data;

constraint data {wr_data > 80 && wr_data <= 255;}
constraint op_constraint {wr_en != rd_en; wr_en dist {1:=70,0:=30}; rd_en dist {1:=70,0:=30};}

endclass : transaction  
//reference model
class fifo_reference#(
    parameter data_width = 8,
    parameter depth = 8
    );
 //queue for fifo mimic   
logic [data_width-1:0] mem [$];
//write
function bit write(input logic [data_width-1:0] data);
if(mem.size() < depth) begin
mem.push_back(data);
return 1;
end
else begin
return 0;
end
endfunction
//read
function logic [data_width-1:0] read();
logic [data_width-1:0] data = 0;
if(mem.size != 0) begin
data = mem.pop_front();
end
return data;
endfunction
//size
function logic [data_width-1:0] size();
return mem.size();
endfunction

endclass :  fifo_reference  
//generator
class generator#(
    parameter data_width = 8,
    parameter depth = 8
    );
    
mailbox #(transaction) gen2drive;
int count;
transaction tr;

function new(mailbox #(transaction) gen2drive,int count);
this.gen2drive = gen2drive;
this.count = count;
endfunction
    
task run();
repeat(count) begin
tr = new();
tr.randomize();
gen2drive.put(tr);
end
gen2drive.put(null);
endtask

endclass : generator 
//driver
class driver#(
    parameter data_width = 8,
    parameter depth = 8,
    parameter addr_width = $clog2(depth) 
    );
    
mailbox #(transaction) gen2drive;
transaction tr;
virtual fifo_if #(data_width,depth,addr_width) in;
fifo_reference #(data_width,depth) ref_model;

function new(mailbox #(transaction) gen2drive,virtual fifo_if #(data_width,depth,addr_width) in,fifo_reference #(data_width,depth) ref_model);
this.gen2drive = gen2drive;
this.in = in;
this.ref_model = ref_model;
endfunction

task run();
forever begin
gen2drive.get(tr);
if(tr == null) break;
@(in.driver_cb);
if(tr.wr_en && (ref_model.size() >= 0 && ref_model.size() < depth)) begin
in.driver_cb.wr_en <= 1'b1;
in.driver_cb.wr_data <= tr.wr_data;
ref_model.write(tr.wr_data);
@(in.driver_cb);
in.driver_cb.wr_en <= 1'b0;
end
else if(ref_model.size() == depth) begin
@(in.driver_cb);
in.driver_cb.rd_en <= 1'b1;
@(in.driver_cb);
in.driver_cb.rd_en <= 1'b0;
end
else begin
@(in.driver_cb);
in.driver_cb.rd_en <= 1'b0;
in.driver_cb.wr_en <= 1'b0;
end
end
endtask
    
endclass : driver  
//monitor
class monitor#(
    parameter data_width = 8,
    parameter depth = 8,
    parameter addr_width = $clog2(depth)
    );
    
mailbox #(transaction) mon2scoreboard;
virtual fifo_if #(data_width,depth,addr_width) in;
transaction tr;
fifo_reference #(data_width,depth) ref_model;
logic [data_width-1:0] expected_data = 0;

function new(mailbox #(transaction) mon2scoreboard,virtual fifo_if #(data_width,depth,addr_width) in,fifo_reference #(data_width,depth) ref_model);
this.mon2scoreboard = mon2scoreboard;
this.in = in;
this.ref_model = ref_model;
endfunction

task run();
tr = new();
forever begin
@(in.monitor_cb);
if(in.monitor_cb.rd_en && !in.monitor_cb.empty_flag) begin
tr.expected_data = ref_model.read();
@(in.monitor_cb);
tr.rd_data = in.monitor_cb.rd_data;
mon2scoreboard.put(tr);
end  
end
endtask
    
endclass : monitor    
//scoreboard
class scoreboard#(
    parameter data_width = 8,
    parameter depth = 8
    );
    
mailbox #(transaction) mon2scoreboard;
transaction tr;

function new(mailbox #(transaction) mon2scoreboard);
this.mon2scoreboard = mon2scoreboard;
endfunction

task run();
forever begin
mon2scoreboard.get(tr);
compare_value(tr);
end
endtask  

function void compare_value(transaction tr);
if(tr.rd_data == tr.expected_data) begin
$display("test pass rd_data = %0d, queue = %0d",tr.rd_data,tr.expected_data);
end
else begin
$display("test fail rd_data = %0d, queue = %0d",tr.rd_data,tr.expected_data);
end
endfunction  
    
endclass : scoreboard   
//coverage
class coverage#(
    parameter data_width = 8,
    parameter depth = 8
    );
    
virtual fifo_if in;

covergroup cg_fifo;
mode_full : coverpoint in.full{
    bins full0 = {0};
    bins full1 = {1};
    }
mode_wr_en : coverpoint in.wr_en{
    bins write0 = {0};
    bins write1 = {1};
    }
mode_rd_en : coverpoint in.rd_en{
    bins read0 = {0};
    bins read1 = {1};
    }        
mode_empty : coverpoint in.empty_flag{
    bins empty0 = {0};
    bins empty1 = {1};
    }
endgroup

function new(virtual fifo_if in);
this.in = in;
cg_fifo = new();
endfunction

task run();
forever begin
@(in.monitor_cb);
start_sample();
end
endtask

function void start_sample();
cg_fifo.sample();
endfunction

function real get_sample();
return cg_fifo.get_inst_coverage();
endfunction                 
    
endclass : coverage 
//environment 
class environment#(
    parameter data_width = 8,
    parameter depth = 8,
    parameter addr_width = $clog2(depth)
    );
    
generator #(data_width,depth) gen;
driver #(data_width,depth,addr_width) drive;
monitor #(data_width,depth,addr_width) mon;
scoreboard #(data_width,depth) score;
coverage #(data_width,depth) cov;
fifo_reference #(data_width,depth) ref_model;
localparam count = 40;

virtual fifo_if #(data_width,depth,addr_width) in;  

mailbox #(transaction) gen2drive;
mailbox #(transaction) mon2scoreboard;

function new(virtual fifo_if in);
this.in = in;
gen2drive = new();
mon2scoreboard = new();
ref_model = new();

gen = new(gen2drive,count); 
drive = new(gen2drive,in,ref_model);  
mon = new(mon2scoreboard,in,ref_model);
score = new(mon2scoreboard);
cov = new(in);
endfunction

task test();
fork
gen.run();
drive.run();
mon.run();
score.run();
cov.run();
join_any
endtask 

task run();
test();
wait(gen2drive.num() == 0);
#30;
$display("coverage = %0.2f%%",cov.get_sample());
#30;
$finish;
endtask
    
endclass : environment    
//top testbench module
module sync_fifo_tb();

localparam data_width = 8;
localparam depth = 8;
localparam addr_width = $clog2(depth);

logic clk;
initial clk = 0;
always #5 clk = ~clk;

environment #(data_width,depth,addr_width) env;

fifo_if #(data_width,depth,addr_width) in (.clk(clk));
//DUT
fifo_sync #(data_width,depth,addr_width) inst1 (.clk(clk),
                                                .reset(in.reset),
                                                .wr_en(in.wr_en),
                                                .rd_en(in.rd_en),
                                                .wr_data(in.wr_data),
                                                .rd_data(in.rd_data),
                                                .full(in.full),
                                                .empty(in.empty_flag)
                                                );

initial begin
in.reset = 1;
#10 in.reset = 0;

env = new(in);

env.run();
end

endmodule

