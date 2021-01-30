`include "fifo.sv"

module fifo_for_test(
    input write_clock, 
    input read_clock,
    input[11:0] input_data, 
    output[11:0] output_data
); 

FifoInput #(.BUS_WIDTH(12)) 
    fifo_in(); 
FifoOutput #(.BUS_WIDTH(12))
    fifo_out(); 

assign fifo_in.data = input_data; 
assign fifo_in.clock = write_clock; 

assign fifo_out.clock = read_clock;
assign output_data = fifo_out.data;

Fifo #(
    .BUS_WIDTH(12),
    .ADDRESS_WIDTH(2)
) 
test_fifo(
    .in(fifo_in),
    .out(fifo_out)
);


endmodule
