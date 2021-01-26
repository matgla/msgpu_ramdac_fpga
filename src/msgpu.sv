`include "mcu_bus_interface.sv"

module msgpu #(
    parameter VGA_RED_BITS = 3, 
    parameter VGA_GREEN_BITS = 3, 
    parameter VGA_BLUE_BITS = 3,
    parameter LED_BITS = 1
)(
    input system_clock,
    
    output reg[LED_BITS - 1:0] led,
    /* ---- VGA ---- */ 
    input vga_clock,
    output vga_hsync,
    output vga_vsync,
    output [VGA_RED_BITS - 1:0] vga_red,
    output [VGA_GREEN_BITS - 1:0] vga_green, 
    output [VGA_BLUE_BITS - 1:0] vga_blue,
    /* -END-VGA-END- */
    /* -- MCU BUS -- */ 
    McuBusInterface mcu_bus
    /* ---- END ---- */
);

// assign led = LED_BITS;

wire reset_vga = 0;
reg enable_vga;
wire[21:0] read_address;
wire [11:0] pixel_data = 0; 

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

wire mcu_command_clock = 0;
wire mcu_data_clock = 0; 
wire [7:0] mcu_data = 0;
wire [7:0] mcu_data_in = 0;

McudBus mcu(
    .bus(mcu_bus),
    .dataclk(mcu_data_clock),
    .cmdclk(mcu_command_clock),
    .data_out(mcu_data),
    .data_in(mcu_data_in)
);

reg [22:0] counter;

reg [63:0] buffer;

always @(posedge mcu_data_clock) begin 
    buffer <= { buffer[31:0], mcu_data };
    if (buffer == 32'h0ff0ab12) led <= ~led;
end

endmodule 
