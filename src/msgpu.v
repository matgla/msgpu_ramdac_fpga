module msgpu (
   input clock,
   input mcu_bus_clock,
   input [7:0] mcu_bus,
   input mcu_bus_command_data,
   input mcu_bus_enable,
   output hsync,
   output vsync,
   output [3:0] vga_red,
   output [3:0] vga_green,
   output [3:0] vga_blue,
   output [1:0] led
);

pll vga_pll(
   .clkout(CLOCK_SYS),
   .clkoutd(CLOCK_PIXEL),
   .clkin(clock)
);

vga vga_instance(
    .clock(CLOCK_PIXEL),
    .hsync(hsync),
    .vsync(vsync),
    .visible_area(visible_area)
);

mcu_bus mcu(
    .sysclk(clock),
    .busclk(mcu_bus_clock),
    .bus(mcu_bus[7:0]),
    .enable(mcu_bus_enable),
    .command_data(mcu_bus_command_data),
    .data_out(data),
    .led(led[1:0])
);

// assign led[2:0] = (data == 8'hffffffff)? 3b'110 : 3b'101;
// assign led = (data == 8'hff)? 2'b10 : 2'b01;

assign vga_red = (visible_area)? 4'b1111 : 4'b0000;
assign vga_blue = (visible_area)? 4'b1111 : 4'b0000;
assign vga_green = (visible_area)? 4'b1111 : 4'b0000;

endmodule
