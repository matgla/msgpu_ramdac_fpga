/* This module generates VGA signal and puts data from line buffer */ 

module vga (
    input enable,
    input clock,
    output reg[12:0] address,
    input[11:0] data,
    output hsync,
    output vsync,
    output reg[3:0] red,
    output reg[3:0] green,
    output reg[3:0] blue,
    output wire visible_area,
    output wire almost_visible_area,
    output reg line_finished
);

reg prepare_for_display;

reg enable_buffer;

vga_sync sync(
    .clock(clock),
    .enable(enable_buffer),
    .hsync(hsync),
    .vsync(vsync),
    .visible_area(visible_area)
);

reg is_first_line;

reg [3:0] state;
localparam STATE_FIRST_LINE = 0;
localparam STATE_SECOND_LINE = 1;

reg [2:0] hsync_buffer;
always @(posedge clock) hsync_buffer <= {hsync_buffer[1:0], hsync};
wire hsync_falling = (hsync_buffer[2:1] == 2'b10);

always @(posedge clock) begin 
    // this must be triggered one tick before real start
    if (enable) enable_buffer <= 1;
    else enable_buffer <= 0;

    /*if (prepare_for_display) begin 
        $display("Prepare");
        red <= data[11:8];
        green <= data[7:4];
        blue <= data[3:0];

        address <= address + 1;
    end*/
    if (visible_area && enable) begin 
        address <= address + 1;
        red <= data[11:8];
        green <= data[7:4];
        blue <= data[3:0];
    end
    line_finished <= 0;
    if (hsync_falling) begin 
        line_finished <= 1;
    end
    case (state)
        STATE_FIRST_LINE: begin
            if (hsync_falling) begin 
                address <= address - 1;
                state <= STATE_SECOND_LINE;
            end
        end
        STATE_SECOND_LINE: begin 
            if (hsync_falling) begin 
                address <= 0;
                state <= STATE_FIRST_LINE; 
            end
        end
    endcase
end

endmodule

`resetall
