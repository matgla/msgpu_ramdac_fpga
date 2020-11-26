module fifo #(
    parameter DATA_WIDTH /*verilator public*/ = 8,
    parameter DATA_SIZE /*verilator public*/ = 4 
)(
    input clockin,
    input [DATA_WIDTH - 1:0] datain,
    output reg [DATA_WIDTH - 1:0] dataout,
    input datain_enable,
    input dataout_enable,
    input reset,
    output full,
    output empty
);

reg [DATA_WIDTH-1:0] writer_pointer;
reg [DATA_WIDTH-1:0] reader_pointer;

parameter MEMORY_DEPTH = 1 << DATA_WIDTH;
reg [DATA_WIDTH-1:0] memory [0:MEMORY_DEPTH-1];
reg [DATA_SIZE-1:0] size_counter;

assign empty = (size_counter == 0);
assign full = (size_counter == DATA_SIZE);

//--------------------//
//   writer pointer   //
//--------------------//
always @(posedge clockin or posedge reset) begin 
    if (reset) begin 
        writer_pointer <= 0;
    end else if (datain_enable && !full) begin 
        writer_pointer <= writer_pointer + 1;
    end
end

//--------------------//
//    read pointer    //
//--------------------//
always @(posedge clockin or posedge reset) begin 
    if (reset) begin 
        reader_pointer <= 0;
    end else if (dataout_enable && !empty) begin 
        reader_pointer <= reader_pointer + 1;
    end
end

//--------------------//
//     management     //
//--------------------//
always @(posedge clockin or posedge reset) begin 
    if (reset) begin 
        size_counter <= 0;
    end else if (datain_enable && !full) begin 
        memory[writer_pointer] <= datain;
        size_counter <= size_counter + 1;
    end else if (dataout_enable && !empty) begin 
        dataout <= memory[reader_pointer];
        size_counter <= size_counter - 1;
    end else if (dataout_enable && empty) begin 
        dataout <= 0;
    end
end

endmodule
