`include "vga_commands.v"

module vga_screen(
    input vga_clock, 
    wire [2:0] command, 
    output reg enable_vga_fifo,
    output reg clear_command,
    wire [11:0] vga_data
);

reg [2:0] state; 

localparam STATE_IDLE = 3'd0;
localparam STATE_START_FIFO = 3'd1;
localparam STATE_DISPLAY = 3'd2;

always @(posedge vga_clock) begin 
    case (state)
        STATE_IDLE: begin 
            clear_command <= 0;
            if (command == `VGA_PREPARE) begin 
                $display("Starting FIFO");
                state <= STATE_START_FIFO;
            end
        end
        STATE_START_FIFO: begin 
            $display("Enabling VGA fifo");
            enable_vga_fifo <= 1;
            state <= STATE_DISPLAY;
            clear_command <= 1;
        end 
        STATE_DISPLAY: begin 
            $display("Display %x", vga_data);
        end
        default: begin 
            state <= STATE_IDLE;
        end 
    endcase
end

endmodule 
