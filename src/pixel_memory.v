module pixel_memory(
    input system_clock,
    input[11:0] pixel_data, 
    input pixel_clock, 
    input[21:0] framebuffer_read_pointer,
    input[21:0] write_address,
    input set_write_address,
    output[11:0] read_data
);

reg[21:0] framebuffer_write_pointer;
reg framebuffer_write_enable;

dual_port_ram #(.DATA_WIDTH(12), .ADDRESS_SIZE(22))
ram_buffer(
   .data(pixel_data),
   .read_address(framebuffer_read_pointer),
   .write_address(framebuffer_write_pointer),
   .write_enable(framebuffer_write_enable),
   .write_clock(system_clock),
   .read_clock(system_clock),
   .output_data(read_data)
);

reg[2:0] pixel_received;

always @(posedge system_clock) begin 
    pixel_received <= {pixel_received[1:0], pixel_clock};
end
wire pixel_posedge = pixel_received[1:0] == 2'b01;

localparam RECEIVER_STATE_IDLE = 0;
localparam RECEIVED_PIXEL = 1;
localparam INCREMENT_POINTER = 2;

reg[2:0] receiver_state;
always @(posedge system_clock) begin
    case (receiver_state) 
        RECEIVER_STATE_IDLE: begin 
            if (pixel_posedge) begin 
                receiver_state <= RECEIVED_PIXEL; 
            end
        end
        RECEIVED_PIXEL: begin 
            receiver_state <= INCREMENT_POINTER;
            framebuffer_write_enable <= 1'b1;
        end
        INCREMENT_POINTER: begin
            framebuffer_write_pointer <= framebuffer_write_pointer + 1;
            receiver_state <= RECEIVER_STATE_IDLE;
        end
        default: begin 
            receiver_state <= RECEIVER_STATE_IDLE;
        end
    endcase
end

always @(posedge system_clock) begin
    framebuffer_write_enable <= 1'b0;
end



endmodule
