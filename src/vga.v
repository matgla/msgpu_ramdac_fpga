/* for now only 640x480@60 is supported */

/* for 640x480@60 polarity is: 
* vsync: negative 
* hsync: negative 
*/

module vga(
    input reset,
    input clock,
    input enable, 
    output hsync,
    output vsync,
    output wire[3:0] red, 
    output wire[3:0] green,
    output wire[3:0] blue,
    input buffer_clock,
    output reg[21:0] read_address,
    input wire[11:0] pixel_data
);

reg [9:0] hsync_counter;
reg [9:0] vsync_counter;

localparam HSYNC_WHOLE_LINE = 800;
localparam HSYNC_FRONT_PORCH = 16;
localparam HSYNC_VISIBLE_AREA = 640;
localparam HSYNC_PULSE = 96;
localparam HSYNC_BACK_PORCH = 48;

localparam VSYNC_VISIBLE_AREA = 480;
localparam VSYNC_FRONT_PORCH = 10;
localparam VSYNC_SYNC_PULSE = 2;
localparam VSYNC_BACK_PORCH = 33;
localparam VSYNC_WHOLE_FRAME = 525;

wire almost_line_end = (hsync_counter == HSYNC_VISIBLE_AREA + 1);
wire line_end = (hsync_counter == HSYNC_WHOLE_LINE - 1);
wire hsync_pulse = (hsync_counter >= (HSYNC_VISIBLE_AREA + HSYNC_FRONT_PORCH - 1) 
    && (hsync_counter < (HSYNC_WHOLE_LINE - HSYNC_BACK_PORCH) - 1));

wire frame_end = (vsync_counter == VSYNC_WHOLE_FRAME - 1);// && line_end;
wire almost_frame_end = (vsync_counter == VSYNC_WHOLE_FRAME - 2) && (hsync_counter == HSYNC_WHOLE_LINE - 1);
wire vsync_pulse = (vsync_counter >= (VSYNC_VISIBLE_AREA + VSYNC_FRONT_PORCH - 1)
    && (vsync_counter < (VSYNC_WHOLE_FRAME - VSYNC_BACK_PORCH) - 1));
assign hsync = ~hsync_pulse;
assign vsync = ~vsync_pulse;
wire visible_area = (hsync_counter < HSYNC_VISIBLE_AREA) 
    && (vsync_counter < VSYNC_VISIBLE_AREA);


reg[11:0] line_buffer[2**10-1:0];
reg[9:0] copied;
reg is_first;

reg [1:0] almost_line_end_buffer;
always @(posedge buffer_clock) almost_line_end_buffer <= {almost_line_end_buffer[0], almost_line_end};
wire almost_line_end_posedge = almost_line_end_buffer == 2'b01;

reg [1:0] almost_frame_end_buffer;
always @(posedge buffer_clock) almost_frame_end_buffer <= {almost_frame_end_buffer[0], almost_frame_end};
wire almost_frame_end_posedge = almost_frame_end_buffer == 2'b01;

always @(posedge buffer_clock or posedge reset) begin 
    if (reset) begin 
        copied <= 0;
        is_first <= 1;
        read_address <= 0;
    end
    if (copied < 640 && !almost_line_end && !almost_frame_end) begin 
        read_address <= read_address + 1;
        if (!is_first) begin   
            copied <= copied + 1;
            line_buffer[copied] <= pixel_data;
        end
        is_first <= 0;
    end

    if (almost_line_end_posedge) begin 
        //copied <= 0;
        is_first <= 1;
        //read_address <= read_address - 1;
    end
    if (almost_frame_end_posedge) begin 
        $display("VSYNC reset");
        //read_address <= 0;
        //copied <= 0;
        is_first <= 1;
    end
end


assign red = visible_area ? line_buffer[hsync_counter][11:8] : 0;
assign green = visible_area ? line_buffer[hsync_counter][7:4] : 0;
assign blue = visible_area ? line_buffer[hsync_counter][3:0] : 0;

always @(posedge clock) begin 
    if (vsync_counter == 0 && hsync_counter < 10 && enable) $display("Read address: %d -> %x" , read_address, line_buffer[hsync_counter]);
end

always @(posedge clock) begin 
    if (frame_end) begin 
        vsync_counter <= 0;
    end
    else if (line_end) vsync_counter <= vsync_counter + 1;
end

always @(posedge clock) begin 
    if (enable) hsync_counter <= hsync_counter + 1;
    if (line_end) begin 
        hsync_counter <= 0;
    end
end

//always @(posedge clock) begin 
//    if (enable && hsync_counter < 5 && vsync_counter == 0) $display("Hsync %d: %x%x%x", hsync_counter, red, green, blue);
//end

endmodule
