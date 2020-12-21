module message_broker(
    input system_clock, 
    input mcu_bus_clock, 
    inout[7:0] mcu_bus,
    input mcu_bus_command_data, 
    output reg mcu_pixel_clock,
    output mcu_command_clock,
    output[11:0] pixel_data 
);

reg[31:0] mcu_address;
reg[7:0] mcu_data; 
reg mcu_data_clock;

mcu_bus mcu(
    .sysclk(system_clock),
    .busclk(mcu_bus_clock),
    .bus_in(mcu_bus[7:0]),
    .bus_out(mcu_bus[7:0]),
    .dataclk(mcu_data_clock),
    .cmdclk(mcu_command_clock),
    .address(mcu_address),
    .command_data(mcu_bus_command_data),
    .data_out(mcu_data)
);

localparam STATE_RECEIVE_FIRST_PART = 0;
localparam STATE_RECEIVE_SECOND_PART = 1; 

reg[2:0] state;
always @(posedge mcu_data_clock) begin 
    mcu_pixel_clock <= 0; 
    case (state) 
        STATE_RECEIVE_FIRST_PART: begin 
            pixel_data[11:4] <= mcu_data; 
            state <= STATE_RECEIVE_SECOND_PART;
        end
        STATE_RECEIVE_SECOND_PART: begin 
            pixel_data[3:0] <= mcu_data[3:0];
            state <= STATE_RECEIVE_FIRST_PART;
            mcu_pixel_clock <= 1;
        end
    endcase
end

always @(posedge mcu_data_clock) begin 
    if (mcu_data_clock == 0) begin 
        $display("GOT address: %x", mcu_address);
    end
end

endmodule
