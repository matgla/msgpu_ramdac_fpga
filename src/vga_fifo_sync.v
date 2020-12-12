module vga_fifo_sync(
    input reset,
    input system_clock,
    input is_fifo_full, 
    output reg fifo_write_enable,
    output reg[13:0] framebuffer_read_pointer
);

localparam STATE_INIT = 3'd0;
localparam STATE_START_READING = 3'd1;
localparam STATE_WAIT_FOR_FIFO_RELEASE= 3'd2;
localparam STATE_READING = 3'd3;

reg[3:0] state; 
reg[3:0] next_state;

always @(posedge system_clock or posedge reset) begin 
    if (reset) begin 
        $display("Resetting fifo sync");
        state <= STATE_INIT;
    end else begin 
        state <= next_state;
    end
end

always @(posedge system_clock) begin 
    case (state)
        STATE_INIT: begin 
            $display("Start frame sync");
            next_state = STATE_START_READING;
            fifo_write_enable <= 0; 
            framebuffer_read_pointer <= 0; 
        end 
        STATE_START_READING: begin 
            if (!is_fifo_full) begin
                next_state = STATE_READING;
            end else begin 
                next_state = STATE_WAIT_FOR_FIFO_RELEASE;
            end
        end
        STATE_READING: begin 
            fifo_write_enable <= 1;
            if (is_fifo_full) begin
                next_state = STATE_WAIT_FOR_FIFO_RELEASE;
                fifo_write_enable <= 0;
            end else begin 
                framebuffer_read_pointer <= framebuffer_read_pointer + 1;
            end
        end
        STATE_WAIT_FOR_FIFO_RELEASE:
            if (!is_fifo_full) begin 
                next_state = STATE_START_READING;
            end
        default: begin 
            $display("REESEEET");
            next_state = STATE_INIT; 
        end
    endcase
end

endmodule
