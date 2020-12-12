/* for now only 640x480@60 is supported */

/* for 640x480@60 polarity is: 
* vsync: negative 
* hsync: negative 
*/

module vga_sync(
    input clock,
    input enable, 
    output hsync,
    output vsync,
    output wire visible_area
);

reg [15:0] hsync_counter;
reg [15:0] vsync_counter;

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

wire line_end = (hsync_counter == HSYNC_WHOLE_LINE - 1);
wire hsync_pulse = (hsync_counter >= (HSYNC_VISIBLE_AREA + HSYNC_FRONT_PORCH - 1) 
    && (hsync_counter < (HSYNC_WHOLE_LINE - HSYNC_BACK_PORCH) - 1));

wire frame_end = (vsync_counter == VSYNC_WHOLE_FRAME - 1);
wire vsync_pulse = (vsync_counter >= (VSYNC_VISIBLE_AREA + VSYNC_FRONT_PORCH - 1)
    && (vsync_counter < (VSYNC_WHOLE_FRAME - VSYNC_SYNC_PULSE) - 1));

always @(posedge clock) begin 
    if (line_end) hsync_counter <= 0;
    else if (enable) hsync_counter <= hsync_counter + 1;
end

always @(posedge clock) begin 
    if (frame_end) vsync_counter <= 0;
    else if (line_end) vsync_counter <= 1;
end

assign hsync = ~hsync_pulse;
assign vsync = ~vsync_pulse;
assign visible_area = (hsync_counter < HSYNC_VISIBLE_AREA && vsync_counter < VSYNC_VISIBLE_AREA) || hsync_counter == HSYNC_WHOLE_LINE - 1;

endmodule
