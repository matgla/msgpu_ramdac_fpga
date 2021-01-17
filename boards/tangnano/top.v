module top(
    input clock, 
    output wire led,
    output wire hsync,
    output wire vsync,
    output wire[3:0] vga_red,
    output wire[3:0] vga_green,
    output wire[3:0] vga_blue
);

wire system_clock; // 201.6 MHz 
wire vga_clock; // 25.175 MHz 
wire psram_clock; //67.3 MHz 

pll pll_instance(
    .clkout(system_clock),
    .clkoutd(vga_clock),
    .clkin(clock)
);

msgpu #(.VGA_RED_BITS(4),
    .VGA_GREEN_BITS(4),
    .VGA_BLUE_BITS(4),
    .LED_BITS(1)
)
msgpu_instance(
    .system_clock(system_clock),
    .vga_clock(vga_clock),
    .led(led),
    .vga_vsync(vsync),
    .vga_hsync(hsync),
    .vga_red(vga_red),
    .vga_green(vga_green),
    .vga_blue(vga_blue)
);

endmodule
