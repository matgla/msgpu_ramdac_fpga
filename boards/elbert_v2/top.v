module gpu(
    input Clk,
    output[7:0] LED,
    output HSync, 
    output VSync, 
    output[2:0] Red, 
    output[2:0] Green,
    output[1:0] Blue
);

reg pll_reset;

wire vga_clock;
wire clock_0;
wire clock_2x;
wire clock_180;

wire locked_out;
wire ibuf_out;

pll pll(
    .CLKIN_IN(Clk),
    .RST_IN(pll_reset),
    .CLKFX_OUT(vga_clock),
    .CLKIN_IBUFG_OUT(ibuf_out),
    .CLK0_OUT(clock_0),
    .CLK2X_OUT(clock_2x),
    .CLK180_OUT(clock_180),
    .LOCKED_OUT(locked_out)
);

msgpu #(.VGA_RED_BITS(3), 
    .VGA_GREEN_BITS(3), 
    .VGA_BLUE_BITS(2),
    .LED_BITS(8)
)
msgpu_instance(
    .system_clock(clock_180),
    .vga_clock(vga_clock),
    .led(LED),
    .vga_hsync(HSync),
    .vga_vsync(VSync),
    .vga_red(Red),
    .vga_green(Green),
    .vga_blue(Blue)
);

endmodule

