module msgpu #(
    parameter VGA_RED_BITS = 3, 
    parameter VGA_GREEN_BITS = 3, 
    parameter VGA_BLUE_BITS = 3,
    parameter LED_BITS = 1
)(
    input system_clock,
    input vga_clock,
    output[LED_BITS - 1:0] led,
    output vga_hsync,
    output vga_vsync,
    output[VGA_RED_BITS - 1:0] vga_red,
    output[VGA_GREEN_BITS - 1:0] vga_green, 
    output[VGA_BLUE_BITS - 1:0] vga_blue
);

assign led = 8'hff;

reg reset_vga;
reg enable_vga;

wire[21:0] read_address;
wire[11:0] pixel_data;

always @(posedge system_clock) begin 
    enable_vga = 1;
end

vga #(
    .RED_BITS(VGA_RED_BITS), 
    .GREEN_BITS(VGA_GREEN_BITS), 
    .BLUE_BITS(VGA_BLUE_BITS)
)
vga_instance (
    .reset(reset_vga),
    .clock(vga_clock),
    .enable(enable_vga),
    .hsync(vga_hsync),
    .vsync(vga_vsync),
    .red(vga_red),
    .green(vga_green),
    .blue(vga_blue),
    .buffer_clock(system_clock),
    .read_address(read_address),
    .pixel_data(pixel_data)
);

endmodule 
