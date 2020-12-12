module dual_port_ram #(
    parameter DATA_WIDTH = 12,
    parameter ADDRESS_SIZE = 13
)(
    input [11:0] data,
    input [ADDRESS_SIZE-1:0] read_address,
    input [ADDRESS_SIZE-1:0] write_address,
    input write_enable,
    input read_clock,
    input write_clock,
    output reg [DATA_WIDTH-1:0] output_data
);

reg [DATA_WIDTH-1:0] memory [2**ADDRESS_SIZE-1:0];

always @(posedge write_clock) begin
    if (write_enable) begin
        memory[write_address] <= data;
    end
end

always @(posedge read_clock) begin
    output_data <= memory[read_address];
end



endmodule
