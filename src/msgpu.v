module msgpu (
   input clock,
   input mcu_bus_clock,
   inout [7:0] mcu_bus,
   input mcu_bus_command_data,
   output hsync,
   output vsync,
   output [3:0] vga_red,
   output [3:0] vga_green,
   output [3:0] vga_blue,
   output led
);

`ifdef NANO
pll vga_pll(
    /* verilator lint_off IMPLICIT */
   .clkout(CLOCK_SYS),
    /* verilator lint_off IMPLICIT */
   .clkoutd(CLOCK_PIXEL),
   .clkin(clock)
);
`endif

vga vga_instance(
    /* verilator lint_off IMPLICIT */
    .clock(CLOCK_PIXEL),
    .hsync(hsync),
    .vsync(vsync),
    .visible_area(visible_area)
);

reg[7:0] data;
reg dataclk;
reg[31:0] address;

mcu_bus mcu(
    .sysclk(clock),
    .busclk(mcu_bus_clock),
    .bus_in(mcu_bus[7:0]),
    .bus_out(mcu_bus[7:0]),
    .dataclk(dataclk),
    .address(address),
    .command_data(mcu_bus_command_data),
    .data_out(data),
    .led(led)
);

reg write_enable = 1'b0;

// psram frame_buffer(
//     .enable(write_enable)
// );

// assign led[2:0] = (data == 8'hffffffff)? 3b'110 : 3b'101;
// assign led = (data == 8'hff)? 2'b10 : 2'b01;

assign vga_red = (visible_area)? 4'b1111 : 4'b0000;
assign vga_blue = (visible_area)? 4'b1111 : 4'b0000;
assign vga_green = (visible_area)? 4'b1111 : 4'b0000;

endmodule
