`ifndef FIFO 
`define FIFO

interface FifoInput #(
    parameter BUS_WIDTH = 12 
)(); 
    logic clock; 
    logic[BUS_WIDTH - 1:0] data;

endinterface

interface FifoOutput #(
    parameter BUS_WIDTH = 12 
)();
    logic clock; 
    logic[BUS_WIDTH - 1:0] data;
    logic full;
    logic empty; 

endinterface

module Fifo #(
    parameter BUS_WIDTH = 12, 
    parameter ADDRESS_WIDTH = 64 
)(
    FifoInput in, 
    FifoOutput out
);

parameter MEMORY_DEPTH = 1 << ADDRESS_WIDTH;
logic[BUS_WIDTH - 1:0] memory[MEMORY_DEPTH];

logic[ADDRESS_WIDTH-1:0] write_pointer = ~0;
logic[ADDRESS_WIDTH-1:0] read_pointer = ~0;

assign out.empty = write_pointer == read_pointer; 
assign out.full = write_pointer + 1'b1 == read_pointer;

always @(posedge in.clock) begin 
    if (!out.full) begin  
        write_pointer = write_pointer + 1'b1;
        memory[write_pointer] <= in.data;
    end
end

always @(posedge out.clock) begin
    if (!out.empty) begin 
        read_pointer = read_pointer + 1'b1;
        out.data <= memory[read_pointer];
    end else begin 
        out.data <= 0;
    end
end

endmodule
    
`endif

